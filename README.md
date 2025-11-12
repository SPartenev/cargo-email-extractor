# CargoFlow - Automated Email and Document Processing System

**Version:** 2.0  
**Status:** Production Ready ✅  
**Last Updated:** November 12, 2025

---

## 🎯 Overview

CargoFlow is an intelligent, end-to-end automated system for processing business emails, extracting attachments, categorizing documents using AI, and organizing contracts. It processes emails from Microsoft 365, extracts attachments (PDF, Office documents, images), performs OCR when needed, uses AI for document classification, and automatically organizes files into structured folders based on contract numbers.

### Key Capabilities

- **Email Extraction**: Automatic retrieval of emails via Microsoft Graph API
- **Document Processing**: OCR and text extraction from PDFs, images, and Office documents
- **AI Classification**: 13 document categories with confidence scoring
- **Contract Detection**: Automatic contract number extraction and organization
- **Queue Management**: Rate-limited processing with retry mechanisms
- **Database Integration**: Complete PostgreSQL tracking with triggers and functions

### Recent Enhancements (November 12, 2025)

- **Smart Invoice Naming**: Invoices automatically named as `invoice_{number}_{supplier}.pdf` using data from `invoice_base` table
- **Multi-Page Document Splitting**: Combined documents (e.g., invoice + CMR) automatically split into separate PDF files by category
- **Category Prefix Naming**: All files prefixed with document category for quick identification
- **Page Orientation Correction**: Automatic EXIF orientation correction and 180° rotation for inverted pages

---

## 📊 System Architecture

### Components

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Email Fetcher  │───▶│ File Processors │───▶│ Queue Managers  │
│  (Graph API)    │    │ (OCR + Office)  │    │ (Text + Image)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┴───────────────────────┘
                              ▼
                  ┌─────────────────────────┐
                  │   PostgreSQL Database   │
                  │    (Cargo_mail)         │
                  └─────────────────────────┘
                              ▼
                  ┌─────────────────────────┐
                  │    n8n AI Workflows     │
                  │  (Category + Extract)   │
                  └─────────────────────────┘
                              ▼
                  ┌─────────────────────────┐
                  │  Contract Organization  │
                  │  (Folder Structure)     │
                  └─────────────────────────┘
```

### Data Flow

1. **Email Extraction** → Microsoft Graph API retrieves emails and attachments
2. **File Storage** → Attachments saved to `C:\CargoAttachments\` with structured folders
3. **Document Processing** → OCR/Office processors extract text
4. **Queue System** → Text and image files queued for AI analysis
5. **AI Classification** → n8n workflows categorize documents (13 categories)
6. **Contract Detection** → Extract contract numbers and organize files
7. **Final Output** → Structured folders by contract, date, and sender

---

## 🗂️ Project Structure

```
C:\Python_project\CargoFlow\
├── Cargoflow_mail/           # Email extraction (Microsoft Graph API)
│   ├── graph_email_extractor_v5.py
│   ├── graph_config.json
│   └── venv/
├── Cargoflow_OCR/            # OCR processing (PDF + Images)
│   ├── (integrated in processors)
│   └── venv/
├── Cargoflow_Office/         # Office document processing
│   ├── office_processor.py
│   └── venv/
├── Cargoflow_Queue/          # Queue management
│   ├── text_queue_manager.py
│   ├── image_queue_manager.py
│   ├── queue_config.json
│   └── venv/
├── Cargoflow_Contracts/      # Contract detection and organization
│   ├── main.py
│   ├── config/
│   ├── services/
│   └── venv/
├── Cargoflow_n8n/           # n8n workflow definitions
│   ├── INV_Text_CargoFlow.json
│   └── INV_PNG_CargoFlow.json
└── Documentation/            # THIS DIRECTORY
    ├── README.md
    ├── CONTEXT_FOR_NEW_CHAT.md
    ├── PROJECT_STATUS.md
    ├── SYSTEM_ARCHITECTURE.md
    ├── DATABASE_SCHEMA.md
    ├── DEPLOYMENT_GUIDE.md
    └── modules/
        ├── 01_EMAIL_FETCHER.md
        ├── 02_OCR_PROCESSOR.md
        ├── 03_OFFICE_PROCESSOR.md
        ├── 04_QUEUE_MANAGERS.md
        ├── 05_N8N_WORKFLOWS.md
        └── 06_CONTRACTS_PROCESSOR.md
```

---

## 🗄️ Database

**Database Name:** `Cargo_mail`  
**Server:** PostgreSQL 17, localhost:5432  
**Tables:** 19 tables (emails, email_attachments, processing_queue, contracts, etc.)

### Key Tables

- `emails` - Email metadata and analysis results
- `email_attachments` - File attachments with AI classification
- `processing_queue` - Queue for document processing
- `processing_history` - Processing logs
- `document_pages` - Individual page categories for multi-page documents
- `contracts` - Detected contracts
- `contract_detection_queue` - Contract processing queue
- `email_ready_queue` - Email folder organization queue
- `invoice_base` + `invoice_items` - Invoice data

---

## ⚙️ Configuration

### Required Credentials

1. **Microsoft Graph API**
   - Client ID
   - Client Secret
   - Tenant ID
   - User Email

2. **PostgreSQL Database**
   - Host: localhost
   - Port: 5432
   - Database: Cargo_mail
   - User: postgres
   - Password: [your password]

3. **n8n Webhooks**
   - Text: `http://localhost:5678/webhook/analyze-text`
   - Image: `http://localhost:5678/webhook/analyze-image`

