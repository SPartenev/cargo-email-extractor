# OCR Processor Module - PDF and Image Text Extraction

**Module:** Cargoflow_OCR  
**Script:** `ocr_processor.py`  
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

The OCR Processor module is the **second component** in the CargoFlow system. It processes PDF and image files to extract text content, making documents searchable and analyzable by AI.

**Primary Functions:**
1. **Extract text from PDFs** (direct extraction when possible)
2. **Convert PDFs to images** (for OCR processing when needed)
3. **Perform OCR on images** (PNG, JPG, TIF formats)
4. **Create searchable text files** for AI analysis
5. **Update database status** to track processing progress

### Key Features

- ✅ **Intelligent PDF Processing** - Direct text extraction OR OCR based on content
- ✅ **Multi-format Support** - PDF, PNG, JPG, JPEG, TIF, TIFF
- ✅ **Image Conversion** - PDF pages → PNG images for AI analysis
- ✅ **Quality Assessment** - Evaluates extracted text quality
- ✅ **Database Integration** - Updates `email_attachments` and `processing_history`
- ✅ **Error Recovery** - Retry logic with exponential backoff
- ✅ **Continuous Monitoring** - Watches for new pending files
- ✅ **Structured Output** - Organized by sender/subject/date

---

## 🏗️ Architecture & Data Flow

### High-Level Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    OCR PROCESSOR MODULE                         │
└─────────────────────────────────────────────────────────────────┘

[1] Query Database for Pending Files
    ↓ SELECT * FROM email_attachments WHERE processing_status = 'pending'
    ↓ AND attachment_type IN ('pdf', 'png', 'jpg', 'tif')
    ↓
[2] For Each Pending File:
    ├─ Read file from C:\CargoAttachments\
    ├─ Determine file type (PDF vs Image)
    ├─ UPDATE processing_status = 'processing'
    └─ Process based on type
    ↓
[3] PDF Processing:
    ├─ Try direct text extraction (PyMuPDF)
    ├─ Assess text quality
    ├─ IF quality good → Save text
    ├─ IF quality poor → Convert to images + OCR
    └─ Create PNG images for each page
    ↓
[4] Image Processing:
    ├─ Load image (Pillow)
    ├─ Perform OCR (pytesseract)
    └─ Extract text content
    ↓
[5] Save Results:
    ├─ Text → C:\CargoProcessing\...\ocr_results\{file}_extracted.txt
    ├─ Images → C:\CargoProcessing\...\images\{file}_page_1.png
    └─ Metadata → C:\CargoProcessing\...\json_extract\{file}_metadata.json
    ↓
[6] Update Database:
    ├─ UPDATE email_attachments SET processing_status = 'completed'
    └─ Log to processing_history
    ↓
[7] Wait and Repeat
    ↓ Sleep 30 seconds
    ↓ Check for new pending files
    └─ [REPEAT from 1]
```

### Component Interaction

```
┌──────────────────┐       ┌──────────────────┐       ┌──────────────────┐
│  Email Fetcher   │──────►│  OCR Processor   │──────►│   Queue Manager  │
│  (pending files) │       │  (extract text)  │       │   (AI analysis)  │
└──────────────────┘       └──────────────────┘       └──────────────────┘
         │                          │                           │
         │                          ↓                           │
         │              ┌──────────────────┐                   │
         │              │   PostgreSQL     │                   │
         └──────────────┤  (email_attachm) │───────────────────┘
                        │  (proc_history)  │
                        └──────────────────┘
                                 │
                                 ↓
                     ┌──────────────────┐
                     │  File System     │
                     │  C:\CargoProcessing\
                     │  ├─ ocr_results\
                     │  ├─ images\
                     │  └─ json_extract\
                     └──────────────────┘
```

---

## ⚙️ Configuration

### Configuration File: `config.py` or Environment Variables

**Location:** `C:\Python_project\CargoFlow\Cargoflow_OCR\config.py`

**Database Configuration:**

```python
DB_CONFIG = {
    'host': 'localhost',
    'port': 5432,
    'database': 'Cargo_mail',
    'user': 'postgres',
    'password': 'Lora24092004'
}
```

**File Paths Configuration:**

```python
# Input files (from Email Fetcher)
INPUT_BASE_PATH = r"C:\CargoAttachments"

# Output files
OUTPUT_BASE_PATH = r"C:\CargoProcessing"
OCR_RESULTS_PATH = OUTPUT_BASE_PATH + r"\processed_documents\2025\ocr_results"
IMAGES_PATH = OUTPUT_BASE_PATH + r"\processed_documents\2025\images"
JSON_EXTRACT_PATH = OUTPUT_BASE_PATH + r"\processed_documents\2025\json_extract"
UNPROCESSED_PATH = OUTPUT_BASE_PATH + r"\unprocessed\unprocessed_ocr"
```

**Processing Configuration:**

```python
# Supported file types
SUPPORTED_EXTENSIONS = ['.pdf', '.png', '.jpg', '.jpeg', '.tif', '.tiff']

# PDF processing
PDF_DPI = 300  # DPI for PDF to image conversion
PDF_IMAGE_FORMAT = 'PNG'

# OCR settings
OCR_LANGUAGE = 'eng+bul'  # English + Bulgarian
OCR_CONFIG = '--psm 6'  # Assume uniform block of text

# Quality thresholds
MIN_TEXT_QUALITY_SCORE = 50  # Minimum acceptable quality (0-100)
MIN_WORDS_FOR_QUALITY_CHECK = 10

