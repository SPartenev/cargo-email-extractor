# CargoFlow - Deployment Guide

**Version:** 1.0  
**Last Updated:** November 06, 2025  
**Estimated Deployment Time:** 2-3 hours

---

## 📋 Table of Contents

1. [Prerequisites & Requirements](#prerequisites--requirements)
2. [Installation Steps](#installation-steps)
3. [Database Setup](#database-setup)
4. [Configuration Files](#configuration-files)
5. [n8n Workflow Import](#n8n-workflow-import)
6. [Component Setup](#component-setup)
7. [First-Time Startup](#first-time-startup)
8. [Post-Deployment Testing](#post-deployment-testing)
9. [Troubleshooting](#troubleshooting)

---

## 🎯 Prerequisites & Requirements

### Hardware Requirements

**Minimum:**
- CPU: 4 cores
- RAM: 8 GB
- Storage: 100 GB free space
- Network: Stable internet connection

**Recommended:**
- CPU: 8+ cores
- RAM: 16 GB
- Storage: 500 GB SSD
- Network: 100 Mbps+ connection

### Software Requirements

| Software | Version | Purpose |
|----------|---------|---------|
| **Windows** | 10/11 or Server 2019+ | Operating System |
| **Python** | 3.11+ | Core runtime |
| **PostgreSQL** | 17+ | Database |
| **Node.js** | 18+ LTS | n8n runtime |
| **npm** | 9+ | Package manager |
| **Git** | Latest | Version control (optional) |
| **Tesseract OCR** | 5.0+ | OCR processing |

### Required Accounts & API Access

1. **Microsoft 365 / Azure AD**
   - Admin access to create App Registration
   - User account for email access
   - Graph API permissions

2. **AI Service (Choose One)**
   - OpenAI API account (GPT-4 recommended)
   - OR Google Cloud account (Gemini Pro)

3. **Database**
   - PostgreSQL admin access
   - Ability to create databases and users

---

## 🚀 Installation Steps

### Step 1: Install Python 3.11+

**Download:**
- Visit: https://www.python.org/downloads/
- Download Python 3.11 or newer

**Installation:**
```bash
# Verify installation
python --version
# Should show: Python 3.11.x

# Verify pip
pip --version
```

**Important:** During installation, check "Add Python to PATH"

---

### Step 2: Install PostgreSQL 17

**Download:**
- Visit: https://www.postgresql.org/download/windows/
- Download PostgreSQL 17 installer

**Installation:**
```
1. Run installer
2. Set password for 'postgres' user (SAVE THIS PASSWORD!)
3. Default port: 5432
4. Install Stack Builder components (optional)
5. Complete installation
```

**Verify:**
```bash
# Open Command Prompt
psql --version
# Should show: psql (PostgreSQL) 17.x
```

---

### Step 3: Install Node.js & npm

**Download:**
- Visit: https://nodejs.org/
- Download LTS version (18.x or newer)

**Installation:**
```bash
# Verify Node.js
node --version
# Should show: v18.x.x or newer

# Verify npm
npm --version
# Should show: 9.x.x or newer
```

---

### Step 4: Install n8n

**Global Installation:**
```bash
npm install -g n8n

# Verify installation
n8n --version
```

**Note:** n8n will be accessible at http://localhost:5678 after starting

---

### Step 5: Install Tesseract OCR

**Download:**
- Visit: https://github.com/UB-Mannheim/tesseract/wiki
- Download Windows installer

**Installation:**
```
1. Run installer
2. Install to: C:\Program Files\Tesseract-OCR\
3. Add to PATH during installation
4. Complete installation
```

**Verify:**
```bash
tesseract --version
# Should show Tesseract version 5.x
```

---

### Step 6: Clone/Download CargoFlow Project

**Option A: Using Git**
```bash
cd C:\Python_project
git clone <repository-url> CargoFlow
cd CargoFlow
```

**Option B: Manual Download**
```
1. Download project ZIP
2. Extract to: C:\Python_project\CargoFlow\
3. Verify folder structure exists
```

**Verify Structure:**
```
C:\Python_project\CargoFlow\
├── Cargoflow_mail\
├── Cargoflow_OCR\
├── Cargoflow_Office\
├── Cargoflow_Queue\
├── Cargoflow_Contracts\
├── Cargoflow_n8n\
└── Documentation\
```

---

## 🗄️ Database Setup

### Step 1: Create Database

**Connect to PostgreSQL:**
```bash
# Open Command Prompt as Administrator
psql -U postgres
```

**Create Database:**
```sql
-- Create database
CREATE DATABASE Cargo_mail
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'English_United States.1252'
    LC_CTYPE = 'English_United States.1252'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

-- Connect to database
\c Cargo_mail

-- Verify connection
SELECT current_database();
```

---

### Step 2: Create Database Schema

**Navigate to Schema Files:**
```bash
cd C:\Python_project\CargoFlow\Documentation\database\schema\
```

**Execute Schema Creation (in order):**

```sql
-- 1. Core Tables (execute in this order)
\i 01_emails.sql
\i 02_email_attachments.sql
\i 03_processing_queue.sql
\i 04_processing_history.sql
\i 05_document_pages.sql
\i 06_contracts.sql
\i 07_contract_detection_queue.sql
\i 08_email_ready_queue.sql
\i 09_contract_folder_seq.sql
\i 10_invoice_base.sql
\i 11_invoice_items.sql

-- 2. Support Tables
\i 12_email_keywords.sql
\i 13_classification_log.sql
\i 14_sender_statistics.sql
\i 15_system_config.sql
\i 16_error_log.sql
\i 17_file_checksums.sql
\i 18_duplicate_tracking.sql
\i 19_webhook_log.sql
```

**Alternative: Single Script Execution**

If schema files are consolidated:
```bash
cd C:\Python_project\CargoFlow\Documentation\database\
psql -U postgres -d Cargo_mail -f full_schema.sql
```

---

### Step 3: Create Functions

**Navigate to Functions Directory:**
```bash
cd C:\Python_project\CargoFlow\Documentation\database\functions\
```

**Execute Function Creation:**
```sql
-- Execute each function file
\i notify_n8n_text_queue.sql
\i notify_n8n_image_queue.sql
\i queue_email_for_folder_update.sql
\i queue_contract_detection.sql
\i match_attachment_on_queue_insert.sql
\i update_queue_attachment_id.sql
\i get_next_folder_index.sql
\i calculate_contract_key.sql
-- ... (all 13 function files)
```

---

### Step 4: Create Triggers

**Navigate to Triggers Directory:**
```bash
cd C:\Python_project\CargoFlow\Documentation\database\triggers\
```

**Execute Trigger Creation:**
```sql
-- Execute each trigger file
\i trigger_notify_text.sql
\i trigger_notify_image.sql
\i trigger_queue_email.sql
\i contract_detection_trigger.sql
\i match_attachment_trigger.sql
\i update_attachment_id_trigger.sql
-- ... (all 8 trigger files)
```

---

### Step 5: Create Indexes

**Execute Index Creation:**
```sql
-- Email Attachments Indexes
CREATE INDEX idx_email_attachments_email_id ON email_attachments(email_id);
CREATE INDEX idx_email_attachments_status ON email_attachments(processing_status);
CREATE INDEX idx_email_attachments_category ON email_attachments(document_category);
CREATE INDEX idx_email_attachments_contract ON email_attachments(contract_number);

-- Processing Queue Indexes
CREATE INDEX idx_processing_queue_status ON processing_queue(status);
CREATE INDEX idx_processing_queue_file_type ON processing_queue(file_type);
CREATE INDEX idx_processing_queue_attachment ON processing_queue(attachment_id);

-- Document Pages Indexes
CREATE INDEX idx_document_pages_attachment ON document_pages(attachment_id);
CREATE INDEX idx_document_pages_category ON document_pages(category);

-- Email Ready Queue Indexes
CREATE INDEX idx_email_ready_queue_processed ON email_ready_queue(processed);
CREATE INDEX idx_email_ready_queue_email_id ON email_ready_queue(email_id);

-- Contracts Indexes
CREATE INDEX idx_contracts_number ON contracts(contract_number);
CREATE INDEX idx_contracts_email_id ON contracts(email_id);

-- Additional Performance Indexes
CREATE INDEX idx_emails_received_time ON emails(received_time);
CREATE INDEX idx_emails_sender ON emails(sender_email);
CREATE INDEX idx_processing_history_status ON processing_history(status);
```

---

### Step 6: Verify Database Setup

**Run Verification Queries:**
```sql
-- Check tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;
-- Expected: 19 tables

-- Check functions exist
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_type = 'FUNCTION'
ORDER BY routine_name;
-- Expected: 13 functions

-- Check triggers exist
SELECT trigger_name, event_object_table 
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
ORDER BY trigger_name;
-- Expected: 8 triggers

-- Check indexes exist
SELECT indexname 
FROM pg_indexes 
WHERE schemaname = 'public'
ORDER BY indexname;
-- Expected: 40+ indexes
```

---

## ⚙️ Configuration Files

### Step 1: Microsoft Graph API Configuration

**Location:** `C:\Python_project\CargoFlow\Cargoflow_mail\config\graph_config.json`

**Create Azure AD App Registration:**

1. Go to: https://portal.azure.com
2. Navigate to: Azure Active Directory → App registrations
3. Click: New registration
4. Set name: "CargoFlow Email Extractor"
5. Select: Single tenant
6. Click: Register

**Grant API Permissions:**
```
1. Go to: API permissions
2. Add permission: Microsoft Graph
3. Select: Application permissions
4. Add these permissions:
   - Mail.Read (Read mail in all mailboxes)
   - Mail.ReadWrite (Read and write mail in all mailboxes)
   - User.Read.All (Read all users' full profiles)
5. Click: Grant admin consent
```

**Create Client Secret:**
```
1. Go to: Certificates & secrets
2. Click: New client secret
3. Description: "CargoFlow Main Secret"
4. Expires: 24 months
5. Click: Add
6. COPY THE SECRET VALUE IMMEDIATELY (you can't see it again!)
```

**Configuration File Template:**
```json
{
  "client_id": "your-application-client-id",
  "client_secret": "your-client-secret-value",
  "tenant_id": "your-tenant-id",
  "user_email": "email@yourdomain.com",
  "database": {
    "host": "localhost",
    "database": "Cargo_mail",
    "user": "postgres",
    "password": "your-postgres-password",
    "port": 5432
  },
  "attachment_base_path": "C:\\CargoAttachments",
  "check_interval_minutes": 5,
  "max_emails_per_check": 50
}
```

**Fill in Your Values:**
- `client_id`: From Azure App registration Overview
- `client_secret`: The secret you just created
- `tenant_id`: From Azure App registration Overview
- `user_email`: Microsoft 365 email to monitor
- `password`: PostgreSQL password you set during installation

---

### Step 2: Queue Manager Configuration

**Location:** `C:\Python_project\CargoFlow\Cargoflow_Queue\config\queue_config.json`

**Template:**
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
  },
  "database": {
    "host": "localhost",
    "database": "Cargo_mail",
    "user": "postgres",
    "password": "your-postgres-password",
    "port": 5432
  }
}
```

**Adjust if Needed:**
- `watch_path`: Ensure directories exist (created automatically by OCR processor)
- `rate_limit_per_minute`: Adjust based on AI API limits
- `webhook_url`: Should match n8n webhook URLs

---

### Step 3: Database Connection Config (Shared)

**Location:** `C:\Python_project\CargoFlow\config\database.py`

**Template:**
```python
import psycopg2
from psycopg2 import pool

DB_CONFIG = {
    'host': 'localhost',
    'port': 5432,
    'database': 'Cargo_mail',
    'user': 'postgres',
    'password': 'your-postgres-password'
}

# Connection pool settings
MIN_CONNECTIONS = 2
MAX_CONNECTIONS = 10

# Timeout settings
CONNECT_TIMEOUT = 10
KEEPALIVES_IDLE = 600  # 10 minutes
KEEPALIVES_INTERVAL = 30  # 30 seconds
KEEPALIVES_COUNT = 3

def get_connection():
    """Get database connection with keep-alive settings."""
    return psycopg2.connect(
        host=DB_CONFIG['host'],
        database=DB_CONFIG['database'],
        user=DB_CONFIG['user'],
        password=DB_CONFIG['password'],
        port=DB_CONFIG.get('port', 5432),
        connect_timeout=CONNECT_TIMEOUT,
        keepalives_idle=KEEPALIVES_IDLE,
        keepalives_interval=KEEPALIVES_INTERVAL,
        keepalives_count=KEEPALIVES_COUNT
    )

def test_connection():
    """Test database connection."""
    try:
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("SELECT 1")
        cur.close()
        conn.close()
        print("✅ Database connection successful!")
        return True
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        return False
```

---

### Step 4: AI API Configuration

**For OpenAI (GPT-4):**

**Location:** Create `.env` file in project root

```env
# OpenAI Configuration
OPENAI_API_KEY=your-openai-api-key-here
OPENAI_MODEL=gpt-4-turbo-preview
OPENAI_MAX_TOKENS=4096
OPENAI_TEMPERATURE=0.1

# Alternative: Google Gemini
# GOOGLE_API_KEY=your-google-api-key-here
# GOOGLE_MODEL=gemini-pro
```

**Get OpenAI API Key:**
1. Go to: https://platform.openai.com/api-keys
2. Create new secret key
3. Copy the key (save it securely!)

**Or Get Google Gemini API Key:**
1. Go to: https://makersuite.google.com/app/apikey
2. Create API key
3. Copy the key

---

### Step 5: n8n Environment Variables

**Location:** User profile or system environment variables

```bash
# Set environment variables (Windows)
setx N8N_HOST "localhost"
setx N8N_PORT "5678"
setx N8N_PROTOCOL "http"

# For production with authentication:
setx N8N_BASIC_AUTH_ACTIVE "true"
setx N8N_BASIC_AUTH_USER "admin"
setx N8N_BASIC_AUTH_PASSWORD "your-secure-password"
```

**Or create `.n8nrc` file in user home directory:**
```
N8N_HOST=localhost
N8N_PORT=5678
N8N_PROTOCOL=http
```

---

### Step 6: Create Required Directories

**Run Directory Creation Script:**
```bash
# Navigate to project root
cd C:\Python_project\CargoFlow

# Create directories
mkdir C:\CargoAttachments
mkdir C:\CargoProcessing
mkdir C:\CargoProcessing\processed_documents
mkdir C:\CargoProcessing\processed_documents\2025
mkdir C:\CargoProcessing\processed_documents\2025\ocr_results
mkdir C:\CargoProcessing\processed_documents\2025\images
mkdir C:\CargoProcessing\processed_documents\2025\json_extract
mkdir C:\CargoProcessing\unprocessed
mkdir C:\CargoProcessing\unprocessed\unprocessed_ocr
mkdir C:\CargoProcessing\unprocessed\unprocessed_office

# Create contract organization directories
mkdir "C:\Users\%USERNAME%\Cargo Flow\Site de communication - Documents\Документи по договори"
mkdir "C:\Users\%USERNAME%\Cargo Flow\Site de communication - Documents\Документи по договори\contracts"
mkdir "C:\Users\%USERNAME%\Cargo Flow\Site de communication - Documents\Документи по договори\non_contracts"
```

**Verify Directories Exist:**
```powershell
# PowerShell command to verify
Get-ChildItem C:\CargoAttachments, C:\CargoProcessing
```

---

## 📦 Component Setup

### Step 1: Install Python Dependencies for Each Component

**Component 1: Email Fetcher**
```bash
cd C:\Python_project\CargoFlow\Cargoflow_mail
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

**requirements.txt for Email Fetcher:**
```
msal==1.24.0
requests==2.31.0
psycopg2-binary==2.9.9
python-dotenv==1.0.0
```

---

**Component 2: OCR Processor**
```bash
cd C:\Python_project\CargoFlow\Cargoflow_OCR
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

**requirements.txt for OCR:**
```
PyMuPDF==1.23.6
Pillow==10.1.0
pytesseract==0.3.10
psycopg2-binary==2.9.9
opencv-python==4.8.1.78
```

---

**Component 3: Office Processor**
```bash
cd C:\Python_project\CargoFlow\Cargoflow_Office
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

**requirements.txt for Office:**
```
python-docx==1.1.0
openpyxl==3.1.2
pywin32==306
pypandoc==1.12
psycopg2-binary==2.9.9
```

---

**Component 4: Queue Managers**
```bash
cd C:\Python_project\CargoFlow\Cargoflow_Queue
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

**requirements.txt for Queue:**
```
requests==2.31.0
psycopg2-binary==2.9.9
watchdog==3.0.0
```

---

**Component 5: Contract Processor**
```bash
cd C:\Python_project\CargoFlow\Cargoflow_Contracts
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

**requirements.txt for Contracts:**
```
psycopg2-binary==2.9.9
click==8.1.7
```

---

### Step 2: Test Each Component Configuration

**Test Email Fetcher:**
```bash
cd C:\Python_project\CargoFlow\Cargoflow_mail
venv\Scripts\activate
python -c "from config.database import test_connection; test_connection()"
```

**Expected Output:**
```
✅ Database connection successful!
```

**Test OCR Processor:**
```bash
cd C:\Python_project\CargoFlow\Cargoflow_OCR
venv\Scripts\activate
python -c "import pytesseract; print(pytesseract.get_tesseract_version())"
```

**Expected Output:**
```
tesseract 5.x.x
```

**Test Queue Managers:**
```bash
cd C:\Python_project\CargoFlow\Cargoflow_Queue
venv\Scripts\activate
python -c "import requests; print('Requests module OK')"
```

---

## 🔄 n8n Workflow Import

### Step 1: Start n8n for First Time

```bash
# Open new terminal
n8n start
```

**Expected Output:**
```
n8n ready on http://localhost:5678
```

### Step 2: Access n8n Web Interface

1. Open browser
2. Navigate to: http://localhost:5678
3. Create admin account (first time only):
   - Email: admin@localhost
   - Password: Choose secure password
   - Click: Continue

---

### Step 3: Import Text Workflow

**Workflow File:** `C:\Python_project\CargoFlow\Documentation\n8n\workflows\Contract_Text_CargoFlow.json`

**Import Steps:**
1. Click: Workflows (left sidebar)
2. Click: Import from File
3. Navigate to workflow file
4. Select: `Contract_Text_CargoFlow.json`
5. Click: Import

**Configure Webhook:**
1. Find: "Webhook" node
2. Set Webhook URL: `analyze-text`
3. Method: POST
4. Response Mode: Last Node

**Configure PostgreSQL Node:**
1. Find: "Postgres Trigger" node
2. Click: Create New Credential
3. Enter database details:
   - Host: localhost
   - Database: Cargo_mail
   - User: postgres
   - Password: [your password]
   - Port: 5432
4. Click: Save

**Configure AI Node:**
1. Find: "OpenAI" or "Google Gemini" node
2. Click: Create New Credential
3. Enter API key
4. Select model (gpt-4-turbo-preview or gemini-pro)
5. Click: Save

**Activate Workflow:**
1. Toggle: Active (top right)
2. Verify: Green "Active" status

---

### Step 4: Import Image Workflow

**Workflow File:** `C:\Python_project\CargoFlow\Documentation\n8n\workflows\Contract_PNG_CargoFlow.json`

**Repeat same steps as Text Workflow:**
1. Import workflow
2. Set Webhook URL: `analyze-image`
3. Configure PostgreSQL credential (use existing)
4. Configure AI credential (use existing)
5. Activate workflow

---

### Step 5: Test Webhooks

**Test Text Webhook:**
```bash
curl -X POST http://localhost:5678/webhook/analyze-text ^
  -H "Content-Type: application/json" ^
  -d "{\"test\": \"data\"}"
```

**Expected Response:**
```json
{"status": "received"}
```

**Test Image Webhook:**
```bash
curl -X POST http://localhost:5678/webhook/analyze-image ^
  -H "Content-Type: application/json" ^
  -d "{\"test\": \"image\"}"
```

---

## 🚀 First-Time Startup

### Pre-Startup Checklist

- [ ] PostgreSQL running (check services)
- [ ] Database created and schema loaded
- [ ] All configuration files filled in
- [ ] Python virtual environments created
- [ ] All dependencies installed
- [ ] n8n workflows imported and active
- [ ] Required directories created
- [ ] Tesseract OCR installed

---

### Startup Sequence (7 Terminals)

**Open 7 Command Prompt/Terminal windows:**

**Terminal 1: Email Fetcher**
```bash
cd C:\Python_project\CargoFlow\Cargoflow_mail
venv\Scripts\activate
python graph_email_extractor_v5.py
```

**Expected Output:**
```
✅ Database connection successful
🔄 Checking for new emails...
📧 Found X new emails
```

---

**Terminal 2: OCR Processor**
```bash
cd C:\Python_project\CargoFlow\Cargoflow_OCR
venv\Scripts\activate
python ocr_processor.py
```

**Expected Output:**
```
📂 Watching for PDF/image files...
✅ OCR processor started
```

---

**Terminal 3: Office Processor**
```bash
cd C:\Python_project\CargoFlow\Cargoflow_Office
venv\Scripts\activate
python office_processor.py
```

**Expected Output:**
```
📂 Watching for Office files...
✅ Office processor started
```

---

**Terminal 4: Text Queue Manager**
```bash
cd C:\Python_project\CargoFlow\Cargoflow_Queue
venv\Scripts\activate
python text_queue_manager.py
```

**Expected Output:**
```
✅ Connected to database
📂 Watching: C:\CargoProcessing\...\ocr_results
🔄 Queue manager started
```

---

**Terminal 5: Image Queue Manager**
```bash
cd C:\Python_project\CargoFlow\Cargoflow_Queue
venv\Scripts\activate
python image_queue_manager.py
```

**Expected Output:**
```
✅ Connected to database
📂 Watching: C:\CargoProcessing\...\images
🔄 Queue manager started
```

---

**Terminal 6: Contract Processor**
```bash
cd C:\Python_project\CargoFlow\Cargoflow_Contracts
venv\Scripts\activate
python main.py --continuous
```

**Expected Output:**
```
✅ Contract processor started
⏳ Waiting for emails to process...
```

---

**Terminal 7: n8n Server**
```bash
n8n start
```

**Expected Output:**
```
n8n ready on http://localhost:5678
Editor is now accessible via:
http://localhost:5678/
```

---

### Verify All Components Running

**PowerShell Command:**
```powershell
# Check Python processes
Get-Process python | Select-Object Id, ProcessName, StartTime
```

**Expected:** 6 Python processes running

**Check n8n:**
```powershell
Get-Process node | Select-Object Id, ProcessName, StartTime
```

**Expected:** 1 Node process running

---

## ✅ Post-Deployment Testing

### Test 1: Database Connection

**Run in PostgreSQL:**
```sql
-- Connect to database
psql -U postgres -d Cargo_mail

-- Check tables
\dt

-- Check record counts (should be 0 initially)
SELECT 
    'emails' as table_name, COUNT(*) as count FROM emails
UNION ALL
SELECT 'email_attachments', COUNT(*) FROM email_attachments
UNION ALL
SELECT 'processing_queue', COUNT(*) FROM processing_queue;
```

**Expected:** All tables exist, counts are 0

---

### Test 2: Email Extraction

**Monitor Terminal 1 (Email Fetcher) for:**
```
🔄 Checking for new emails...
📧 Found [N] new emails
✅ Processed email: [subject]
```

**Verify in Database:**
```sql
SELECT COUNT(*) FROM emails;
SELECT id, subject, sender_email FROM emails LIMIT 5;
```

**Expected:** New emails appear in database

---

### Test 3: File Processing

**Check Directories:**
```bash
# Check attachments directory
dir C:\CargoAttachments

# Check processing directory
dir C:\CargoProcessing\processed_documents\2025\ocr_results
dir C:\CargoProcessing\processed_documents\2025\images
```

**Expected:** Files appearing in directories

---

### Test 4: AI Categorization

**Monitor Queue Manager terminals for:**
```
📄 Added to queue: [filename]
✅ Sent to n8n: [filename]
```

**Check n8n Interface:**
1. Open: http://localhost:5678
2. Click: Executions
3. Verify: Recent executions with success status

**Verify in Database:**
```sql
SELECT 
    attachment_name,
    document_category,
    contract_number,
    confidence_score,
    classification_timestamp
FROM email_attachments
WHERE document_category IS NOT NULL
ORDER BY classification_timestamp DESC
LIMIT 10;
```

**Expected:** Files getting categorized with AI

---

### Test 5: Contract Detection

**Monitor Terminal 6 (Contract Processor) for:**
```
📋 Processing email [ID]
✅ Created folder: [contract_number_index]
```

**Verify Folders Created:**
```bash
dir "C:\Users\%USERNAME%\Cargo Flow\Site de communication - Documents\Документи по договори\contracts"
```

**Verify in Database:**
```sql
SELECT * FROM contracts;
SELECT email_id, folder_name FROM emails WHERE folder_name IS NOT NULL;
```

**Expected:** Contracts table populated, folders created

---

### Test 6: End-to-End Flow

**Send a test email with attachment to monitored account**

**Track Progress:**
```sql
-- Step 1: Email arrives
SELECT id, subject FROM emails ORDER BY received_time DESC LIMIT 1;

-- Step 2: Attachment recorded
SELECT id, filename, processing_status 
FROM email_attachments 
WHERE email_id = [email_id];

-- Step 3: Processing queue
SELECT file_path, status 
FROM processing_queue 
WHERE attachment_id = [attachment_id];

-- Step 4: AI categorization
SELECT document_category, contract_number 
FROM email_attachments 
WHERE id = [attachment_id];

-- Step 5: Contract organization
SELECT folder_name FROM emails WHERE id = [email_id];
SELECT * FROM contracts WHERE email_id = [email_id];
```

**Expected Timeline:**
- 0-5 min: Email extracted
- 5-10 min: File processed (OCR/Office)
- 10-15 min: AI categorization complete
- 15-20 min: Contract organized (if applicable)

---

## 🔧 Troubleshooting

### Issue: Email Fetcher Not Connecting

**Symptoms:**
```
❌ Failed to authenticate with Microsoft Graph API
```

**Solutions:**
1. Verify Azure AD app permissions granted
2. Check client_id, client_secret, tenant_id in config
3. Ensure user_email has mailbox
4. Test with: `python test_graph_connection.py`

---

### Issue: Database Connection Fails

**Symptoms:**
```
❌ Database connection failed: could not connect to server
```

**Solutions:**
1. Check PostgreSQL service running:
   ```bash
   # Windows Services
   services.msc → PostgreSQL 17
   ```
2. Verify password correct in all config files
3. Test connection:
   ```bash
   psql -U postgres -d Cargo_mail
   ```
4. Check firewall not blocking port 5432

---

### Issue: OCR Not Working

**Symptoms:**
```
❌ Tesseract not found
```

**Solutions:**
1. Verify Tesseract installed:
   ```bash
   tesseract --version
   ```
2. Add to PATH if missing:
   ```
   C:\Program Files\Tesseract-OCR
   ```
3. Restart terminal after PATH change

---

### Issue: n8n Webhooks Not Responding

**Symptoms:**
```
❌ Failed to send to n8n: Connection refused
```

**Solutions:**
1. Check n8n running:
   ```bash
   curl http://localhost:5678
   ```
2. Verify workflows active in n8n UI
3. Check webhook URLs match config:
   - Text: http://localhost:5678/webhook/analyze-text
   - Image: http://localhost:5678/webhook/analyze-image
4. Review n8n logs for errors

---

### Issue: AI API Errors

**Symptoms:**
```
❌ OpenAI API error: Authentication failed
```

**Solutions:**
1. Verify API key correct in .env file
2. Check API credits/quota not exhausted
3. Test API key:
   ```bash
   curl https://api.openai.com/v1/models \
     -H "Authorization: Bearer YOUR_API_KEY"
   ```
4. Switch to alternative AI provider if needed

---

### Issue: Files Not Being Categorized

**Symptoms:**
- Files in processing_queue with status='pending' for long time
- No classification_timestamp updates

**Solutions:**
1. Check queue managers running (Terminal 4, 5)
2. Verify n8n workflows active
3. Check PostgreSQL triggers firing:
   ```sql
   SELECT * FROM pg_stat_user_triggers;
   ```
4. Review n8n execution logs
5. Restart queue managers

---

### Issue: Contract Folders Not Created

**Symptoms:**
- contracts table empty
- No folders in output directory

**Solutions:**
1. Check contract processor running (Terminal 6)
2. Verify contract numbers being extracted:
   ```sql
   SELECT COUNT(*) FROM email_attachments 
   WHERE contract_number IS NOT NULL;
   ```
3. Check email_ready_queue has records:
   ```sql
   SELECT * FROM email_ready_queue 
   WHERE processed = FALSE;
   ```
4. Review contract processor logs

---

## 📞 Support & Additional Resources

### Documentation Reference

- **[README.md](README.md)** - Project overview
- **[SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md)** - Architecture details
- **[DATABASE_SCHEMA.md](DATABASE_SCHEMA.md)** - Database documentation
- **[MODULE_DEPENDENCIES.md](MODULE_DEPENDENCIES.md)** - Component dependencies
- **[STATUS_FLOW_MAP.md](docs/STATUS_FLOW_MAP.md)** - Status flow documentation
- **Module Docs:** [modules/](modules/) - Individual component guides

### Log File Locations

| Component | Log File |
|-----------|----------|
| Email Fetcher | `Cargoflow_mail\logs\graph_extraction.log` |
| OCR Processor | `Cargoflow_OCR\logs\document_processing.log` |
| Office Processor | `Cargoflow_Office\logs\document_processing.log` |
| Queue Managers | `Cargoflow_Queue\logs\[text\|image]_queue_manager.log` |
| Contract Processor | `Cargoflow_Contracts\logs\contract_detector_[date].log` |
| n8n | `~/.n8n/logs/` |

### Health Check Script

**Create:** `health_check.py`
```python
import psycopg2
import requests

def check_database():
    try:
        conn = psycopg2.connect(
            host='localhost',
            database='Cargo_mail',
            user='postgres',
            password='your-password'
        )
        conn.close()
        print("✅ Database: OK")
        return True
    except:
        print("❌ Database: FAILED")
        return False

def check_n8n():
    try:
        r = requests.get('http://localhost:5678', timeout=5)
        print("✅ n8n: OK")
        return True
    except:
        print("❌ n8n: FAILED")
        return False

if __name__ == '__main__':
    db_ok = check_database()
    n8n_ok = check_n8n()
    
    if db_ok and n8n_ok:
        print("\n✅ All systems operational")
    else:
        print("\n❌ System check failed")
```

---

## 🎉 Deployment Complete!

**Congratulations!** CargoFlow is now deployed and running.

### Next Steps:

1. **Monitor Initial Run** - Watch all 7 terminals for 1-2 hours
2. **Verify Data Flow** - Check database for new records
3. **Test End-to-End** - Send test email and track through system
4. **Review Logs** - Check for any errors or warnings
5. **Optimize Settings** - Adjust rate limits, intervals as needed

### System Maintenance:

- **Daily:** Check all processes running, review error logs
- **Weekly:** Database VACUUM ANALYZE, clear old logs
- **Monthly:** Review and update AI prompts, optimize performance

---

**Deployment Guide Version:** 1.0  
**Last Updated:** November 06, 2025  
**Support:** Refer to TROUBLESHOOTING.md for common issues
