# Office Processor Module - Office Document Text Extraction

**Module:** Cargoflow_Office  
**Script:** `office_processor.py`  
**Status:** ✅ Production Ready  
**Last Updated:** November 12, 2025

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

The Office Processor module is the **third component** in the CargoFlow system. It processes Microsoft Office documents (Word, Excel) and other text-based files to extract text content, making documents searchable and analyzable by AI.

**Primary Functions:**
1. **Extract text from Word documents** (DOCX, DOC)
2. **Extract text from Excel spreadsheets** (XLSX, XLS)
3. **Process text files** (TXT, RTF, XML)
4. **Handle OpenDocument formats** (ODT)
5. **Create searchable text files** for AI analysis
6. **Monitor file system** for new Office documents

### Key Features

- ✅ **File System Watcher** - Monitors directories for new Office files
- ✅ **Multi-format Support** - DOCX, DOC, XLSX, XLS, TXT, RTF, XML, ODT
- ✅ **Intelligent Extraction** - Format-specific text extraction methods
- ✅ **Encoding Detection** - Handles multiple text encodings
- ✅ **Database Linking** - Links files to email records via `email_id`
- ✅ **Error Recovery** - Moves problematic files to unprocessed folder
- ✅ **Continuous Monitoring** - Runs as background service
- ✅ **Shared Output Structure** - Same structure as OCR Processor

---

## 🏗️ Architecture & Data Flow

### High-Level Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                  OFFICE PROCESSOR MODULE                        │
└─────────────────────────────────────────────────────────────────┘

[1] File System Watcher (watchdog)
    ↓ Monitors: C:\CargoAttachments\
    ↓ Events: on_created, on_modified
    ↓ Filter: .docx, .doc, .xlsx, .xls, .txt, .rtf, .xml, .odt
    ↓
[2] File Detection:
    ├─ Skip temporary files (~$...)
    ├─ Check if already processed (success_log.txt)
    └─ Wait for file to be ready (not locked)
    ↓
[3] Extract email_id from file path:
    ├─ Query PostgreSQL by attachment_folder
    ├─ OR match by sender_email + subject
    └─ Link file to email record
    ↓
[4] Text Extraction (format-specific):
    ├─ DOCX → python-docx (paragraph extraction)
    ├─ DOC → win32com.client (COM automation)
    ├─ XLSX → openpyxl (sheet + cell iteration)
    ├─ XLS → xlrd (legacy Excel format)
    ├─ TXT/RTF/XML → text read with encoding detection
    └─ ODT → pypandoc (requires Pandoc)
    ↓
[5] Save Results:
    ├─ Text → C:\CargoProcessing\...\ocr_results\{file}_extracted.txt
    └─ Metadata → JSON header with email_id, timestamps
    ↓
[6] Log Success/Error:
    ├─ success_log.txt (prevents reprocessing)
    └─ error_log.txt (debugging)
    ↓
[7] Continue Monitoring
    ↓ Wait for next file system event
    └─ [REPEAT from 1]
```

### Component Interaction

```
┌──────────────────┐       ┌──────────────────┐       ┌──────────────────┐
│  Email Fetcher   │──────►│Office Processor  │──────►│   Queue Manager  │
│  (saves files)   │       │(extract text)    │       │   (AI analysis)  │
└──────────────────┘       └──────────────────┘       └──────────────────┘
         │                          │                           │
         │                          ↓                           │
         │              ┌──────────────────┐                   │
         │              │   PostgreSQL     │                   │
         │              │    (emails)      │                   │
         │              │  (email_id link) │                   │
         │              └──────────────────┘                   │
         │                          │                           │
         ↓                          ↓                           ↓
┌─────────────────────────────────────────────────────────────────┐
│                    File System                                  │
│  Input: C:\CargoAttachments\                                    │
│  Output: C:\CargoProcessing\ocr_results\ (SHARED with OCR)     │
└─────────────────────────────────────────────────────────────────┘
```

### Key Architectural Differences from OCR Processor

| Aspect | OCR Processor | Office Processor |
|--------|---------------|------------------|
| **Trigger** | Database polling (`processing_status='pending'`) | File system watcher (watchdog) |
| **Status Updates** | Updates `email_attachments.processing_status` | No status updates to database |
| **Input Filter** | SQL query with file type filter | File extension filter in watcher |
| **Processing Model** | Batch processing (10 files/cycle) | Event-driven (immediate on file creation) |
| **Database Usage** | Heavy (READ + WRITE) | Minimal (only email_id lookup) |
| **Output Location** | `ocr_results/` | `ocr_results/` (SAME as OCR) |

**CRITICAL:** Office Processor does NOT update `processing_status` in database. It operates independently via file system monitoring.

---

## ⚙️ Configuration

### Configuration: Embedded in `office_processor.py`

**File Paths Configuration:**

```python
# Input directory (from Email Fetcher)
EMAIL_ATTACHMENTS_ROOT = Path(r'C:\CargoAttachments')

# Output directory (SHARED with OCR Processor)
PROCESSED_DOCS_BASE = Path(r'C:\CargoProcessing\processed_documents')
CURRENT_YEAR = str(datetime.now().year)
OCR_RESULTS_BASE_DIR = PROCESSED_DOCS_BASE / CURRENT_YEAR / 'ocr_results'

# Error handling
UNPROCESSED_DIR = Path(r'C:\CargoProcessing\unprocessed\unprocessed_office')
```

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

**Processing Configuration:**

```python
# Supported file types
class DocumentType(Enum):
    DOCX = ".docx"
    DOC = ".doc"
    XLSX = ".xlsx"
    XLS = ".xls"
    RTF = ".rtf"
    TXT = ".txt"
    XML = ".xml"
    ODT = ".odt"

