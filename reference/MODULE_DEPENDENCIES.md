# CargoFlow - Module Dependencies & Integration

**Created:** November 06, 2025  
**Last Updated:** November 12, 2025  
**Status:** Complete  
**Purpose:** Comprehensive documentation of module dependencies, inter-module communication, and integration points

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Dependency Graph](#dependency-graph)
3. [Module-by-Module Dependencies](#module-by-module-dependencies)
4. [Communication Mechanisms](#communication-mechanisms)
5. [File System Dependencies](#file-system-dependencies)
6. [Database Dependencies](#database-dependencies)
7. [External Service Dependencies](#external-service-dependencies)
8. [Configuration Dependencies](#configuration-dependencies)
9. [Network & API Dependencies](#network--api-dependencies)
10. [Dependency Matrix](#dependency-matrix)
11. [Critical Paths](#critical-paths)
12. [Failure Impact Analysis](#failure-impact-analysis)
13. [Troubleshooting Dependencies](#troubleshooting-dependencies)

---

## 🎯 Overview

The CargoFlow system consists of **7 interconnected modules** that work together to process emails and documents automatically. Understanding module dependencies is critical for:

- **System maintenance** - Know what to restart when something fails
- **Troubleshooting** - Identify bottlenecks and failure points
- **Deployment** - Understand startup order and prerequisites
- **Development** - Avoid breaking dependent modules

### System Architecture Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                     CARGOFLOW SYSTEM                            │
│                    7 Interconnected Modules                     │
└─────────────────────────────────────────────────────────────────┘

External Services:
├── Microsoft Graph API (Microsoft 365)
├── PostgreSQL Database (Cargo_mail)
├── n8n Workflow Server (localhost:5678)
└── AI APIs (OpenAI GPT / Google Gemini)

Modules:
├── [1] Email Fetcher ────────┐
├── [2] OCR Processor         │
├── [3] Office Processor      ├──> Database
├── [4] Queue Managers        │
├── [5] n8n Workflows         │
├── [6] Contract Processor    │
└── [7] Monitoring (implicit) ┘
```

---

## 🔗 Dependency Graph

### High-Level Module Flow

```
┌──────────────────┐
│  Microsoft Graph │
│   (External)     │
└────────┬─────────┘
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  [1] EMAIL FETCHER                                  │
│  - Fetches emails via Graph API                     │
│  - Saves attachments to disk                        │
│  - Writes to PostgreSQL (emails, email_attachments) │
└────────┬────────────────────────────────────────────┘
         │
         ├─────────────────┬────────────────────┐
         ▼                 ▼                    ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│ [2] OCR          │ │ [3] OFFICE       │ │  File System     │
│  PROCESSOR       │ │  PROCESSOR       │ │  C:\CargoAtt..   │
│  - PDF/Image     │ │  - Word/Excel    │ └──────────────────┘
│  - Tesseract OCR │ │  - Text extract  │
│  - Text output   │ │  - Text output   │
└────────┬─────────┘ └────────┬─────────┘
         │                    │
         └──────────┬─────────┘
                    ▼
         ┌──────────────────────┐
         │   File System        │
         │ C:\CargoProcessing\  │
         └──────────┬───────────┘
                    │
         ┌──────────┴─────────┐
         ▼                    ▼
┌──────────────────┐ ┌──────────────────┐
│ [4a] TEXT QUEUE  │ │ [4b] IMAGE QUEUE │
│   MANAGER        │ │    MANAGER       │
│ - Watches text   │ │ - Watches images │
│ - Inserts to DB  │ │ - Inserts to DB  │
└────────┬─────────┘ └────────┬─────────┘
         │                    │
         └──────────┬─────────┘
                    ▼
         ┌──────────────────────┐
         │  PostgreSQL NOTIFY   │
         │  (Trigger System)    │
         └──────────┬───────────┘
                    │
         ┌──────────┴─────────┐
         ▼                    ▼
┌──────────────────┐ ┌──────────────────┐
│ [5a] n8n TEXT    │ │ [5b] n8n IMAGE   │
│   WORKFLOW       │ │   WORKFLOW       │
│ - AI categorize  │ │ - AI analyze     │
│ - Extract data   │ │ - OCR + AI       │
└────────┬─────────┘ └────────┬─────────┘
         │                    │
         └──────────┬─────────┘
                    ▼
         ┌──────────────────────┐
         │   PostgreSQL UPDATE  │
         │  (email_attachments) │
         └──────────┬───────────┘
                    │
                    ▼
         ┌──────────────────────┐
         │ PostgreSQL TRIGGER   │
         │ (queue_email_for_    │
         │  folder_update)      │
         └──────────┬───────────┘
                    │
                    ▼
         ┌──────────────────────┐
         │ email_ready_queue    │
         └──────────┬───────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│ [6] CONTRACT PROCESSOR                  │
│ - Reads email_ready_queue               │
│ - Groups files by contract              │
│ - Creates folder structure              │
│ - Updates emails.folder_name            │
└─────────────────────────────────────────┘
```

### Dependency Levels

**Level 0 - External Dependencies (Prerequisites):**
- Microsoft Graph API
- PostgreSQL Database
- n8n Server
- AI APIs (OpenAI/Gemini)
- File System (C:\ drive with sufficient space)

**Level 1 - Entry Point:**
- [1] Email Fetcher (depends on: Graph API, PostgreSQL, File System)

**Level 2 - File Processors:**
- [2] OCR Processor (depends on: Email Fetcher output, PostgreSQL)
- [3] Office Processor (depends on: Email Fetcher output, PostgreSQL)

**Level 3 - Queue Management:**
- [4] Queue Managers (depends on: OCR/Office output, PostgreSQL, n8n availability)

**Level 4 - AI Processing:**
- [5] n8n Workflows (depends on: Queue Managers, PostgreSQL triggers, AI APIs)

**Level 5 - Organization:**
- [6] Contract Processor (depends on: n8n output, PostgreSQL, File System)

---

## 📦 Module-by-Module Dependencies

### [1] Email Fetcher

**Location:** `C:\Python_project\CargoFlow\Cargoflow_mail\`  
**Script:** `graph_email_extractor_v5.py`

#### Direct Dependencies:
- **Microsoft Graph API** (CRITICAL)
  - Authentication: Azure AD credentials
  - Endpoint: Microsoft 365 mailbox
  - Rate limits: Microsoft's API throttling
  
- **PostgreSQL Database** (CRITICAL)
  - Tables: `emails`, `email_attachments`
  - Connection: localhost:5432/Cargo_mail
  
- **File System** (CRITICAL)
  - Output: `C:\CargoAttachments\{sender}\{date}\{subject}\`
  - Space required: ~10-50 GB (grows over time)

#### Configuration Dependencies:
- `graph_config.json` - Microsoft credentials
- Database connection parameters
- File path configuration

#### Downstream Dependencies (Who depends on Email Fetcher):
- **[2] OCR Processor** - reads from `email_attachments` table
- **[3] Office Processor** - reads from `email_attachments` table
- **All other modules** - indirectly (no emails = no work)

#### Failure Impact:
- **If Email Fetcher fails:** No new emails → Entire system stops getting new work
- **Recovery time:** Minutes (restart process)
- **Data loss risk:** Low (emails remain in Microsoft 365)

---

### [2] OCR Processor

**Location:** `C:\Python_project\CargoFlow\Cargoflow_OCR\`  
**Script:** `ocr_processor.py`

#### Direct Dependencies:
- **Email Fetcher output** (CRITICAL)
  - Reads: `email_attachments` WHERE `processing_status='pending'`
  - Input files: `C:\CargoAttachments\`
  
- **PostgreSQL Database** (CRITICAL)
  - Tables: `email_attachments`, `processing_history`
  - Updates: `processing_status` field
  
- **Tesseract OCR** (CRITICAL)
  - Binary: `C:\Program Files\Tesseract-OCR\tesseract.exe`
  - Language data: tessdata folder
  
- **Python Libraries** (CRITICAL)
  - PyMuPDF (fitz) - PDF processing
  - Pillow (PIL) - Image processing
  - pytesseract - OCR interface

#### Configuration Dependencies:
- Database connection parameters
- Tesseract binary path
- Output directory: `C:\CargoProcessing\`

#### Downstream Dependencies:
- **[4a] Text Queue Manager** - processes OCR output files
- **[5b] n8n Image Workflow** - processes PNG files created by OCR

#### Failure Impact:
- **If OCR Processor fails:** PDFs/images not converted → AI can't categorize them
- **Recovery time:** Minutes (restart process)
- **Data loss risk:** None (can reprocess from originals)

---

### [3] Office Processor

**Location:** `C:\Python_project\CargoFlow\Cargoflow_Office\`  
**Script:** `office_processor.py`

#### Direct Dependencies:
- **Email Fetcher output** (CRITICAL)
  - Watches: `C:\CargoAttachments\` (file system monitoring)
  - File types: .docx, .doc, .xlsx, .xls, .txt, .rtf, .odt
  
- **Python Libraries** (CRITICAL)
  - python-docx - Word processing
  - openpyxl - Excel processing
  - win32com (optional) - Legacy formats

#### Configuration Dependencies:
- Output directory: `C:\CargoProcessing\`
- File type filters
- Processing timeout settings

#### Downstream Dependencies:
- **[4a] Text Queue Manager** - processes Office output files

#### Failure Impact:
- **If Office Processor fails:** Word/Excel files not converted → Limited AI categorization
- **Recovery time:** Minutes (restart process)
- **Data loss risk:** None (can reprocess from originals)

---

### [4] Queue Managers

**Location:** `C:\Python_project\CargoFlow\Cargoflow_Queue\`  
**Scripts:** `text_queue_manager.py`, `image_queue_manager.py`

#### [4a] Text Queue Manager

##### Direct Dependencies:
- **OCR/Office Processor output** (CRITICAL)
  - Watches: `C:\CargoProcessing\processed_documents\2025\ocr_results\`
  - File pattern: `*_extracted.txt`
  
- **PostgreSQL Database** (CRITICAL)
  - Tables: `processing_queue`, `email_attachments`
  - Inserts: New queue items
  - Triggers: `trigger_notify_text` (PostgreSQL NOTIFY)
  
- **n8n Server availability** (CRITICAL)
  - Webhook: `http://localhost:5678/webhook/analyze-text`
  - Health check: Must respond to requests

##### Configuration Dependencies:
- `queue_config.json` - rate limits, paths, webhooks
- Database connection
- n8n webhook URLs

##### Downstream Dependencies:
- **[5a] n8n Text Workflow** - triggered by PostgreSQL NOTIFY

#### [4b] Image Queue Manager

##### Direct Dependencies:
- **OCR Processor output** (CRITICAL)
  - Watches: `C:\CargoProcessing\processed_documents\2025\images\`
  - File pattern: `*.png`
  
- **PostgreSQL Database** (CRITICAL)
  - Same as Text Queue Manager
  - Triggers: `trigger_notify_image` (PostgreSQL NOTIFY)
  
- **n8n Server availability** (CRITICAL)
  - Webhook: `http://localhost:5678/webhook/analyze-image`

##### Configuration Dependencies:
- Same as Text Queue Manager

##### Downstream Dependencies:
- **[5b] n8n Image Workflow** - triggered by PostgreSQL NOTIFY

#### Failure Impact:
- **If Queue Managers fail:** Files processed but not sent to AI → No categorization
- **Recovery time:** Minutes (restart process)
- **Data loss risk:** Low (files remain on disk, can requeue)
- **Critical symptoms:** `processing_queue` stops growing, no AI categorization

---

### [5] n8n Workflows

**Location:** `C:\Python_project\CargoFlow\Cargoflow_n8n\`  
**Server:** `http://localhost:5678`  
**Workflows:** 2 (Text + Image)

#### [5a] Text Workflow (Category_ALL_text / INV_Text_CargoFlow)

##### Direct Dependencies:
- **Queue Managers** (CRITICAL)
  - Triggered by: PostgreSQL NOTIFY via trigger
  - Input: `processing_queue` table data
  
- **AI API** (CRITICAL)
  - Provider: OpenAI GPT-4 OR Google Gemini
  - Endpoint: API-specific
  - Rate limits: Provider-specific
  
- **PostgreSQL Database** (CRITICAL)
  - Reads: `processing_queue`, `email_attachments`
  - Writes: `email_attachments` (category, contract_number)
  - Writes: `invoice_base`, `invoice_items` (if invoice detected)

##### Configuration Dependencies:
- n8n workflow JSON files
- AI API credentials (OpenAI or Gemini)
- Database credentials in n8n
- Webhook endpoints configured

##### Downstream Dependencies:
- **[6] Contract Processor** - triggered when all attachments categorized

#### [5b] Image Workflow (Read_PNG_ / INV_PNG_CargoFlow)

##### Direct Dependencies:
- Same as Text Workflow
- Additional: OCR processing within workflow (image → text → AI)

#### Failure Impact:
- **If n8n fails:** No AI categorization → Entire pipeline stops at queue level
- **Recovery time:** Minutes to hours (depends on n8n state)
- **Data loss risk:** Medium (may need to reprocess queue)
- **Critical symptoms:** 
  - `document_category` stays NULL
  - `classification_timestamp` not updated
  - Queue grows indefinitely

---

### [6] Contract Processor

**Location:** `C:\Python_project\CargoFlow\Cargoflow_Contracts\`  
**Script:** `main.py`

#### Direct Dependencies:
- **n8n Workflows output** (CRITICAL)
  - Reads: `email_ready_queue` WHERE `processed=FALSE`
  - Requires: `email_attachments.contract_number` populated
  
- **PostgreSQL Database** (CRITICAL)
  - Reads: `email_ready_queue`, `email_attachments`, `document_pages`
  - Writes: `contracts`, `emails.folder_name`
  - Updates: `email_attachments.processing_status='organized'`
  
- **File System** (CRITICAL)
  - Output: `C:\Users\Delta\Cargo Flow\...\Документи по договори\`
  - Operations: Copy files, create folders

#### Configuration Dependencies:
- Database connection
- Output folder paths
- Contract number regex patterns

#### Downstream Dependencies:
- None (final output stage)

#### Failure Impact:
- **If Contract Processor fails:** Files categorized but not organized
- **Recovery time:** Minutes (restart process)
- **Data loss risk:** Very low (can reprocess from `email_ready_queue`)
- **Critical symptoms:**
  - `contracts` table stays empty
  - `emails.folder_name` stays NULL
  - No organized folder structure created

---

## 🔄 Communication Mechanisms

### 1. Database as Message Queue (Primary)

**Mechanism:** PostgreSQL tables + triggers + NOTIFY/LISTEN

```sql
-- Example: Queue Manager inserts → Trigger fires → n8n receives notification
INSERT INTO processing_queue (file_path, file_type, ...)
VALUES (...);
  ↓
CREATE TRIGGER trigger_notify_text
  AFTER INSERT ON processing_queue
  FOR EACH ROW
  WHEN (NEW.file_type = 'text')
  EXECUTE FUNCTION notify_n8n_text_queue();
  ↓
PERFORM pg_notify('n8n_text_queue', json_data);
  ↓
n8n workflow LISTENS on 'n8n_text_queue' channel
```

**Tables Used:**
- `processing_queue` - Files waiting for AI processing
- `email_ready_queue` - Emails ready for folder organization
- `contract_detection_queue` - Contracts detected, pending organization

**Advantages:**
- Reliable (ACID properties)
- Persistent (survives crashes)
- Traceable (query history)

**Disadvantages:**
- Database load (triggers execute on every insert)
- Potential bottleneck if heavy processing in triggers

---

### 2. File System Watching (Secondary)

**Mechanism:** Python `watchdog` library monitoring directories

**Used by:**
- **Office Processor** - Watches `C:\CargoAttachments\` for new files
- **Queue Managers** - Watch `C:\CargoProcessing\` for processed files

**Example:**
```python
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

class FileHandler(FileSystemEventHandler):
    def on_created(self, event):
        if event.is_directory:
            return
        # Process new file
        process_file(event.src_path)
```

**Advantages:**
- Low latency (immediate detection)
- No database polling

**Disadvantages:**
- Not persistent (if process dies, events are lost)
- Race conditions (file might not be fully written)

---

### 3. Webhook HTTP POST (AI Integration)

**Mechanism:** HTTP POST requests from Queue Managers to n8n

**Endpoint Structure:**
```
Queue Manager → HTTP POST → http://localhost:5678/webhook/analyze-text
                              ↓
                         n8n receives webhook
                              ↓
                         AI processing
                              ↓
                         Database UPDATE
```

**Used by:**
- Text Queue Manager → n8n Text Workflow
- Image Queue Manager → n8n Image Workflow

**Payload Example:**
```json
{
  "attachment_id": 123,
  "email_id": 456,
  "file_path": "C:\\CargoProcessing\\...",
  "file_type": "text",
  "file_metadata": {
    "total_pages": 3,
    "original_document": "invoice.pdf"
  }
}
```

**Advantages:**
- Standard HTTP protocol
- Easy debugging (cURL, Postman)
- n8n specializes in webhooks

**Disadvantages:**
- Requires n8n server running
- Network dependency (even if localhost)
- No built-in retry mechanism

---

### 4. Direct Database Queries (Data Access)

**Mechanism:** SQL queries via psycopg2 (Python) or n8n PostgreSQL node

**Used by:** All modules for reading/writing data

**Common Query Patterns:**

```sql
-- Email Fetcher: Check if email exists
SELECT id FROM emails WHERE graph_id = :graph_id;

-- OCR Processor: Get pending attachments
SELECT * FROM email_attachments 
WHERE processing_status = 'pending' 
  AND file_extension IN ('.pdf', '.jpg', '.png');

-- n8n: Update category
UPDATE email_attachments 
SET document_category = :category,
    contract_number = :contract_num,
    classification_timestamp = NOW()
WHERE id = :attachment_id;

-- Contract Processor: Get ready emails
SELECT * FROM email_ready_queue 
WHERE processed = FALSE 
ORDER BY ready_at 
LIMIT 10;
```

---

## 📁 File System Dependencies

### Directory Structure

```
C:\
├── CargoAttachments\                    # Email Fetcher OUTPUT
│   └── {sender_email}\
│       └── {YYYY-MM}\
│           └── {subject}_{timestamp}\
│               ├── email_metadata.json
│               ├── email_body.txt
│               └── attachment.pdf       # Original files
│
├── CargoProcessing\                     # OCR/Office OUTPUT
│   ├── processed_documents\
│   │   └── 2025\
│   │       ├── ocr_results\             # Text Queue WATCHES this
│   │       │   └── {sender}\{subject}\
│   │       │       └── file_extracted.txt
│   │       │
│   │       ├── images\                  # Image Queue WATCHES this
│   │       │   └── {sender}\{subject}\
│   │       │       └── file_page1.png
│   │       │
│   │       └── json_extract\
│   │           └── metadata.json
│   │
│   └── unprocessed\                     # Failed processing
│       ├── unprocessed_ocr\
│       └── unprocessed_office\
│
└── Users\Delta\Cargo Flow\
    └── Site de communication - Documents\
        └── Документи по договори\       # Contract Processor OUTPUT
            ├── contracts\
            │   ├── by_sender\
            │   ├── by_date\
            │   └── by_contract_number\
            │       └── 50251006834_001\ # Organized files
            │
            └── non_contracts\
                ├── by_sender\
                ├── by_date\
                └── by_type\
```

### Module File Access Patterns

| Module | Input Directory | Output Directory | Access Type |
|--------|----------------|------------------|-------------|
| Email Fetcher | Microsoft Graph | `C:\CargoAttachments\` | Write |
| OCR Processor | `C:\CargoAttachments\` | `C:\CargoProcessing\` | Read + Write |
| Office Processor | `C:\CargoAttachments\` | `C:\CargoProcessing\` | Read + Write |
| Text Queue | `C:\CargoProcessing\ocr_results\` | (none) | Read only |
| Image Queue | `C:\CargoProcessing\images\` | (none) | Read only |
| n8n Workflows | (none - reads from DB) | (none) | N/A |
| Contract Processor | (none - reads from DB) | `C:\...\Документи по договори\` | Write + Copy |

### File Lock Considerations

**Potential Issues:**
- Multiple modules might try to access the same file simultaneously
- Windows file locks can cause "Permission Denied" errors

**Mitigation Strategies:**
1. **Time separation** - OCR processes file, then Queue reads it (different times)
2. **Read-only access** - Queue Managers only read files
3. **Unique output names** - Each module writes to different folders
4. **Retry logic** - Wait and retry if file is locked

---

## 🗄️ Database Dependencies

### Table Dependency Graph

```
emails (1,723 records)
  │
  ├─→ email_attachments (979 records)
  │     │
  │     ├─→ processing_queue (213 records)
  │     │     │
  │     │     └─→ n8n workflows (via NOTIFY)
  │     │
  │     ├─→ document_pages (14 records)
  │     │
  │     ├─→ invoice_base (46 records)
  │     │     │
  │     │     └─→ invoice_items (122 records)
  │     │
  │     └─→ contract_detection_queue (107 records)
  │
  ├─→ email_ready_queue (9 records)
  │     │
  │     └─→ Contract Processor
  │
  └─→ contracts (0 records) ← Contract Processor writes here
```

### Critical Foreign Keys

```sql
-- email_attachments depends on emails
email_attachments.email_id → emails.id

-- document_pages depends on email_attachments
document_pages.attachment_id → email_attachments.id

-- invoice_base depends on emails
invoice_base.email_id → emails.id

-- invoice_items depends on invoice_base
invoice_items.invoice_id → invoice_base.id

-- processing_queue (loose coupling - no FK)
processing_queue.email_id → emails.id (not enforced)
processing_queue.attachment_id → email_attachments.id (not enforced)
```

### Trigger Dependencies

**Order matters!** Triggers fire in alphabetical order by trigger name.

| Trigger Name | Table | Event | Function | Purpose |
|-------------|-------|-------|----------|---------|
| `trigger_match_attachment` | `processing_queue` | AFTER INSERT | `match_attachment_on_queue_insert()` | Match queue item to attachment_id |
| `trigger_notify_image` | `processing_queue` | AFTER INSERT | `notify_n8n_image_queue()` | Notify n8n for images |
| `trigger_notify_text` | `processing_queue` | AFTER INSERT | `notify_n8n_text_queue()` | Notify n8n for text |
| `trigger_queue_email` | `email_attachments` | AFTER UPDATE | `queue_email_for_folder_update()` | Queue email when all attachments done |
| `contract_detection_trigger` | `email_attachments` | AFTER UPDATE | `queue_contract_detection()` | Trigger contract detection |

**Dependency Chain:**
```
Queue Manager INSERTs into processing_queue
  ↓
trigger_match_attachment fires (finds attachment_id)
  ↓
trigger_notify_text/image fires (sends NOTIFY)
  ↓
n8n receives notification
  ↓
n8n UPDATEs email_attachments (document_category, contract_number)
  ↓
trigger_queue_email fires (checks if all attachments done)
  ↓
INSERTs into email_ready_queue
  ↓
Contract Processor reads email_ready_queue
```

---

## 🌐 External Service Dependencies

### 1. Microsoft Graph API

**Purpose:** Fetch emails from Microsoft 365 mailbox

**Endpoint:** `https://graph.microsoft.com/v1.0/`

**Authentication:**
- Method: OAuth 2.0 Client Credentials
- Tenant ID: `your-tenant-id-here`
- Client ID: `your-client-id-here`
- Client Secret: (stored in `graph_config.json`)

**API Calls Used:**
- `GET /users/{user_email}/mailFolders` - List folders
- `GET /users/{user_email}/mailFolders/{folder_id}/messages` - List emails
- `GET /messages/{message_id}/attachments` - Get attachments
- `GET /attachments/{attachment_id}/$value` - Download attachment content

**Rate Limits:**
- Microsoft throttling: ~100,000 requests/hour
- Our usage: ~10-50 requests/minute (normal operation)

**Failure Scenarios:**
- **Token expired:** Re-authenticate (handled automatically)
- **Network timeout:** Retry with exponential backoff
- **Mailbox locked:** Wait and retry
- **Service outage:** System pauses, resumes when service returns

**Dependencies Impact:**
- **If Graph API fails:** No new emails → All modules starve for work
- **Mitigation:** System continues processing existing work

---

### 2. AI APIs (OpenAI or Google Gemini)

**Purpose:** Document categorization and data extraction

**Providers (either/or):**

#### Option A: OpenAI GPT-4
- Endpoint: `https://api.openai.com/v1/chat/completions`
- Model: `gpt-4` or `gpt-4-turbo`
- Rate limits: Tier-dependent (check OpenAI dashboard)

#### Option B: Google Gemini
- Endpoint: `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro`
- Model: `gemini-1.5-pro`
- Rate limits: 60 requests/minute (free tier)

**Configuration:** Set in n8n workflow nodes

**API Calls:**
- Text analysis: ~1-2 calls per document
- Image analysis: ~1-3 calls per page

**Failure Scenarios:**
- **Rate limit exceeded:** Queue builds up, waits for limit reset
- **Invalid API key:** All AI processing fails
- **Service outage:** Processing stops, resumes when service returns
- **Timeout:** Individual files fail, retry logic applies

**Dependencies Impact:**
- **If AI API fails:** Documents processed but not categorized
- **Mitigation:** Files remain in `processing_queue` for retry

---

### 3. PostgreSQL Database

**Purpose:** Central coordination and data storage

**Connection:**
- Host: `localhost`
- Port: `5432`
- Database: `Cargo_mail`
- User: `postgres`
- Password: (stored in module configs)

**Version:** PostgreSQL 17

**Critical Features Used:**
- NOTIFY/LISTEN for inter-module communication
- Triggers for automated workflows
- JSONB columns for flexible data
- Full-text search (future)

**Backup Strategy:**
- Daily `pg_dump` (recommended)
- Point-in-time recovery (PITR) via WAL archiving (optional)

**Failure Scenarios:**
- **Connection lost:** Modules retry with exponential backoff
- **Database down:** All modules pause, resume when DB returns
- **Disk full:** System stops, requires manual intervention
- **Corrupt data:** Restore from backup

**Dependencies Impact:**
- **If PostgreSQL fails:** Entire system stops
- **Mitigation:** None (single point of failure - needs HA setup for production)

---

### 4. n8n Workflow Server

**Purpose:** Workflow orchestration and AI integration

**Server:**
- URL: `http://localhost:5678`
- Storage: SQLite or PostgreSQL (n8n internal)
- Workflows: 2 (Text + Image)

**Webhooks:**
- Text: `http://localhost:5678/webhook/analyze-text`
- Image: `http://localhost:5678/webhook/analyze-image`

**Dependencies:**
- Node.js runtime
- n8n package (`npm install -g n8n`)
- AI API credentials configured in workflows
- PostgreSQL connection credentials

**Failure Scenarios:**
- **n8n not started:** Queue Managers fail to send data
- **Workflow deactivated:** No AI processing
- **Node configuration error:** Workflow fails partway
- **Memory exhaustion:** n8n crashes (restart required)

**Dependencies Impact:**
- **If n8n fails:** No AI categorization → System processes files but doesn't categorize
- **Mitigation:** Restart n8n, processing resumes automatically

---

## ⚙️ Configuration Dependencies

### Configuration Files Required

| Module | Config File | Critical Settings |
|--------|------------|------------------|
| Email Fetcher | `graph_config.json` | Microsoft credentials, database connection |
| OCR Processor | (hardcoded) | Tesseract path, output directories |
| Office Processor | (hardcoded) | Output directories, file type filters |
| Queue Managers | `queue_config.json` | Watch paths, webhooks, rate limits |
| n8n Workflows | n8n internal | AI API keys, database credentials |
| Contract Processor | (hardcoded) | Database connection, output paths |

### graph_config.json (Email Fetcher)

```json
{
  "client_id": "your-client-id-here",
  "client_secret": "your-client-secret-here",
  "tenant_id": "your-tenant-id-here",
  "user_email": "pa@cargo-flow.fr",
  "database": {
    "host": "localhost",
    "database": "Cargo_mail",
    "user": "postgres",
    "password": "Lora24092004",
    "port": 5432
  },
  "attachment_folder": "C:\\CargoAttachments",
  "scan_interval_minutes": 5
}
```

**Critical:** If any credential is wrong, Email Fetcher fails to start.

---

### queue_config.json (Queue Managers)

```json
{
  "database": {
    "host": "localhost",
    "database": "Cargo_mail",
    "user": "postgres",
    "password": "Lora24092004",
    "port": 5432
  },
  "text_queue": {
    "watch_path": "C:\\CargoProcessing\\processed_documents\\2025\\ocr_results",
    "webhook_url": "http://localhost:5678/webhook/analyze-text",
    "rate_limit_per_minute": 3,
    "scan_interval_seconds": 15,
    "file_pattern": "*_extracted.txt"
  },
  "image_queue": {
    "watch_path": "C:\\CargoProcessing\\processed_documents\\2025\\images",
    "webhook_url": "http://localhost:5678/webhook/analyze-image",
    "rate_limit_per_minute": 3,
    "scan_interval_seconds": 15,
    "file_pattern": "*.png"
  }
}
```

**Critical:** Webhook URLs must match n8n configuration.

---

### n8n Workflow Configuration

**Stored internally in n8n (SQLite or PostgreSQL)**

**Critical nodes:**
- **Webhook Trigger** - Must match Queue Manager URLs
- **PostgreSQL** - Database credentials
- **AI API** - OpenAI or Gemini credentials
- **Update Nodes** - SQL queries to update email_attachments

**How to export:**
```bash
# From n8n UI: Workflows → Select workflow → Download
# Saved as JSON in C:\Python_project\CargoFlow\Cargoflow_n8n\workflows\
```

---

### Environment Variables (Recommended Future Enhancement)

**Currently:** Credentials scattered across multiple config files

**Better approach:** Centralize in `.env` file

```bash
# .env (proposed)
MICROSOFT_CLIENT_ID=your-client-id-here
MICROSOFT_CLIENT_SECRET=your-client-secret-here
MICROSOFT_TENANT_ID=your-tenant-id-here
MICROSOFT_USER_EMAIL=pa@cargo-flow.fr

POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=Cargo_mail
POSTGRES_USER=postgres
POSTGRES_PASSWORD=Lora24092004

OPENAI_API_KEY=sk-...
GEMINI_API_KEY=AI...

N8N_WEBHOOK_BASE=http://localhost:5678/webhook
```

**Usage:** Load with python-dotenv in each module

---

## 🌐 Network & API Dependencies

### Port Usage

| Port | Service | Module | Purpose |
|------|---------|--------|---------|
| 5432 | PostgreSQL | All | Database |
| 5678 | n8n | Queue Managers, n8n | Webhooks |
| 443 | Microsoft Graph | Email Fetcher | HTTPS API |
| 443 | OpenAI/Gemini | n8n | AI APIs |

### Firewall Requirements

**Outbound (Required):**
- Port 443 to `graph.microsoft.com` (Microsoft Graph)
- Port 443 to `api.openai.com` (if using OpenAI)
- Port 443 to `generativelanguage.googleapis.com` (if using Gemini)

**Local (Required):**
- Port 5432 (PostgreSQL) - localhost only
- Port 5678 (n8n) - localhost only

**Inbound:**
- None required (all local processing)

---

## 📊 Dependency Matrix

### Complete Module Dependency Table

| Module | Microsoft Graph | PostgreSQL | n8n | AI API | File System | Tesseract | Python Libs |
|--------|----------------|------------|-----|--------|-------------|-----------|-------------|
| **Email Fetcher** | 🔴 CRITICAL | 🔴 CRITICAL | - | - | 🔴 CRITICAL | - | 🟡 REQUIRED |
| **OCR Processor** | - | 🔴 CRITICAL | - | - | 🔴 CRITICAL | 🔴 CRITICAL | 🟡 REQUIRED |
| **Office Processor** | - | - | - | - | 🔴 CRITICAL | - | 🟡 REQUIRED |
| **Text Queue** | - | 🔴 CRITICAL | 🔴 CRITICAL | - | 🔴 CRITICAL | - | 🟡 REQUIRED |
| **Image Queue** | - | 🔴 CRITICAL | 🔴 CRITICAL | - | 🔴 CRITICAL | - | 🟡 REQUIRED |
| **n8n Workflows** | - | 🔴 CRITICAL | - | 🔴 CRITICAL | - | - | - |
| **Contract Processor** | - | 🔴 CRITICAL | - | - | 🔴 CRITICAL | - | 🟡 REQUIRED |

**Legend:**
- 🔴 CRITICAL - Module cannot function without this
- 🟡 REQUIRED - Needed but module might partially work
- 🟢 OPTIONAL - Nice to have, not essential
- `-` - Not used

---

## 🛤️ Critical Paths

### Path 1: Email to AI Categorization (Full Pipeline)

```
Microsoft Graph API
  ↓ [Email Fetcher]
PostgreSQL (emails, email_attachments written)
  ↓ [OCR/Office Processor]
File System (processed files created)
  ↓ [Queue Managers]
PostgreSQL (processing_queue written)
  ↓ [PostgreSQL NOTIFY Trigger]
n8n Workflow (receives notification)
  ↓ [AI API Call]
AI Response (category + contract_number)
  ↓ [n8n UPDATE]
PostgreSQL (email_attachments updated)
  ↓ [PostgreSQL Trigger]
email_ready_queue (INSERT)
```

**Total time:** 2-5 minutes per document (typical)

**Bottlenecks:**
- AI API rate limits (most common)
- OCR processing time (for large PDFs)
- Database triggers (if poorly optimized)

---

### Path 2: Contract Organization (Final Output)

```
email_ready_queue (processed=FALSE)
  ↓ [Contract Processor reads]
Aggregate contract numbers for email
  ↓
Generate contract_key
  ↓ [Query contract_folder_seq]
Get next index for this contract
  ↓
Update emails.folder_name
  ↓
INSERT into contracts table
  ↓
Create physical folder structure
  ↓
Copy/Move files to organized folders
  ↓
Mark email_ready_queue as processed
```

**Total time:** Seconds per email (once dependencies are met)

**Bottlenecks:**
- File I/O (copying large attachments)
- Network drives (if output path is network-mounted)

---

## 💥 Failure Impact Analysis

### Scenario 1: Email Fetcher Crashes

**Immediate Impact:**
- No new emails retrieved
- Existing queue continues processing

**Affected Modules:**
- None immediately (existing work continues)

**Recovery:**
1. Restart Email Fetcher process
2. It will catch up on missed emails (Microsoft Graph stores them)

**Data Loss Risk:** None (emails remain in Microsoft 365)

---

### Scenario 2: PostgreSQL Database Down

**Immediate Impact:**
- ALL modules fail to function
- No reads, no writes

**Affected Modules:**
- 🔴 ALL (100% of system)

**Recovery:**
1. Restart PostgreSQL service
2. All modules automatically reconnect
3. Processing resumes where it stopped

**Data Loss Risk:** Low (if database files intact)

---

### Scenario 3: n8n Server Down

**Immediate Impact:**
- Queue Managers cannot send webhooks
- No AI categorization
- Files processed but not categorized

**Affected Modules:**
- Queue Managers (webhook failures)
- Downstream: Contract Processor (no categories → no organization)

**Recovery:**
1. Restart n8n server
2. Activate workflows
3. Queue Managers resume sending data
4. Backlog of pending files gets processed

**Data Loss Risk:** None (files remain in processing_queue)

---

### Scenario 4: AI API Rate Limit Exceeded

**Immediate Impact:**
- n8n workflows pause (wait for rate limit reset)
- Queue builds up

**Affected Modules:**
- n8n workflows (direct)
- Contract Processor (indirect - waits for categories)

**Recovery:**
- Automatic (rate limit resets after time window)
- Consider: Slow down Queue Manager rate_limit_per_minute

**Data Loss Risk:** None (queued items will eventually process)

---

### Scenario 5: Disk Full (C:\ drive)

**Immediate Impact:**
- Cannot save new attachments
- Cannot create processed files
- OCR/Office Processor fail

**Affected Modules:**
- Email Fetcher (cannot save attachments)
- OCR/Office Processor (cannot write output)
- Contract Processor (cannot create folders)

**Recovery:**
1. Free up disk space (delete old logs, temp files)
2. Restart affected modules

**Data Loss Risk:** Medium (some emails might be skipped if storage full during fetch)

---

## 🔧 Troubleshooting Dependencies

### Quick Dependency Checks

#### 1. Check PostgreSQL Connection
```bash
# From any module directory
python -c "import psycopg2; conn = psycopg2.connect('host=localhost dbname=Cargo_mail user=postgres password=Lora24092004'); print('DB OK')"
```

Expected: `DB OK`  
If fails: Check PostgreSQL service, credentials, firewall

---

#### 2. Check Microsoft Graph API
```bash
# From Cargoflow_mail directory
python -c "from graph_email_extractor_v5 import GraphEmailExtractor; g = GraphEmailExtractor(); print('Graph OK' if g.get_token() else 'Graph FAIL')"
```

Expected: `Graph OK`  
If fails: Check credentials in graph_config.json, network connectivity

---

#### 3. Check n8n Server
```bash
curl http://localhost:5678/
```

Expected: HTML response with n8n UI  
If fails: Check if n8n is running (`n8n start`), port 5678 availability

---

#### 4. Check n8n Webhooks
```bash
curl -X POST http://localhost:5678/webhook/analyze-text -H "Content-Type: application/json" -d "{\"test\":true}"
```

Expected: HTTP 200 or 404 (but not "Connection refused")  
If "Connection refused": n8n not running  
If 404: Webhook not found (check workflow activation)

---

#### 5. Check Tesseract OCR
```bash
tesseract --version
```

Expected: `tesseract 5.x.x`  
If fails: Install Tesseract, add to PATH

---

#### 6. Check File System Paths
```bash
# Windows
dir C:\CargoAttachments
dir C:\CargoProcessing
dir "C:\Users\Delta\Cargo Flow\Site de communication - Documents\Документи по договори"

# PowerShell
Test-Path "C:\CargoAttachments"
```

Expected: Directories exist and are writable  
If fails: Create directories, check permissions

---

### Common Dependency Issues

#### Issue: "Connection refused" errors

**Symptoms:**
- Queue Managers log "Failed to connect to http://localhost:5678"
- n8n workflows don't execute

**Root Causes:**
1. n8n server not started
2. Wrong port number in config
3. Firewall blocking localhost:5678

**Fix:**
```bash
# Check if n8n is running
netstat -ano | findstr :5678

# If not running, start n8n
n8n start

# Check firewall
# Windows Firewall → Allow app → Node.js
```

---

#### Issue: "Database connection lost"

**Symptoms:**
- Modules log "psycopg2.OperationalError"
- Processing stops mid-operation

**Root Causes:**
1. PostgreSQL service stopped
2. Too many connections (max_connections exceeded)
3. Network issue (even on localhost)
4. Long-running transaction timed out

**Fix:**
```bash
# Restart PostgreSQL service
net stop postgresql-x64-17
net start postgresql-x64-17

# Check connection count
psql -U postgres -d Cargo_mail -c "SELECT count(*) FROM pg_stat_activity;"

# Terminate idle connections
psql -U postgres -d Cargo_mail -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'idle' AND query_start < NOW() - INTERVAL '5 minutes';"
```

---

#### Issue: "Module not found" errors

**Symptoms:**
- Python script fails to start
- ImportError for specific libraries

**Root Causes:**
1. Wrong virtual environment activated
2. Dependencies not installed
3. Wrong Python version

**Fix:**
```bash
# Activate correct venv
cd C:\Python_project\CargoFlow\Cargoflow_XXX
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Verify installation
pip list | grep <package_name>
```

---

#### Issue: Files not being processed

**Symptoms:**
- Files exist in C:\CargoAttachments but not in database
- OCR/Office Processor not picking them up

**Root Causes:**
1. File extension not supported
2. File too small (filtered out)
3. Processing status stuck
4. Module not running

**Fix:**
```sql
-- Check file status
SELECT attachment_name, processing_status, file_extension
FROM email_attachments
WHERE processing_status = 'pending'
ORDER BY created_at DESC
LIMIT 10;

-- Reset stuck statuses (if needed)
UPDATE email_attachments
SET processing_status = 'pending'
WHERE processing_status = 'processing'
  AND updated_at < NOW() - INTERVAL '1 hour';
```

---

## 📚 Related Documentation

- **[STATUS_FLOW_MAP.md](docs/STATUS_FLOW_MAP.md)** - Complete status flow across modules
- **[SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md)** - Overall system architecture
- **[DATABASE_SCHEMA.md](DATABASE_SCHEMA.md)** - Database tables and relationships
- **[modules/01_EMAIL_FETCHER.md](modules/01_EMAIL_FETCHER.md)** - Email Fetcher details
- **[modules/04_QUEUE_MANAGERS.md](modules/04_QUEUE_MANAGERS.md)** - Queue Manager details
- **[modules/05_N8N_WORKFLOWS.md](modules/05_N8N_WORKFLOWS.md)** - n8n workflow details

---

**Document Status:** ✅ Complete  
**Last Updated:** November 12, 2025  
**Maintained By:** Documentation Team