# Performance
BATCH_SIZE = 10  # Process N files per cycle
SLEEP_INTERVAL = 30  # Seconds between checks
MAX_RETRIES = 3  # Max retry attempts for failed files
```

### Dependencies

**Python Packages:**

```
PyMuPDF>=1.23.0  # PDF processing (fitz)
Pillow>=10.0.0   # Image processing
pytesseract>=0.3.10  # OCR engine wrapper
psycopg2-binary>=2.9.9  # PostgreSQL
pathlib>=1.0.1
```

**External Software:**

- **Tesseract OCR** (required)
  - Windows: Download from https://github.com/UB-Mannheim/tesseract/wiki
  - Linux: `sudo apt-get install tesseract-ocr`
  - Add to PATH or configure `pytesseract.pytesseract.tesseract_cmd`

**Tesseract Configuration:**

```python
# Windows example
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

# Linux example
# pytesseract.pytesseract.tesseract_cmd = '/usr/bin/tesseract'
```

---

## 🔧 Key Components

### Class: `OCRProcessor`

Main class that handles all OCR operations.

#### Constructor: `__init__()`

```python
def __init__(self):
    self.db_config = DB_CONFIG
    self.conn = None
    self.input_base = Path(INPUT_BASE_PATH)
    self.output_base = Path(OUTPUT_BASE_PATH)
    self.ocr_results_path = Path(OCR_RESULTS_PATH)
    self.images_path = Path(IMAGES_PATH)
    self.json_path = Path(JSON_EXTRACT_PATH)
    self.unprocessed_path = Path(UNPROCESSED_PATH)
    self.supported_extensions = SUPPORTED_EXTENSIONS
```

**Initialization Steps:**
1. Load configuration
2. Setup file paths
3. Create output directories if needed
4. Connect to database

---

### Core Functions

#### 1. `connect_database()`

**Purpose:** Establishes connection to PostgreSQL database.

**Connection Settings:**
```python
psycopg2.connect(
    host=self.db_config['host'],
    database=self.db_config['database'],
    user=self.db_config['user'],
    password=self.db_config['password'],
    port=self.db_config.get('port', 5432),
    connect_timeout=10,
    keepalives_idle=600,
    keepalives_interval=30,
    keepalives_count=3
)
```

**Returns:** Connection object or None

**Error Handling:**
- Retry on connection failure
- Exponential backoff (10s, 20s, 30s)
- Max 3 retry attempts

---

#### 2. `get_pending_files()`

**Purpose:** Queries database for files that need OCR processing.

**Query:**
```sql
SELECT 
    id,
    email_id,
    attachment_name,
    attachment_path,
    attachment_type,
    processing_status
FROM email_attachments
WHERE processing_status = 'pending'
  AND attachment_type IN ('pdf', 'png', 'jpg', 'jpeg', 'tif', 'tiff')
ORDER BY created_at ASC
LIMIT 10;
```

**Returns:** List of file records (up to BATCH_SIZE)

**Filtering:**
- Only `pending` status
- Only supported file types
- Oldest files first (FIFO processing)

---

#### 3. `process_pdf(file_path, file_record)`

**Purpose:** Intelligent PDF processing with quality-based decision.

**Process Flow:**

```python
[1] Open PDF with PyMuPDF (fitz)
    ↓
[2] Try Direct Text Extraction
    ↓ For each page: page.get_text()
    ↓
[3] Assess Text Quality
    ↓ Check: word count, non-ASCII ratio, whitespace ratio
    ↓
[4] Decision Point:
    ├─ Quality GOOD (score > 50)?
    │   └─ Save extracted text
    │       └─ Also convert pages to PNG
    │
    └─ Quality POOR (score ≤ 50)?
        └─ Convert all pages to PNG
            └─ Perform OCR on each image
                └─ Save OCR text
```

**Quality Metrics:**

```python
def assess_text_quality(text):
    """
    Scores text quality from 0-100
    
    Penalties:
    - High non-ASCII ratio (embedded fonts/garbage)
    - Low word count (mostly whitespace)
    - High whitespace ratio (poor extraction)
    """
    score = 100
    
    # Penalty for non-ASCII characters
    non_ascii_ratio = sum(ord(c) > 127 for c in text) / len(text)
    score -= non_ascii_ratio * 50
    
    # Penalty for low word count
    word_count = len(text.split())
    if word_count < MIN_WORDS_FOR_QUALITY_CHECK:
        score -= 30
    
    # Penalty for excessive whitespace
    whitespace_ratio = text.count(' ') / len(text)
    if whitespace_ratio > 0.3:
        score -= 20
    
    return max(0, min(100, score))
```

**Outputs:**
1. **Text File:** `{filename}_extracted.txt`
2. **PNG Images:** `{filename}_page_1.png`, `{filename}_page_2.png`, ...
3. **Metadata JSON:** `{filename}_metadata.json`

**Example Metadata:**
```json
{
    "email_id": 1723,
    "attachment_id": 2045,
    "original_file": "invoice_oct_2025.pdf",
    "page_count": 3,
    "extraction_method": "direct",
    "quality_score": 85,
    "processing_time_ms": 1234,
    "text_file": "invoice_oct_2025_extracted.txt",
    "image_files": [
        "invoice_oct_2025_page_1.png",
        "invoice_oct_2025_page_2.png",
        "invoice_oct_2025_page_3.png"
    ]
}
```

---

#### 4. `process_image(file_path, file_record)`

**Purpose:** OCR processing for image files (PNG, JPG, TIF).

**Process:**

```python
[1] Load Image
    ↓ Pillow (PIL): Image.open()
    ↓