# File timeout
FILE_TIMEOUT = 10  # seconds to wait for file to be ready
```

### Dependencies

**Python Packages:**

```
python-docx>=0.8.11  # DOCX extraction
openpyxl>=3.1.0      # XLSX extraction
xlrd>=2.0.1          # XLS extraction (legacy)
pywin32>=305         # DOC extraction (Windows COM)
pypandoc>=1.11       # ODT extraction (optional)
watchdog>=3.0.0      # File system monitoring
psycopg2-binary>=2.9.9  # PostgreSQL
pathlib>=1.0.1
```

**External Software:**

- **Microsoft Word** (required for DOC files)
  - Windows: COM automation via `win32com.client`
  - Office must be installed on the system

- **Pandoc** (optional, for ODT files)
  - Windows: Download from https://pandoc.org/installing.html
  - Linux: `sudo apt-get install pandoc`

**System Requirements:**

- **Windows OS** (for DOC processing via COM)
- **Python 3.11+**
- **Microsoft Office** (for .doc files)
- **Pandoc** (for .odt files, optional)

---

## 🔧 Key Components

### Class: `Config`

Configuration dataclass for processing settings.

```python
@dataclass
class Config:
    supported_extensions: set = None
    file_timeout: int = 10
    
    def __post_init__(self):
        if self.supported_extensions is None:
            self.supported_extensions = {ext.value for ext in DocumentType}
```

**Purpose:** Centralized configuration for supported file types and timeouts.

---

### Class: `TextExtractor`

Main text extraction engine supporting multiple Office formats.

#### Methods:

##### 1. `extract_from_docx(file_path: Path) -> Optional[str]`

**Purpose:** Extract text from modern Word documents (.docx).

**Method:**
```python
document = Document(str(file_path))
text = ' '.join(paragraph.text for paragraph in document.paragraphs)
return clean_text(text)
```

**Library:** `python-docx`

**Process:**
1. Open DOCX file
2. Iterate through all paragraphs
3. Join paragraph text
4. Clean and return

**Returns:** Extracted text string or None on error

---

##### 2. `extract_from_doc(file_path: Path) -> Optional[str]`

**Purpose:** Extract text from legacy Word documents (.doc).

**Method:**
```python
pythoncom.CoInitialize()
word = win32com.client.DispatchEx("Word.Application")
word.Visible = False
word.DisplayAlerts = False

doc = word.Documents.Open(str(file_path.absolute()))
text = doc.Content.Text
doc.Close(False)
```

**Library:** `win32com.client` (Windows COM automation)

**Process:**
1. Initialize COM
2. Launch Word application (invisible)
3. Open document
4. Extract text content
5. Close document
6. Quit Word application
7. Uninitialize COM

**CRITICAL:** Must clean up COM objects properly to prevent memory leaks.

**Returns:** Extracted text string or None on error

---

##### 3. `extract_from_xlsx(file_path: Path) -> Optional[str]`

**Purpose:** Extract text from modern Excel spreadsheets (.xlsx).

**Method:**
```python
workbook = openpyxl.load_workbook(str(file_path), data_only=True)
text = []

for sheet in workbook.sheetnames:
    worksheet = workbook[sheet]
    text.append(f"\n=== Sheet: {sheet} ===\n")
    
    for row in worksheet.iter_rows(values_only=True):
        row_text = ' '.join([str(cell) if cell is not None else '' for cell in row])
        if row_text.strip():
            text.append(row_text)

return clean_text('\n'.join(text))
```

**Library:** `openpyxl`

**Process:**
1. Load workbook (data_only=True for calculated values)
2. Iterate through all sheets
3. For each sheet, iterate through rows
4. Join cell values
5. Format with sheet headers

**Output Format:**
```
=== Sheet: Sheet1 ===
Name    Age    City
John    25     Sofia
Maria   30     Plovdiv

=== Sheet: Sheet2 ===
Product    Price    Quantity
Laptop    1500    5
```

**Returns:** Formatted text string or None on error

---

##### 4. `extract_from_xls(file_path: Path) -> Optional[str]`

**Purpose:** Extract text from legacy Excel spreadsheets (.xls).

**Method:**
```python
workbook = xlrd.open_workbook(str(file_path))
text = []

for sheet_index in range(workbook.nsheets):
    sheet = workbook.sheet_by_index(sheet_index)
    text.append(f"\n=== Sheet: {sheet.name} ===\n")
    
    for row in range(sheet.nrows):
        row_values = sheet.row_values(row)
        row_text = ' '.join(str(cell) for cell in row_values if cell)
        if row_text.strip():
            text.append(row_text)
```

**Library:** `xlrd` (legacy Excel format)

**Returns:** Formatted text string or None on error

---

##### 5. `extract_from_txt(file_path: Path) -> Optional[str]`

**Purpose:** Extract text from plain text files with encoding detection.

**Method:**
```python
# Try UTF-8 first
try:
    return clean_text(file_path.read_text(encoding='utf-8'))
except UnicodeDecodeError:
    # Try alternative encodings
    for encoding in ['cp1251', 'iso-8859-1', 'windows-1252']:
        try:
            return clean_text(file_path.read_text(encoding=encoding))
        except UnicodeDecodeError:
            continue
```

**Supported Encodings:**
1. UTF-8 (modern standard)
2. CP1251 (Cyrillic Windows)
3. ISO-8859-1 (Latin-1)
4. Windows-1252 (Western European)

**Returns:** Decoded text string or None if all encodings fail

---

##### 6. `extract_from_odt(file_path: Path) -> Optional[str]`

**Purpose:** Extract text from OpenDocument Text files (.odt).

**Method:**
```python
if not PYPANDOC_AVAILABLE:
    logger.warning(f"pypandoc not available, skipping ODT file")
    return None

text = pypandoc.convert_file(str(file_path), 'plain')
return clean_text(text)
```

**Library:** `pypandoc` (requires Pandoc installation)

**Requirements:**
- Pandoc must be installed on system
- pypandoc Python package

**Returns:** Plain text string or None on error

---

##### 7. `extract(file_path: Path) -> Optional[str]`

**Purpose:** Main extraction dispatcher - selects appropriate method based on file extension.

**Method:**
```python
try:
    doc_type = DocumentType(file_path.suffix.lower())
