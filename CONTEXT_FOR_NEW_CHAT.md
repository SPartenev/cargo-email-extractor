# CargoFlow - Quick Context for New Chat Sessions

**Last Updated:** November 05, 2025  
**Read Time:** 5 minutes

---

## 🎯 What is CargoFlow?

An **automated email and document processing system** that:
1. Fetches emails from Microsoft 365 (Graph API)
2. Extracts and saves attachments
3. Processes documents (OCR, Office files)
4. Uses AI to categorize documents (13 categories)
5. Extracts contract numbers
6. Organizes files into structured folders

---

## 📊 System Components (7 Processes)

| Component | Script | Purpose |
|-----------|--------|---------|
| 1. **Email Fetcher** | `graph_email_extractor_v5.py` | Retrieves emails via Graph API |
| 2. **OCR Processor** | (integrated) | Extracts text from PDFs/images |
| 3. **Office Processor** | `office_processor.py` | Processes Word/Excel files |
| 4. **Text Queue** | `text_queue_manager.py` | Queues text files for AI |
| 5. **Image Queue** | `image_queue_manager.py` | Queues images for AI |
| 6. **n8n Workflows** | n8n server | AI categorization |
| 7. **Contract Processor** | `main.py` | Contract detection & organization |

---

## 🗄️ Database: `Cargo_mail` (PostgreSQL)

### Core Tables (4 main)
- **emails** (226 records) - Email metadata
- **email_attachments** (296 records) - Files with AI categories
- **processing_queue** (155 records) - Processing queue
- **contracts** (0 records) - Detected contracts

### Important Columns
- `email_attachments.document_category` - AI-assigned category (13 types)
- `email_attachments.contract_number` - Extracted contract number
- `email_attachments.processing_status` - 'pending' or 'completed'
- `processing_queue.status` - 'pending', 'completed', 'failed'

---

## 🔄 Data Flow (Step-by-Step)

```
1. Microsoft Graph → emails table → C:\CargoAttachments\
                                        ↓
2. OCR/Office → C:\CargoProcessing\ (text + images)
                                        ↓
3. Queue Managers → processing_queue table
                                        ↓
4. PostgreSQL Triggers → n8n webhooks (AI analysis)
                                        ↓
5. n8n AI → email_attachments (category + contract_number)
                                        ↓
6. Contract Processor → Organized folders
```

---

## 📁 File Paths

| Path | Purpose |
|------|---------|
| `C:\CargoAttachments\` | Raw email attachments (by sender/date) |
| `C:\CargoProcessing\` | Processed files (text + images) |
| `C:\Users\Delta\Cargo Flow\...\Документи по договори\` | Organized contracts |

---

## 🎯 Document Categories (13 Types)

AI assigns one of these categories to each document:

1. **contract** - Main contracts
2. **contract_amendment** - Amendments
3. **contract_termination** - Terminations
4. **contract_extension** - Extensions
5. **service_agreement** - Service agreements
6. **framework_agreement** - Framework agreements
7. **cmr** - CMR transport documents
8. **protocol** - Protocols
9. **annex** - Annexes
10. **insurance** - Insurance documents
11. **invoice** - Invoices (→ `invoice_base` table)
12. **credit_note** - Credit notes
13. **other** - Uncategorized

---

## 🔧 Key PostgreSQL Triggers

| Trigger | Event | Function | Purpose |
|---------|-------|----------|---------|
| `trigger_notify_text` | processing_queue INSERT | `notify_n8n_text_queue()` | Triggers text AI workflow |
| `trigger_notify_image` | processing_queue INSERT | `notify_n8n_image_queue()` | Triggers image AI workflow |
| `trigger_queue_email` | email_attachments UPDATE | `queue_email_for_folder_update()` | Queues for folder organization |
| `contract_detection_trigger` | email_attachments UPDATE | `queue_contract_detection()` | Triggers contract detection |

---

## 🚀 How to Start the System

**Open 7 terminals and run:**

```bash
# 1. Email Fetcher
cd C:\Python_project\CargoFlow\Cargoflow_mail
venv\Scripts\activate
python graph_email_extractor_v5.py

