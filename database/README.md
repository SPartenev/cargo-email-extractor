# Database Documentation

**Database:** Cargo_mail (PostgreSQL 17)  
**Location:** localhost:5432  
**Last Updated:** November 12, 2025

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

**Available Files:**
- `01_all_tables.sql` - All 19 table CREATE statements

**Usage:**
```bash
# Create all tables
psql -U postgres -d Cargo_mail -f schema/01_all_tables.sql
```

**Tables Included:**
- Core tables: emails, email_attachments, processing_queue, contracts
- Invoice tables: invoice_base, invoice_items
- Queue tables: email_ready_queue, contract_detection_queue
- Support tables: document_pages, contract_folder_seq, processing_history
- And 8 more tables

---

## ⚡ Triggers

### `triggers/`

**Purpose:** PostgreSQL triggers for automation and workflow integration.

**Available Files:**
- `01_all_triggers.sql` - All 8 trigger CREATE statements

**Active Triggers (8):**
1. `trigger_notify_text` - Notifies n8n when text file added to queue
2. `trigger_notify_image` - Notifies n8n when image added to queue
3. `trigger_notify_image_group_ready` - Notifies n8n when all image pages ready
4. `trigger_queue_email` - Queues email when all attachments classified
5. `contract_detection_trigger` - Triggers contract detection
6. `trigger_process_email_contracts` - Processes email contracts
7. `trigger_match_attachment_on_insert` - Matches attachments on queue insert
8. `trigger_update_queue_attachment_id` - Updates queue with attachment IDs

**Usage:**
```bash
# Create all triggers (requires functions to be created first)
psql -U postgres -d Cargo_mail -f triggers/01_all_triggers.sql
```

---

## 🔧 Functions

### `functions/`

**Purpose:** PostgreSQL functions used by triggers and application logic.

**Available Files:**
- `01_all_functions.sql` - All 15 function CREATE statements

**Active Functions (15):**
- `notify_n8n_text_queue()` - NOTIFY for text processing
- `notify_n8n_image_queue()` - NOTIFY for image processing
- `notify_n8n_image_group_ready()` - NOTIFY when image group ready
- `queue_email_for_folder_update()` - Queue email for organization
- `queue_contract_detection()` - Queue for contract detection
- `process_email_contracts()` - Process email contracts
- `match_attachment_on_queue_insert()` - Match attachments on insert
- `update_queue_attachment_id()` - Update queue with attachment IDs
- `get_contracts_by_email()` - Get contracts for email
- `get_invoice_json()` - Get invoice as JSON
- `get_pending_contract_detections()` - Get pending detections
- `mark_detection_completed()` - Mark detection as completed
- `mark_detection_error()` - Mark detection with error
- `generate_microinvest_csv_for_email()` - Generate CSV for accounting

**Usage:**
```bash
# Create all functions (must be created before triggers)
psql -U postgres -d Cargo_mail -f functions/01_all_functions.sql
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

- **[DATABASE_SCHEMA.md](../reference/DATABASE_SCHEMA.md)** - Complete schema documentation
- **[STATUS_FLOW_MAP.md](../reference/STATUS_FLOW_MAP.md)** - Trigger points and data flow
- **[SYSTEM_ARCHITECTURE.md](../SYSTEM_ARCHITECTURE.md)** - System architecture

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

## 📋 Installation Order

**Important:** Functions must be created before triggers!

```bash
# 1. Create all tables
psql -U postgres -d Cargo_mail -f schema/01_all_tables.sql

# 2. Create all functions
psql -U postgres -d Cargo_mail -f functions/01_all_functions.sql

# 3. Create all triggers (depends on functions)
psql -U postgres -d Cargo_mail -f triggers/01_all_triggers.sql
```

---

**Last Updated:** November 12, 2025  
**Status:** SQL files generated from live database
