# CargoFlow - Quick Context for New Chat Sessions

**Last Updated:** November 12, 2025  
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

## 🗄️ Database: `Cargo_mail` (PostgreSQL 17)

### Core Tables (19 tables total)
- **emails** (226 records) - Email metadata ✅ Active
- **email_attachments** (296 records) - Files with AI categories ✅ Active
- **processing_queue** (213 records) - Processing queue ⚠️ 61% complete (130/213)
- **contracts** (0 records) - Detected contracts ❌ Empty
- **processing_history** - Processing logs
- **email_ready_queue** - Queue for folder organization
- **contract_detection_queue** - Contract processing queue
- **document_pages** - Page-level categories
- **invoice_base** + **invoice_items** - Invoice data

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

### File Organization Features

**Invoice Naming:**
- Format: `invoice_{invoice_number}_{supplier_name}.pdf`
- Data extracted from `invoice_base` table
- Example: `invoice_2000001866_CARGOFLO_V_LOGISTICS_SARL.pdf`

**Multi-Page Document Splitting:**
- PNG pages grouped by category (from `document_pages` table)
- Separate PDF files created for each category
- Example: 7-page document → `other_50251007351.pdf` (5 pages) + `protocol_50251007351.pdf` (2 pages)
- Text files remain as single documents (not split)

**Page Orientation:**
- Automatic EXIF orientation correction
- 180° rotation applied for inverted pages

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

## 🔧 Key PostgreSQL Triggers (8 triggers total)

| Trigger | Event | Function | Purpose |
|---------|-------|----------|---------|
| `trigger_notify_text` | processing_queue INSERT | `notify_n8n_text_queue()` | Triggers text AI workflow |
| `trigger_notify_image` | processing_queue INSERT | `notify_n8n_image_queue()` | Triggers image AI workflow |
| `trigger_queue_email` | email_attachments UPDATE | `queue_email_for_folder_update()` | Queues for folder organization |
| `contract_detection_trigger` | email_attachments UPDATE | `queue_contract_detection()` | Triggers contract detection |

**Total:** 8 triggers, 13 functions, 19 tables, optimized indexes

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
-- Overall Health Check
SELECT 
    'emails' as metric, COUNT(*)::text as value FROM emails
UNION ALL
SELECT 'attachments', COUNT(*)::text FROM email_attachments
UNION ALL
SELECT 'categorized', COUNT(*)::text FROM email_attachments WHERE document_category IS NOT NULL
UNION ALL
SELECT 'pending_queue', COUNT(*)::text FROM processing_queue WHERE status = 'pending'
UNION ALL
SELECT 'contracts', COUNT(*)::text FROM contracts;

-- Processing Queue Status
SELECT file_type, status, COUNT(*) 
FROM processing_queue 
GROUP BY file_type, status;

-- Recent AI Classifications
SELECT attachment_name, document_category, classification_timestamp
FROM email_attachments
WHERE classification_timestamp > NOW() - INTERVAL '1 day'
ORDER BY classification_timestamp DESC LIMIT 10;

-- Recent Activity Check
SELECT 
    'last_email' as event, 
    MAX(received_time)::text as timestamp 
FROM emails
UNION ALL
SELECT 'last_categorization', MAX(classification_timestamp)::text FROM email_attachments
UNION ALL
SELECT 'last_queue_processing', MAX(processed_at)::text FROM processing_queue;

-- Pending Items Summary
SELECT 
  (SELECT COUNT(*) FROM email_attachments WHERE processing_status = 'pending') as pending_attachments,
  (SELECT COUNT(*) FROM processing_queue WHERE status = 'pending') as pending_queue,
  (SELECT COUNT(*) FROM email_ready_queue WHERE processed = FALSE) as pending_emails;
