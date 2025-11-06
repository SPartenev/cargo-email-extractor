# Database Documentation

**Database:** Cargo_mail (PostgreSQL 17)  
**Location:** localhost:5432  
**Last Updated:** November 06, 2025

---

## 📁 Folder Structure

```
database/
├── schema/          # Table definitions, indexes, constraints
├── triggers/        # Database triggers
├── functions/       # PostgreSQL functions
└── README.md        # This file
```

---

## 📊 Database Overview

### Core Tables (8)
- **emails** - Email metadata from Microsoft Graph API
- **email_attachments** - File attachments with AI categorization
- **processing_queue** - Queue for AI processing
- **processing_history** - Processing logs
- **contracts** - Detected contracts
- **email_ready_queue** - Emails ready for organization
- **contract_folder_seq** - Folder index sequence
- **document_pages** - Individual page categories

### Supporting Tables (3)
- **invoice_base** - Invoice header data
- **invoice_items** - Invoice line items
- **contract_detection_queue** - Contract detection queue

---

## 🗂️ Schema Files

### `schema/`

**Purpose:** Contains SQL scripts for creating tables, indexes, and constraints.

**Files to create:**
- `tables.sql` - All table CREATE statements
- `indexes.sql` - All index definitions
- `constraints.sql` - Foreign keys and constraints
- `views.sql` - Database views (e.g., invoice_full_view)

**Usage:**
```bash
# Create all tables
psql -U postgres -d Cargo_mail -f schema/tables.sql

# Create indexes
psql -U postgres -d Cargo_mail -f schema/indexes.sql

# Add constraints
psql -U postgres -d Cargo_mail -f schema/constraints.sql
```

---

## ⚡ Triggers

### `triggers/`

**Purpose:** PostgreSQL triggers for automation and workflow integration.

**Active Triggers (4):**
1. `trigger_notify_text` - Notifies n8n when text file added to queue
2. `trigger_notify_image` - Notifies n8n when image added to queue
3. `trigger_queue_email` - Queues email when all attachments classified
4. `contract_detection_trigger` - Triggers contract detection

**Files to create:**
- `email_triggers.sql` - Email-related triggers
- `queue_triggers.sql` - Processing queue triggers
- `contract_triggers.sql` - Contract detection triggers

**Usage:**
```bash
# Create all triggers
psql -U postgres -d Cargo_mail -f triggers/email_triggers.sql
psql -U postgres -d Cargo_mail -f triggers/queue_triggers.sql
psql -U postgres -d Cargo_mail -f triggers/contract_triggers.sql
```

---

## 🔧 Functions

### `functions/`

**Purpose:** PostgreSQL functions used by triggers and application logic.

**Active Functions (13):**
- `notify_n8n_text_queue()` - NOTIFY for text processing
- `notify_n8n_image_queue()` - NOTIFY for image processing
- `queue_email_for_folder_update()` - Queue email for organization
- `queue_contract_detection()` - Queue for contract detection
- And 9 more utility functions

**Files to create:**
- `notify_functions.sql` - NOTIFY/LISTEN functions
- `queue_functions.sql` - Queue management functions
- `utility_functions.sql` - Helper functions

**Usage:**
```bash
# Create all functions
psql -U postgres -d Cargo_mail -f functions/notify_functions.sql
psql -U postgres -d Cargo_mail -f functions/queue_functions.sql
psql -U postgres -d Cargo_mail -f functions/utility_functions.sql
```

---

## 🔗 Database Connection

### Connection Details

```python
DB_CONFIG = {
    'host': 'localhost',
    'port': 5432,
    'database': 'Cargo_mail',
    'user': 'postgres',
    'password': 'Lora24092004'  # Change in production!
}
```

### Connection String

```
postgresql://postgres:Lora24092004@localhost:5432/Cargo_mail
```

---

## 📈 Database Statistics (Nov 06, 2025)

| Table | Records | Status |
|-------|---------|--------|
| emails | 226 | ✅ Active |
| email_attachments | 296 | ✅ Active |
| processing_queue | 213 | ⚠️ 83 pending |
| contracts | 0 | ❌ Empty |
| email_ready_queue | 9 | ⚠️ Unprocessed |

---

## 🔄 Common Operations

### Check Database Health
```sql
-- Overall system health
SELECT 
    'emails' as table_name, 
    COUNT(*) as records
FROM emails
UNION ALL
SELECT 'email_attachments', COUNT(*) FROM email_attachments
UNION ALL
SELECT 'processing_queue', COUNT(*) FROM processing_queue
UNION ALL
SELECT 'contracts', COUNT(*) FROM contracts;
```

### Check Processing Status
```sql
-- Email attachment status distribution
SELECT 
    processing_status,
    COUNT(*) as count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) as percentage
FROM email_attachments
GROUP BY processing_status
ORDER BY count DESC;
```

### Check Queue Status
```sql
-- Processing queue by status
SELECT 
    file_type,
    status,
    COUNT(*) as count
FROM processing_queue
GROUP BY file_type, status
ORDER BY file_type, status;
```

---

## 🛠️ Maintenance

### Daily Maintenance
```sql
-- Vacuum analyze for performance
VACUUM ANALYZE emails;
VACUUM ANALYZE email_attachments;
VACUUM ANALYZE processing_queue;
```

### Weekly Maintenance
```sql
-- Reindex for optimal performance
REINDEX TABLE emails;
REINDEX TABLE email_attachments;
REINDEX TABLE processing_queue;
```

### Backup
```bash
# Full database backup
pg_dump -U postgres -d Cargo_mail -F c -f backup_$(date +%Y%m%d).dump

# Restore from backup
pg_restore -U postgres -d Cargo_mail backup_20251106.dump
```

---

## 📚 Related Documentation

- **[DATABASE_SCHEMA.md](../docs/DATABASE_SCHEMA.md)** - Complete schema documentation (planned)
- **[STATUS_FLOW_MAP.md](../docs/STATUS_FLOW_MAP.md)** - Trigger points and data flow
- **[SYSTEM_ARCHITECTURE.md](../docs/SYSTEM_ARCHITECTURE.md)** - System architecture (planned)

---

## 🚨 Important Notes

### Security
- **Never commit passwords to Git!**
- Use environment variables for production
- Rotate credentials regularly
- Use SSL connections in production

### Performance
- 44 indexes optimized for common queries
- Keep-alive connections prevent timeouts
- Connection pooling recommended for production

### Known Issues
- Heavy trigger replaced with lightweight queue system (29 Oct 2025)
- Long-running queries terminated automatically after 10 minutes

---

**Last Updated:** November 06, 2025  
**Status:** Documentation in progress