except ValueError:
    logger.warning(f"Unsupported file type: {file_path.suffix}")
    return None

extractors = {
    DocumentType.DOCX: self.extract_from_docx,
    DocumentType.DOC: self.extract_from_doc,
    DocumentType.XLSX: self.extract_from_xlsx,
    DocumentType.XLS: self.extract_from_xls,
    DocumentType.RTF: self.extract_from_txt,
    DocumentType.TXT: self.extract_from_txt,
    DocumentType.XML: self.extract_from_txt,
    DocumentType.ODT: self.extract_from_odt,
}

extractor = extractors.get(doc_type)
if extractor:
    return extractor(file_path)
return None
```

**Returns:** Extracted text or None

---

### Helper Functions

#### 1. `get_email_id_from_path(file_path: Path) -> Optional[int]`

**Purpose:** Link file to email record in database by extracting email_id from path.

**Method:**
```python
conn = psycopg2.connect(**DB_CONFIG)
cursor = conn.cursor()

# Strategy 1: Exact match by attachment_folder
attachment_folder = str(file_path.parent)
cursor.execute("""
    SELECT id FROM emails
    WHERE attachment_folder = %s
    LIMIT 1
""", (attachment_folder,))

result = cursor.fetchone()

# Strategy 2: Match by sender + subject (if exact match fails)
if not result:
    # Extract sender (has @) and subject from path
    parts = file_path.parts
    sender = None
    subject = None
    
    for i, part in enumerate(parts):
        if '@' in part:
            sender = part
            if i + 1 < len(parts):
                subject = parts[i + 1]
            break
    
    if sender and subject:
        subject_clean = subject.replace('_', ' ')
        cursor.execute("""
            SELECT id FROM emails
            WHERE sender_email = %s
            AND subject LIKE %s
            LIMIT 1
        """, (sender, f'%{subject_clean}%'))
        
        result = cursor.fetchone()
```

**Matching Strategies:**
1. **Exact:** Match `attachment_folder` column
2. **Fuzzy:** Match `sender_email` + `subject` (LIKE)

**Returns:** `email_id` (int) or None

**Usage:** Creates link between file and email for downstream analysis.

---

#### 2. `is_file_ready(file_path: Path, timeout: int = 10) -> bool`

**Purpose:** Wait for file to be fully written (not locked by another process).

**Method:**
```python
start_time = time.time()
while time.time() - start_time < timeout:
    try:
        with open(file_path, 'rb') as f:
            f.read()
        return True
    except (IOError, PermissionError):
        time.sleep(0.1)
return False
```

**Returns:** True if file is accessible, False if timeout

---

#### 3. `is_file_processed(file_path: Path) -> bool`

**Purpose:** Check if file was already processed to prevent duplicates.

**Method:**
```python
if not SUCCESS_LOG_FILE.exists():
    return False
with open(SUCCESS_LOG_FILE, 'r', encoding='utf-8', errors='ignore') as f:
    return str(file_path) in f.read()
```

**Returns:** True if file path is in success log

---

#### 4. `clean_text(text: str) -> str`

**Purpose:** Clean and normalize extracted text.

**Operations:**
```python
text = re.sub(r'[\x00-\x1F\x7F]', '', text)  # Remove control chars
text = re.sub(r'\n\s*\n', '\n', text)        # Remove extra newlines
text = re.sub(r'\s+', ' ', text)             # Normalize whitespace
return text.strip()
```

**Returns:** Cleaned text string

---

### Class: `OfficeDocumentHandler`

**Purpose:** File system event handler for watchdog library.

**Inherits:** `FileSystemEventHandler`

#### Methods:

##### 1. `_is_supported(filename: str) -> bool`

**Filter Logic:**
```python
if filename.startswith('~$'):
    return False  # Skip temporary files
ext = Path(filename).suffix.lower()
return ext in self.config.supported_extensions
```

**Skips:**
- Temporary Office files (~$...)
- Unsupported extensions

---

##### 2. `on_created(event)`

**Trigger:** New file created in watched directory

**Action:**
```python
if not event.is_directory and self._is_supported(event.src_path):
    time.sleep(2)  # Wait for file to be fully written
    process_file(Path(event.src_path), self.config)
```

---

##### 3. `on_modified(event)`

**Trigger:** Existing file modified

**Action:** Same as `on_created` (processes file again if supported)

---

### Main Processing Function

#### `process_file(file_path: Path, config: Config) -> None`

**Purpose:** Complete file processing pipeline.

**Steps:**

```python
[1] Validation:
    ├─ Check if already processed (skip)
    ├─ Check if file exists
    ├─ Skip temporary files (~$...)
    └─ Wait for file to be ready (not locked)

[2] Path Analysis:
    ├─ Extract relative path from CargoAttachments
    └─ Prepare output directory structure

[3] Database Linking:
    └─ get_email_id_from_path() → email_id

[4] Text Extraction:
    ├─ extractor = TextExtractor()
    └─ extracted_text = extractor.extract(file_path)

[5] Create Metadata:
    metadata = {
        "file_metadata": {
            "email_id": email_id,
            "original_file_path": str(file_path),
            "processing_timestamp": datetime.now().isoformat(),
            "file_size_kb": file_size,
            "upload_date": upload_date,
            "file_type": file_path.suffix.lower()
        },
        "processing_metadata": {
            "text_extraction_method": "Office Document Extraction"
        }
    }

[6] Save Results:
    ├─ Output: ocr_results_dir / f"{file_path.stem}_extracted.txt"
    └─ Format: JSON metadata + "---TEXT_CONTENT---" + text

[7] Logging:
    ├─ log_success(file_path) → success_log.txt
    └─ log_error(file_path, error) → error_log.txt (if failed)