[2] Preprocess (optional)
    ↓ Resize if too large (max 4000x4000)
    ↓ Convert to grayscale if needed
    ↓
[3] Perform OCR
    ↓ pytesseract.image_to_string()
    ↓ Languages: English + Bulgarian
    ↓
[4] Save Results
    ↓ Text → ocr_results/{filename}_extracted.txt
    └─ Metadata → json_extract/{filename}_metadata.json
```

**OCR Configuration:**
```python
custom_config = r'--oem 3 --psm 6 -l eng+bul'
text = pytesseract.image_to_string(image, config=custom_config)
```

**Parameters:**
- `--oem 3` - Use default OCR engine
- `--psm 6` - Assume uniform block of text
- `-l eng+bul` - English and Bulgarian languages

**Returns:** Extracted text string

---

#### 5. `convert_pdf_to_images(pdf_path, output_folder)`

**Purpose:** Converts each PDF page to a high-resolution PNG image.

**Process:**
```python
import fitz  # PyMuPDF

doc = fitz.open(pdf_path)
for page_num in range(len(doc)):
    page = doc[page_num]
    
    # High resolution conversion
    matrix = fitz.Matrix(300/72, 300/72)  # 300 DPI
    pix = page.get_pixmap(matrix=matrix)
    
    # Save as PNG
    output_file = f"{output_folder}/{basename}_page_{page_num + 1}.png"
    pix.save(output_file)
```

**Settings:**
- **Resolution:** 300 DPI (high quality)
- **Format:** PNG (lossless)
- **Color:** RGB (full color)

**Output:** List of created PNG file paths

---

#### 6. `save_text_result(text, output_file)`

**Purpose:** Saves extracted text to structured file location.

**File Structure:**
```
C:\CargoProcessing\processed_documents\2025\ocr_results\
└── {sender_email}\
    └── {subject}\
        └── {filename}_extracted.txt
```

**Encoding:** UTF-8 with BOM

**Content Format:**
```
=== OCR EXTRACTION RESULTS ===
File: invoice_oct_2025.pdf
Processed: 2025-11-06 15:30:45
Method: direct_extraction
Quality Score: 85

=== EXTRACTED TEXT ===

[extracted text content here]
```

**Returns:** Path to saved file

---

#### 7. `update_database_status(file_id, status, error_message=None)`

**Purpose:** Updates processing status in database.

**SQL Update:**
```sql
UPDATE email_attachments 
SET 
    processing_status = %s,
    processed_at = NOW(),
    error_message = %s
WHERE id = %s;
```

**Status Values:**
- `'processing'` - Currently being processed
- `'completed'` - Successfully processed
- `'failed'` - Processing failed

**Also Logs To:**
```sql
INSERT INTO processing_history (
    attachment_id,
    file_path,
    file_type,
    status,
    processing_time_ms,
    error_message
) VALUES (...);
```

---

#### 8. `run_continuous()`

**Purpose:** Continuous monitoring loop for processing new files.

**Loop Structure:**
```python
while True:
    try:
        # Get pending files
        pending_files = self.get_pending_files()
        
        if not pending_files:
            logger.info("No pending files. Waiting...")
            time.sleep(SLEEP_INTERVAL)
            continue
        
        # Process each file
        for file_record in pending_files:
            self.process_file(file_record)
        
        # Sleep before next check
        time.sleep(SLEEP_INTERVAL)
        
    except KeyboardInterrupt:
        logger.info("Shutting down gracefully...")
        break
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        time.sleep(60)  # Wait 1 minute on error
```

**Behavior:**
- Checks every 30 seconds (configurable)
- Processes up to 10 files per cycle
- Graceful shutdown on Ctrl+C
- Continues on errors (resilient)

---

## 🗄️ Database Integration

### Tables Updated

#### 1. `email_attachments` Table

**Read Operations:**

```sql
-- Get pending files for processing
SELECT id, email_id, attachment_name, attachment_path, attachment_type
FROM email_attachments
WHERE processing_status = 'pending'
  AND attachment_type IN ('pdf', 'png', 'jpg', 'jpeg', 'tif', 'tiff');
```

**Write Operations:**

```sql
-- Update to 'processing' status
UPDATE email_attachments
SET processing_status = 'processing',
    processing_started_at = NOW()
WHERE id = %s;

-- Update to 'completed' status
UPDATE email_attachments
SET processing_status = 'completed',
    processed_at = NOW(),
    extracted_text_path = %s,
    image_paths = %s
WHERE id = %s;

-- Update to 'failed' status
UPDATE email_attachments
SET processing_status = 'failed',
    processed_at = NOW(),
    error_message = %s,
    retry_count = retry_count + 1
