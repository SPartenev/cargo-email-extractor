# Modules Documentation

**Last Updated:** November 12, 2025  
**Total Modules:** 7

---

## 📋 Module Index

| # | Module | File | Status | Priority |
|---|--------|------|--------|----------|
| 1 | [Email Fetcher](#1-email-fetcher) | `email_fetcher.md` | 📝 To Document | ⚠️ HIGH |
| 2 | [OCR Processor](#2-ocr-processor) | `ocr_processor.md` | 📝 To Document | ⚠️ HIGH |
| 3 | [Office Processor](#3-office-processor) | `office_processor.md` | 📝 To Document | ⚠️ HIGH |
| 4 | [Text Queue Manager](#4-text-queue-manager) | `text_queue_manager.md` | 📝 To Document | ⚠️ HIGH |
| 5 | [Image Queue Manager](#5-image-queue-manager) | `image_queue_manager.md` | 📝 To Document | ⚠️ HIGH |
| 6 | [n8n Workflows](#6-n8n-workflows) | `n8n_workflows.md` | 📝 To Document | ⚠️ HIGH |
| 7 | [Contract Processor](#7-contract-processor) | `contract_processor.md` | 📝 To Document | ⚠️ HIGH |

---

## 🎯 Module Overview

### 1. Email Fetcher

**Script:** `graph_email_extractor_v5.py`  
**Location:** `C:\Python_project\CargoFlow\Cargoflow_mail\`  
**Status:** ✅ Active

**Purpose:**
- Fetches emails from Microsoft 365 via Graph API
- Extracts and saves attachments
- Records to database

**Dependencies:**
- Microsoft Graph API
- PostgreSQL database

**Key Features:**
- Keep-alive connections for stability
- Automatic retry on failures
- Structured file organization

**Documentation:** `email_fetcher.md` (to be created)

---

### 2. OCR Processor

**Script:** `ocr_processor.py`  
**Location:** `C:\Python_project\CargoFlow\Cargoflow_OCR\`  
**Status:** ✅ Active

**Purpose:**
- Extracts text from PDF documents
- Converts pages to PNG images
- OCR processing for scanned documents

**Dependencies:**
- PyMuPDF (fitz)
- Pillow
- Tesseract OCR
- PostgreSQL database

**Key Features:**
- Direct text extraction when possible
- OCR fallback for scanned documents
- PNG image generation for AI analysis

**Documentation:** `ocr_processor.md` (to be created)

---

### 3. Office Processor

**Script:** `office_processor.py`  
**Location:** `C:\Python_project\CargoFlow\Cargoflow_Office\`  
**Status:** ✅ Active

**Purpose:**
- Processes Word documents (.docx, .doc)
- Processes Excel files (.xlsx, .xls)
- Extracts text from various Office formats

**Dependencies:**
- python-docx
- openpyxl
- win32com (for legacy formats)
- PostgreSQL database

**Key Features:**
- Multiple format support
- Automatic format detection
- Error handling for corrupted files

**Documentation:** `office_processor.md` (to be created)

---

### 4. Text Queue Manager

**Script:** `text_queue_manager.py`  
**Location:** `C:\Python_project\CargoFlow\Cargoflow_Queue\`  
**Status:** ⚠️ Stopped (28 Oct 09:40)

**Purpose:**
- Monitors text files from OCR/Office processing
- Queues files for n8n AI analysis
- Rate limiting to prevent API overload

**Dependencies:**
- File system monitoring
- n8n webhooks
- PostgreSQL database

**Key Features:**
- Automatic file detection
- Rate limiting (3 files/minute)
- Retry mechanism for failures

**Documentation:** `text_queue_manager.md` (to be created)

---

### 5. Image Queue Manager

**Script:** `image_queue_manager.py`  
**Location:** `C:\Python_project\CargoFlow\Cargoflow_Queue\`  
**Status:** ⚠️ Stopped (28 Oct 09:40)

**Purpose:**
- Monitors PNG images from OCR processing
- Queues images for n8n AI analysis
- Manages attachment_id matching

**Dependencies:**
- File system monitoring
- n8n webhooks
- PostgreSQL database

**Key Features:**
- Intelligent filename matching
- Small file filtering (logos, banners)
- Rate limiting (3 files/minute)

**Documentation:** `image_queue_manager.md` (to be created)

---

### 6. n8n Workflows

**Workflows:** Multiple JSON files  
**Location:** `C:\Python_project\CargoFlow\Cargoflow_n8n\`  
**Status:** ⚠️ Status unknown

**Purpose:**
- AI categorization of documents (13 categories)
- Contract number extraction
- Invoice data extraction

**Dependencies:**
- n8n server (localhost:5678)
- OpenAI API or Google Gemini
- PostgreSQL database

**Key Features:**
- AI-powered categorization
- Multiple workflow types (text, image, invoice)
- PostgreSQL NOTIFY/LISTEN integration

**Documentation:** `n8n_workflows.md` (to be created)

---

### 7. Contract Processor

**Script:** `main.py`  
**Location:** `C:\Python_project\CargoFlow\Cargoflow_Contracts\`  
**Status:** ❌ Not started

**Purpose:**
- Detects contracts by number patterns
- Organizes files into structured folders
- Creates contract database entries

**Dependencies:**
- email_ready_queue (PostgreSQL)
- contract_folder_seq (PostgreSQL)
- File system access

**Key Features:**
- Regex pattern matching
- Folder organization by contract
- Index-based naming system

**Documentation:** `contract_processor.md` (to be created)

---

## 🔗 Module Dependencies

### Dependency Levels

```
Level 1: Email Fetcher (Independent)
    ↓
Level 2: OCR Processor, Office Processor
    ↓
Level 3: Text Queue Manager, Image Queue Manager
    ↓
Level 4: n8n Workflows (AI Processing)
    ↓
Level 5: Contract Processor
```

### Critical Dependencies

**Email Fetcher → All Modules**
- Without emails, nothing else works
- Must run continuously

**OCR/Office → Queue Managers**
- Queue managers need processed files
- Files must be in correct directories

**Queue Managers → n8n**
- n8n needs queue managers to send files
- STOPPED: Both queue managers inactive since 28 Oct

**n8n → Contract Processor**
- Contract processor needs contract_number from AI
- Blocked: n8n status unknown

---

## 📊 Module Status Summary

### ✅ Active (3/7)
1. Email Fetcher
2. OCR Processor
3. Office Processor

### ⚠️ Stopped (2/7)
4. Text Queue Manager (stopped 28 Oct 09:40)
5. Image Queue Manager (stopped 28 Oct 09:40)

### ⚠️ Unknown (1/7)
6. n8n Workflows (status unknown)

### ❌ Not Started (1/7)
7. Contract Processor

---

## 🚀 Quick Start

### Start All Modules

```bash
# Terminal 1: Email Fetcher
cd C:\Python_project\CargoFlow\Cargoflow_mail
venv\Scripts\activate
python graph_email_extractor_v5.py

# Terminal 2: OCR Processor
cd C:\Python_project\CargoFlow\Cargoflow_OCR
venv\Scripts\activate
python ocr_processor.py

# Terminal 3: Office Processor
cd C:\Python_project\CargoFlow\Cargoflow_Office
venv\Scripts\activate
python office_processor.py

# Terminal 4: Text Queue Manager
cd C:\Python_project\CargoFlow\Cargoflow_Queue
venv\Scripts\activate
python text_queue_manager.py

# Terminal 5: Image Queue Manager
cd C:\Python_project\CargoFlow\Cargoflow_Queue
python image_queue_manager.py

# Terminal 6: n8n
n8n start

# Terminal 7: Contract Processor
cd C:\Python_project\CargoFlow\Cargoflow_Contracts
venv\Scripts\activate
python main.py --continuous
```

---

## 🔧 Configuration Files

Each module has its own configuration:

| Module | Config File | Location |
|--------|-------------|----------|
| Email Fetcher | `graph_config.json` | Cargoflow_mail/ |
| Queue Managers | `queue_config.json` | Cargoflow_Queue/ |
| All Modules | `.env` | Project root |

**See:** [config/README.md](../config/README.md) for examples

---

## 📝 Documentation Structure

Each module documentation file will contain:

### Standard Sections
1. **Overview** - Purpose and functionality
2. **Configuration** - Settings and parameters
3. **Dependencies** - Required libraries and services
4. **Inputs** - What the module receives
5. **Outputs** - What the module produces
6. **Database Operations** - Tables used
7. **File Operations** - File system interactions
8. **Error Handling** - How errors are managed
9. **Known Issues** - Current problems
10. **Example Usage** - How to use the module
11. **Troubleshooting** - Common problems and solutions

---

## 📚 Related Documentation

- **[STATUS_FLOW_MAP.md](../docs/STATUS_FLOW_MAP.md)** - Complete data flow
- **[SYSTEM_ARCHITECTURE.md](../docs/SYSTEM_ARCHITECTURE.md)** - System overview (planned)
- **[MODULE_DEPENDENCIES.md](../docs/MODULE_DEPENDENCIES.md)** - Detailed dependencies (planned)

---

## 🎯 Next Steps

### Immediate (Critical)
1. **Restart Queue Managers** - Both stopped on 28 Oct
2. **Verify n8n Status** - Check if workflows active
3. **Start Contract Processor** - Never been started

### Documentation (High Priority)
1. Create detailed documentation for each module
2. Document configuration options
3. Add troubleshooting guides

---

## 📞 Module Support

For module-specific issues, check:
1. Module log files in respective directories
2. Module-specific README files (when created)
3. TROUBLESHOOTING.md (planned)

---

**Last Updated:** November 12, 2025  
**Status:** Index complete - Individual module docs in progress