[8] Error Handling:
    └─ Copy failed files to UNPROCESSED_DIR
```

**Output File Structure:**
```
{
  "file_metadata": {
    "email_id": 123,
    "original_file_path": "C:/CargoAttachments/.../document.docx",
    "processing_timestamp": "2025-11-06T14:30:22",
    "file_size_kb": 125.5,
    "upload_date": "06/11/2025",
    "file_type": ".docx"
  },
  "processing_metadata": {
    "text_extraction_method": "Office Document Extraction"
  }
}
---TEXT_CONTENT---

[extracted text here]
```

---

## 🗄️ Database Integration

### Minimal Database Usage

**IMPORTANT:** Office Processor has **minimal database interaction** compared to OCR Processor.

**Database Usage:**
- ✅ **READ:** `emails` table (for email_id lookup)
- ❌ **NO WRITE:** Does NOT update `email_attachments.processing_status`
- ❌ **NO WRITE:** Does NOT write to `processing_history`

### Query: Get Email ID

```sql
-- Strategy 1: Exact match by folder
SELECT id FROM emails
WHERE attachment_folder = 'C:\CargoAttachments\sender@company.com\2025-11\Subject_20251106_143022'
LIMIT 1;

-- Strategy 2: Fuzzy match by sender + subject
SELECT id FROM emails
WHERE sender_email = 'sender@company.com'
AND subject LIKE '%Subject%'
LIMIT 1;
```

**Purpose:** Link processed file to email record via `email_id` in metadata JSON.

**No Status Updates:** Office Processor does NOT update any status columns in the database.

---

## 📊 Status Management & Database State

### Overview

**CRITICAL DIFFERENCE:** Office Processor operates **independently** from the database status system used by OCR Processor.

### How Office Processor Differs from OCR Processor

| Aspect | OCR Processor | Office Processor |
|--------|---------------|------------------|
| **Trigger Mechanism** | Database polling (`processing_status='pending'`) | File system watcher (watchdog events) |
| **Status READ** | ✅ Reads `processing_status` column | ❌ Does NOT read any status |
| **Status WRITE** | ✅ Updates `processing_status` → 'processing' → 'completed' | ❌ Does NOT write any status |
| **Database Writes** | Heavy (UPDATE + INSERT to history) | None (only reads `emails.id`) |
| **Processing Queue** | Managed via database | Managed via file system events |
| **Duplicate Prevention** | Database status | Local file log (`success_log.txt`) |

### Status Lifecycle: Office Processor

```
┌─────────────────────────────────────────────────────────────────────┐
│         OFFICE PROCESSOR - NO DATABASE STATUS UPDATES               │
└─────────────────────────────────────────────────────────────────────┘

[Email Fetcher] 
    ↓ Saves Office file to C:\CargoAttachments\
    ↓ Creates: email_attachments (processing_status='pending')
    ↓
[Watchdog File System Monitor]
    ↓ Detects: on_created event
    ↓ Filter: .docx, .doc, .xlsx, .xls, .txt, .rtf, .xml, .odt
    ↓
┌─────────────────┐
│ File Detected   │ ← Office Processor STARTS
└─────────────────┘
    ↓
[Office Processor]
    ├─ Check: is_file_processed() → success_log.txt
    ├─ Check: is_file_ready() → wait for unlock
    ├─ Extract: get_email_id_from_path() → PostgreSQL SELECT
    ├─ Process: TextExtractor.extract()
    ├─ Save: ocr_results/{file}_extracted.txt
    └─ Log: log_success() → success_log.txt
    ↓
┌─────────────────┐
│ File Processed  │ ← Office Processor ENDS
└─────────────────┘
    ↓
[Queue Manager] ← NEXT MODULE (watches ocr_results/ folder)
    ↓ Detects new .txt file
    └─ INSERT INTO processing_queue (status='pending')
    

DATABASE STATE: UNCHANGED
- email_attachments.processing_status REMAINS 'pending'
- NO updates to processing_history table
- NO status transitions in database
```

### What Office Processor Does and Does NOT Do

**Office Processor DOES:**

✅ **Monitors:** File system (C:\CargoAttachments\) for new Office files  
✅ **Reads:** `emails.id` from PostgreSQL (for email_id linking)  
✅ **Extracts:** Text from DOCX, DOC, XLSX, XLS, TXT, RTF, XML, ODT  
✅ **Creates:** Text files in `C:\CargoProcessing\ocr_results\` (SAME location as OCR)  
✅ **Logs:** Success/error to local files (`success_log.txt`, `error_log.txt`)  

**Office Processor does NOT:**

❌ **Read** `email_attachments.processing_status` from database  
❌ **Update** `email_attachments.processing_status` to any value  
❌ **Write** to `processing_history` table  
❌ **Check** database for pending files (uses file system instead)  
❌ **Create** database triggers  

### Parallel Processing with OCR Processor

**IMPORTANT:** Office Processor and OCR Processor run **simultaneously** and **independently**.

```
C:\CargoAttachments\
├── sender@company.com\
    ├── document.pdf     → OCR Processor (via database polling)
    ├── spreadsheet.xlsx → Office Processor (via file watcher)
    └── presentation.pptx → Office Processor (via file watcher)

Both modules output to SAME location:
C:\CargoProcessing\ocr_results\sender@company.com\
├── document_extracted.txt     (from OCR)
├── spreadsheet_extracted.txt  (from Office)
└── presentation_extracted.txt (from Office)
```

**Coordination:**
- OCR: Processes PDF, PNG, JPG, TIF (via database)
- Office: Processes DOCX, DOC, XLSX, XLS, TXT (via file system)
- Output: Same folder structure for Queue Manager

---

### Module Dependency Chain

```
┌──────────────────┐
│ Email Fetcher    │ ← Module 1
│                  │
└──────────────────┘
         │
         │ Creates:
         │ - Files in C:\CargoAttachments\
         │ - email_attachments (processing_status='pending')
         │
         ↓