WHERE id = %s;
```

---

#### 2. `processing_history` Table

**Insert Log Entry:**

```sql
INSERT INTO processing_history (
    attachment_id,
    file_path,
    file_type,
    status,
    processing_time_ms,
    error_message,
    created_at
) VALUES (
    %s,  -- attachment_id
    %s,  -- file_path
    %s,  -- file_type ('pdf', 'png', etc.)
    %s,  -- status ('completed', 'failed')
    %s,  -- processing_time_ms
    %s,  -- error_message (NULL if successful)
    NOW()
);
```

**Purpose:** 
- Audit trail of all processing attempts
- Performance metrics (processing_time_ms)
- Error tracking and diagnostics

---

## 📊 Status Management & Database State

### Overview

The OCR Processor module is a **critical transformation point** in the CargoFlow system. It converts raw files (PDFs/images) into searchable text and structured images, enabling downstream AI analysis.

### Status Lifecycle in OCR Processor

```
┌─────────────────────────────────────────────────────────────────────┐
│              OCR PROCESSOR - STATUS TRANSFORMATIONS                 │
└─────────────────────────────────────────────────────────────────────┘

[Email Fetcher] 
    ↓ Creates: processing_status = 'pending'
    ↓
┌─────────────┐
│   pending   │ ← OCR Processor READS this status
└─────────────┘
    ↓ Query: SELECT * FROM email_attachments WHERE processing_status = 'pending'
    ↓
[OCR Processor picks up file]
    ↓ UPDATE processing_status = 'processing'
    ↓
┌─────────────┐
│ processing  │ ← OCR Processor WRITES this status
└─────────────┘
    ↓ Extract text from PDF/Image
    ↓ Save to C:\CargoProcessing\
    ↓ UPDATE processing_status = 'completed'
    ↓
┌─────────────┐
│ completed   │ ← OCR Processor WRITES this status
└─────────────┘
    ↓
[Files Created]:
├─ C:\CargoProcessing\...\ocr_results\{file}_extracted.txt
├─ C:\CargoProcessing\...\images\{file}_page_1.png
└─ C:\CargoProcessing\...\json_extract\{file}_metadata.json
    ↓
[Queue Manager] ← NEXT MODULE (watches C:\CargoProcessing\)
    ↓ Detects new files
    └─ INSERT INTO processing_queue


ERROR PATH:
┌─────────────┐
│   failed    │ ← OCR Processor WRITES on error
└─────────────┘
    ↓ retry_count < MAX_RETRIES?
    ├─ YES → Reset to 'pending' (retry after delay)
    └─ NO → Permanent failure (manual intervention)
```

---

### Tables & Columns Modified

#### 1. `email_attachments` Table

**Columns READ by OCR Processor:**

| Column | Purpose | Query Example |
|--------|---------|---------------|
| `id` | Primary key | WHERE id = %s |
| `email_id` | Link to parent email | For metadata |
| `attachment_name` | Original filename | For output naming |
| `attachment_path` | Input file location | C:\CargoAttachments\... |
| `attachment_type` | File extension filter | WHERE attachment_type IN ('pdf', 'png', ...) |
| `processing_status` | **TRIGGER FIELD** | WHERE processing_status = 'pending' |
| `retry_count` | Retry tracking | Check < MAX_RETRIES |

**Columns WRITTEN by OCR Processor:**

| Column | From Value | To Value | When | Notes |
|--------|------------|----------|------|-------|
| `processing_status` | `'pending'` | `'processing'` | Start of processing | Prevents double-processing |
| `processing_status` | `'processing'` | `'completed'` | Success | Signals completion |
| `processing_status` | `'processing'` | `'failed'` | Error | Enables retry logic |
| `processing_started_at` | NULL | NOW() | Start | Timestamp tracking |
| `processed_at` | NULL | NOW() | End (success or fail) | Completion time |
| `extracted_text_path` | NULL | File path | Success | Points to .txt file |
| `image_paths` | NULL | JSON array | Success (PDF only) | Points to .png files |
| `error_message` | NULL | Error text | Failure | For debugging |
| `retry_count` | N | N+1 | Failure | Retry tracking |

---

#### 2. `processing_history` Table

**Operation:** INSERT (one record per processing attempt)

| Column | Value | Notes |
|--------|-------|-------|
| `attachment_id` | email_attachments.id | Links to source file |
| `file_path` | Full input path | C:\CargoAttachments\... |
| `file_type` | Extension | 'pdf', 'png', 'jpg', etc. |
| `status` | 'completed' or 'failed' | Final outcome |
| `processing_time_ms` | Milliseconds | Performance metric |
| `error_message` | Error text or NULL | Only on failure |
| `created_at` | NOW() | Processing timestamp |

**Purpose:**
- Complete audit trail
- Performance analytics
- Error pattern detection
- Retry decision data

---

### Status Values & Meanings

#### `email_attachments.processing_status`

| Status | Set By | Meaning | Next Action |
|--------|--------|---------|-------------|
| `pending` | Email Fetcher | File saved, awaiting OCR | **OCR Processor picks it up** |
| **`processing`** | **OCR Processor** | **Currently extracting text** | **Wait for completion** |
| **`completed`** | **OCR Processor** | **Text extraction successful** | **Queue Manager processes** |
| `failed` | OCR Processor | OCR failed (will retry) | Retry or manual check |
| `queued` | Queue Manager | File sent to n8n (downstream) | Not OCR's concern |

**OCR Processor's Responsibility:**
- **READS:** `pending` status to find work
- **WRITES:** `processing` → `completed` (or `failed`)

---

### Module Dependency Chain

```
┌──────────────────┐
│ Email Fetcher    │ ← Module 1
│                  │
└──────────────────┘
         │
         │ Creates:
         │ - email_attachments.processing_status = 'pending'
         │ - Files in C:\CargoAttachments\
         │
         ↓