---

## 🚀 Quick Start

### Prerequisites

- Python 3.11+
- PostgreSQL 17
- n8n (for AI workflows)
- Microsoft 365 account with Graph API access

### Installation

```bash
# 1. Clone/Navigate to project
cd C:\Python_project\CargoFlow

# 2. Setup virtual environments (each component has its own)
cd Cargoflow_mail && python -m venv venv && venv\Scripts\activate && pip install -r requirements.txt
cd ..\Cargoflow_Office && python -m venv venv && venv\Scripts\activate && pip install -r requirements.txt
cd ..\Cargoflow_Queue && python -m venv venv && venv\Scripts\activate && pip install -r requirements.txt
cd ..\Cargoflow_Contracts && python -m venv venv && venv\Scripts\activate && pip install -r requirements.txt

# 3. Configure credentials
# Edit: Cargoflow_mail/graph_config.json
# Edit: Cargoflow_Queue/queue_config.json
# Edit: Cargoflow_Contracts/config/database.py

# 4. Import database schema
psql -U postgres -d Cargo_mail -f database_schema.sql
```

### Starting the System

**7 Terminal Windows Required:**

```bash
# Terminal 1: Email Extraction
cd C:\Python_project\CargoFlow\Cargoflow_mail
venv\Scripts\activate
python graph_email_extractor_v5.py

# Terminal 2: OCR Processor (if separate)
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
venv\Scripts\activate
python image_queue_manager.py

# Terminal 6: Contract Processor
cd C:\Python_project\CargoFlow\Cargoflow_Contracts
venv\Scripts\activate
python main.py --continuous

# Terminal 7: n8n Server
n8n start
```

---

## 📚 Documentation

### Essential Reading

1. **[CONTEXT_FOR_NEW_CHAT.md](./CONTEXT_FOR_NEW_CHAT.md)** - Quick context for new developers
2. **[PROJECT_STATUS.md](./PROJECT_STATUS.md)** - Current system status
3. **[SYSTEM_ARCHITECTURE.md](./SYSTEM_ARCHITECTURE.md)** - Detailed architecture
4. **[DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md)** - Complete database documentation
5. **[DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)** - Deployment instructions

### Module Documentation

- [Email Fetcher](./modules/01_EMAIL_FETCHER.md)
- [OCR Processor](./modules/02_OCR_PROCESSOR.md)
- [Office Processor](./modules/03_OFFICE_PROCESSOR.md)
- [Queue Managers](./modules/04_QUEUE_MANAGERS.md)
- [n8n Workflows](./modules/05_N8N_WORKFLOWS.md)
- [Contracts Processor](./modules/06_CONTRACTS_PROCESSOR.md)

---

## 🎯 Document Categories (AI Classification)

The system automatically categorizes documents into 13 types:

1. **contract** - Main contracts
2. **contract_amendment** - Contract amendments
3. **contract_termination** - Contract terminations
4. **contract_extension** - Contract extensions
5. **service_agreement** - Service agreements
6. **framework_agreement** - Framework agreements
7. **cmr** - CMR transport documents
8. **protocol** - Protocols
9. **annex** - Annexes/Attachments
10. **insurance** - Insurance documents
11. **invoice** - Invoices (with extraction to `invoice_base` table)
12. **credit_note** - Credit notes
13. **other** - Uncategorized documents

---

## 🔧 Maintenance

### Monitoring

```sql
-- Check system status
SELECT 
    'emails' as table_name, COUNT(*) as count FROM emails
UNION ALL
SELECT 'email_attachments', COUNT(*) FROM email_attachments
UNION ALL
SELECT 'processing_queue', COUNT(*) FROM processing_queue
UNION ALL
SELECT 'contracts', COUNT(*) FROM contracts;

-- Check processing queue
SELECT file_type, status, COUNT(*) 
FROM processing_queue 
GROUP BY file_type, status;

-- Recent AI classifications
SELECT attachment_name, document_category, confidence_score, classification_timestamp
FROM email_attachments
WHERE classification_timestamp > NOW() - INTERVAL '1 hour'
ORDER BY classification_timestamp DESC;
```

### Logs

- `Cargoflow_mail/graph_extraction.log`
- `Cargoflow_Queue/text_queue_manager.log`
- `Cargoflow_Queue/image_queue_manager.log`
- `Cargoflow_Contracts/logs/contract_detector_*.log`

---

## 📞 Support

For issues or questions:
1. Check logs in respective component directories
2. Review [PROJECT_STATUS.md](./PROJECT_STATUS.md) for known issues
3. Consult module documentation in `Documentation/modules/`

---

## 📋 License

Internal project for Cargo Flow company.

---

**🚀 System Status:** Production Ready  
**📅 Last Updated:** November 12, 2025  
**👨‍💻 Maintained by:** CargoFlow DevOps Team
