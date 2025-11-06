# CargoFlow - Status Flow Map & System Dependencies

**Created:** November 06, 2025  
**Version:** 1.0  
**Purpose:** Complete map of all statuses, dependencies, and data flows in CargoFlow system

---

## 📊 Table of Contents

1. [System Overview](#system-overview)
2. [Component Modules](#component-modules)
3. [Status Flow Diagram](#status-flow-diagram)
4. [Status Definitions](#status-definitions)
5. [Database Tables](#database-tables)
6. [Trigger Points](#trigger-points)
7. [Module Dependencies](#module-dependencies)
8. [Data Flow Paths](#data-flow-paths)
9. [Error Handling](#error-handling)
10. [Recovery Procedures](#recovery-procedures)

---

## 🎯 System Overview

CargoFlow is an **automated email and document processing system** with **7 interconnected components** working together to process emails, extract attachments, categorize documents, extract contract numbers, and organize files.

### Core Workflow
```
Email → Extraction → Processing → AI Categorization → Contract Detection → Organization
```

### Current Status (Nov 06, 2025)
- **Total Emails:** 226
- **Total Attachments:** 296
- **Categorized:** 102 (34%)
- **Queue Pending:** 83
- **Contracts Detected:** 0

---

## 🧩 Component Modules

| # | Module | Script | Status | Purpose |
|---|--------|--------|--------|---------|
| 1 | **Email Fetcher** | `graph_email_extractor_v5.py` | ✅ Active | Fetches emails from Microsoft 365 Graph API |
| 2 | **OCR Processor** | `ocr_processor.py` | ✅ Active | Extracts text from PDF/images using OCR |
| 3 | **Office Processor** | `office_processor.py` | ✅ Active | Processes Word/Excel documents |
| 4 | **Text Queue Manager** | `text_queue_manager.py` | ⚠️ Stopped | Queues text files for AI analysis |
| 5 | **Image Queue Manager** | `image_queue_manager.py` | ⚠️ Stopped | Queues PNG images for AI analysis |
| 6 | **n8n Workflows** | n8n server (localhost:5678) | ⚠️ Unknown | AI categorization + invoice extraction |
| 7 | **Contract Processor** | `main.py` (Cargoflow_Contracts) | ❌ Not Started | Contract detection & folder organization |

---

## 📈 Status Flow Diagram

### Main Status Flow (email_attachments.processing_status)

```
┌─────────────────────────────────────────────────────────────────────┐
│                      EMAIL ATTACHMENT LIFECYCLE                      │
└─────────────────────────────────────────────────────────────────────┘

[1] NEW EMAIL
    ↓
    │ Microsoft Graph API
    │ graph_email_extractor_v5.py
    ↓
┌─────────────┐
│   pending   │  ← Initial state when attachment is saved
└─────────────┘
    ↓
    │ File identified for processing
    │ OCR Processor OR Office Processor
    ↓
┌─────────────┐
│ processing  │  ← File being extracted (OCR/Office)
└─────────────┘
    ↓
    │ Text/PNG extraction completed
    │ Saved to C:\CargoProcessing\
    ↓
┌─────────────┐
│ completed   │  ← File successfully processed
└─────────────┘
    ↓
    │ Added to processing_queue
    │ Queue Manager → n8n webhook
    ↓
┌─────────────┐
│  queued     │  ← Sent to n8n for AI analysis
└─────────────┘
    ↓
    │ AI categorization completed
    │ n8n → UPDATE email_attachments
    ↓
┌─────────────┐
│ classified  │  ← document_category assigned
└─────────────┘  ← contract_number extracted (if applicable)
    ↓
    │ All attachments for email classified
    │ Trigger: trigger_queue_email
    ↓
┌─────────────┐
│group_ready  │  ← Email ready for contract organization
└─────────────┘  ← Added to email_ready_queue
    ↓
    │ Contract Processor
    │ main.py --continuous
    ↓
┌─────────────┐
│  organized  │  ← Files moved to organized folders
└─────────────┘  ← contracts table populated


ERROR STATES:
┌─────────────┐
│   failed    │  ← Processing error (OCR/Office/n8n failure)
└─────────────┘
    ↓
    │ Retry mechanism (max 3 attempts)
    ↓
    ├─→ [retry] → back to processing
    └─→ [max attempts] → permanent failure

┌─────────────┐
│  duplicate  │  ← Duplicate file detected
└─────────────┘
```

### Processing Queue Status Flow (processing_queue.status)

```
┌─────────────────────────────────────────────────────────────────────┐
│                      PROCESSING QUEUE LIFECYCLE                      │
└─────────────────────────────────────────────────────────────────────┘

[File added to queue]
    ↓
┌─────────────┐
│   pending   │  ← Waiting for queue manager to pick up
└─────────────┘
    ↓
    │ Queue Manager picks file
    │ text_queue_manager.py OR image_queue_manager.py
    ↓
┌─────────────┐
│   sending   │  ← Sending to n8n webhook
└─────────────┘
    ↓
    │ n8n webhook response received
    ↓
┌─────────────┐
│  completed  │  ← Successfully sent to n8n
└─────────────┘
    ↓
    │ n8n workflow processes file
    │ AI analysis completed
    ↓
[email_attachments updated with category]


ERROR STATE:
┌─────────────┐
│   failed    │  ← Webhook error or n8n unavailable
└─────────────┘
    ↓
    │ attempts < max_attempts (3)
    ↓
    ├─→ [retry after delay] → back to pending
    └─→ [max attempts reached] → permanent failure
```

---

## 📝 Status Definitions

### email_attachments.processing_status

| Status | Meaning | Set By | Next Step |
|--------|---------|--------|-----------|
| `pending` | Attachment saved, not yet processed | Email Fetcher | OCR/Office Processor picks it up |
| `processing` | Currently being processed (OCR/Office) | OCR/Office Processor | Extract text/images |
| `completed` | Text/PNG extraction done | OCR/Office Processor | Queue Manager adds to processing_queue |
| `queued` | Added to processing_queue | Queue Manager | n8n webhook triggered |
| `classified` | AI categorization done | n8n Workflow | Trigger checks if all attachments done |
| `group_ready` | All email attachments classified | PostgreSQL Trigger | Contract Processor organizes |
| `organized` | Files moved to organized folders | Contract Processor | Final state ✅ |
| `failed` | Processing error occurred | OCR/Office/Queue | Retry or manual intervention |
| `duplicate` | Duplicate file detected | System | Skip processing |

### processing_queue.status

| Status | Meaning | Set By | Next Step |
|--------|---------|--------|-----------|
| `pending` | Waiting to be sent to n8n | Queue Manager | Send to n8n webhook |
| `sending` | Currently sending to n8n | Queue Manager | Wait for response |
| `completed` | Successfully sent to n8n | Queue Manager | n8n processes file |
| `failed` | Webhook/n8n error | Queue Manager | Retry (max 3 attempts) |

### email_ready_queue.processed

| Value | Meaning | Set By | Next Step |
|-------|---------|--------|-----------|
| `FALSE` | Email ready for organization | PostgreSQL Trigger | Contract Processor picks it up |
| `TRUE` | Organization completed | Contract Processor | Final state ✅ |

---

## 🗂️ Database Tables

### Core Tables

| Table | Records | Purpose | Key Columns |
|-------|---------|---------|-------------|
| **emails** | 226 | Email metadata | id, subject, sender_email, received_time, attachment_folder |
| **email_attachments** | 296 | File metadata + AI results | id, email_id, filename, processing_status, document_category, contract_number |
| **processing_queue** | 213 | Queue for AI processing | id, file_path, status, attachment_id, attempts |
| **processing_history** | ~1,380 | Processing logs | id, file_path, status, error_message, processing_time_ms |
| **contracts** | 0 | Detected contracts | id, contract_number, email_id, created_at |
| **email_ready_queue** | 9 | Emails ready for organization | email_id, ready_at, processed |
| **contract_folder_seq** | 0 | Folder index sequence | contract_key, last_index |
| **document_pages** | 14 | Individual page categories | id, attachment_id, page_number, category, contract_number |

### Supporting Tables

| Table | Records | Purpose |
|-------|---------|---------|
| **invoice_base** | 46 | Invoice header data |
| **invoice_items** | ? | Invoice line items |
| **contract_detection_queue** | 107 | Contract detection queue |

---

## ⚡ Trigger Points

### PostgreSQL Triggers

| Trigger | Table | Event | Function | Purpose |
|---------|-------|-------|----------|---------|
| `trigger_notify_text` | processing_queue | INSERT | `notify_n8n_text_queue()` | Notifies n8n when text file added |
| `trigger_notify_image` | processing_queue | INSERT | `notify_n8n_image_queue()` | Notifies n8n when image added |
| `trigger_queue_email` | email_attachments | UPDATE | `queue_email_for_folder_update()` | Queues email when all attachments classified |
| `contract_detection_trigger` | email_attachments | UPDATE | `queue_contract_detection()` | Triggers contract detection |

### Trigger Conditions

**trigger_queue_email:**
```sql
-- Fires when:
-- 1. processing_status changes to 'classified'
-- 2. ALL attachments for that email are 'classified'
-- 
-- Action: INSERT into email_ready_queue
```

**trigger_notify_text/image:**
```sql
-- Fires when:
-- 1. New record INSERT into processing_queue
-- 2. status = 'pending'
-- 
-- Action: PostgreSQL NOTIFY → n8n listens
```

---

## 🔗 Module Dependencies

### Dependency Graph

```
┌─────────────────────────────────────────────────────────────────────┐
│                         MODULE DEPENDENCIES                          │
└─────────────────────────────────────────────────────────────────────┘

Level 1: Data Ingestion
┌──────────────────┐
│ Email Fetcher    │ → Depends on: Microsoft Graph API
│ (Independent)    │ → Outputs: emails, email_attachments (pending)
└──────────────────┘

Level 2: File Processing
┌──────────────────┐
│ OCR Processor    │ → Depends on: email_attachments (pending)
│                  │ → Outputs: TXT files, PNG images
└──────────────────┘
         │
         ├──────────────────┐
         ↓                  ↓
┌──────────────────┐  ┌──────────────────┐
│ Office Processor │  │ Text Queue Mgr   │
│                  │  │ Image Queue Mgr  │
└──────────────────┘  └──────────────────┘
    Depends on:            Depends on:
    - Attachments          - C:\CargoProcessing\
    - MS Office DLLs       - processing_queue
                           - n8n webhooks

Level 3: AI Processing
┌──────────────────┐
│ n8n Workflows    │ → Depends on: Queue Managers
│                  │ → Outputs: document_category, contract_number
└──────────────────┘
    Depends on:
    - OpenAI API (or Google Gemini)
    - PostgreSQL NOTIFY/LISTEN

Level 4: Organization
┌──────────────────┐
│ Contract         │ → Depends on: email_ready_queue
│ Processor        │ → Outputs: contracts, organized folders
└──────────────────┘
    Depends on:
    - All attachments classified
    - contract_number extracted
```

### Critical Dependencies

**Email Fetcher → All Other Modules**
- Without emails, nothing else can work
- **Status:** ✅ Working

**OCR/Office → Queue Managers**
- Queue managers need processed files
- **Status:** ✅ OCR/Office working, ⚠️ Queue managers stopped

**Queue Managers → n8n**
- n8n needs queue managers to send files
- **Status:** ⚠️ Both stopped (28 Oct 09:40)

**n8n → Contract Processor**
- Contract processor needs contract_number from AI
- **Status:** ⚠️ n8n status unknown, ❌ Contract processor not started

### Blocking Issues

```
ISSUE #1: Queue Managers Stopped
├─ Blocks: AI categorization
├─ Impact: 83 files pending in processing_queue
└─ Fix: Restart text_queue_manager.py & image_queue_manager.py

ISSUE #2: n8n Status Unknown
├─ Blocks: AI categorization
├─ Impact: No new document_category assignments
└─ Fix: Check http://localhost:5678

ISSUE #3: Contract Processor Not Started
├─ Blocks: File organization
├─ Impact: contracts table empty (0 records)
└─ Fix: Start main.py --continuous
```

---

## 🔄 Data Flow Paths

### Path 1: Email → Classified Document

```
[1] Microsoft Graph API
    ↓ graph_email_extractor_v5.py
    ↓ INSERT INTO emails, email_attachments (pending)
    ↓ Save to C:\CargoAttachments\{sender}\{date}\{subject}\
    ↓
[2] OCR Processor / Office Processor
    ↓ SELECT FROM email_attachments WHERE processing_status = 'pending'
    ↓ UPDATE processing_status = 'processing'
    ↓ Extract text → C:\CargoProcessing\...\ocr_results\{file}_extracted.txt
    ↓ Extract images → C:\CargoProcessing\...\images\{file}_1.png
    ↓ UPDATE processing_status = 'completed'
    ↓
[3] Queue Manager
    ↓ Watch C:\CargoProcessing\... for new files
    ↓ INSERT INTO processing_queue (pending, file_path, attachment_id)
    ↓ PostgreSQL Trigger → NOTIFY n8n_channel_text/image_ready
    ↓
[4] n8n Workflow
    ↓ LISTEN on n8n_channel_text/image_ready
    ↓ Fetch file content
    ↓ Send to AI (OpenAI/Gemini)
    ↓ AI Response: {category, confidence, contract_number}
    ↓ UPDATE email_attachments SET:
    ↓   - document_category = 'invoice'/'cmr'/etc
    ↓   - contract_number = '50251006834'
    ↓   - confidence_score = 0.95
    ↓   - processing_status = 'classified'
    ↓   - classification_timestamp = NOW()
    ↓
[5] PostgreSQL Trigger (trigger_queue_email)
    ↓ IF ALL attachments for email are 'classified'
    ↓ THEN INSERT INTO email_ready_queue (email_id, processed=FALSE)
    ↓
[6] Contract Processor
    ↓ SELECT FROM email_ready_queue WHERE processed = FALSE
    ↓ Collect contract_numbers for email
    ↓ Generate contract_key (concatenate all contract numbers)
    ↓ Get next index from contract_folder_seq
    ↓ UPDATE emails SET folder_name = '{contract_key}_{index}'
    ↓ INSERT INTO contracts (contract_number, email_id, ...)
    ↓ Create folder: C:\...\Документи по договори\{contract_key}_{index}\
    ↓ Move/Copy files to organized folder
    ↓ UPDATE email_ready_queue SET processed = TRUE
    ↓ UPDATE email_attachments SET processing_status = 'organized'
```

### Path 2: Invoice Extraction (Specialized)

```
[4b] n8n Workflow (if category = 'invoice')
     ↓ Extract invoice data:
     ↓   - invoice_number
     ↓   - vendor_name
     ↓   - total_amount
     ↓   - invoice_date
     ↓   - line_items[]
     ↓
     ↓ INSERT INTO invoice_base (email_id, invoice_number, ...)
     ↓ INSERT INTO invoice_items (invoice_id, description, quantity, ...)
     ↓
     ↓ Continue with normal flow
```

---

## ❌ Error Handling

### Error States & Recovery

| Error Type | Detection | Recovery | Max Retries |
|------------|-----------|----------|-------------|
| **OCR Failure** | ocr_processor.py catches exception | Log error, UPDATE status='failed' | 3 |
| **Office Failure** | office_processor.py catches exception | Log error, UPDATE status='failed' | 3 |
| **Queue Webhook Failure** | HTTP error from n8n | Increment attempts, retry after delay | 3 |
| **n8n Processing Error** | AI API error | Log in n8n, mark as failed | Manual |
| **Database Connection Lost** | psycopg2 OperationalError | Auto-reconnect with keep-alive | 5 |
| **File Not Found** | FileNotFoundError | Log error, skip file | N/A |
| **Duplicate File** | Hash comparison | UPDATE status='duplicate' | N/A |

### Error Flow

```
[Error Detected]
    ↓
    ├─→ attempts < max_attempts (3)?
    │   YES ↓
    │   ├─→ Wait: attempts * retry_delay (10s)
    │   └─→ Retry operation
    │
    └─→ attempts >= max_attempts?
        YES ↓
        ├─→ UPDATE status = 'failed'
        ├─→ Log to processing_history
        └─→ [Manual Intervention Required]
```

### Common Error Scenarios

**1. Queue Manager Stops**
```
Symptom: No new files in processing_queue
Cause: Process crashed or hung
Fix: Restart queue manager
Check: ps aux | grep queue_manager.py
```

**2. n8n Not Responding**
```
Symptom: processing_queue status stays 'pending'
Cause: n8n server down or webhook broken
Fix: Check http://localhost:5678
Restart: n8n start
```

**3. Database Connection Lost**
```
Symptom: "connection closed" errors in logs
Cause: PostgreSQL timeout or network issue
Fix: Auto-reconnect (keep-alive enabled)
Manual: Restart affected process
```

**4. AI API Rate Limit**
```
Symptom: n8n workflow fails with 429 error
Cause: Too many API requests
Fix: Reduce queue_manager rate_limit_per_minute
Default: 3 files/minute
```

---

## 🔧 Recovery Procedures

### Procedure 1: System Full Restart

**When:** Major system failure, all processes stopped

**Steps:**
```bash
# Step 1: Check PostgreSQL
psql -U postgres -d Cargo_mail -c "SELECT COUNT(*) FROM emails;"
# Should return: 226 (or more)

# Step 2: Start Email Fetcher (Terminal 1)
cd C:\Python_project\CargoFlow\Cargoflow_mail
venv\Scripts\activate
python graph_email_extractor_v5.py

# Step 3: Start OCR Processor (Terminal 2)
cd C:\Python_project\CargoFlow\Cargoflow_OCR
venv\Scripts\activate
python ocr_processor.py

# Step 4: Start Office Processor (Terminal 3)
cd C:\Python_project\CargoFlow\Cargoflow_Office
venv\Scripts\activate
python office_processor.py

# Step 5: Start Text Queue (Terminal 4)
cd C:\Python_project\CargoFlow\Cargoflow_Queue
venv\Scripts\activate
python text_queue_manager.py

# Step 6: Start Image Queue (Terminal 5)
cd C:\Python_project\CargoFlow\Cargoflow_Queue
python image_queue_manager.py

# Step 7: Start n8n (Terminal 6)
n8n start
# Verify: http://localhost:5678

# Step 8: Start Contract Processor (Terminal 7)
cd C:\Python_project\CargoFlow\Cargoflow_Contracts
venv\Scripts\activate
python main.py --continuous
```

### Procedure 2: Reset Failed Queue Items

**When:** Many items stuck in 'failed' status

**SQL:**
```sql
-- Check failed items
SELECT file_type, COUNT(*) 
FROM processing_queue 
WHERE status = 'failed' 
GROUP BY file_type;

-- Reset to pending (will retry)
UPDATE processing_queue 
SET status = 'pending', 
    attempts = 0,
    last_attempt_at = NULL
WHERE status = 'failed' 
  AND attempts >= 3
  AND created_at > NOW() - INTERVAL '7 days';

-- Verify
SELECT COUNT(*) FROM processing_queue WHERE status = 'pending';
```

### Procedure 3: Reprocess Unclassified Attachments

**When:** Attachments have processing_status='completed' but no category

**SQL:**
```sql
-- Find unclassified attachments
SELECT COUNT(*) 
FROM email_attachments 
WHERE processing_status = 'completed' 
  AND document_category IS NULL;

-- Reset to pending (will reprocess)
UPDATE email_attachments 
SET processing_status = 'pending'
WHERE processing_status = 'completed' 
  AND document_category IS NULL
  AND file_size > 1024; -- Skip tiny files (logos)

-- Verify OCR/Office processors pick them up
-- Check logs: document_processing.log
```

### Procedure 4: Process Email Ready Queue

**When:** contracts table is empty but attachments are classified

**SQL:**
```sql
-- Check email_ready_queue
SELECT COUNT(*) FROM email_ready_queue WHERE processed = FALSE;

-- If empty but attachments classified, manually trigger
INSERT INTO email_ready_queue (email_id, ready_at, processed)
SELECT DISTINCT ea.email_id, NOW(), FALSE
FROM email_attachments ea
WHERE ea.processing_status = 'classified'
  AND ea.document_category IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM email_ready_queue erq 
    WHERE erq.email_id = ea.email_id
  )
GROUP BY ea.email_id
HAVING COUNT(*) = (
  SELECT COUNT(*) 
  FROM email_attachments ea2 
  WHERE ea2.email_id = ea.email_id
);

-- Start Contract Processor
-- It will process the queue
```

### Procedure 5: Kill Blocking Database Queries

**When:** Database appears hung or slow

**SQL:**
```sql
-- Find long-running queries
SELECT 
    pid,
    usename,
    state,
    query,
    NOW() - query_start AS duration
FROM pg_stat_activity
WHERE state != 'idle'
  AND query_start < NOW() - INTERVAL '5 minutes'
ORDER BY duration DESC;

-- Kill specific query (if needed)
SELECT pg_terminate_backend(12345); -- Replace with actual pid

-- Kill all long-running queries (DANGEROUS!)
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state = 'active'
  AND query_start < NOW() - INTERVAL '10 minutes'
  AND pid != pg_backend_pid(); -- Don't kill yourself
```

---

## 📊 Health Check Commands

### System Health Check

```sql
-- Overall system health
SELECT 
    'emails' as table_name, 
    COUNT(*) as records,
    MAX(received_time) as last_activity
FROM emails
UNION ALL
SELECT 
    'email_attachments', 
    COUNT(*),
    MAX(created_at)
FROM email_attachments
UNION ALL
SELECT 
    'processing_queue', 
    COUNT(*),
    MAX(created_at)
FROM processing_queue
UNION ALL
SELECT 
    'contracts', 
    COUNT(*),
    MAX(created_at)
FROM contracts;
```

### Status Distribution

```sql
-- Email attachment status distribution
SELECT 
    processing_status,
    COUNT(*) as count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) as percentage
FROM email_attachments
GROUP BY processing_status
ORDER BY count DESC;

-- Processing queue status
SELECT 
    file_type,
    status,
    COUNT(*) as count
FROM processing_queue
GROUP BY file_type, status
ORDER BY file_type, status;
```

### Recent Activity

```sql
-- Recent classifications (last 24 hours)
SELECT 
    attachment_name,
    document_category,
    contract_number,
    confidence_score,
    classification_timestamp
FROM email_attachments
WHERE classification_timestamp > NOW() - INTERVAL '24 hours'
ORDER BY classification_timestamp DESC
LIMIT 20;

-- Recent queue activity
SELECT 
    file_type,
    status,
    COUNT(*) as count,
    MAX(processed_at) as last_processed
FROM processing_queue
WHERE processed_at > NOW() - INTERVAL '24 hours'
GROUP BY file_type, status;
```

### Pending Items

```sql
-- Count pending items at each stage
SELECT 
    'pending_attachments' as stage,
    COUNT(*) as count
FROM email_attachments 
WHERE processing_status = 'pending'
UNION ALL
SELECT 
    'pending_queue',
    COUNT(*)
FROM processing_queue 
WHERE status = 'pending'
UNION ALL
SELECT 
    'pending_emails',
    COUNT(*)
FROM email_ready_queue 
WHERE processed = FALSE
UNION ALL
SELECT 
    'unclassified_attachments',
    COUNT(*)
FROM email_attachments 
WHERE processing_status = 'completed' 
  AND document_category IS NULL;
```

---

## 🎯 Success Criteria

### System is "Fully Operational" when:

- [x] ✅ Email extraction running continuously
- [x] ✅ Attachments being saved to disk (296 files)
- [ ] ⚠️ **80%+ of attachments categorized** (Currently: 34%)
- [ ] ⚠️ **Queue processing active** (pending < 20%) (Currently: 39%)
- [ ] ❌ **Contract numbers extracted** (Currently: partial)
- [ ] ❌ **Contracts table populated** (Currently: 0 records)
- [ ] ❌ **Files organized into folders** (Currently: not started)

### Current Score: **3/7 criteria met (43%)**

---

## 📝 Notes

### Known Issues
1. Queue managers stopped on 28 Oct 09:40 - **CRITICAL**
2. AI categorization stopped on 28 Oct 13:30 - **CRITICAL**
3. Contract processor never started - **CRITICAL**
4. Heavy trigger replaced with lightweight queue system (29 Oct) - **RESOLVED**

### Recent Changes
- **30 Oct 2025:** Created email_ready_queue and contract_folder_seq tables
- **27 Oct 2025:** Added contract_number extraction to AI agent
- **26 Oct 2025:** Improved database connection stability with keep-alive

### Next Steps
1. Restart queue managers (text + image)
2. Verify n8n is running and workflows active
3. Start contract processor
4. Monitor AI categorization progress
5. Verify contract detection working

---

**Document Version:** 1.0  
**Last Updated:** November 06, 2025  
**Status:** Complete - Ready for system restart and testing