┌──────────────────┐
│ OCR Processor    │ ← Module 2 (parallel)
│                  │
└──────────────────┘
         │
         │ Processes: PDF, PNG, JPG, TIF
         │ Via: Database polling (processing_status='pending')
         │ Updates: processing_status → 'completed'
         │ Creates: C:\CargoProcessing\ocr_results\*_extracted.txt
         │
         ↓
┌──────────────────┐
│Office Processor  │ ← Module 3 (parallel) - YOU ARE HERE
│                  │
└──────────────────┘
         │
         │ Processes: DOCX, DOC, XLSX, XLS, TXT, RTF, XML, ODT
         │ Via: File system watcher (watchdog)
         │ Updates: NONE (no database status changes)
         │ Creates: C:\CargoProcessing\ocr_results\*_extracted.txt
         │
         ↓
┌──────────────────┐
│ Queue Managers   │ ← Modules 4 & 5
│                  │
└──────────────────┘
         │
         │ WATCHES:
         │ - C:\CargoProcessing\ocr_results\ (for ALL .txt files)
         │ - From BOTH OCR and Office processors
         │
         │ ACTION:
         │ - INSERT INTO processing_queue (status='pending')
         │ - Triggers PostgreSQL NOTIFY → n8n
         │
         ↓
    [AI Analysis]
```

---

### Checking Office Processor Activity

**Since Office Processor doesn't update database status**, use these methods:

#### Method 1: Check Success Log

```bash
# Windows
type C:\Python_project\CargoFlow\Cargoflow_Office\success_log.txt

# Linux
cat /path/to/Cargoflow_Office/success_log.txt
```

**Output:**
```
2025-11-06T14:30:22 - C:\CargoAttachments\sender@company.com\...\document.docx
2025-11-06T14:31:15 - C:\CargoAttachments\sender@company.com\...\spreadsheet.xlsx
```

---

#### Method 2: Check Output Files

```bash
# Windows
dir /s C:\CargoProcessing\processed_documents\2025\ocr_results\*_extracted.txt

# Linux
find /mnt/c/CargoProcessing/processed_documents/2025/ocr_results/ -name "*_extracted.txt"
```

**Expected:** Text files created by Office Processor

---

#### Method 3: Check Log File

```bash
# Windows
type C:\Python_project\CargoFlow\Cargoflow_Office\document_processing.log

# Linux
tail -f /path/to/Cargoflow_Office/document_processing.log
```

**Look for:**
```
Processing file: C:\CargoAttachments\...\document.docx
Text saved to: C:\CargoProcessing\...\document_extracted.txt
File already processed: C:\CargoAttachments\...\spreadsheet.xlsx
```

---

#### Method 4: Query Email IDs in Output

```python
import json
from pathlib import Path

output_dir = Path(r'C:\CargoProcessing\processed_documents\2025\ocr_results')

for txt_file in output_dir.rglob('*_extracted.txt'):
    with open(txt_file, 'r', encoding='utf-8') as f:
        first_lines = f.read(500)
        if 'email_id' in first_lines:
            # Extract metadata JSON
            metadata_end = first_lines.find('---TEXT_CONTENT---')
            if metadata_end > 0:
                metadata_json = first_lines[:metadata_end]
                metadata = json.loads(metadata_json)
                email_id = metadata['file_metadata'].get('email_id')
                print(f"{txt_file.name} → email_id: {email_id}")
```

**Purpose:** Verify that Office Processor successfully linked files to email records.

---

### Troubleshooting: Office Processor Not Processing Files

#### Issue 1: Files Not Being Detected

**Symptoms:**
- New Office files in `C:\CargoAttachments\`
- No entries in `success_log.txt`
- No output files in `ocr_results\`

**Causes:**
1. Office Processor not running
2. Watchdog not monitoring correct directory
3. File extension not supported

**Solution:**

1. **Check if Office Processor is running:**
   ```bash
   # Windows Task Manager: Look for "python.exe" with "office_processor.py"
   tasklist | findstr python
   
   # Linux
   ps aux | grep office_processor
   ```

2. **Check log file for errors:**
   ```bash
   type C:\Python_project\CargoFlow\Cargoflow_Office\document_processing.log
   ```

3. **Restart Office Processor:**
   ```bash
   cd C:\Python_project\CargoFlow\Cargoflow_Office
   venv\Scripts\activate
   python office_processor.py
   ```

---

#### Issue 2: Files Processed But No Output

**Symptoms:**
- Entries in `success_log.txt`
- But NO files in `ocr_results\`

**Causes:**
1. Output directory permissions
2. Disk space full
3. Path configuration error

**Solution:**

1. **Check output directory exists:**
   ```bash
   dir "C:\CargoProcessing\processed_documents\2025\ocr_results"
   ```

2. **Check disk space:**
   ```bash
   wmic logicaldisk get size,freespace,caption
   ```

3. **Verify path configuration:**
   ```python
   # In office_processor.py
   print(OCR_RESULTS_BASE_DIR)
   # Should output: C:\CargoProcessing\processed_documents\2025\ocr_results
   ```

---

#### Issue 3: COM Errors (DOC Files)

**Symptoms:**
```
Error processing file: pywintypes.com_error: (-2147221005, 'Invalid class string', None, None)
```

**Causes:**
1. Microsoft Word not installed
2. COM registration issues
3. Office license problems

**Solution:**

1. **Verify Word installation:**
   ```bash
   # Try opening Word manually
   start winword.exe
   ```

2. **Re-register COM:**
   ```bash
   # Run as Administrator
   cd "C:\Program Files\Microsoft Office\Office16"
   winword.exe /regserver
   ```

3. **Check Office license:**
   - Open any Office app
   - Verify license is activated

---

#### Issue 4: No email_id Linked

**Symptoms:**
- Output files created
- But `email_id: null` in metadata JSON

**Causes:**
1. File path doesn't match database records
2. Email not in `emails` table yet
3. Path parsing logic failed

**Solution:**

1. **Check if email exists:**
   ```sql
   SELECT id, sender_email, subject, attachment_folder
   FROM emails
   WHERE attachment_folder LIKE '%sender@company.com%'
   LIMIT 5;
   ```

2. **Verify path structure:**
   ```
   Expected: C:\CargoAttachments\sender@company.com\2025-11\Subject_20251106_143022\document.docx
   Actual: [check file path]
   ```

3. **Manual email_id lookup:**
   ```sql
   SELECT id FROM emails
   WHERE sender_email = 'sender@company.com'
   AND subject LIKE '%Subject%';
   ```

---

### Summary: Office Processor's Independence

**Key Points:**

1. **No Database Status System:** Office Processor does NOT participate in the `processing_status` workflow
2. **File System Driven:** Uses watchdog events instead of database queries
3. **Parallel Operation:** Runs alongside OCR Processor independently
4. **Shared Output:** Both modules write to same `ocr_results/` folder
5. **Minimal Database:** Only reads `emails.id` for linking, no writes
6. **Local Tracking:** Uses `success_log.txt` for duplicate prevention

**Advantages:**
- ✅ No database contention with OCR Processor
- ✅ Immediate processing (event-driven, no polling delay)
- ✅ Independent failure (one module's issues don't affect the other)

**Disadvantages:**
- ❌ No centralized status tracking in database
- ❌ Harder to monitor progress via SQL queries
- ❌ Relies on file system events (can miss files if watcher down)

**Coordination Point:** Queue Manager (Module 4) consolidates outputs from BOTH OCR and Office processors by watching the shared `ocr_results/` folder.

---

## 📁 File Storage Structure

### Input Files: `C:\CargoAttachments\`

**Structure** (created by Email Fetcher):
```
C:\CargoAttachments\
└── sender@company.com\
    └── 2025-11\
        └── Monthly_Report_20251106_143022\
            ├── email_metadata.json
            ├── email_body.html
            ├── report.docx     ← Office Processor reads this
            └── data.xlsx       ← Office Processor reads this