┌──────────────────┐
│ OCR Processor    │ ← YOU ARE HERE (Module 2)
│                  │
└──────────────────┘
         │
         │ READS:
         │ - WHERE processing_status = 'pending'
         │ - AND attachment_type IN ('pdf', 'png', 'jpg', 'tif')
         │
         │ WRITES:
         │ - processing_status = 'processing' → 'completed'
         │ - extracted_text_path = '{file_path}'
         │ - image_paths = ['page_1.png', 'page_2.png', ...]
         │
         │ CREATES FILES:
         │ - C:\CargoProcessing\...\ocr_results\{file}_extracted.txt
         │ - C:\CargoProcessing\...\images\{file}_page_1.png
         │ - C:\CargoProcessing\...\json_extract\{file}_metadata.json
         │
         ↓
┌──────────────────┐
│ Queue Managers   │ ← Module 4 & 5
│                  │
└──────────────────┘
         │
         │ WATCHES:
         │ - C:\CargoProcessing\ocr_results\ (text files)
         │ - C:\CargoProcessing\images\ (PNG files)
         │
         │ ACTION:
         │ - INSERT INTO processing_queue (status='pending')
         │ - Triggers PostgreSQL NOTIFY → n8n
         │
         ↓
┌──────────────────┐
│ n8n Workflows    │ ← Module 6
│                  │
└──────────────────┘
         │
         │ AI Analysis:
         │ - Categorizes documents
         │ - Extracts contract numbers
         │ - Updates email_attachments
         │
         ↓
    [AI Categorization Complete]
```

---

### What OCR Processor Does and Does NOT Do

**OCR Processor DOES:**

✅ **Reads:** `processing_status = 'pending'` from `email_attachments`  
✅ **Writes:** `processing_status = 'processing'` (in progress)  
✅ **Writes:** `processing_status = 'completed'` (success)  
✅ **Writes:** `processing_status = 'failed'` (error)  
✅ **Creates:** Text files in `C:\CargoProcessing\ocr_results\`  
✅ **Creates:** PNG images in `C:\CargoProcessing\images\`  
✅ **Creates:** Metadata JSON in `C:\CargoProcessing\json_extract\`  
✅ **Logs:** Processing attempts to `processing_history`  

**OCR Processor does NOT:**

❌ **Create** `processing_status = 'pending'` - Email Fetcher does this  
❌ **Update** `processing_status = 'queued'` - Queue Manager does this  
❌ **Update** `processing_status = 'classified'` - n8n does this  
❌ **Add to** `processing_queue` table - Queue Manager does this  
❌ **Categorize** documents - n8n AI does this  
❌ **Extract** contract numbers - n8n AI does this  

---

### Checking Status After OCR Processor Runs

#### Query 1: Check Processing Progress

```sql
-- Count files by status
SELECT 
    processing_status,
    COUNT(*) as count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) as percentage
FROM email_attachments
WHERE attachment_type IN ('pdf', 'png', 'jpg', 'tif')
GROUP BY processing_status
ORDER BY count DESC;
```

**Expected Result:**
```
processing_status | count | percentage
------------------|-------|------------
completed         | 185   | 62.5%
pending           | 95    | 32.1%
processing        | 12    | 4.1%
failed            | 4     | 1.3%
```

---

#### Query 2: Check Recently Completed Files

```sql
-- Files completed in last hour
SELECT 
    id,
    attachment_name,
    attachment_type,
    processing_status,
    processed_at,
    extracted_text_path
FROM email_attachments
WHERE processing_status = 'completed'
  AND processed_at > NOW() - INTERVAL '1 hour'
ORDER BY processed_at DESC
LIMIT 20;
```

**Expected Result:**
- Recently processed files visible
- `extracted_text_path` populated
- `processed_at` timestamp recent

---

#### Query 3: Check Files Currently Processing

```sql
-- Files in 'processing' status
SELECT 
    id,
    attachment_name,
    processing_status,
    processing_started_at,
    NOW() - processing_started_at as duration
FROM email_attachments
WHERE processing_status = 'processing'
ORDER BY processing_started_at ASC;
```

**Expected Result:**
- Should be empty or very few files
- If files stuck > 5 minutes → potential issue

---

#### Query 4: Check Failed Files

```sql
-- Failed files with error messages
SELECT 
    id,
    attachment_name,
    attachment_type,
    retry_count,
    error_message,
    processed_at
FROM email_attachments
WHERE processing_status = 'failed'
ORDER BY processed_at DESC
LIMIT 10;
```

**Expected Result:**
- Few failed files (< 5%)
- Check `error_message` for patterns
- `retry_count` < MAX_RETRIES → will retry

---

#### Query 5: Verify Output Files on Disk

```sql
-- Get extracted text paths
SELECT 
    attachment_name,
    extracted_text_path,
    image_paths
FROM email_attachments
WHERE processing_status = 'completed'
  AND processed_at > NOW() - INTERVAL '1 hour';
```

**Verification:**
```bash
# Windows
dir "C:\CargoProcessing\processed_documents\2025\ocr_results\sender@company.com\Subject\"

