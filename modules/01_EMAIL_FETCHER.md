# Email Fetcher Module - Microsoft Graph API Integration

**Module:** Cargoflow_mail  
**Script:** `graph_email_extractor_v5.py`  
**Status:** ✅ Production Ready  
**Last Updated:** November 06, 2025

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Architecture & Data Flow](#architecture--data-flow)
3. [Configuration](#configuration)
4. [Key Components](#key-components)
5. [Database Integration](#database-integration)
6. [Status Management & Database State](#status-management--database-state)
7. [File Storage Structure](#file-storage-structure)
8. [Error Handling & Resilience](#error-handling--resilience)
9. [Logging & Monitoring](#logging--monitoring)
10. [Usage & Deployment](#usage--deployment)
11. [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

### Purpose

The Email Fetcher module is the **first component** in the CargoFlow system. It connects to Microsoft 365 via Microsoft Graph API to:

1. **Extract emails** from a specified user mailbox
2. **Download attachments** to structured folders
3. **Store metadata** in PostgreSQL database
4. **Enable incremental processing** (only fetch new emails)
5. **Run continuously** with configurable check intervals

### Key Features

- ✅ **Microsoft Graph API Integration** using MSAL authentication
- ✅ **Incremental Email Fetching** (only new emails since last run)
- ✅ **Smart Attachment Filtering** (skips logos, signatures, tiny images)
- ✅ **Structured File Storage** (organized by sender/date/subject)
- ✅ **PostgreSQL Integration** (emails + email_attachments tables)
- ✅ **Connection Health Checks** with automatic reconnection
- ✅ **Continuous Monitoring Mode** (daemon-like operation)
- ✅ **Retry Logic** for database and API failures
- ✅ **Rotating Logs** (max 10MB per file, keeps 5 backups)

---

## 🏗️ Architecture & Data Flow

### High-Level Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    EMAIL FETCHER MODULE                         │
└─────────────────────────────────────────────────────────────────┘

[1] Microsoft Graph API Authentication (MSAL)
    ↓
[2] Get Access Token (OAuth 2.0)
    ↓
[3] Fetch Latest Emails (top 100, ordered by receivedDateTime DESC)
    ↓
[4] Check Last Processed Email ID from Database
    ↓
[5] Filter Only New Emails (incremental)
    ↓
[6] For Each Email:
    ├─ Extract Metadata (subject, sender, recipients, timestamps)
    ├─ Download Attachments (via Graph API)
    ├─ Apply Smart Filtering (skip tiny logos/signatures)
    ├─ Save Files to Disk (structured folders)
    └─ Insert into PostgreSQL (emails + email_attachments)
    ↓
[7] Wait N Minutes (configurable interval)
    ↓
[8] Repeat from [3]
```

### Component Interaction

```
┌──────────────────┐       ┌──────────────────┐       ┌──────────────────┐
│  Microsoft 365   │◄─────►│  Email Fetcher   │◄─────►│   PostgreSQL     │
│  (Graph API)     │       │  (Python Script) │       │   (Cargo_mail)   │
└──────────────────┘       └──────────────────┘       └──────────────────┘
         │                          │                           │
         │                          ↓                           │
         │              ┌──────────────────┐                   │
         └──────────────┤  File System     │───────────────────┘
                        │  (C:\CargoAttachments\)             
                        └──────────────────┘
```

---

## ⚙️ Configuration

### Configuration File: `graph_config.json`

**Location:** `C:\Python_project\CargoFlow\Cargoflow_mail\graph_config.json`

**Structure:**

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
  "paths": {
    "attachments_base": "C:/CargoAttachments"
  },
  "monitoring": {
    "check_interval_minutes": 3
  }
}
```

### Configuration Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `client_id` | string | Yes | Azure AD Application (client) ID |
| `client_secret` | string | Yes | Azure AD client secret |
| `tenant_id` | string | Yes | Azure AD tenant ID |
| `user_email` | string | Yes | Microsoft 365 user email to monitor |
| `database.host` | string | Yes | PostgreSQL server hostname |
| `database.database` | string | Yes | Database name (Cargo_mail) |
| `database.user` | string | Yes | Database username |
| `database.password` | string | Yes | Database password |
| `database.port` | integer | No | Database port (default: 5432) |
| `paths.attachments_base` | string | No | Base path for attachments (default: C:/CargoAttachments) |
| `monitoring.check_interval_minutes` | integer | No | Minutes between checks (default: 3) |

### Setting Up Azure AD Application

**Prerequisites:**
1. Azure AD tenant
2. Microsoft 365 subscription
3. Admin consent for Microsoft Graph API permissions

**Required Microsoft Graph API Permissions:**
- `Mail.Read` - Read user mail
- `Mail.ReadWrite` - Read and write user mail
- `User.Read.All` - Read all users' basic profiles

**Setup Steps:**
1. Go to Azure Portal → Azure Active Directory → App registrations
2. Create new registration
3. Copy `client_id`, `tenant_id`
4. Create client secret, copy `client_secret`
5. Add API permissions (Microsoft Graph)
6. Grant admin consent

---

## 🔧 Key Components

### Class: `GraphEmailExtractor`

Main class that handles all email extraction operations.

#### Constructor: `__init__(config_file, base_path)`

```python
def __init__(self, config_file="graph_config.json", base_path=None):
    self.config = self.load_config(config_file)
    self.base_path = Path(base_path or self.config.get('paths', {}).get('attachments_base', 'C:/CargoAttachments'))
    self.conn = None
    self.access_token = None
    self.user_email = self.config.get('user_email', None)
    self.check_interval = self.config.get('monitoring', {}).get('check_interval_minutes', 3)
    self.max_reconnect_attempts = 5
    self.reconnect_delay = 10  # seconds
```

**Parameters:**
- `config_file` - Path to JSON configuration file
- `base_path` - Base directory for attachments (optional, uses config if not provided)

---

### Core Functions

#### 1. `get_access_token()`

**Purpose:** Authenticates with Microsoft Graph API using MSAL (Microsoft Authentication Library).

**Method:** OAuth 2.0 Client Credentials Flow

**Returns:** `True` if successful, `False` otherwise

**Code Flow:**
```python
authority = f"https://login.microsoftonline.com/{tenant_id}"
app = ConfidentialClientApplication(client_id, authority, client_credential)
result = app.acquire_token_for_client(scopes=["https://graph.microsoft.com/.default"])
```

**Error Handling:**
- Logs authentication errors
- Returns False on failure
- System cannot proceed without valid token

---

#### 2. `get_emails(user_email, top=100)`

**Purpose:** Fetches emails from Microsoft Graph API.

**Graph API Endpoint:**
```
GET https://graph.microsoft.com/v1.0/users/{user_email}/messages
```

**Query Parameters:**
- `$top=100` - Limit to 100 emails
- `$orderby=receivedDateTime DESC` - Newest first
- `$select=id,subject,from,toRecipients,receivedDateTime,sentDateTime,body,hasAttachments,importance,internetMessageId`

**Returns:** List of email objects (JSON)

**Rate Limiting:** Handled by Microsoft Graph (automatic throttling)

---

#### 3. `get_last_processed_email_id()`

**Purpose:** Determines the last processed email to enable incremental fetching.

**Query:**
```sql
SELECT entry_id 
FROM emails 
ORDER BY received_time DESC 
LIMIT 1
```

**Returns:** 
- `entry_id` (string) - Last processed email ID
- `None` - If no emails in database (bootstrap mode)

**Usage:** Prevents re-processing of already handled emails.

---

#### 4. `get_attachments(user_email, message_id)`

**Purpose:** Downloads attachment metadata for a specific email.

**Graph API Endpoint:**
```
GET https://graph.microsoft.com/v1.0/users/{user_email}/messages/{message_id}/attachments
```

**Returns:** List of attachment objects with:
- `name` - Filename
- `contentBytes` - Base64-encoded content
- `size` - File size in bytes
- `contentType` - MIME type

---

#### 5. `should_save_attachment(attachment_name, attachment_size)`

**Purpose:** Intelligent filtering to skip embedded logos, signatures, and tiny images.

**Filtering Rules:**

| Rule | Condition | Action |
|------|-----------|--------|
| Non-images | `.pdf`, `.docx`, `.xlsx`, etc. | ✅ Always save |
| Very small images | Size < 10 KB | ❌ Skip (likely logo) |
| Standard names | `image001`, `logo`, `signature`, `banner`, `icon` | ❌ Skip |
| PNG screenshots | Name contains `screenshot`, `screen`, `capture`, `snap` | ✅ Save |
| Large PNGs | Size > 100 KB | ✅ Save (likely document) |
| Other images | Default | ✅ Save |

**Examples:**
```python
should_save_attachment("logo.png", 5120)          # False - tiny logo
should_save_attachment("image001.jpg", 8192)      # False - embedded image
should_save_attachment("screenshot_2025.png", 256000)  # True - screenshot
should_save_attachment("document.pdf", 102400)    # True - non-image
```

---

#### 6. `save_attachments(user_email, message_id, email_data)`

**Purpose:** Downloads and saves attachments to disk with structured folder organization.

**Folder Structure:**
```
C:\CargoAttachments\
└── {sender_email}\
    └── {YYYY-MM}\
        └── {subject}_{YYYYMMDD_HHMMSS}\
            ├── email_metadata.json
            ├── email_body.html (or .txt)
            ├── attachment1.pdf
            ├── attachment2.docx
            └── screenshot.png
```

**Files Created:**
1. `email_metadata.json` - Complete email JSON data
2. `email_body.html` or `email_body.txt` - Email body content
3. One file per attachment (original names, cleaned)

**Filename Cleaning:**
- Removes invalid characters: `<>:"/\|?*`
- Truncates to 100 characters
- Preserves file extension

**Returns:** 
- `attachment_folder` (str) - Path to created folder
- `saved_files` (list) - List of saved file paths

---

#### 7. `process_email(user_email, email_data, folder_name)`

**Purpose:** Processes a single email and inserts it into PostgreSQL database.

**Database Tables Updated:**
1. **`emails`** - Email metadata
2. **`email_attachments`** - Individual attachment records

**SQL Operations:**

**Insert Email:**
```sql
INSERT INTO emails (
    subject, sender_name, sender_email, recipients,
    received_time, sent_time, body_text, body_html,
    has_attachments, attachment_count, attachment_folder,
    attachment_paths, importance, entry_id, folder_name
) VALUES (...)
ON CONFLICT (entry_id) DO UPDATE SET
    attachment_folder = EXCLUDED.attachment_folder,
    attachment_paths = EXCLUDED.attachment_paths,
    attachment_count = EXCLUDED.attachment_count
```

**Insert Attachments:**
```sql
INSERT INTO email_attachments (
    email_id, attachment_name, attachment_path, attachment_type
) VALUES (...)
ON CONFLICT DO NOTHING
```

**Conflict Handling:**
- `entry_id` is UNIQUE - prevents duplicate emails
- Updates attachment info if email already exists
- `ON CONFLICT DO NOTHING` for attachments (idempotent)

**Returns:** `True` if successful, `False` on error

---

#### 8. `extract_all_emails()`

**Purpose:** Main orchestration function that extracts all new emails.

**Process:**
1. Get access token
2. Get user email
3. Fetch last processed email ID
4. Fetch latest 100 emails from Graph API
5. Filter to only new emails (incremental)
6. Process each email (download + save)
7. Log statistics

**Incremental Logic:**
```python
if last_entry_id:
    new_emails = []
    for email in emails:
        current_entry_id = email.get('internetMessageId')
        if current_entry_id == last_entry_id:
            break  # Stop at last processed email
        new_emails.append(email)
```

**Returns:** `True` if successful, `False` on error

---

#### 9. `run_continuous()`

**Purpose:** Continuous monitoring mode - runs indefinitely with periodic checks.

**Behavior:**
```
[START] → Check for new emails → Process → Wait N minutes → [REPEAT]
```

**Configuration:**
- Check interval: `monitoring.check_interval_minutes` (default: 3 minutes)

**Loop Structure:**
```python
while True:
    try:
        extract_all_emails()
    except Exception as e:
        logger.error(f"Error: {e}")
        time.sleep(300)  # Wait 5 minutes on error
        continue
    
    time.sleep(check_interval * 60)  # Wait N minutes
```

**Graceful Shutdown:**
- Catches `KeyboardInterrupt` (Ctrl+C)
- Logs total checks performed
- Closes database connections

---

### Database Connection Management

#### `connect_to_database(retry_attempt=0)`

**Purpose:** Establishes PostgreSQL connection with retry logic and keep-alive settings.

**Keep-Alive Configuration:**
```python
psycopg2.connect(
    host=..., database=..., user=..., password=...,
    connect_timeout=10,       # 10 seconds timeout
    keepalives_idle=600,      # 10 minutes idle before keep-alive
    keepalives_interval=30,   # 30 seconds between keep-alive packets
    keepalives_count=3        # 3 failed keep-alives before disconnect
)
```

**Retry Logic:**
- Max attempts: 5
- Delay: 10 seconds × retry_attempt (10s, 20s, 30s, 40s, 50s)
- Exponential backoff

**Returns:** `True` if connected, `False` after max attempts

---

#### `ensure_db_connection()`

**Purpose:** Health check and automatic reconnection.

**Process:**
1. Check if connection is `None` or `closed`
2. If closed → reconnect
3. Execute test query: `SELECT 1`
4. If test fails → reconnect

**Usage:** Called before every database operation to ensure valid connection.

**Returns:** `True` if connection is healthy, `False` otherwise

---

## 🗄️ Database Integration

### Tables Updated

#### 1. `emails` Table

**Primary Key:** `id` (auto-increment)  
**Unique Key:** `entry_id` (Microsoft internetMessageId)

**Key Columns:**

| Column | Type | Description |
|--------|------|-------------|
| `subject` | text | Email subject line |
| `sender_name` | varchar | Sender's display name |
| `sender_email` | varchar | Sender's email address |
| `recipients` | text | To: recipients (semicolon-separated) |
| `received_time` | timestamp | When email was received |
| `sent_time` | timestamp | When email was sent |
| `body_text` | text | Plain text body |
| `body_html` | text | HTML body |
| `has_attachments` | boolean | Has attachments? |
| `attachment_count` | integer | Number of attachments |
| `attachment_folder` | text | Folder path on disk |
| `attachment_paths` | jsonb | JSON array of file paths |
| `entry_id` | varchar | Unique message ID (UNIQUE) |
| `folder_name` | varchar | Mailbox folder (e.g., "Inbox") |

**Indexes:**
- Primary key on `id`
- Unique index on `entry_id`
- Index on `sender_email`
- Index on `received_time`

---

#### 2. `email_attachments` Table

**Primary Key:** `id` (auto-increment)  
**Foreign Key:** `email_id` → `emails(id)`

**Key Columns:**

| Column | Type | Description |
|--------|------|-------------|
| `email_id` | integer | Foreign key to emails |
| `attachment_name` | varchar | Original filename |
| `attachment_path` | text | Full file path on disk |
| `attachment_type` | varchar | File extension (e.g., "pdf") |
| `created_at` | timestamp | Record creation time |
| `document_category` | varchar | AI-assigned category (populated later) |
| `confidence_score` | numeric | AI confidence (0.0-1.0) |
| `processing_status` | varchar | 'pending', 'completed', 'failed' |
| `contract_number` | varchar | Extracted contract number (populated later) |

**Initial State After Email Fetcher:**
- `document_category` = `NULL` (awaits AI processing)
- `processing_status` = `'pending'` (awaits OCR/Office processing)
- `contract_number` = `NULL` (awaits AI extraction)

**Indexes:**
- Primary key on `id`
- Foreign key on `email_id`
- Index on `processing_status`

---

## 📊 Status Management & Database State

### Overview

The Email Fetcher module is the **entry point** of the CargoFlow system. It sets the **initial state** for all records in the database. Understanding what statuses this module creates is critical for tracking data flow through the entire system.

### Status Lifecycle Created by Email Fetcher

```
┌─────────────────────────────────────────────────────────────────────┐
│              EMAIL FETCHER - INITIAL STATE CREATION                 │
└─────────────────────────────────────────────────────────────────────┘

[Microsoft Graph API]
    ↓
[Email Fetcher Module]
    ↓
┌─────────────────────────────────────────────────────────────────────┐
│                       DATABASE RECORDS CREATED                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  📧 emails Table                                                    │
│  ├─ subject: "Invoice October 2025"                                │
│  ├─ sender_email: "supplier@company.com"                           │
│  ├─ received_time: 2025-11-06 14:30:22                             │
│  ├─ has_attachments: TRUE                                           │
│  ├─ attachment_count: 3                                             │
│  ├─ attachment_folder: "C:\CargoAttachments\supplier@..."          │
│  └─ entry_id: "<unique_message_id>" (UNIQUE KEY)                   │
│                                                                     │
│  📎 email_attachments Table (3 records)                            │
│  ├─ Record 1:                                                       │
│  │   ├─ email_id: 1723 (FK to emails)                              │
│  │   ├─ attachment_name: "invoice.pdf"                             │
│  │   ├─ attachment_path: "C:\CargoAttachments\...\invoice.pdf"    │
│  │   ├─ attachment_type: "pdf"                                     │
│  │   ├─ processing_status: "pending" ← INITIAL STATE               │
│  │   ├─ document_category: NULL ← AWAITS AI                        │
│  │   ├─ contract_number: NULL ← AWAITS AI                          │
│  │   └─ created_at: 2025-11-06 14:30:23                            │
│  │                                                                  │
│  ├─ Record 2: (similar structure)                                  │
│  └─ Record 3: (similar structure)                                  │
└─────────────────────────────────────────────────────────────────────┘
    ↓
[Files saved to C:\CargoAttachments\...]
    ↓
[NEXT MODULE: OCR Processor / Office Processor]
```

---

### Tables & Columns Modified

#### 1. `emails` Table

**Operation:** INSERT (or UPDATE on conflict)

| Column | Initial Value | Notes |
|--------|---------------|-------|
| `subject` | Email subject | From Graph API |
| `sender_email` | Sender address | From Graph API |
| `received_time` | Email timestamp | From Graph API |
| `has_attachments` | TRUE/FALSE | From Graph API |
| `attachment_count` | Number of files saved | After filtering |
| `attachment_folder` | Full folder path | Created by module |
| `attachment_paths` | JSON array of paths | All saved files |
| `entry_id` | Unique message ID | UNIQUE constraint |
| **Status Fields** | | |
| `analysis_status` | NULL | ❌ NOT set by Email Fetcher |
| `classification_status` | NULL | ❌ NOT set by Email Fetcher |
| `contract_folder_name` | NULL | ❌ Set by Contract Processor later |

**Key Points:**
- Email Fetcher does NOT set any status fields in `emails` table
- Only metadata and file paths are populated
- Status fields remain `NULL` until later modules process them

---

#### 2. `email_attachments` Table

**Operation:** INSERT (one record per saved file)

| Column | Initial Value | Module Responsible | Notes |
|--------|---------------|-------------------|-------|
| `email_id` | emails.id (FK) | Email Fetcher | Links to parent email |
| `attachment_name` | Original filename | Email Fetcher | Cleaned filename |
| `attachment_path` | Full file path | Email Fetcher | On disk location |
| `attachment_type` | File extension | Email Fetcher | "pdf", "docx", etc. |
| `attachment_size` | File size (bytes) | Email Fetcher | From Graph API |
| `created_at` | NOW() | Email Fetcher | Record creation time |
| **Status Column** | | | |
| `processing_status` | **"pending"** | ✅ Email Fetcher | **INITIAL STATE** |
| **AI Analysis Fields** | | | |
| `document_category` | NULL | ❌ n8n Workflow | Awaits AI categorization |
| `confidence_score` | NULL | ❌ n8n Workflow | Awaits AI analysis |
| `contract_number` | NULL | ❌ n8n Workflow | Awaits AI extraction |
| `classification_timestamp` | NULL | ❌ n8n Workflow | Awaits AI processing |
| `extracted_data` | NULL | ❌ n8n Workflow | Awaits AI extraction |
| `processed_at` | NULL | ❌ OCR/Office Processor | Awaits file processing |

**Critical Initial State:**
```sql
processing_status = 'pending'
```

This is the **trigger** for the next module (OCR/Office Processor) to pick up the file for processing.

---

### Status Values & Meanings

#### `email_attachments.processing_status`

| Status | Set By | Meaning | Next Step |
|--------|--------|---------|----------|
| **`pending`** | ✅ **Email Fetcher** | File saved to disk, awaiting processing | OCR/Office Processor picks it up |
| `processing` | OCR/Office Processor | Currently extracting text/images | Wait for completion |
| `completed` | OCR/Office Processor | Text extraction done | Queue Manager adds to processing_queue |
| `queued` | Queue Manager | Added to AI processing queue | n8n webhook triggered |
| `classified` | n8n Workflow | AI categorization completed | Trigger checks if all attachments done |
| `group_ready` | PostgreSQL Trigger | All email attachments classified | Contract Processor organizes |
| `organized` | Contract Processor | Files moved to organized folders | ✅ Final state |
| `failed` | Any module | Processing error occurred | Retry or manual intervention |

**Email Fetcher's Role:** Sets ONLY `pending` status

---

### Module Dependency Chain

```
┌──────────────────┐
│ Email Fetcher    │ ← YOU ARE HERE
│ (Module 1)       │
└──────────────────┘
         │
         │ Creates:
         │ - emails table record
         │ - email_attachments records (processing_status = 'pending')
         │ - Files on disk (C:\CargoAttachments\)
         │
         ↓
┌──────────────────┐
│ OCR Processor    │ ← Next Module (Module 2)
│ Office Processor │
└──────────────────┘
         │
         │ Looks for:
         │ - SELECT * FROM email_attachments WHERE processing_status = 'pending'
         │
         │ Updates:
         │ - processing_status = 'processing' → 'completed'
         │ - Creates text files in C:\CargoProcessing\
         │
         ↓
┌──────────────────┐
│ Queue Managers   │ ← Module 4 & 5
└──────────────────┘
         │
         │ Watches:
         │ - C:\CargoProcessing\ for new files
         │
         │ Updates:
         │ - INSERT INTO processing_queue (status = 'pending')
         │ - Triggers PostgreSQL NOTIFY → n8n
         │
         ↓
┌──────────────────┐
│ n8n Workflows    │ ← Module 6
└──────────────────┘
         │
         │ Updates:
         │ - document_category = 'invoice'/'cmr'/etc.
         │ - contract_number = '50251006834'
         │ - processing_status = 'classified'
         │
         ↓
┌──────────────────┐
│Contract Processor│ ← Module 7
└──────────────────┘
         │
         │ Final state:
         │ - processing_status = 'organized'
         │ - Files moved to organized folders
         │
         ↓
    [COMPLETE ✅]
```

---

### What Email Fetcher Does NOT Do

**Email Fetcher does NOT:**

❌ **Extract text from PDFs** - That's OCR Processor's job  
❌ **Process Office documents** - That's Office Processor's job  
❌ **Categorize documents** - That's n8n Workflow's job  
❌ **Extract contract numbers** - That's n8n Workflow's job  
❌ **Organize files by contract** - That's Contract Processor's job  

**Email Fetcher ONLY:**

✅ **Fetches emails** from Microsoft Graph API  
✅ **Downloads attachments** to structured folders  
✅ **Saves metadata** to database  
✅ **Sets initial status** (`processing_status = 'pending'`)  
✅ **Provides files** for next module to process  

---

### Checking Status After Email Fetcher Runs

#### Query 1: Check New Emails

```sql
-- Check emails created in last hour
SELECT 
    id,
    subject,
    sender_email,
    attachment_count,
    created_at
FROM emails
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC;
```

**Expected Result:**
- New emails visible with metadata
- `attachment_count` matches number of saved files

---

#### Query 2: Check Pending Attachments

```sql
-- Check attachments awaiting processing
SELECT 
    id,
    email_id,
    attachment_name,
    attachment_type,
    processing_status,
    created_at
FROM email_attachments
WHERE processing_status = 'pending'
ORDER BY created_at DESC
LIMIT 20;
```

**Expected Result:**
- All new attachments have `processing_status = 'pending'`
- `document_category = NULL`
- `contract_number = NULL`

---

#### Query 3: Verify Files on Disk

```sql
-- Check attachment paths
SELECT 
    attachment_name,
    attachment_path,
    attachment_type
FROM email_attachments
WHERE created_at > NOW() - INTERVAL '1 hour';
```

**Verification:**
```bash
# Windows
dir "C:\CargoAttachments\sender@company.com\2025-11\"

# Linux
ls -la "/mnt/c/CargoAttachments/sender@company.com/2025-11/"
```

**Expected:**
- Folders exist with proper structure
- Files saved with correct names
- `email_metadata.json` and `email_body.html/txt` present

---

### Status Transition Example

**Initial State (after Email Fetcher):**

```sql
SELECT id, attachment_name, processing_status, document_category, contract_number
FROM email_attachments
WHERE id = 1050;
```

**Result:**
```
id   | attachment_name  | processing_status | document_category | contract_number
-----|------------------|-------------------|-------------------|----------------
1050 | invoice_oct.pdf  | pending           | NULL              | NULL
```

**After OCR Processor:**
```
1050 | invoice_oct.pdf  | completed         | NULL              | NULL
```

**After n8n Workflow:**
```
1050 | invoice_oct.pdf  | classified        | invoice           | 50251006834
```

**After Contract Processor:**
```
1050 | invoice_oct.pdf  | organized         | invoice           | 50251006834
```

---

### Troubleshooting Status Issues

#### Issue: Attachments stuck in 'pending'

**Symptoms:**
```sql
SELECT COUNT(*) FROM email_attachments WHERE processing_status = 'pending';
-- Returns: 285 (many pending)
```

**Causes:**
1. OCR/Office Processor not running
2. OCR/Office Processor crashed
3. Files not accessible on disk

**Solution:**
1. Check if processors are running:
   ```bash
   # Windows Task Manager or:
   tasklist | findstr python
   
   # Linux:
   ps aux | grep processor
   ```
2. Check processor logs:
   ```bash
   tail -f document_processing.log
   ```
3. Restart processors if needed

---

#### Issue: No attachments created for email

**Symptoms:**
```sql
SELECT id, subject, attachment_count FROM emails WHERE id = 1723;
-- Result: attachment_count = 0, but email shows attachments in Outlook
```

**Causes:**
1. All attachments filtered out (tiny logos/signatures)
2. File download failed
3. Disk write permission error

**Solution:**
1. Check logs:
   ```bash
   grep "1723" graph_extraction.log | grep "Skipping"
   ```
2. Review filtering rules in `should_save_attachment()`
3. Verify disk space and permissions

---

### Summary: Email Fetcher's Database State

**What Email Fetcher Creates:**

| Table | Records | Status Set | Next Module |
|-------|---------|------------|-------------|
| `emails` | 1 per email | No status fields set | N/A (metadata only) |
| `email_attachments` | 1 per saved file | `processing_status = 'pending'` | OCR/Office Processor |

**Critical Status:**
```sql
processing_status = 'pending'
```

This single status value is the **trigger** that starts the entire processing pipeline. Without it, no other module will pick up the file.

**Next Module Dependency:**
- OCR Processor (for PDFs and images)
- Office Processor (for Word/Excel documents)

Both modules query:
```sql
SELECT * FROM email_attachments 
WHERE processing_status = 'pending' 
AND attachment_type IN ('pdf', 'png', 'jpg', 'docx', 'xlsx', ...)
```

---

## 📁 File Storage Structure

### Base Path: `C:\CargoAttachments\`

### Directory Structure

```
C:\CargoAttachments\
│
├── sender1@example.com\
│   ├── 2025-10\
│   │   ├── Invoice_October_20251015_141023\
│   │   │   ├── email_metadata.json
│   │   │   ├── email_body.html
│   │   │   ├── invoice_oct.pdf
│   │   │   └── attachment.xlsx
│   │   │
│   │   └── Contract_Amendment_20251018_092145\
│   │       ├── email_metadata.json
│   │       ├── email_body.txt
│   │       └── amendment.docx
│   │
│   └── 2025-11\
│       └── Transport_Documents_20251106_153022\
│           ├── email_metadata.json
│           ├── email_body.html
│           └── cmr_document.pdf
│
└── sender2@company.com\
    └── 2025-11\
        └── Reports_November_20251105_100015\
            ├── email_metadata.json
            ├── email_body.txt
            └── monthly_report.xlsx
```

### Naming Conventions

| Level | Pattern | Example |
|-------|---------|---------|
| Sender | `{sender_email}` | `pa@cargo-flow.fr` |
| Month | `YYYY-MM` | `2025-11` |
| Email Folder | `{subject}_{YYYYMMDD_HHMMSS}` | `Invoice_October_20251015_141023` |
| Metadata | `email_metadata.json` | Fixed name |
| Body | `email_body.html` or `email_body.txt` | Based on content type |
| Attachments | Original filename (cleaned) | `invoice_oct.pdf` |

### File Cleaning Rules

**Invalid Characters Replaced with `_`:**
```
< > : " / \ | ? *
```

**Maximum Length:** 100 characters (truncated if longer)

**Examples:**
```python
"Invoice: October 2025.pdf"  →  "Invoice_ October 2025.pdf"
"Contract #12345/2025.docx"  →  "Contract #12345_2025.docx"
"Very Long Filename That Exceeds One Hundred Characters..."  →  "Very Long Filename That Exceeds One Hundred Chara..."
```

---

## 🛡️ Error Handling & Resilience

### Connection Retry Logic

**Database Connection:**
- Max attempts: 5
- Exponential backoff: 10s, 20s, 30s, 40s, 50s
- Total max wait: 150 seconds (2.5 minutes)

**Graph API Token:**
- Retries handled by MSAL library
- Automatic token refresh on expiration

### Error Recovery Strategies

| Error Type | Detection | Recovery |
|------------|-----------|----------|
| Database connection lost | `conn.closed == True` | Call `connect_to_database()` |
| Database query timeout | `psycopg2.OperationalError` | Reconnect and retry |
| Graph API rate limit | HTTP 429 | Automatic throttling by Microsoft |
| Graph API auth failure | HTTP 401 | Re-authenticate with MSAL |
| File write error | `IOError`, `OSError` | Log error, continue with next file |
| Attachment download error | Exception in `save_attachments()` | Log error, continue with next email |

### Transactional Safety

**Database Operations:**
```python
try:
    cursor.execute(...)
    self.conn.commit()
except Exception as e:
    self.conn.rollback()
    logger.error(f"Error: {e}")
```

**Idempotency:**
- `ON CONFLICT (entry_id) DO UPDATE` - Safe to re-run
- Duplicate emails update attachment info only
- Duplicate attachments ignored (`ON CONFLICT DO NOTHING`)

---

## 📊 Logging & Monitoring

### Log Configuration

**Log File:** `graph_extraction.log`  
**Rotation:** 10 MB per file, keeps 5 backups  
**Encoding:** UTF-8  
**Format:** `%(asctime)s - %(levelname)s - %(message)s`

**Log Levels:**
- `INFO` - Normal operations
- `WARNING` - Recoverable issues
- `ERROR` - Errors requiring attention

### Output Destinations

1. **File:** `graph_extraction.log` (rotating)
2. **Console:** `stdout` (real-time monitoring)

### Key Log Messages

**Startup:**
```
GRAPH EMAIL EXTRACTOR - CONTINUOUS MODE
Потребител: pa@cargo-flow.fr
Проверка: на всеки 3 минути
База данни: Cargo_mail
```

**Authentication:**
```
✅ Успешно получен access token
✅ Успешна връзка към базата данни
```

**Email Processing:**
```
Намерени 15 мейла от API
От тях 5 са нови (след последния обработен)
Обработва мейл 1/5: Invoice October 2025
  Записан файл: invoice_oct.pdf
  Пълен път: C:\CargoAttachments\sender@example.com\2025-10\...
```

**Statistics:**
```
Записани 5 от 5 мейла
Мейли с файлове: 3
```

**Errors:**
```
❌ Грешка при свързване към базата данни: connection refused
⏳ Опит 1/5 за повторно свързване след 10s...
```

**Continuous Mode:**
```
ПРОВЕРКА #42 - 2025-11-06 15:30:22
Проверка завършена
Следваща проверка в 15:33:22
Изчакване 3 минути...
```

### Monitoring Queries

**Check Last Run:**
```sql
SELECT MAX(received_time) as last_email, MAX(created_at) as last_processed
FROM emails;
```

**Emails Fetched Today:**
```sql
SELECT COUNT(*) as emails_today
FROM emails
WHERE received_time >= CURRENT_DATE;
```

**Attachments by Type:**
```sql
SELECT attachment_type, COUNT(*) as count
FROM email_attachments
GROUP BY attachment_type
ORDER BY count DESC;
```

---

## 🚀 Usage & Deployment

### Installation

**Prerequisites:**
- Python 3.11+
- PostgreSQL 17
- Azure AD application configured

**Steps:**

```bash
# 1. Navigate to module directory
cd C:\Python_project\CargoFlow\Cargoflow_mail

# 2. Create virtual environment
python -m venv venv

# 3. Activate virtual environment
venv\Scripts\activate  # Windows
# source venv/bin/activate  # Linux/Mac

# 4. Install dependencies
pip install -r requirements.txt

# 5. Configure graph_config.json
# Edit with your Azure AD credentials and database settings

# 6. Test connection
python -c "from graph_email_extractor_v5 import GraphEmailExtractor; e = GraphEmailExtractor(); e.connect_to_database()"
```

### Running the Module

#### One-Time Execution

**Use Case:** Manual fetch or testing

```bash
cd C:\Python_project\CargoFlow\Cargoflow_mail
venv\Scripts\activate
python graph_email_extractor_v5.py --once
```

**Behavior:**
- Fetches new emails once
- Processes all new emails
- Exits after completion

---

#### Continuous Mode (Recommended)

**Use Case:** Production deployment

```bash
cd C:\Python_project\CargoFlow\Cargoflow_mail
venv\Scripts\activate
python graph_email_extractor_v5.py
```

**Behavior:**
- Runs indefinitely
- Checks for new emails every N minutes (configured)
- Logs each check with statistics
- Graceful shutdown with Ctrl+C

**Screen/tmux Recommended (Linux):**
```bash
screen -S email_fetcher
python graph_email_extractor_v5.py
# Detach with Ctrl+A, D
```

**Windows Service (Optional):**
Use NSSM (Non-Sucking Service Manager) to run as Windows service.

---

### Dependencies

**requirements.txt:**
```
requests>=2.31.0
psycopg2-binary>=2.9.9
msal>=1.24.0
pathlib>=1.0.1
```

**Install:**
```bash
pip install -r requirements.txt
```

---

## 🔧 Troubleshooting

### Common Issues

#### Issue 1: Authentication Failed

**Symptoms:**
```
❌ Грешка при получаване на token: invalid_client
```

**Causes:**
- Incorrect `client_id`, `client_secret`, or `tenant_id`
- Azure AD app not configured correctly
- Missing API permissions

**Solutions:**
1. Verify Azure AD credentials in `graph_config.json`
2. Check Azure Portal → App registrations → API permissions
3. Ensure admin consent granted
4. Regenerate client secret if expired

---

#### Issue 2: Database Connection Failed

**Symptoms:**
```
❌ Грешка при свързване към базата данни: connection refused
```

**Causes:**
- PostgreSQL not running
- Incorrect database credentials
- Firewall blocking connection

**Solutions:**
1. Check PostgreSQL status: `pg_ctl status`
2. Verify credentials in `graph_config.json`
3. Test connection: `psql -U postgres -d Cargo_mail`
4. Check firewall rules

---

#### Issue 3: No New Emails Fetched

**Symptoms:**
```
Намерени 50 мейла от API
От тях 0 са нови (след последния обработен)
```

**Causes:**
- All emails already processed
- `entry_id` matching issue

**Solutions:**
1. Check last processed email:
   ```sql
   SELECT entry_id, received_time FROM emails ORDER BY received_time DESC LIMIT 1;
   ```
2. Verify Graph API returns newer emails
3. Clear database and re-run (bootstrap mode)

---

#### Issue 4: Attachments Not Saved

**Symptoms:**
```
Обработва мейл 1/5: Test Email
Записани 0 от 5 мейла
```

**Causes:**
- All attachments filtered out (tiny logos)
- Disk space full
- File write permission denied

**Solutions:**
1. Check disk space: `df -h` (Linux) or Properties (Windows)
2. Check folder permissions: `C:\CargoAttachments\`
3. Review filtering logic in `should_save_attachment()`
4. Check logs for specific file errors

---

#### Issue 5: Memory Leak (Long-Running)

**Symptoms:**
- Process memory usage grows over time
- System becomes slow after days of running

**Causes:**
- Unclosed database cursors
- Large email bodies kept in memory

**Solutions:**
1. Restart process periodically (daily cron job)
2. Monitor memory: `psutil` library
3. Add memory logging to detect leaks

---

### Debug Mode

**Enable Debug Logging:**

Edit `graph_email_extractor_v5.py`:
```python
logging.basicConfig(
    level=logging.DEBUG,  # Change from INFO to DEBUG
    ...
)
```

**Output:**
- Detailed HTTP requests/responses
- Database queries logged
- Attachment filtering decisions

---

### Health Check Commands

**1. Check Last Email:**
```sql
SELECT id, subject, sender_email, received_time, attachment_count
FROM emails
ORDER BY received_time DESC
LIMIT 5;
```

**2. Check Attachments Today:**
```sql
SELECT COUNT(*) as attachments_today
FROM email_attachments
WHERE created_at >= CURRENT_DATE;
```

**3. Check Processing Status:**
```sql
SELECT processing_status, COUNT(*) as count
FROM email_attachments
GROUP BY processing_status;
```

**4. Check Senders:**
```sql
SELECT sender_email, COUNT(*) as email_count
FROM emails
GROUP BY sender_email
ORDER BY email_count DESC
LIMIT 10;
```

---

## 📞 Support & Maintenance

### Regular Maintenance

**Daily:**
- Check logs for errors
- Verify new emails are being fetched
- Monitor disk space

**Weekly:**
- Review attachment filtering (check skipped files)
- Database VACUUM ANALYZE
- Log rotation check

**Monthly:**
- Update dependencies: `pip install --upgrade -r requirements.txt`
- Review Azure AD token expiration
- Archive old logs

### Performance Tuning

**Increase Check Frequency:**
```json
"monitoring": {
  "check_interval_minutes": 1  // Check every minute
}
```

**Fetch More Emails per Check:**
Edit `extract_all_emails()`:
```python
emails = self.get_emails(user_email, top=500)  # Fetch 500 emails
```

**Disable Attachment Filtering:**
Edit `should_save_attachment()`:
```python
return True  # Save all attachments
```

---

## 🔗 Related Documentation

- [Database Schema](../DATABASE_SCHEMA.md) - `emails` and `email_attachments` tables
- [OCR Processor](02_OCR_PROCESSOR.md) - Next step after email fetching
- [Office Processor](03_OFFICE_PROCESSOR.md) - Processing Office documents
- [System Architecture](../SYSTEM_ARCHITECTURE.md) - Overall system design

---

**Module Status:** ✅ Production Ready  
**Last Updated:** November 06, 2025  
**Maintained by:** CargoFlow DevOps Team