```

---

### Output Files: `C:\CargoProcessing\`

**Structure** (created by Office Processor):

```
C:\CargoProcessing\
├── processed_documents\
│   └── 2025\
│       └── ocr_results\              ← SHARED output location
│           └── sender@company.com\
│               └── Monthly_Report_20251106_143022\
│                   ├── report_extracted.txt    (from Office Processor)
│                   └── data_extracted.txt      (from Office Processor)
│
└── unprocessed\
    └── unprocessed_office\           ← Failed files moved here
        ├── corrupted_file_20251106_143500.docx
        └── unsupported_format_20251106_144000.xyz
```

### File Naming Conventions

| File Type | Pattern | Example |
|-----------|---------|---------|
| Extracted Text | `{original_name}_extracted.txt` | `report_extracted.txt` |

**Note:** Office Processor does NOT create PNG images (unlike OCR Processor).

---

## 🛡️ Error Handling & Resilience

### Error Recovery Strategies

| Error Type | Detection | Recovery | Action |
|------------|-----------|----------|--------|
| **File Not Found** | `FileNotFoundError` | Log error, skip file | No retry |
| **File Locked** | `is_file_ready()` timeout | Wait 10 seconds | Process next file |
| **Already Processed** | `is_file_processed()` | Skip file | No action |
| **Temporary File** | Filename starts with `~$` | Skip file | No action |
| **COM Error (DOC)** | `pywintypes.com_error` | Log error, move to unprocessed | Manual check |
| **Encoding Error** | `UnicodeDecodeError` | Try alternative encodings | 4 encoding attempts |
| **pypandoc Missing** | `ImportError` | Skip ODT files, log warning | Continue with other formats |
| **Extraction Failed** | `Exception` | Log error, move to unprocessed | Manual review |
| **Disk Space Full** | `OSError` | Log error, alert | Requires intervention |

---

### Error Handling Flow

```python
try:
    extractor = TextExtractor()
    extracted_text = extractor.extract(file_path)
    
    if extracted_text and extracted_text.strip():
        # Save successful extraction
        text_file_path = ocr_results_dir / f"{file_path.stem}_extracted.txt"
        with open(text_file_path, 'w', encoding='utf-8') as f:
            f.write(json.dumps(metadata, indent=2) + '\n')
            f.write('---TEXT_CONTENT---\n')
            f.write(extracted_text.strip())
        
        log_success(file_path)
    else:
        # No text extracted
        logger.warning(f"No text extracted from: {file_path}")
        log_error(file_path, "No text extracted")

except Exception as e:
    # Any error during processing
    logger.error(f"Error processing file {file_path}: {e}")
    log_error(file_path, str(e))
    
    # Copy to unprocessed directory
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    unprocessed_path = UNPROCESSED_DIR / f"{file_path.stem}_{timestamp}{file_path.suffix}"
    try:
        shutil.copy2(file_path, unprocessed_path)
        logger.info(f"Copied to unprocessed: {unprocessed_path}")
    except Exception as copy_error:
        logger.error(f"Error copying to unprocessed: {copy_error}")