# Linux
ls -la "/mnt/c/CargoProcessing/processed_documents/2025/ocr_results/sender@company.com/Subject/"
```

**Expected:**
- `{filename}_extracted.txt` files exist
- `{filename}_page_1.png` files exist (for PDFs)
- `{filename}_metadata.json` files exist

---

### Status Transition Example

**Initial State (from Email Fetcher):**

```sql
SELECT id, attachment_name, processing_status, extracted_text_path
FROM email_attachments
WHERE id = 2045;
```

**Result:**
```
id   | attachment_name       | processing_status | extracted_text_path
-----|----------------------|-------------------|--------------------|  
2045 | invoice_oct_2025.pdf | pending           | NULL
```

---

**After OCR Processor Starts:**

```sql
-- OCR Processor executes:
UPDATE email_attachments 
SET processing_status = 'processing', processing_started_at = NOW()
WHERE id = 2045;
```

**Result:**
```
2045 | invoice_oct_2025.pdf | processing        | NULL
```

---

**After OCR Processor Completes:**

```sql
-- OCR Processor executes:
UPDATE email_attachments 
SET 
    processing_status = 'completed',
    processed_at = NOW(),
    extracted_text_path = 'C:\CargoProcessing\...\invoice_oct_2025_extracted.txt',
    image_paths = '["invoice_oct_2025_page_1.png", "invoice_oct_2025_page_2.png"]'
WHERE id = 2045;
```

**Result:**
```
2045 | invoice_oct_2025.pdf | completed         | C:\CargoProcessing\...\invoice_oct_2025_extracted.txt
```

---

**After Queue Manager Processes:**

```sql
-- Queue Manager executes (in processing_queue):
INSERT INTO processing_queue (attachment_id, file_path, status)
VALUES (2045, 'C:\CargoProcessing\...\invoice_oct_2025_extracted.txt', 'pending');
```

**Result:**
```
email_attachments: processing_status = 'completed' (unchanged)
processing_queue: New record with status = 'pending'
```

---

### Troubleshooting Status Issues

#### Issue 1: Files Stuck in 'pending'

**Symptoms:**
```sql
SELECT COUNT(*) FROM email_attachments WHERE processing_status = 'pending';
-- Returns: 285 (many pending files)
```

**Causes:**
1. OCR Processor not running
2. OCR Processor crashed
3. Files not accessible on disk
4. Database connection lost

**Solution:**

1. **Check if OCR Processor is running:**
   ```bash
   # Windows Task Manager or:
   tasklist | findstr python
   
   # Linux:
   ps aux | grep ocr_processor
   ```

2. **Check OCR Processor logs:**
   ```bash
   tail -f document_processing.log
   # Look for errors or "No pending files" messages
   ```

3. **Restart OCR Processor:**
   ```bash
   cd C:\Python_project\CargoFlow\Cargoflow_OCR
   venv\Scripts\activate
   python ocr_processor.py
   ```

4. **Verify files exist:**
   ```sql
   SELECT attachment_path FROM email_attachments 
   WHERE processing_status = 'pending' LIMIT 5;
   ```
   Then check if those files actually exist on disk.

---

#### Issue 2: Files Stuck in 'processing'

**Symptoms:**
```sql
SELECT 
    id, 
    attachment_name, 
    processing_started_at,
    NOW() - processing_started_at as stuck_duration
FROM email_attachments
WHERE processing_status = 'processing'
  AND processing_started_at < NOW() - INTERVAL '10 minutes';
-- Returns: Files stuck > 10 minutes
```

**Causes:**
1. OCR Processor crashed mid-process
2. Very large file causing timeout
3. Corrupted file causing hang

**Solution:**

1. **Reset stuck files to pending:**
   ```sql
   UPDATE email_attachments
   SET processing_status = 'pending',
       processing_started_at = NULL
   WHERE processing_status = 'processing'
     AND processing_started_at < NOW() - INTERVAL '10 minutes';
   ```

2. **Check logs for specific file errors:**
   ```bash
   grep "attachment_id_2045" document_processing.log
   ```

3. **Manually verify file:**
   - Try opening the file
   - Check file size (> 100MB?)
   - Check file corruption

---

#### Issue 3: High Failure Rate

**Symptoms:**
```sql
SELECT 
    COUNT(*) as failed_count,
    COUNT(*) * 100.0 / (SELECT COUNT(*) FROM email_attachments WHERE attachment_type IN ('pdf', 'png')) as failure_rate
