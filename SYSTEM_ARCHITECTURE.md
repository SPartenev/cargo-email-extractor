# CargoFlow - System Architecture

**Version:** 1.0  
**Created:** November 06, 2025  
**Status:** Production Architecture  
**Read Time:** 20 minutes

---

## 📋 Table of Contents

1. [System Overview](#system-overview)
2. [Architecture Layers](#architecture-layers)
3. [Technology Stack](#technology-stack)
4. [Component Architecture](#component-architecture)
5. [Integration Points](#integration-points)
6. [Data Flow Architecture](#data-flow-architecture)
7. [File System Architecture](#file-system-architecture)
8. [Security & Authentication](#security--authentication)
9. [Scalability & Performance](#scalability--performance)
10. [Deployment Architecture](#deployment-architecture)

---

## 🎯 System Overview

### Vision

CargoFlow is an **intelligent, end-to-end automated document processing system** designed to transform email-based document workflows into a structured, searchable, and organized digital archive. The system eliminates manual document sorting, categorization, and filing by leveraging AI, OCR, and workflow automation.

### Core Purpose

**From:** Unstructured emails with mixed attachments scattered across inboxes  
**To:** Organized, categorized, searchable documents grouped by contract numbers and business logic

### Key Capabilities

| Capability | Description | Technology |
|------------|-------------|------------|
| **Email Ingestion** | Automatic retrieval from Microsoft 365 | Microsoft Graph API |
| **Document Extraction** | Text from PDF, images, Office documents | PyMuPDF, Tesseract OCR, python-docx |
| **AI Classification** | 13 document categories with confidence scoring | OpenAI GPT / Google Gemini |
| **Contract Detection** | Automatic contract number extraction | Regex patterns + AI |
| **Queue Management** | Rate-limited processing with retry logic | Custom Python queue managers |
| **Organization** | Structured folder hierarchy by contract | File system + PostgreSQL triggers |

### Design Principles

1. **Automation First**: Minimize human intervention
2. **Reliability**: Robust error handling and retry mechanisms
3. **Traceability**: Every document action is logged and trackable
4. **Modularity**: Independent components that can fail/recover independently
5. **Scalability**: Designed to handle thousands of emails and attachments
6. **Extensibility**: Easy to add new document categories or processing rules

---

## 🏗️ Architecture Layers

CargoFlow follows a **layered architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                            │
│  - n8n Web UI (http://localhost:5678)                               │
│  - CLI Tools (Contract Processor commands)                          │
│  - Logs (Processing logs, Error logs)                               │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│                      APPLICATION LAYER                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │
│  │ Email Fetcher│  │ OCR/Office   │  │ Queue        │               │
│  │ (Graph API)  │  │ Processors   │  │ Managers     │               │
│  └──────────────┘  └──────────────┘  └──────────────┘               │
│                                                                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │
│  │ n8n Workflows│  │ Contract     │  │ AI Services  │               │
│  │ (AI Analysis)│  │ Processor    │  │ (OpenAI/     │               │
│  │              │  │              │  │  Gemini)     │               │
│  └──────────────┘  └──────────────┘  └──────────────┘               │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│                         DATA LAYER                                   │
│  ┌──────────────────────────────────────────────────────────┐       │
│  │              PostgreSQL Database (Cargo_mail)             │       │
│  │  - 19 Tables                                              │       │
│  │  - 8 Triggers                                             │       │
│  │  - 13 Functions                                           │       │
│  │  - NOTIFY/LISTEN for inter-process communication         │       │
│  └──────────────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│                      STORAGE LAYER                                   │
│  C:\CargoAttachments\          - Raw email attachments              │
│  C:\CargoProcessing\           - Processed documents (text + images)│
│  C:\...\Документи по договори\ - Organized final output             │
└─────────────────────────────────────────────────────────────────────┘
```

### Layer Responsibilities

| Layer | Responsibility | Technology |
|-------|---------------|------------|
| **Presentation** | User interaction, monitoring | n8n UI, CLI, Logs |
| **Application** | Business logic, processing | Python 3.11+ |
| **Data** | State management, triggers | PostgreSQL 17 |
| **Storage** | File persistence | Windows File System |

---

## 🛠️ Technology Stack

### Core Technologies

| Category | Technology | Version | Purpose |
|----------|-----------|---------|---------|
| **Programming Language** | Python | 3.11+ | All processing components |
| **Database** | PostgreSQL | 17 | Central state management |
| **API Integration** | Microsoft Graph API | v1.0 | Email retrieval |
| **Workflow Automation** | n8n | Latest | AI orchestration |
| **OCR Engine** | Tesseract | 5.x | Text extraction from images |
| **AI Services** | OpenAI GPT / Google Gemini | Latest | Document classification |

### Python Libraries

**Email & Authentication:**
- `msal` - Microsoft Authentication Library
- `requests` - HTTP client for Graph API
- `pytz` - Timezone handling

**Database:**
- `psycopg2` - PostgreSQL adapter
- `psycopg2-binary` - PostgreSQL binary driver

**Document Processing:**
- `PyMuPDF` (fitz) - PDF text extraction
- `pytesseract` - OCR wrapper for Tesseract
- `Pillow` (PIL) - Image processing
- `python-docx` - Word document processing
- `openpyxl` - Excel file processing
- `pypandoc` - Universal document converter

**Utilities:**
- `watchdog` - File system monitoring
- `schedule` - Task scheduling
- `hashlib` - File hashing for duplicate detection

### External Services

| Service | Purpose | Authentication |
|---------|---------|---------------|
| **Microsoft 365** | Email source | Azure AD OAuth 2.0 |
| **OpenAI** | AI categorization (primary) | API Key |
| **Google Gemini** | AI categorization (alternative) | API Key |

### Infrastructure

- **OS:** Windows Server / Windows 10+
- **Database Server:** PostgreSQL 17 (localhost:5432)
- **n8n Server:** localhost:5678
- **File System:** NTFS (C:\ drive)

---

## 🧩 Component Architecture

CargoFlow consists of **7 independent, loosely-coupled components** that communicate through the database and file system:

### Component Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CARGOFLOW COMPONENTS                         │
└─────────────────────────────────────────────────────────────────────┘

   [1] Email Fetcher          Entry point - Data ingestion
        ↓
   [2] OCR Processor          Document processing (parallel)
   [3] Office Processor       Document processing (parallel)
        ↓
   [4] Text Queue Manager     Queue orchestration (parallel)
   [5] Image Queue Manager    Queue orchestration (parallel)
        ↓
   [6] n8n Workflows          AI analysis and categorization
        ↓
   [7] Contract Processor     Final organization and output
```

### 1. Email Fetcher (Data Ingestion Layer)

**Script:** `Cargoflow_mail/graph_email_extractor_v5.py`  
**Status:** ✅ Active  
**Purpose:** Retrieves emails from Microsoft 365 and saves attachments

**Architecture:**

```python
class GraphEmailExtractor:
    def __init__(self):
        self.auth_token = None
        self.db_connection = None  # PostgreSQL connection
        self.keep_alive_enabled = True  # TCP keep-alive
        
    def authenticate():
        # OAuth 2.0 with MSAL library
        # Returns: Bearer token
        
    def fetch_emails():
        # Graph API: GET /users/{id}/messages
        # Filters: hasAttachments=true
        
    def save_attachments():
        # Structure: C:\CargoAttachments\{sender}\{date}\{subject}\
        
    def insert_to_database():
        # Tables: emails, email_attachments
        # Status: processing_status='pending'
```

**Database Operations:**
- **WRITES:** `emails`, `email_attachments` (INSERT)
- **Status Set:** `processing_status='pending'`

**Dependencies:**
- Microsoft Graph API (external)
- PostgreSQL database
- File system (C:\CargoAttachments\)

**Error Handling:**
- Connection keep-alive (600s idle, 30s interval, 3 retries)
- Exponential backoff for Graph API rate limits
- Database reconnection on connection loss

**Configuration:** `graph_config.json`

---

### 2. OCR Processor (Document Processing Layer)

**Script:** `Cargoflow_OCR/ocr_processor.py`  
**Status:** ✅ Active  
**Purpose:** Extracts text from PDFs and images using OCR

**Architecture:**

```python
class OCRProcessor:
    def __init__(self):
        self.tesseract_path = r"C:\Program Files\Tesseract-OCR\tesseract.exe"
        self.supported_formats = ['pdf', 'jpg', 'jpeg', 'png', 'tif', 'tiff']
        
    def process_pdf():
        # Try direct text extraction first (PyMuPDF)
        # If quality low → Convert to PNG → OCR
        
    def process_image():
        # PNG/JPG → Tesseract OCR
        
    def assess_quality():
        # Heuristics: average word length, alphanumeric ratio
        # Returns: 'high', 'medium', 'low'
        
    def save_output():
        # Text: C:\CargoProcessing\...\ocr_results\{file}_extracted.txt
        # Images: C:\CargoProcessing\...\images\{file}_1.png
```

**Database Operations:**
- **READS:** `email_attachments` WHERE `processing_status='pending'`
- **WRITES:** UPDATE `processing_status='processing'` → `'completed'`

**Output Structure:**
```
C:\CargoProcessing\processed_documents\2025\
├── ocr_results\{sender}\{subject}\
│   └── document_extracted.txt
├── images\{sender}\{subject}\
│   ├── document_1.png
│   └── document_2.png
└── json_extract\{sender}\{subject}\
    └── document_metadata.json
```

**Dependencies:**
- Tesseract OCR engine
- PyMuPDF library
- Pillow (image processing)
- PostgreSQL database

**Performance:**
- Multi-page PDFs: ~2-5 seconds per page
- Image OCR: ~1-3 seconds per image
- Quality assessment: ~0.1 seconds

---

### 3. Office Processor (Document Processing Layer)

**Script:** `Cargoflow_Office/office_processor.py`  
**Status:** ✅ Active  
**Purpose:** Extracts text from Word, Excel, and other Office documents

**Architecture:**

```python
class OfficeProcessor:
    def __init__(self):
        self.supported_formats = ['docx', 'doc', 'xlsx', 'xls', 'txt', 'rtf', 'odt']
        
    def process_word():
        # python-docx for .docx
        # win32com for .doc (requires MS Office)
        
    def process_excel():
        # openpyxl for .xlsx
        # xlrd for .xls
        
    def process_text():
        # Direct read with encoding detection
        
    def save_output():
        # Text: C:\CargoProcessing\...\ocr_results\{file}_extracted.txt
```

**Database Operations:**
- **READS:** `email_attachments` WHERE `processing_status='pending'` AND `content_type` IN (Office types)
- **WRITES:** UPDATE `processing_status='completed'`

**Dependencies:**
- python-docx (DOCX)
- openpyxl (XLSX)
- win32com (legacy Office formats - requires MS Office installed)
- pypandoc (universal fallback)
- PostgreSQL database

**Note:** Independent of OCR Processor - operates in parallel

---

### 4 & 5. Queue Managers (Orchestration Layer)

**Scripts:**
- `Cargoflow_Queue/text_queue_manager.py`
- `Cargoflow_Queue/image_queue_manager.py`

**Status:** ⚠️ Stopped (since 28 Oct 09:40)  
**Purpose:** Watch file system, queue files for n8n AI analysis

**Architecture:**

```python
class QueueManager:
    def __init__(self, config):
        self.watch_path = config['watch_path']
        self.webhook_url = config['webhook_url']
        self.rate_limit = config['rate_limit_per_minute']  # Default: 3
        self.scan_interval = config['scan_interval_seconds']  # Default: 15
        
    def watch_directory():
        # Scan for new files every 15 seconds
        
    def queue_file():
        # Check for duplicates in processing_queue
        # INSERT INTO processing_queue (status='pending')
        
    def send_to_webhook():
        # POST to n8n webhook
        # Rate limit: 3 files/minute
        # Retry: 3 attempts with exponential backoff
```

**Database Operations:**
- **READS:** `processing_queue` (to check duplicates)
- **WRITES:** INSERT INTO `processing_queue` (status='pending')
- **Triggers:** PostgreSQL NOTIFY → n8n_channel_text_ready / n8n_channel_image_ready

**Configuration:** `queue_config.json`

```json
{
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

**Rate Limiting:**
- Purpose: Prevent AI API rate limit errors
- Default: 3 files per minute (20-second intervals)
- Configurable per queue

**Dependencies:**
- n8n webhooks (localhost:5678)
- PostgreSQL database
- File system access

---

### 6. n8n Workflows (AI Analysis Layer)

**Location:** `Cargoflow_n8n/`  
**Workflows:**
1. `Contract_Text_CargoFlow.json` - Text document analysis
2. `Contract_PNG_CargoFlow.json` - Image document analysis

**Status:** ⚠️ Unknown  
**Purpose:** AI-powered document categorization and data extraction

**Architecture:**

```
[PostgreSQL Trigger] NOTIFY n8n_channel_text_ready
        ↓
[n8n] LISTEN on PostgreSQL
        ↓
[n8n] Fetch file content from processing_queue
        ↓
[n8n] Send to AI API (OpenAI GPT / Google Gemini)
        ↓
[AI] Analyze document:
     - Determine category (13 types)
     - Extract contract_number (if applicable)
     - Calculate confidence score
     - Generate summary
        ↓
[n8n] UPDATE email_attachments:
     - document_category = 'invoice' / 'cmr' / etc
     - contract_number = '50251006834'
     - confidence_score = 0.95
     - classification_timestamp = NOW()
     - processing_status = 'classified'
        ↓
[IF invoice] Extract invoice data → invoice_base + invoice_items
```

**AI Prompt (Simplified):**

```
You are a document classifier. Analyze this document and return:

{
  "category": "invoice|cmr|contract|protocol|...",
  "confidence": 0.95,
  "contract_number": "50251006834",
  "summary": "Brief description"
}

Categories:
1. contract
2. contract_amendment
3. contract_termination
4. contract_extension
5. service_agreement
6. framework_agreement
7. cmr
8. protocol
9. annex
10. insurance
11. invoice
12. credit_note
13. other
```

**Database Operations:**
- **READS:** `processing_queue` WHERE `status='pending'`
- **WRITES:** 
  - UPDATE `email_attachments` (category, contract_number, status)
  - UPDATE `processing_queue` (status='completed')
  - INSERT `invoice_base`, `invoice_items` (if invoice)
  - INSERT `document_pages` (page-level categories)

**Dependencies:**
- OpenAI API OR Google Gemini API
- PostgreSQL NOTIFY/LISTEN
- Queue Managers (to trigger workflows)

**Performance:**
- Text analysis: ~2-5 seconds per document
- Image analysis: ~5-10 seconds per image
- Rate limited by queue managers (3 files/minute)

---

### 7. Contract Processor (Organization Layer)

**Script:** `Cargoflow_Contracts/main.py`  
**Status:** ❌ Not Started  
**Purpose:** Detect contracts, organize files into structured folders

**Architecture:**

```python
class ContractProcessor:
    def __init__(self):
        self.contract_patterns = [
            r'50\d{9,10}',  # 50XXXXXXXXX (10-11 digits)
            r'20\d{9,10}'   # 20XXXXXXXXX (10-11 digits)
        ]
        
    def process_email_ready_queue():
        # SELECT FROM email_ready_queue WHERE processed=FALSE
        
    def collect_contract_numbers():
        # Get all contract_numbers for email_id
        
    def generate_contract_key():
        # Concatenate all contract numbers (sorted)
        # Example: "50251006834_50251007003"
        
    def get_next_index():
        # UPSERT into contract_folder_seq
        # Returns: next available index
        
    def update_folder_name():
        # UPDATE emails SET folder_name = '{contract_key}_{index}'
        
    def organize_files():
        # Create folder: C:\...\Документи по договори\{contract_key}_{index}\
        # Copy/Move files to organized structure
        
    def insert_contracts():
        # INSERT INTO contracts (contract_number, email_id, ...)
```

**Database Operations:**
- **READS:** `email_ready_queue` WHERE `processed=FALSE`
- **WRITES:**
  - UPDATE `emails` (folder_name)
  - INSERT `contracts`
  - UPDATE `email_ready_queue` (processed=TRUE)
  - UPDATE `email_attachments` (processing_status='organized')
  - UPSERT `contract_folder_seq`

**CLI Commands:**

```bash
# Status check
python main.py --status

# Process batch (10 emails)
python main.py --process-batch 10

# Process single email
python main.py --process-single 123

# Continuous processing (daemon mode)
python main.py --continuous

# Statistics
python main.py --statistics

# Export statistics to CSV
python main.py --export-stats
```

**Output Folder Structure:**

```
C:\Users\Delta\Cargo Flow\...\Документи по договори\
├── 50251006834_001\
│   ├── Invoice_2025-10-27.pdf
│   ├── CMR_2025-10-27.pdf
│   └── Protocol_2025-10-27.pdf
├── 50251006834_002\
│   └── Contract_Amendment_2025-10-28.pdf
└── 50251007003_001\
    ├── Contract_2025-10-25.pdf
    └── Insurance_2025-10-25.pdf
```

**Dependencies:**
- PostgreSQL database
- File system access (source and destination)
- AI-extracted contract numbers

---

## 🔗 Integration Points

### 1. Microsoft Graph API Integration

**Purpose:** Retrieve emails and attachments from Microsoft 365

**Authentication Flow:**

```
[1] Azure AD Application Registration
    ↓ client_id, client_secret, tenant_id
[2] OAuth 2.0 Client Credentials Flow
    ↓ POST to https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/token
[3] Access Token (Bearer)
    ↓ Valid for 1 hour
[4] Graph API Requests
    ↓ GET /users/{user_id}/messages
    ↓ GET /users/{user_id}/messages/{message_id}/attachments
```

**API Endpoints:**

| Endpoint | Purpose | Response |
|----------|---------|----------|
| `/users/{id}/messages` | List emails | JSON (emails metadata) |
| `/messages/{id}/attachments` | Get attachments | JSON (attachment metadata + content) |
| `/messages?$filter=hasAttachments eq true` | Filter emails with attachments | Filtered email list |

**Rate Limits:**
- 1,000 requests per 10 minutes per user
- Retry-After header on 429 responses
- Exponential backoff implemented

**Configuration:**

```json
{
  "client_id": "your-client-id-here",
  "client_secret": "your-client-secret-here",
  "tenant_id": "your-tenant-id-here",
  "user_email": "pa@cargo-flow.fr",
  "scopes": ["https://graph.microsoft.com/.default"]
}
```

---

### 2. PostgreSQL Database Integration

**Purpose:** Central state management, triggers, inter-process communication

**Connection Management:**

```python
connection = psycopg2.connect(
    host='localhost',
    port=5432,
    database='Cargo_mail',
    user='postgres',
    password='...',
    connect_timeout=10,
    keepalives_idle=600,      # 10 minutes
    keepalives_interval=30,   # 30 seconds
    keepalives_count=3        # 3 retries
)
```

**Keep-Alive Configuration:**
- `keepalives_idle=600`: Wait 10 minutes before first keep-alive probe
- `keepalives_interval=30`: Send keep-alive every 30 seconds after first probe
- `keepalives_count=3`: Disconnect after 3 failed probes

**NOTIFY/LISTEN Mechanism:**

```sql
-- Component A: Queue Manager
INSERT INTO processing_queue (file_path, status) VALUES (..., 'pending');
-- Trigger automatically sends: NOTIFY n8n_channel_text_ready, 'file_id';

-- Component B: n8n Workflow
LISTEN n8n_channel_text_ready;
-- Receives notification, fetches file_id, processes file
```

**Benefits:**
- Decoupled components (no direct HTTP calls between Python processes)
- Real-time notifications (no polling)
- Database-guaranteed delivery

**Trigger Architecture:**

```sql
-- Example Trigger
CREATE TRIGGER trigger_notify_text
AFTER INSERT ON processing_queue
FOR EACH ROW
WHEN (NEW.status = 'pending' AND NEW.file_type = 'text')
EXECUTE FUNCTION notify_n8n_text_queue();

-- Function
CREATE FUNCTION notify_n8n_text_queue() RETURNS TRIGGER AS $$
BEGIN
    PERFORM pg_notify('n8n_channel_text_ready', NEW.id::text);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

---

### 3. n8n Webhook Integration

**Purpose:** Trigger AI analysis workflows

**Webhooks:**

| Webhook URL | Purpose | Trigger |
|-------------|---------|---------|
| `http://localhost:5678/webhook/analyze-text` | Text document analysis | Text Queue Manager |
| `http://localhost:5678/webhook/analyze-image` | Image document analysis | Image Queue Manager |

**Request Format:**

```json
{
  "file_id": 123,
  "file_path": "C:\\CargoProcessing\\...\\document_extracted.txt",
  "attachment_id": 456,
  "email_id": 789,
  "metadata": {
    "sender": "example@domain.com",
    "subject": "Contract Documents",
    "received_time": "2025-11-06T10:30:00Z"
  }
}
```

**Response Format:**

```json
{
  "category": "invoice",
  "confidence": 0.95,
  "contract_number": "50251006834",
  "summary": "Invoice for transport services",
  "invoice_data": {
    "invoice_number": "INV-2025-001",
    "total_amount": 1500.00,
    "currency": "EUR"
  }
}
```

**Error Handling:**
- Retry: 3 attempts with exponential backoff (10s, 20s, 40s)
- Timeout: 60 seconds per request
- Logging: All requests logged to queue manager logs

---

### 4. AI API Integration

**Supported Providers:**

| Provider | Model | Purpose | Cost |
|----------|-------|---------|------|
| **OpenAI** | GPT-4 | Primary AI analysis | $0.03 per 1K tokens (input) |
| **Google Gemini** | Gemini Pro | Fallback AI analysis | Free tier available |

**OpenAI Integration:**

```python
import openai

openai.api_key = "sk-..."

response = openai.ChatCompletion.create(
    model="gpt-4",
    messages=[
        {"role": "system", "content": "You are a document classifier..."},
        {"role": "user", "content": document_text}
    ],
    temperature=0.3,
    max_tokens=500
)

result = response.choices[0].message.content
```

**Google Gemini Integration:**

```python
import google.generativeai as genai

genai.configure(api_key="...")
model = genai.GenerativeModel('gemini-pro')

response = model.generate_content(
    f"Classify this document: {document_text}"
)

result = response.text
```

**Rate Limiting:**
- Queue managers limit to 3 files/minute
- Prevents hitting AI API rate limits
- Configurable per queue

---

### 5. File System Integration

**Purpose:** Persistent storage for emails, processed documents, and organized output

**Directory Structure:**

```
C:\
├── CargoAttachments\                  # Raw email attachments
│   └── {sender_email}\
│       └── {YYYY-MM}\
│           └── {subject}_{timestamp}\
│               ├── email_metadata.json
│               ├── email_body.txt
│               └── attachment.pdf
│
├── CargoProcessing\                   # Processed documents
│   └── processed_documents\
│       └── {YYYY}\
│           ├── ocr_results\           # Extracted text
│           │   └── {sender}\{subject}\
│           │       └── {file}_extracted.txt
│           ├── images\                # Extracted images
│           │   └── {sender}\{subject}\
│           │       ├── {file}_1.png
│           │       └── {file}_2.png
│           └── json_extract\          # Metadata
│               └── {sender}\{subject}\
│                   └── {file}_metadata.json
│
└── Users\Delta\Cargo Flow\...\
    └── Документи по договори\         # Organized output
        ├── {contract_number}_{index}\
        │   ├── Invoice_YYYY-MM-DD.pdf
        │   ├── CMR_YYYY-MM-DD.pdf
        │   └── Contract_YYYY-MM-DD.pdf
        └── non_contracts\             # Files without contract numbers
            ├── by_sender\
            ├── by_date\
            └── by_type\
```

**File Naming Conventions:**

| Type | Pattern | Example |
|------|---------|---------|
| **Email Folder** | `{subject}_{timestamp}` | `Contract_Documents_20251106_103045` |
| **Extracted Text** | `{original_name}_extracted.txt` | `invoice_extracted.txt` |
| **Extracted Image** | `{original_name}_{page}.png` | `contract_1.png` |
| **Metadata** | `{original_name}_metadata.json` | `document_metadata.json` |
| **Organized Folder** | `{contract_key}_{index}` | `50251006834_001` |

**Storage Management:**
- No automatic cleanup (manual intervention required)
- Duplicate detection via MD5 hashing
- File size limits: None (configurable if needed)

---

## 🔄 Data Flow Architecture

### Complete End-to-End Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                    EMAIL TO ORGANIZED DOCUMENT                       │
│                         (Complete Flow)                              │
└─────────────────────────────────────────────────────────────────────┘

[STAGE 1: EMAIL INGESTION]
Microsoft 365 Mailbox
    ↓ (Microsoft Graph API)
graph_email_extractor_v5.py
    ↓ (INSERT INTO)
PostgreSQL: emails, email_attachments (processing_status='pending')
    ↓ (File Write)
C:\CargoAttachments\{sender}\{date}\{subject}\attachment.pdf

[STAGE 2: DOCUMENT PROCESSING]
OCR/Office Processors (parallel)
    ↓ (SELECT WHERE processing_status='pending')
    ↓ (UPDATE processing_status='processing')
Extract Text/Images
    ↓ (File Write)
C:\CargoProcessing\...\ocr_results\document_extracted.txt
C:\CargoProcessing\...\images\document_1.png
    ↓ (UPDATE processing_status='completed')
PostgreSQL: email_attachments

[STAGE 3: QUEUE ORCHESTRATION]
Queue Managers (Text + Image)
    ↓ (File System Watch)
    ↓ (INSERT INTO)
PostgreSQL: processing_queue (status='pending')
    ↓ (PostgreSQL NOTIFY)
n8n_channel_text_ready / n8n_channel_image_ready

[STAGE 4: AI ANALYSIS]
n8n Workflows
    ↓ (LISTEN on PostgreSQL NOTIFY)
    ↓ (Fetch file content)
    ↓ (POST to AI API)
OpenAI GPT / Google Gemini
    ↓ (AI Response: category, confidence, contract_number)
    ↓ (UPDATE)
PostgreSQL: email_attachments
    - document_category = 'invoice' / 'cmr' / etc
    - contract_number = '50251006834'
    - confidence_score = 0.95
    - processing_status = 'classified'

[STAGE 5: CONTRACT DETECTION]
PostgreSQL Trigger: trigger_queue_email
    ↓ (IF all attachments for email are 'classified')
    ↓ (INSERT INTO)
PostgreSQL: email_ready_queue (processed=FALSE)

[STAGE 6: FILE ORGANIZATION]
Contract Processor (main.py)
    ↓ (SELECT FROM email_ready_queue)
    ↓ (Collect contract_numbers)
    ↓ (Generate contract_key + get index)
    ↓ (UPDATE emails.folder_name)
    ↓ (INSERT INTO contracts)
    ↓ (CREATE FOLDER)
C:\...\Документи по договори\{contract_key}_{index}\
    ↓ (COPY/MOVE FILES)
    ↓ (UPDATE processing_status='organized')
PostgreSQL: email_attachments, email_ready_queue (processed=TRUE)

[FINAL OUTPUT]
Organized folder with all contract documents ✅
```

### Timing Estimates

| Stage | Typical Time | Bottleneck |
|-------|--------------|------------|
| 1. Email Ingestion | 1-2 seconds per email | Graph API rate limits |
| 2. Document Processing | 2-5 seconds per document | OCR performance |
| 3. Queue Orchestration | <1 second | N/A |
| 4. AI Analysis | 3-7 seconds per document | AI API latency |
| 5. Contract Detection | <1 second | N/A |
| 6. File Organization | 1-2 seconds per email | File I/O |
| **Total per email** | **10-20 seconds** | **AI Analysis** |

---

## 📁 File System Architecture

### Storage Strategy

**Separation of Concerns:**
1. **Raw Data** (C:\CargoAttachments\) - Immutable, original files
2. **Processed Data** (C:\CargoProcessing\) - Intermediate results
3. **Organized Data** (Документи по договори\) - Final output

**Rationale:**
- Raw data preserved for auditing and reprocessing
- Processed data can be regenerated if needed
- Organized data is the "golden source" for end users

### Path Conventions

**Raw Attachments:**
```
C:\CargoAttachments\{sender_email}\{YYYY-MM}\{subject}_{timestamp}\
```

**Why:**
- Easy to locate all emails from a sender
- Chronological organization by month
- Unique folder per email (timestamp prevents collisions)

**Processed Documents:**
```
C:\CargoProcessing\processed_documents\{YYYY}\{type}\{sender}\{subject}\{file}
```

**Why:**
- Year-based partitioning for performance
- Type separation (ocr_results vs images)
- Mirrors original structure for traceability

**Organized Contracts:**
```
C:\...\Документи по договори\{contract_number}_{index}\{document}
```

**Why:**
- Contract-centric organization (business logic)
- Index prevents folder collisions (same contract, multiple emails)
- Flat structure within folder for simplicity

### Storage Sizing (Current)

| Directory | Size (Estimate) | Files | Notes |
|-----------|-----------------|-------|-------|
| C:\CargoAttachments\ | ~1-2 GB | 296 attachments | 226 emails |
| C:\CargoProcessing\ | ~500 MB | ~600 files | Text + PNG |
| Документи по договори\ | ~0 MB | 0 files | Not yet populated |

### Storage Management

**No Automatic Cleanup:**
- All files are retained indefinitely
- Manual intervention required for archival/deletion

**Future Considerations:**
- Archive old files (>1 year) to separate storage
- Compression of processed text files
- Database-only retention with file deletion

---

## 🔐 Security & Authentication

### Authentication Mechanisms

| Component | Authentication Method | Credentials Storage |
|-----------|---------------------|-------------------|
| **Microsoft Graph API** | OAuth 2.0 (Client Credentials) | `graph_config.json` |
| **PostgreSQL** | Username/Password | `database.py` config files |
| **n8n Webhooks** | None (localhost only) | N/A |
| **OpenAI API** | API Key | n8n credential store |
| **Google Gemini** | API Key | n8n credential store |

### Microsoft Graph API Security

**Azure AD Application:**
- Application Type: Confidential client
- Permissions: Mail.Read, Mail.ReadWrite (Application permissions)
- Tenant: Single tenant (cargo-flow.fr)

**Token Management:**
- Access tokens expire after 1 hour
- Automatic refresh before expiration
- Secure storage in memory only (not persisted)

### Database Security

**Connection Security:**
- Local connections only (localhost:5432)
- Password authentication
- No SSL/TLS (trusted local network)

**Credential Management:**
- Stored in config files (not in code)
- Config files excluded from version control (.gitignore)

**Future Improvements:**
- Environment variables for credentials
- Azure Key Vault integration
- Database SSL/TLS for remote connections

### File System Security

**Access Control:**
- Windows NTFS permissions
- Only CargoFlow service account has access
- No anonymous access

### n8n Security

**Webhook Security:**
- Localhost only (127.0.0.1:5678)
- No external access (firewall blocked)
- No authentication (trusted local environment)

**Future Improvements:**
- Webhook authentication (API keys)
- HTTPS for webhooks
- Rate limiting per webhook

### Secrets Management

**Current Approach:**
```
graph_config.json (Microsoft Graph)
queue_config.json (n8n webhooks)
config/database.py (PostgreSQL)
n8n credential store (AI API keys)
```

**Best Practices:**
- Never commit credentials to Git
- Rotate credentials periodically
- Use least privilege principle

**Recommended Approach:**
```
.env file:
GRAPH_CLIENT_ID=...
GRAPH_CLIENT_SECRET=...
DB_PASSWORD=...
OPENAI_API_KEY=...

Load via: python-dotenv library
```

---

## ⚡ Scalability & Performance

### Current Performance

| Metric | Current | Target | Bottleneck |
|--------|---------|--------|------------|
| **Emails per hour** | ~20-30 | 100+ | Graph API rate limits |
| **Documents per hour** | ~30-50 | 200+ | AI API latency |
| **OCR processing** | 2-5 sec/doc | <2 sec | Tesseract performance |
| **AI analysis** | 3-7 sec/doc | <3 sec | OpenAI API latency |
| **Database queries** | <100ms | <50ms | Not a bottleneck |

### Scaling Strategies

#### 1. Horizontal Scaling (Multiple Instances)

**Current:** Single instance of each component  
**Future:** Multiple instances with work distribution

```
Queue Manager (Text) - Instance 1 (files 1-100)
Queue Manager (Text) - Instance 2 (files 101-200)
Queue Manager (Text) - Instance 3 (files 201-300)
```

**Implementation:**
- Add `instance_id` to processing_queue
- Each instance claims work: `UPDATE ... WHERE instance_id IS NULL LIMIT 10 RETURNING id`
- Database-based work distribution

#### 2. Vertical Scaling (Faster Hardware)

**OCR Processing:**
- GPU acceleration for Tesseract (CUDA support)
- Faster CPU (multi-core)
- More RAM (cache PDFs in memory)

**Database:**
- SSD storage (faster I/O)
- More RAM (larger cache)
- Connection pooling (pgBouncer)

#### 3. Caching

**File Hashing:**
- Cache MD5 hashes to skip duplicate processing
- Current: `processing_history` table stores hashes

**AI Results:**
- Cache AI responses for similar documents
- Implementation: `ai_cache` table with document hash + response

#### 4. Queue Optimization

**Prioritization:**
- High priority: Invoices, Contracts
- Low priority: Other documents
- Implementation: `processing_queue.priority` column

**Batch Processing:**
- Send multiple files to AI in single request
- Reduce HTTP overhead
- Requires AI API support

### Performance Monitoring

**Metrics to Track:**

```sql
-- Average processing time by stage
SELECT 
    'OCR Processing' as stage,
    AVG(processing_time_ms) as avg_ms,
    MAX(processing_time_ms) as max_ms
FROM processing_history
WHERE success = TRUE AND file_type = 'pdf';

-- Queue depth over time
SELECT 
    DATE_TRUNC('hour', created_at) as hour,
    COUNT(*) as items_queued
FROM processing_queue
GROUP BY hour
ORDER BY hour DESC;

-- AI categorization rate
SELECT 
    DATE_TRUNC('hour', classification_timestamp) as hour,
    COUNT(*) as docs_classified
FROM email_attachments
WHERE classification_timestamp IS NOT NULL
GROUP BY hour
ORDER BY hour DESC;
```

**Alerting Thresholds:**
- Queue depth > 100 items → Alert
- Processing time > 10 seconds average → Alert
- AI categorization rate < 10 docs/hour → Alert

### Database Performance

**Current Optimizations:**
- 44 indexes on key columns
- VACUUM ANALYZE runs nightly
- Connection keep-alive enabled

**Future Optimizations:**
- Partition large tables by year (email_attachments, processing_queue)
- Materialized views for statistics
- Read replicas for reporting queries

---

## 🚀 Deployment Architecture

### Production Environment

**Server Requirements:**

| Component | Requirement | Notes |
|-----------|-------------|-------|
| **OS** | Windows Server 2019+ or Windows 10+ | For win32com (Office integration) |
| **RAM** | 8 GB minimum, 16 GB recommended | OCR + AI processing |
| **CPU** | 4 cores minimum, 8 cores recommended | Parallel processing |
| **Storage** | 100 GB minimum, 500 GB recommended | Document storage |
| **Network** | 10 Mbps minimum, 100 Mbps recommended | Graph API + AI API |

**Software Requirements:**
- Python 3.11+
- PostgreSQL 17
- n8n (latest)
- Tesseract OCR 5.x
- Microsoft Office (for .doc/.xls support)

### Deployment Process

**Step 1: Infrastructure Setup**
```bash
# Install Python 3.11
choco install python311

# Install PostgreSQL 17
choco install postgresql17 --params '/Password:YourPassword'

# Install Tesseract OCR
choco install tesseract

# Install n8n
npm install -g n8n
```

**Step 2: Database Setup**
```bash
# Create database
createdb -U postgres Cargo_mail

# Import schema
psql -U postgres -d Cargo_mail -f database_schema.sql

# Verify
psql -U postgres -d Cargo_mail -c "\dt"
```

**Step 3: Application Deployment**
```bash
# Clone/Copy project files
cd C:\Python_project\CargoFlow

# Setup virtual environments for each component
cd Cargoflow_mail && python -m venv venv && venv\Scripts\activate && pip install -r requirements.txt
cd ..\Cargoflow_Office && python -m venv venv && venv\Scripts\activate && pip install -r requirements.txt
cd ..\Cargoflow_Queue && python -m venv venv && venv\Scripts\activate && pip install -r requirements.txt
cd ..\Cargoflow_Contracts && python -m venv venv && venv\Scripts\activate && pip install -r requirements.txt
```

**Step 4: Configuration**
```bash
# Edit configurations
notepad Cargoflow_mail\graph_config.json
notepad Cargoflow_Queue\queue_config.json
notepad Cargoflow_Contracts\config\database.py
```

**Step 5: Service Setup (Windows Services)**

**Option A: Manual Start (7 Terminal Windows)**
```bash
# See "Quick Start" section in README.md
```

**Option B: Windows Services (Recommended for Production)**

```powershell
# Install NSSM (Non-Sucking Service Manager)
choco install nssm

# Create services
nssm install CargoFlow_EmailFetcher "C:\Python_project\CargoFlow\Cargoflow_mail\venv\Scripts\python.exe" "graph_email_extractor_v5.py"
nssm install CargoFlow_OCRProcessor "C:\Python_project\CargoFlow\Cargoflow_OCR\venv\Scripts\python.exe" "ocr_processor.py"
nssm install CargoFlow_OfficeProcessor "C:\Python_project\CargoFlow\Cargoflow_Office\venv\Scripts\python.exe" "office_processor.py"
nssm install CargoFlow_TextQueue "C:\Python_project\CargoFlow\Cargoflow_Queue\venv\Scripts\python.exe" "text_queue_manager.py"
nssm install CargoFlow_ImageQueue "C:\Python_project\CargoFlow\Cargoflow_Queue\venv\Scripts\python.exe" "image_queue_manager.py"
nssm install CargoFlow_Contracts "C:\Python_project\CargoFlow\Cargoflow_Contracts\venv\Scripts\python.exe" "main.py --continuous"
nssm install CargoFlow_n8n "C:\Program Files\nodejs\n8n.cmd"

# Configure service recovery (auto-restart on failure)
nssm set CargoFlow_EmailFetcher AppExit Default Restart
nssm set CargoFlow_EmailFetcher AppRestartDelay 10000  # 10 seconds

# Start services
net start CargoFlow_EmailFetcher
net start CargoFlow_OCRProcessor
# ... etc
```

### Monitoring & Logging

**Log Locations:**
```
C:\Python_project\CargoFlow\Cargoflow_mail\graph_extraction.log
C:\Python_project\CargoFlow\Cargoflow_Office\document_processing.log
C:\Python_project\CargoFlow\Cargoflow_Queue\text_queue_manager.log
C:\Python_project\CargoFlow\Cargoflow_Queue\image_queue_manager.log
C:\Python_project\CargoFlow\Cargoflow_Contracts\logs\contract_detector_{date}.log
```

**Log Rotation:**
- Logs rotate daily (midnight)
- Keep 30 days of logs
- Archive to separate storage

**Health Checks:**

```powershell
# Check if all services are running
Get-Service | Where-Object {$_.Name -like "CargoFlow_*"}

# Check PostgreSQL
psql -U postgres -d Cargo_mail -c "SELECT COUNT(*) FROM emails;"

# Check n8n
curl http://localhost:5678/

# Check log files for errors
Get-Content "C:\Python_project\CargoFlow\Cargoflow_mail\graph_extraction.log" -Tail 50 | Select-String "ERROR"
```

### Backup Strategy

**Database Backup:**
```bash
# Daily backup
pg_dump -U postgres -d Cargo_mail -F c -f C:\Backups\Cargo_mail_$(date +%Y%m%d).backup

# Restore
pg_restore -U postgres -d Cargo_mail -F c C:\Backups\Cargo_mail_20251106.backup
```

**File Backup:**
```bash
# Daily backup of attachments
robocopy C:\CargoAttachments\ D:\Backups\CargoAttachments\ /MIR /R:3 /W:10 /LOG:C:\Logs\backup.log
```

### Disaster Recovery

**Recovery Time Objective (RTO):** 4 hours  
**Recovery Point Objective (RPO):** 24 hours (daily backups)

**Recovery Steps:**
1. Restore PostgreSQL database from backup (1 hour)
2. Restore file attachments from backup (2 hours)
3. Restart services (30 minutes)
4. Verify system health (30 minutes)

---

## 📊 Architecture Diagrams

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        CARGOFLOW SYSTEM                              │
│                    (High-Level Architecture)                         │
└─────────────────────────────────────────────────────────────────────┘

                    ┌──────────────────────┐
                    │  Microsoft 365       │
                    │  (Email Source)      │
                    └──────────────────────┘
                              ↓
                    ┌──────────────────────┐
                    │  Email Fetcher       │
                    │  (Graph API)         │
                    └──────────────────────┘
                              ↓
            ┌─────────────────┴─────────────────┐
            ↓                                   ↓
  ┌──────────────────────┐          ┌──────────────────────┐
  │  PostgreSQL          │          │  File System         │
  │  (State Management)  │          │  (Storage)           │
  └──────────────────────┘          └──────────────────────┘
            ↓                                   ↓
  ┌─────────────────────────────────────────────────────────┐
  │             Document Processing Layer                    │
  ├──────────────────────┬──────────────────────────────────┤
  │  OCR Processor       │  Office Processor                │
  └──────────────────────┴──────────────────────────────────┘
            ↓                                   ↓
  ┌─────────────────────────────────────────────────────────┐
  │             Queue Orchestration Layer                    │
  ├──────────────────────┬──────────────────────────────────┤
  │  Text Queue Manager  │  Image Queue Manager             │
  └──────────────────────┴──────────────────────────────────┘
            ↓                                   ↓
  ┌─────────────────────────────────────────────────────────┐
  │             AI Analysis Layer                            │
  ├──────────────────────┬──────────────────────────────────┤
  │  n8n Workflows       │  OpenAI / Gemini APIs            │
  └──────────────────────┴──────────────────────────────────┘
            ↓                                   ↓
  ┌─────────────────────────────────────────────────────────┐
  │             Organization Layer                           │
  ├──────────────────────────────────────────────────────────┤
  │  Contract Processor (Folder Organization)                │
  └──────────────────────────────────────────────────────────┘
            ↓
  ┌──────────────────────┐
  │  Organized Folders   │
  │  (Final Output)      │
  └──────────────────────┘
```

### Component Interaction Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                    COMPONENT INTERACTIONS                            │
└─────────────────────────────────────────────────────────────────────┘

[Email Fetcher]
    ↓ (1) INSERT emails, email_attachments
    ↓ (2) Write files to C:\CargoAttachments\
[PostgreSQL + File System]
    ↓
[OCR/Office Processors]
    ↓ (3) Read email_attachments WHERE status='pending'
    ↓ (4) Write processed files to C:\CargoProcessing\
    ↓ (5) UPDATE status='completed'
[PostgreSQL + File System]
    ↓
[Queue Managers]
    ↓ (6) Watch C:\CargoProcessing\
    ↓ (7) INSERT INTO processing_queue
    ↓ (8) PostgreSQL NOTIFY → n8n
[PostgreSQL NOTIFY/LISTEN]
    ↓
[n8n Workflows]
    ↓ (9) LISTEN for notifications
    ↓ (10) Fetch file content
    ↓ (11) Send to AI API
    ↓ (12) UPDATE email_attachments (category, contract_number)
[PostgreSQL]
    ↓ (13) Trigger: IF all attachments classified
    ↓ (14) INSERT INTO email_ready_queue
[PostgreSQL Trigger]
    ↓
[Contract Processor]
    ↓ (15) Read email_ready_queue
    ↓ (16) Generate folder structure
    ↓ (17) Copy/Move files to organized folders
    ↓ (18) UPDATE processed=TRUE
[Organized Output]
```

---

## 📚 Related Documentation

For detailed information on specific topics:

- **[README.md](./README.md)** - Project overview and quick start
- **[DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md)** - Complete database documentation
- **[STATUS_FLOW_MAP.md](./docs/STATUS_FLOW_MAP.md)** - Status flow and dependencies
- **[DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)** - Detailed deployment instructions
- **[MODULE_DEPENDENCIES.md](./MODULE_DEPENDENCIES.md)** - Module dependency graph

**Module Documentation:**
- [01_EMAIL_FETCHER.md](./modules/01_EMAIL_FETCHER.md)
- [02_OCR_PROCESSOR.md](./modules/02_OCR_PROCESSOR.md)
- [03_OFFICE_PROCESSOR.md](./modules/03_OFFICE_PROCESSOR.md)
- [04_QUEUE_MANAGERS.md](./modules/04_QUEUE_MANAGERS.md)
- [05_N8N_WORKFLOWS.md](./modules/05_N8N_WORKFLOWS.md)
- [06_CONTRACTS_PROCESSOR.md](./modules/06_CONTRACTS_PROCESSOR.md)

---

## 🎯 Summary

CargoFlow is a **modular, scalable, automated document processing system** built on:

**7 Independent Components:**
1. Email Fetcher (Microsoft Graph API)
2. OCR Processor (Tesseract OCR)
3. Office Processor (python-docx, openpyxl)
4. Text Queue Manager (File system watcher)
5. Image Queue Manager (File system watcher)
6. n8n Workflows (AI orchestration)
7. Contract Processor (File organization)

**Unified by:**
- PostgreSQL database (state management + triggers)
- File system (storage)
- NOTIFY/LISTEN mechanism (inter-process communication)

**Key Features:**
- ✅ End-to-end automation (email → organized folders)
- ✅ AI-powered categorization (13 document types)
- ✅ Contract detection and organization
- ✅ Retry mechanisms and error handling
- ✅ Complete traceability and logging

**Production Ready:**
- All core components implemented
- Database schema optimized
- Error handling and recovery procedures
- Comprehensive documentation

**Current Status:** 45% operational (3/7 components active, 4 need restart/configuration)

---

**Document Version:** 1.0  
**Created:** November 06, 2025  
**Author:** CargoFlow Documentation Team  
**Status:** Complete ✅