```

---

### Unprocessed Files Directory

**Purpose:** Failed files are copied (not moved) to unprocessed directory for later manual review.

**Location:** `C:\CargoProcessing\unprocessed\unprocessed_office\`

**Filename Format:** `{original_stem}_{timestamp}.{ext}`
- Example: `corrupted_file_20251106_143500.docx`

**Review Process:**
1. Check `error_log.txt` for error message
2. Try opening file manually to verify corruption
3. If file is valid, investigate extraction logic
4. If file is corrupted, notify sender or delete

---

## 📊 Logging & Monitoring

### Log Files

Office Processor maintains **three log files**:

#### 1. Main Log: `document_processing.log`

**Location:** `C:\Python_project\CargoFlow\Cargoflow_Office\document_processing.log`

**Configuration:**
```python
RotatingFileHandler(
    str(LOG_FILE),
    maxBytes=10*1024*1024,  # 10MB per file
    backupCount=5,           # Keep 5 backup files
    encoding='utf-8'
)
```

**Log Format:**
```
%(asctime)s - %(levelname)s - %(message)s
```

**Example Output:**
```
2025-11-06 14:30:22,123 - INFO - Processing file: C:\CargoAttachments\...\report.docx
2025-11-06 14:30:23,456 - INFO - ✅ Found email_id 123 for report.docx
2025-11-06 14:30:24,789 - INFO - Text saved to: C:\CargoProcessing\...\report_extracted.txt
2025-11-06 14:31:10,234 - ERROR - Error processing file C:\CargoAttachments\...\corrupted.doc: COM Error
```

---

#### 2. Success Log: `success_log.txt`

**Purpose:** Track successfully processed files to prevent duplicates.

**Location:** `C:\Python_project\CargoFlow\Cargoflow_Office\success_log.txt`

**Format:**
```
2025-11-06T14:30:24 - C:\CargoAttachments\sender@company.com\2025-11\Subject\report.docx
2025-11-06T14:31:15 - C:\CargoAttachments\sender@company.com\2025-11\Subject\data.xlsx
```

**Usage:**
```python
def is_file_processed(file_path: Path) -> bool:
    if not SUCCESS_LOG_FILE.exists():
        return False
    with open(SUCCESS_LOG_FILE, 'r', encoding='utf-8', errors='ignore') as f:
        return str(file_path) in f.read()
```

---

#### 3. Error Log: `error_log.txt`

**Purpose:** Detailed error messages for failed files.

**Location:** `C:\Python_project\CargoFlow\Cargoflow_Office\error_log.txt`

**Format:**
```
2025-11-06T14:35:10 - C:\CargoAttachments\...\corrupted.doc: pywintypes.com_error: Invalid class string
2025-11-06T14:40:22 - C:\CargoAttachments\...\large_file.xlsx: MemoryError: Cannot allocate memory
```

**Usage:**
```python
def log_error(file_path: Path, error_message: str) -> None:
    ERROR_LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(ERROR_LOG_FILE, 'a', encoding='utf-8') as f:
        f.write(f"{datetime.now().isoformat()} - {file_path}: {error_message}\n")
```

---

### Key Log Messages

**Startup:**
```
============================================================
OFFICE DOCUMENTS PROCESSOR STARTED
============================================================
Watching directory: C:\CargoAttachments
Output directory: C:\CargoProcessing\processed_documents\2025\ocr_results
Supported extensions: .doc, .docx, .odt, .rtf, .txt, .xls, .xlsx, .xml
============================================================
Scanning for existing Office documents in: C:\CargoAttachments
Processing folder: C:\CargoAttachments\2025-11
File watcher started. Press Ctrl+C to stop.
```

**Processing:**
```
Processing file: C:\CargoAttachments\sender@company.com\...\report.docx
✅ Found email_id 123 for report.docx
Text saved to: C:\CargoProcessing\...\report_extracted.txt
```

**Skipped:**
```
File already processed: C:\CargoAttachments\...\data.xlsx
Skipping temporary file: C:\CargoAttachments\...\~$report.docx
```

**Errors:**
```
Error extracting from DOCX C:\CargoAttachments\...\corrupted.docx: zipfile.BadZipFile
Error processing file C:\CargoAttachments\...\file.doc: COM Error
Copied to unprocessed: C:\CargoProcessing\unprocessed\unprocessed_office\file_20251106_143500.doc
```

---

## 🚀 Usage & Deployment

### Installation

**Prerequisites:**
- Python 3.11+
- Microsoft Office (for DOC files)
- Pandoc (optional, for ODT files)

**Steps:**

```bash
# 1. Navigate to module directory
cd C:\Python_project\CargoFlow\Cargoflow_Office

# 2. Create virtual environment
python -m venv venv

# 3. Activate virtual environment
venv\Scripts\activate  # Windows
# source venv/bin/activate  # Linux/Mac

# 4. Install Python dependencies
pip install -r requirements.txt

# 5. (Optional) Install Pandoc for ODT support
# Download from: https://pandoc.org/installing.html
# Or: choco install pandoc (Windows Chocolatey)

# 6. Verify Office installation
# Try opening Word manually to ensure it's installed and licensed

# 7. Configure database
# Edit DB_CONFIG in office_processor.py if needed

# 8. Test database connection
python -c "import psycopg2; print(psycopg2.connect(host='localhost', database='Cargo_mail', user='postgres', password='Lora24092004'))"
```

---

### Running the Module

#### Continuous Mode (Recommended)

```bash
cd C:\Python_project\CargoFlow\Cargoflow_Office
venv\Scripts\activate
python office_processor.py
```

**Behavior:**
- Runs indefinitely as background service
- Watches `C:\CargoAttachments\` for new Office files
- Processes files immediately on creation/modification
- Graceful shutdown with Ctrl+C

**Startup Process:**
1. Scans for existing Office files in `C:\CargoAttachments\`
2. Processes any unprocessed files found
3. Starts watchdog file system monitor
4. Enters event loop (waits for file system events)

---

### System Integration

**Office Processor runs as part of 7-process CargoFlow system:**

```bash
# Terminal 1: Email Fetcher
cd C:\Python_project\CargoFlow\Cargoflow_mail
venv\Scripts\activate
python graph_email_extractor_v5.py

# Terminal 2: OCR Processor
cd C:\Python_project\CargoFlow\Cargoflow_OCR
venv\Scripts\activate
python ocr_processor.py

# Terminal 3: Office Processor ← YOU ARE HERE
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