FROM email_attachments
WHERE processing_status = 'failed';
-- Returns: failure_rate > 10%
```

**Causes:**
1. Tesseract OCR not installed/configured
2. Corrupted files
3. Unsupported file formats
4. Disk space full

**Solution:**

1. **Check Tesseract installation:**
   ```bash
   tesseract --version
   # Should output version info
   ```

2. **Check common error messages:**
   ```sql
   SELECT error_message, COUNT(*) as count
   FROM email_attachments
   WHERE processing_status = 'failed'
   GROUP BY error_message
   ORDER BY count DESC;
   ```

3. **Review failed files:**
   ```sql
   SELECT id, attachment_name, attachment_type, error_message
   FROM email_attachments
   WHERE processing_status = 'failed'
   LIMIT 10;
   ```

4. **Manually test a failed file:**
   ```python
   from ocr_processor import OCRProcessor
   processor = OCRProcessor()
   processor.process_pdf("path/to/failed/file.pdf", file_record)
   ```

---

#### Issue 4: No Output Files Created

**Symptoms:**
- Database shows `processing_status = 'completed'`
- But `extracted_text_path` is NULL or empty
- Or files don't exist on disk

**Causes:**
1. Output directory permissions
2. Disk space full
3. Path configuration error

**Solution:**

1. **Check output directories exist:**
   ```bash
   # Windows
   dir "C:\CargoProcessing\processed_documents\2025\"
   
   # Should see: ocr_results, images, json_extract
   ```

2. **Check disk space:**
   ```bash
   # Windows
   wmic logicaldisk get size,freespace,caption
   
   # Linux
   df -h
   ```

3. **Check path configuration:**
   ```python
   # In config.py
   print(OCR_RESULTS_PATH)
   print(IMAGES_PATH)
   print(JSON_EXTRACT_PATH)
   ```

4. **Manually create directories:**
   ```bash
   mkdir -p "C:\CargoProcessing\processed_documents\2025\ocr_results"
   mkdir -p "C:\CargoProcessing\processed_documents\2025\images"
   mkdir -p "C:\CargoProcessing\processed_documents\2025\json_extract"
   ```

---

### Summary: OCR Processor's Database State

**What OCR Processor Reads:**

| Table | Query | Purpose |
|-------|-------|---------|  
| `email_attachments` | `WHERE processing_status = 'pending'` | Find files to process |
| `email_attachments` | `WHERE attachment_type IN ('pdf', 'png', ...)` | Filter by supported types |

**What OCR Processor Writes:**

| Table | Operation | Fields Updated |
|-------|-----------|----------------|
| `email_attachments` | UPDATE | `processing_status`: `'pending'` → `'processing'` → `'completed'` (or `'failed'`) |
| `email_attachments` | UPDATE | `processing_started_at`, `processed_at`, `extracted_text_path`, `image_paths`, `error_message`, `retry_count` |
| `processing_history` | INSERT | Complete processing log entry |

**Critical Status Transitions:**

```
pending → processing → completed
                    └→ failed (if error)
```

This status flow is the **trigger** for the Queue Manager to pick up the processed files.

**Next Module Dependency:**
- Text Queue Manager (watches `ocr_results/` for `.txt` files)
- Image Queue Manager (watches `images/` for `.png` files)

Both modules wait for OCR Processor to create files on disk, then add them to `processing_queue` for n8n analysis.

---

## 📁 File Storage Structure

### Input Files: `C:\CargoAttachments\`

**Structure** (created by Email Fetcher):
```
C:\CargoAttachments\
└── sender@company.com\
    └── 2025-11\
        └── Invoice_October_20251106_143022\
            ├── email_metadata.json
            ├── email_body.html
            └── invoice_oct_2025.pdf  ← OCR Processor reads this
```

---

### Output Files: `C:\CargoProcessing\`

**Structure** (created by OCR Processor):

```
C:\CargoProcessing\
├── processed_documents\
│   └── 2025\
│       ├── ocr_results\              ← Text extraction output
│       │   └── sender@company.com\
│       │       └── Invoice_October_20251106_143022\
│       │           └── invoice_oct_2025_extracted.txt
│       │
│       ├── images\                   ← PNG conversion output (PDF pages)
│       │   └── sender@company.com\
│       │       └── Invoice_October_20251106_143022\
│       │           ├── invoice_oct_2025_page_1.png
│       │           ├── invoice_oct_2025_page_2.png
│       │           └── invoice_oct_2025_page_3.png
│       │
│       └── json_extract\             ← Processing metadata
│           └── sender@company.com\
│               └── Invoice_October_20251106_143022\
│                   └── invoice_oct_2025_metadata.json
│
└── unprocessed\
    └── unprocessed_ocr\              ← Failed files moved here
        ├── corrupted_file.pdf
        └── unsupported_format.xyz
```

---

### File Naming Conventions

| File Type | Pattern | Example |
|-----------|---------|---------|  
| Extracted Text | `{original_name}_extracted.txt` | `invoice_oct_2025_extracted.txt` |
| PNG Images | `{original_name}_page_{N}.png` | `invoice_oct_2025_page_1.png` |
| Metadata | `{original_name}_metadata.json` | `invoice_oct_2025_metadata.json` |

---

## 🛡️ Error Handling & Resilience

### Retry Logic

**Configuration:**
```python
MAX_RETRIES = 3
RETRY_DELAY = 60  # seconds
RETRY_BACKOFF = 2  # exponential multiplier
```

**Retry Flow:**
```python
if retry_count < MAX_RETRIES:
    delay = RETRY_DELAY * (RETRY_BACKOFF ** retry_count)
    # Wait: 60s, 120s, 240s
    
    # Reset to pending for retry
    UPDATE email_attachments
    SET processing_status = 'pending',
        retry_count = retry_count + 1
    WHERE id = %s;
else:
    # Permanent failure
    # Keep status = 'failed'
    # Manual intervention required