# 2-3. OCR + Office (if separate)
# ... similar pattern ...

# 4. Text Queue
cd C:\Python_project\CargoFlow\Cargoflow_Queue
venv\Scripts\activate
python text_queue_manager.py

# 5. Image Queue
python image_queue_manager.py

# 6. Contract Processor
cd C:\Python_project\CargoFlow\Cargoflow_Contracts
venv\Scripts\activate
python main.py --continuous

# 7. n8n
n8n start
```

---

## 📊 Quick Diagnostic Queries

```sql
-- System Status
SELECT 'emails' as table_name, COUNT(*) FROM emails
UNION ALL
SELECT 'attachments', COUNT(*) FROM email_attachments
UNION ALL
SELECT 'queue', COUNT(*) FROM processing_queue;

-- Processing Queue Status
SELECT file_type, status, COUNT(*) 
FROM processing_queue 
GROUP BY file_type, status;

-- Recent AI Classifications
SELECT attachment_name, document_category, classification_timestamp
FROM email_attachments
WHERE classification_timestamp > NOW() - INTERVAL '1 day'
ORDER BY classification_timestamp DESC LIMIT 10;

-- Pending Items
SELECT 
  (SELECT COUNT(*) FROM email_attachments WHERE processing_status = 'pending') as pending_attachments,
  (SELECT COUNT(*) FROM processing_queue WHERE status = 'pending') as pending_queue,
  (SELECT COUNT(*) FROM email_ready_queue WHERE processed = FALSE) as pending_emails;
```

---

## ⚠️ Known Issues (from 30 Oct 2025)

1. **Queue Managers stopped** (28 Oct 09:40)
   - No new processing since then
   - Need restart

2. **AI Categorization stopped** (28 Oct 13:30)
   - 122 completed files without categories
   - n8n workflow may need restart

3. **contracts table empty**
   - Folder organization not running
   - Need to process `email_ready_queue`

---

## 🔍 Common Tasks

### Check if system is running
```sql
SELECT MAX(classification_timestamp) FROM email_attachments; -- Should be recent
SELECT MAX(processed_at) FROM processing_queue; -- Should be recent
```

### Restart stalled queue
```bash
cd C:\Python_project\CargoFlow\Cargoflow_Queue
venv\Scripts\activate
python text_queue_manager.py  # or image_queue_manager.py
```

### Check n8n status
- Open: http://localhost:5678
- Check workflows: `INV_Text_CargoFlow`, `INV_PNG_CargoFlow`

---

## 📚 Full Documentation

For detailed information, see:
- **[README.md](./README.md)** - Complete overview
- **[SYSTEM_ARCHITECTURE.md](./SYSTEM_ARCHITECTURE.md)** - Architecture details
- **[DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md)** - Database documentation
- **[PROJECT_STATUS.md](./PROJECT_STATUS.md)** - Current status
- **[modules/](./modules/)** - Module-specific documentation

---

## 🆘 Emergency Commands

```sql
-- Kill long-running queries
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE state = 'active' AND query_start < NOW() - INTERVAL '5 minutes';

-- Reset failed queue items
UPDATE processing_queue 
SET status = 'pending', attempts = 0 
WHERE status = 'failed' AND attempts >= max_attempts;

-- Check database connections
SELECT count(*) FROM pg_stat_activity WHERE datname = 'Cargo_mail';
```

---

## 📞 Quick Reference

| Item | Value |
|------|-------|
| Database | `Cargo_mail` @ localhost:5432 |
| n8n | http://localhost:5678 |
| Python | 3.11+ |
| Main Email | pa@cargo-flow.fr |
| Graph API | Microsoft 365 |

---

**💡 Tip:** Start with [PROJECT_STATUS.md](./PROJECT_STATUS.md) to see current system state before making changes!