# Terminal 7: n8n Workflows
n8n start
```

---

## 🔧 Troubleshooting

### Common Issues

#### Issue 1: COM Automation Fails (DOC Files)

**Symptoms:**
```
pywintypes.com_error: (-2147221005, 'Invalid class string', None, None)
```

**Causes:**
1. Microsoft Word not installed
2. Word not registered for COM
3. Office license expired
4. 32-bit/64-bit Python-Office mismatch

**Solutions:**

1. **Verify Word installation:**
   ```bash
   # Try launching Word manually
   start winword.exe
   ```

2. **Re-register Word for COM:**
   ```bash
   # Run Command Prompt as Administrator
   cd "C:\Program Files\Microsoft Office\Office16"
   winword.exe /regserver
   ```

3. **Check Office license:**
   - Open Word manually
   - File → Account → Check license status

4. **Check Python architecture:**
   ```python
   import platform
   print(platform.architecture())  # Should match Office (32-bit or 64-bit)
   ```

---

#### Issue 2: Encoding Errors (Text Files)

**Symptoms:**
```
UnicodeDecodeError: 'utf-8' codec can't decode byte 0x84 in position 15
```

**Cause:** Text file uses non-UTF-8 encoding (e.g., Cyrillic CP1251)

**Solution:**

Office Processor automatically tries multiple encodings:
1. UTF-8
2. CP1251 (Cyrillic)
3. ISO-8859-1 (Latin-1)
4. Windows-1252 (Western European)

**If all fail:** File may be binary or use rare encoding. Check file manually.

---

#### Issue 3: pypandoc/Pandoc Not Found (ODT Files)

**Symptoms:**
```
Warning: pypandoc not available. ODT files will not be processed.
```

**Cause:** pypandoc Python package or Pandoc software not installed.

**Solution:**

1. **Install pypandoc:**
   ```bash
   pip install pypandoc
   ```

2. **Install Pandoc:**
   ```bash
   # Windows (Chocolatey)
   choco install pandoc
   
   # Windows (Direct download)
   # https://pandoc.org/installing.html
   
   # Linux
   sudo apt-get install pandoc
   
   # macOS
   brew install pandoc
   ```

3. **Verify installation:**
   ```bash
   pandoc --version
   ```

4. **Test pypandoc:**
   ```python
   import pypandoc
   print(pypandoc.get_pandoc_version())
   ```

---

#### Issue 4: Watchdog Not Detecting Files

**Symptoms:**
- New Office files created in `C:\CargoAttachments\`
- Office Processor running
- But no processing happens

**Causes:**
1. Watchdog monitoring wrong directory
2. File extension not in supported list
3. File is temporary (~$...)

**Solution:**

1. **Verify monitored directory:**
   ```python
   # In office_processor.py main()
   print(f"Watching directory: {EMAIL_ATTACHMENTS_ROOT}")
   # Should output: C:\CargoAttachments
   ```

2. **Check file extension:**
   ```python
   # Supported extensions
   print([ext.value for ext in DocumentType])
   # Should include your file's extension
   ```

3. **Check for temporary file:**
   ```bash
   # Temporary files start with ~$
   dir C:\CargoAttachments\sender@company.com\...\~$*
   ```

4. **Restart Office Processor:**
   ```bash
   # Ctrl+C to stop
   python office_processor.py
   ```

---

#### Issue 5: Memory Errors (Large Excel Files)

**Symptoms:**
```
MemoryError: Cannot allocate memory for large XLSX file
```

**Cause:** Very large Excel file (100+ MB) with many sheets/rows

**Solutions:**

1. **Increase Python memory limit:**
   ```bash
   # Not directly possible in Python, but can use 64-bit Python
   ```

2. **Process Excel in chunks:**
   ```python
   # Modify extract_from_xlsx to read limited rows
   for row in worksheet.iter_rows(values_only=True, max_row=10000):
       # Process first 10,000 rows only
   ```

3. **Skip very large files:**
   ```python
   # Add size check in process_file()
   file_size = file_path.stat().st_size / (1024 * 1024)  # MB
   if file_size > 100:  # Skip files > 100MB
       logger.warning(f"File too large: {file_size}MB, skipping")
       return
   ```

---

#### Issue 6: Files Not Linked to email_id

**Symptoms:**
- Output files created successfully
- But metadata shows `"email_id": null`

**Cause:** Path doesn't match database records

**Solution:**

1. **Check if email exists:**
   ```sql
   SELECT id, sender_email, subject, attachment_folder
   FROM emails
   WHERE sender_email = 'sender@company.com'
   LIMIT 5;
   ```

2. **Verify path format:**
   ```
   Expected: C:\CargoAttachments\sender@company.com\2025-11\Subject_20251106_143022\file.docx
   Check: Does your file path match this structure?
   ```

3. **Manual lookup:**
   ```python
   # Test get_email_id_from_path() function
   from pathlib import Path
   file_path = Path(r'C:\CargoAttachments\sender@company.com\2025-11\Subject\file.docx')
   email_id = get_email_id_from_path(file_path)
   print(f"email_id: {email_id}")
   ```

4. **If still null:**
   - Email may not be in database yet (Email Fetcher running?)
   - Path structure may be non-standard
   - Check logs for "Could not find email_id" warnings

---

## 🔗 Related Documentation

- [Database Schema](../DATABASE_SCHEMA.md) - `emails` table structure
- [Email Fetcher](01_EMAIL_FETCHER.md) - Previous module (creates files)
- [OCR Processor](02_OCR_PROCESSOR.md) - Parallel module (processes images/PDFs)
- [Queue Managers](04_QUEUE_MANAGERS.md) - Next modules (process output files)
- [Status Flow Map](../docs/STATUS_FLOW_MAP.md) - Complete system status flow

---

**Module Status:** ✅ Production Ready  
**Last Updated:** November 12, 2025  
**Maintained by:** CargoFlow DevOps Team