```

---

### Error Recovery Strategies

| Error Type | Detection | Recovery | Max Retries |
|------------|-----------|----------|-------------|
| **File Not Found** | `FileNotFoundError` | Log error, mark failed | No retry |
| **Corrupted PDF** | `fitz.fitz.FileDataError` | Try OCR mode, or fail | 1 |
| **OCR Engine Error** | `pytesseract.TesseractError` | Check Tesseract install | 3 |
| **Database Connection Lost** | `psycopg2.OperationalError` | Reconnect automatically | 5 |
| **Disk Space Full** | `OSError: [Errno 28]` | Alert, wait for cleanup | No retry |
| **Timeout (Large File)** | Processing > 5 minutes | Kill process, retry | 2 |
| **Memory Error** | `MemoryError` | Reduce image resolution | 2 |

---

## 📊 Logging & Monitoring

### Log Configuration

**Log File:** `document_processing.log`  
**Location:** `C:\Python_project\CargoFlow\Cargoflow_OCR\`  
**Rotation:** 10 MB per file, keeps 5 backups  
**Encoding:** UTF-8  
**Format:** `%(asctime)s - %(levelname)s - [%(funcName)s] %(message)s`

**Log Levels:**
- `DEBUG` - Detailed processing steps
- `INFO` - Normal operations
- `WARNING` - Recoverable issues
- `ERROR` - Processing failures

---

### Key Log Messages

**Startup:**
```
OCR PROCESSOR - CONTINUOUS MODE
Database: Cargo_mail
Input: C:\CargoAttachments\
Output: C:\CargoProcessing\
Check interval: 30 seconds
```

**Processing:**
```
Found 5 pending files for processing
Processing attachment 2045: invoice_oct_2025.pdf
  - File type: pdf
  - Size: 245 KB
  - Direct extraction attempt...
  - Quality score: 85 (good)
  - Saved text: invoice_oct_2025_extracted.txt
  - Created 3 PNG images
  - Processing time: 1.23s
  - Status updated: completed
```

**Errors:**
```
ERROR processing attachment 2048: corrupted_file.pdf
  - Error: fitz.fitz.FileDataError: cannot open document
  - Retry count: 1/3
  - Status updated: pending (will retry in 60s)
```

---

## 🚀 Usage & Deployment

### Installation

**Prerequisites:**
- Python 3.11+
- PostgreSQL 17
- Tesseract OCR installed

**Steps:**

```bash
# 1. Navigate to module directory
cd C:\Python_project\CargoFlow\Cargoflow_OCR

# 2. Create virtual environment
python -m venv venv

# 3. Activate virtual environment
venv\Scripts\activate  # Windows
# source venv/bin/activate  # Linux/Mac

# 4. Install Python dependencies
pip install -r requirements.txt

# 5. Install Tesseract OCR (Windows)
# Download from: https://github.com/UB-Mannheim/tesseract/wiki
# Install to: C:\Program Files\Tesseract-OCR\
# Add to PATH or configure in script

# 6. Configure database
# Edit config.py with your database credentials

# 7. Test Tesseract installation
tesseract --version
# Should output version info

# 8. Test database connection
python -c "from ocr_processor import OCRProcessor; p = OCRProcessor(); p.connect_database()"
```

---

### Running the Module

#### Continuous Mode (Recommended)

```bash
cd C:\Python_project\CargoFlow\Cargoflow_OCR
venv\Scripts\activate
python ocr_processor.py
```

**Behavior:**
- Runs indefinitely
- Checks for new files every 30 seconds
- Processes up to 10 files per cycle
- Graceful shutdown with Ctrl+C

---

## 🔧 Troubleshooting

### Common Issues

#### Issue 1: Tesseract Not Found

**Symptoms:**
```
pytesseract.pytesseract.TesseractNotFoundError: tesseract is not installed
```

**Solutions:**

1. **Install Tesseract:**
   ```bash
   # Windows: Download installer
   https://github.com/UB-Mannheim/tesseract/wiki
   
   # Linux (Ubuntu/Debian):
   sudo apt-get install tesseract-ocr
   
   # macOS:
   brew install tesseract
   ```

2. **Configure Path:**
   ```python
   # In ocr_processor.py
   pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'
   ```

3. **Verify Installation:**
   ```bash
   tesseract --version
   tesseract --list-langs
   ```

---

#### Issue 2: Poor OCR Quality

**Symptoms:**
- Extracted text is gibberish
- Many unrecognized characters
- Low quality scores

**Solutions:**

1. **Check Image Quality:**
   - Increase PDF DPI: `PDF_DPI = 600`
   - Ensure images are not blurry

2. **Adjust OCR Config:**
   ```python
   # Try different PSM modes
   custom_config = r'--oem 3 --psm 3 -l eng+bul'  # Auto page segmentation
   ```

3. **Preprocess Images:**
   ```python
   # Convert to grayscale
   image = image.convert('L')
   
   # Increase contrast
   from PIL import ImageEnhance
   enhancer = ImageEnhance.Contrast(image)
   image = enhancer.enhance(2.0)
   ```

---

#### Issue 3: Memory Errors with Large PDFs

**Symptoms:**
```
MemoryError: cannot allocate memory
```

**Solutions:**

1. **Reduce Image Resolution:**
   ```python
   PDF_DPI = 200  # Instead of 300
   ```

2. **Process Pages One at a Time:**
   ```python
   # Don't load entire document into memory
   for page_num in range(len(doc)):
       page = doc[page_num]
       # Process page
       page = None  # Free memory
   ```

3. **Increase System RAM:**
   - Upgrade hardware
   - Or close other applications

---

## 🔗 Related Documentation

- [Database Schema](../DATABASE_SCHEMA.md) - `email_attachments` and `processing_history` tables
- [Email Fetcher](01_EMAIL_FETCHER.md) - Previous module (creates pending files)
- [Queue Managers](04_QUEUE_MANAGERS.md) - Next modules (process output files)
- [Status Flow Map](../docs/STATUS_FLOW_MAP.md) - Complete system status flow

---

**Module Status:** ✅ Production Ready  
**Last Updated:** November 06, 2025  
**Maintained by:** CargoFlow DevOps Team
