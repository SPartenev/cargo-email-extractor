# CargoFlow - Troubleshooting Guide

**Version:** 1.0  
**Last Updated:** November 12, 2025  
**Purpose:** Comprehensive troubleshooting for all CargoFlow components

---

## 📋 Quick Navigation

- [Quick Diagnostic Guide](#quick-diagnostic-guide) - 5-minute system health check
- [Component Issues](#component-specific-issues) - Email, OCR, Queue, n8n, Contracts
- [Error Reference](#error-message-reference) - Common errors and solutions
- [Database Issues](#database-issues) - Locks, slow queries, corruption
- [Performance](#performance-issues) - CPU, memory, disk optimization
- [Recovery](#recovery-procedures) - System restart, backup restore

---

## 🚨 Quick Diagnostic Guide

### Step 1: Check All Processes (30 seconds)

```powershell
# Check Python processes
Get-Process python | Select-Object Id, ProcessName, StartTime

# Check n8n
Get-Process node | Select-Object Id, ProcessName, StartTime
```

**Expected:** 6 Python + 1 Node.js processes

---

### Step 2: Database Quick Check (30 seconds)

```sql
-- Recent activity
SELECT MAX(received_time) FROM emails;  -- Should be recent
SELECT MAX(classification_timestamp) FROM email_attachments WHERE document_category IS NOT NULL;  -- Within 15 min

-- Pending counts (should be low)
SELECT COUNT(*) FROM processing_queue WHERE status='pending';
SELECT COUNT(*) FROM email_attachments WHERE processing_status='pending';
```

---

### Step 3: n8n Status (15 seconds)

```bash
curl http://localhost:5678
# Expected: HTTP 200 or HTML response
```

---

## 🔧 Component-Specific Issues

### Email Fetcher

**Issue: Authentication Failed**

Symptoms: `AADSTS700016` or `AADSTS7000215`

Solutions:
1. Verify `client_id`, `client_secret`, `tenant_id` in config
2. Check secret not expired (24 months max)
3. Grant admin consent in Azure AD

**Issue: No Emails Retrieved**

Check:
- Correct `user_email` in config
- Mailbox has emails
- Inbox folder name matches

---

### OCR Processor

**Issue: Tesseract Not Found**

```bash
# Install Tesseract
# Download from: github.com/UB-Mannheim/tesseract
# Add to PATH: C:\Program Files\Tesseract-OCR
```

**Issue: Poor Quality**

- Check source PDF quality
- Files with score < 0.5 marked for review
- Adjust OCR parameters if needed

---

### Queue Managers

**Issue: Manager Stopped**

```bash
# Restart
cd C:\Python_project\CargoFlow\Cargoflow_Queue
venv\Scripts\activate
python text_queue_manager.py  # or image_queue_manager.py
```

**Issue: Webhook Fails**

- Check n8n running: `curl http://localhost:5678`
- Verify workflow active in n8n UI
- Test webhook: `curl -X POST http://localhost:5678/webhook/analyze-text`

---

### n8n Workflows

**Issue: Execution Fails**

1. Open http://localhost:5678 → Executions
2. Click failed execution
3. Review error node

Common fixes:
- PostgreSQL credentials incorrect
- AI API key expired
- Timeout (increase in settings)

---

### Contract Processor

**Issue: Contracts Table Empty**

```sql
-- Check if contract numbers extracted
SELECT COUNT(*) FROM email_attachments WHERE contract_number IS NOT NULL;

-- If > 0, start processor
cd C:\Python_project\CargoFlow\Cargoflow_Contracts
venv\Scripts\activate
python main.py --continuous
```

---

## 📚 Error Message Reference

| Error | Component | Solution |
|-------|-----------|----------|
| AADSTS700016 | Email | Verify client_id |
| AADSTS7000215 | Email | Create new secret |
| TesseractNotFoundError | OCR | Install Tesseract, add to PATH |
| ConnectionRefusedError | Queue | Start n8n server |
| psycopg2.OperationalError | All | Check PostgreSQL running |

---

## 🗄️ Database Issues

### Slow Queries

```sql
-- Find slow queries
SELECT query, calls, mean_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC LIMIT 10;

-- Add indexes
CREATE INDEX idx_name ON table(column);
```

### Database Locks

```sql
-- Find blocking queries
SELECT blocked_locks.pid AS blocked_pid,
       blocking_locks.pid AS blocking_pid,
       blocked_activity.query AS blocked_statement
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
-- [full query in detailed docs]

-- Kill blocker
SELECT pg_terminate_backend([blocking_pid]);
```

---

## ⚡ Performance Issues

### High CPU

- Limit concurrent OCR processes
- Optimize database queries
- Reduce AI API call frequency

### High Memory

- Restart processes periodically
- Process files in chunks
- Close connections properly

### Disk Space Low

```bash
# Archive old files
forfiles /P "C:\CargoAttachments" /D -90 /C "cmd /c move @path C:\Archive"

# Delete old logs
forfiles /P "logs" /M *.log /D -30 /C "cmd /c del @path"

# Clean database
DELETE FROM processing_history WHERE created_at < NOW() - INTERVAL '180 days';
VACUUM FULL;
```

---

## 🔄 Recovery Procedures

### Complete System Restart

1. Stop all processes: `Get-Process python | Stop-Process`
2. Check database: `psql -U postgres -d Cargo_mail`
3. Restart PostgreSQL: `net restart postgresql-17`
4. Restart all 7 components

### Database Recovery

```bash
# Backup current state
pg_dump -U postgres -d Cargo_mail -F c -f emergency_backup.dump

# Restore from backup
pg_restore -U postgres -d Cargo_mail backup.dump
```

### Clear Stuck Queue

```sql
-- Reset items pending > 24 hours
UPDATE processing_queue 
SET status = 'pending', attempts = 0
WHERE status = 'pending' 
AND created_at < NOW() - INTERVAL '24 hours';
```

---

## 🔍 Monitoring & Prevention

### Daily Health Check

```sql
-- Save as: daily_health_check.sql
SELECT MAX(received_time) as last_email FROM emails;
SELECT MAX(classification_timestamp) as last_category FROM email_attachments;
SELECT COUNT(*) as pending FROM processing_queue WHERE status='pending';
```

### Weekly Maintenance

```sql
VACUUM ANALYZE;
REINDEX DATABASE Cargo_mail;
```

### Monthly Tasks

- Full database backup
- Archive old files (> 90 days)
- Clean logs (> 30 days)
- Review slow queries

---

## 📞 Getting Help

Before asking for help:
1. Check this guide
2. Review error logs
3. Run health checks
4. Document the issue

Include when reporting:
- Component affected
- Exact error message
- When it started
- Log excerpts
- Database state

---

**For detailed troubleshooting, see full documentation:**
- DEPLOYMENT_GUIDE.md
- STATUS_FLOW_MAP.md  
- Module-specific docs in `modules/`

---

**Version:** 1.0  
**Last Updated:** November 12, 2025