```

---

## 📊 Current System Status (November 12, 2025)

### Overall Progress: 45% Operational

| Component | Status | Progress | Records |
|-----------|--------|----------|---------|
| Email Extraction | ✅ Working | 100% | 226 emails |
| File Attachments | ✅ Working | 100% | 296 attachments |
| AI Categorization | ⚠️ Partial | 34% | 102/296 categorized |
| Processing Queue | ⚠️ Stalled | 61% | 130/213 completed |
| Contract Detection | ❌ Not Started | 0% | 0 contracts |

### 🎉 Documentation: 100% Complete!
- **19/19 documents** completed (33,000+ lines)
- All modules fully documented
- Complete architecture, deployment, and troubleshooting guides

---

## ⚠️ Known Issues & Action Required

### 🔥 CRITICAL (Must Do Immediately)

1. **Queue Managers stopped** (28 Oct 09:40)
   - 83 files pending in processing_queue
   - No new AI categorization since stop
   - **Action:** Restart text_queue_manager.py and image_queue_manager.py

2. **n8n Workflows Status Unknown**
   - Need to verify if n8n server is running (localhost:5678)
   - Check workflows: `INV_Text_CargoFlow`, `INV_PNG_CargoFlow`
   - **Action:** Verify and restart if needed

3. **Contract Processor Not Running**
   - `contracts` table is empty (0 records)
   - Folder organization not working
   - **Action:** Start `python main.py --continuous` in Cargoflow_Contracts

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

## 📚 Full Documentation (100% Complete!)

**Total:** 19 documents, 33,000+ lines of documentation 🎉

### Core Documentation (8/8 ✅)
- **[README.md](./README.md)** - Complete overview (400+ lines)
- **[SYSTEM_ARCHITECTURE.md](./SYSTEM_ARCHITECTURE.md)** - Architecture details (6000+ lines)
- **[DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md)** - Database documentation (650+ lines)
- **[PROJECT_STATUS.md](./PROJECT_STATUS.md)** - Current status (800+ lines)
- **[DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)** - Deployment instructions (1200+ lines)
- **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)** - Common issues and solutions (1800+ lines)
- **[MODULE_DEPENDENCIES.md](./MODULE_DEPENDENCIES.md)** - Module dependencies (13000+ lines)
- **[STATUS_FLOW_MAP.md](./docs/STATUS_FLOW_MAP.md)** - Complete status flow (650+ lines)

### Module Documentation (6/6 ✅)
- **[01_EMAIL_FETCHER.md](./modules/01_EMAIL_FETCHER.md)** - Email extraction (700+ lines)
- **[02_OCR_PROCESSOR.md](./modules/02_OCR_PROCESSOR.md)** - OCR processing (600+ lines)
- **[03_OFFICE_PROCESSOR.md](./modules/03_OFFICE_PROCESSOR.md)** - Office processing (1000+ lines)
- **[04_QUEUE_MANAGERS.md](./modules/04_QUEUE_MANAGERS.md)** - Queue management (1500+ lines)
- **[05_N8N_WORKFLOWS.md](./modules/05_N8N_WORKFLOWS.md)** - n8n workflows (2000+ lines)
- **[06_CONTRACTS_PROCESSOR.md](./modules/06_CONTRACTS_PROCESSOR.md)** - Contract processor (1000+ lines)

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

---

## 🎯 Definition of "Fully Operational"

System is considered fully operational when:

**✅ Завършени (3/8):**
- [x] ✅ Email extraction running continuously
- [x] ✅ Attachments being saved to disk
- [x] ✅ Complete documentation (19/19 documents)

**⚠️ В процес / ❌ Не завършени (5/8):**
- [ ] ⚠️ **80%+ of attachments categorized by AI** (Current: 34% - трябва 80%+)
- [ ] ⚠️ **Queue processing active (pending < 20%)** (Current: 39% pending - трябва < 20%)
- [ ] ❌ **Contract numbers extracted from documents** (не работи)
- [ ] ❌ **Contracts table populated** (0 записа)
- [ ] ❌ **Files organized into contract folders** (не работи)

**Current Status:** 3/8 criteria met (37.5%)

---

**💡 Tip:** Start with [PROJECT_STATUS.md](./PROJECT_STATUS.md) to see current system state before making changes!
