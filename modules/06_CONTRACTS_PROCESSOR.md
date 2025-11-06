# Contracts Processor Module - Contract Detection & Folder Organization

**Module:** Cargoflow_Contracts  
**Script:** `main.py`  
**Status:** ✅ Production Ready  
**Last Updated:** November 06, 2025

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Architecture & Data Flow](#architecture--data-flow)
3. [Configuration](#configuration)
4. [Key Components](#key-components)
5. [Contract Detection Logic](#contract-detection-logic)
6. [Folder Organization System](#folder-organization-system)
7. [Database Integration](#database-integration)
8. [Status Management & Database State](#status-management--database-state)
9. [CLI Commands](#cli-commands)
10. [Error Handling & Resilience](#error-handling--resilience)
11. [Logging & Monitoring](#logging--monitoring)
12. [Usage & Deployment](#usage--deployment)
13. [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

### Purpose

The Contracts Processor is the **final module** (Module 6) in the CargoFlow system. It detects contract numbers in categorized documents and organizes files into structured folders by contract, creating a logical filing system for easy document retrieval.

**Primary Functions:**
1. **Contract Detection** - Identify files with valid contract numbers
2. **Folder Organization** - Create structured directory hierarchy
3. **Contract Indexing** - Assign unique indices to contract folders
4. **File Copying** - Copy files to organized structure (preserve originals)
5. **Database Tracking** - Record contracts in `contracts` table
6. **Email Ready Queue Processing** - Process batch of emails
7. **CLI Management** - 8 different operation modes

### Key Features

- ✅ **Regex Pattern Matching** - 50XXXXXXXXX, 20XXXXXXXXX detection
- ✅ **Confidence Scoring** - 0.0-1.0 reliability metric
- ✅ **Automatic Indexing** - Sequential folder numbering per contract
- ✅ **Structured Organization** - By contract → date → sender
- ✅ **Batch Processing** - Handle multiple emails simultaneously
- ✅ **Continuous Mode** - Run as background service
- ✅ **Statistics & Reporting** - Detailed processing metrics
- ✅ **Cleanup Utilities** - Remove duplicates and errors

---

## 🏗️ Architecture & Data Flow

### High-Level Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                  CONTRACTS PROCESSOR MODULE (6)                 │
└─────────────────────────────────────────────────────────────────┘

[1] Email Ready Queue:
    ↓ Check: email_ready_queue WHERE processed = FALSE
    ↓ Trigger: All attachments for email categorized by n8n
    ↓
[2] Gather Contract Numbers:
    ├─ SELECT contract_number FROM email_attachments
    │  WHERE email_id = X AND contract_number IS NOT NULL
    └─ Result: ['50251006834', '50251007003']
    ↓
[3] Generate Contract Key:
    └─ Concatenate all unique contract numbers
    └─ contract_key = '50251006834_50251007003'
    ↓
[4] Get Next Index:
    ├─ SELECT last_index FROM contract_folder_seq
    │  WHERE contract_key = '50251006834_50251007003'
    ├─ IF NOT EXISTS: INSERT with last_index = 1
    └─ INCREMENT: last_index = last_index + 1
    ↓
[5] Generate Folder Name:
    └─ folder_name = '50251006834_50251007003_002'
    ↓
[6] Create Folder Structure:
    └─ C:\Users\Delta\Cargo Flow\...\Документи по договори\
        └─ contracts\
            └─ 50251006834_50251007003_002\
                ├── [email files copied here]
                └── metadata.json
    ↓
[7] Copy Files:
    ├─ FOR EACH attachment in email:
    │   ├─ Source: C:\CargoAttachments\sender@email.com\...
    │   └─ Dest: .../contracts/50251006834_50251007003_002/
    └─ Preserve original structure
    ↓
[8] Database Updates:
    ├─ UPDATE emails SET folder_name = '50251006834_50251007003_002'
    ├─ INSERT INTO contracts (contract_number, folder_path, ...)
    ├─ UPDATE email_attachments SET processing_status = 'organized'
    └─ UPDATE email_ready_queue SET processed = TRUE
    ↓
[9] Continue or Stop:
    └─ IF --continuous: LOOP to [1]
    └─ ELSE: Exit
```

### Component Interaction

```
┌──────────────────┐       ┌──────────────────┐       ┌──────────────────┐
│ n8n Workflows    │──────►│Contracts         │──────►│ Organized Folders│
│ (categorization) │       │Processor         │       │ (final output)   │
└──────────────────┘       └──────────────────┘       └──────────────────┘
         │                          │                           │
         │                          ↓                           │
         │              ┌──────────────────┐                   │
         │              │   PostgreSQL     │                   │
         │              │ email_ready_queue│                   │
         │              │ contracts table  │                   │
         │              │contract_folder_seq│                  │
         │              └──────────────────┘                   │
         │                          │                           │
         ↓                          ↓                           ↓
┌─────────────────────────────────────────────────────────────────┐
│                    File System                                  │
│  Input: C:\CargoAttachments\ (original files)                  │
│  Output: C:\Users\Delta\Cargo Flow\...\Документи по договори\  │
│  Structure: contracts/{contract_key}_{index}/                  │
└─────────────────────────────────────────────────────────────────┘
```

### Processing Model

**Trigger:** email_ready_queue

**Batch Processing:**
- Process one email at a time
- All attachments for email organized together
- Sequential processing (not parallel)

**Folder Naming:**
- Pattern: `{contract_key}_{index}`
- Example: `50251006834_002`
- Index auto-increments per contract_key

---

## ⚙️ Configuration

### Configuration File: `config.py`

**Location:** `C:\Python_project\CargoFlow\Cargoflow_Contracts\config.py`

```python
import os
from pathlib import Path

# Database Configuration
DB_CONFIG = {
    'host': 'localhost',
    'port': 5432,
    'database': 'Cargo_mail',
    'user': 'postgres',
    'password': 'Lora24092004'
}

# Folder Organization Paths
BASE_OUTPUT_DIR = Path(
    r'C:\Users\Delta\Cargo Flow\Site de communication - Documents\Документи по договори'
)

# Subfolder structure
CONTRACTS_DIR = BASE_OUTPUT_DIR / 'contracts'
NON_CONTRACTS_DIR = BASE_OUTPUT_DIR / 'non_contracts'

# Contract Detection Patterns
CONTRACT_PATTERNS = {
    'primary': [
        r'50\d{9,10}',  # 50 followed by 9-10 digits
        r'20\d{9,10}'   # 20 followed by 9-10 digits
    ],
    'contextual': [
        r'(?:Договор|Contract)\s*(?:№|No\.?|#)\s*(50\d{9,10})',
        r'(?:Договор|Contract)\s*(?:№|No\.?|#)\s*(20\d{9,10})'
    ]
}

# Confidence Thresholds
MIN_CONFIDENCE = 0.7  # Minimum confidence to consider valid contract

# Processing Settings
BATCH_SIZE = 10  # Emails to process per batch
SCAN_INTERVAL = 30  # Seconds between scans in continuous mode

# Logging
LOG_LEVEL = 'INFO'
LOG_FILE = 'contract_processor.log'
LOG_MAX_BYTES = 10 * 1024 * 1024  # 10 MB
LOG_BACKUP_COUNT = 5
```

### Environment Variables

```bash
# Optional overrides
export CARGOFLOW_DB_HOST=localhost
export CARGOFLOW_DB_PASSWORD=Lora24092004
export CARGOFLOW_OUTPUT_DIR="C:\Users\Delta\Cargo Flow\..."
```

---

## 🔧 Key Components

### Class: `ContractProcessor`

Main processing engine for contract detection and organization.

**Attributes:**

```python
class ContractProcessor:
    def __init__(self):
        self.db_config = DB_CONFIG
        self.base_output_dir = BASE_OUTPUT_DIR
        self.contracts_dir = CONTRACTS_DIR
        self.non_contracts_dir = NON_CONTRACTS_DIR
        self.logger = setup_logger()
        self.stats = {
            'emails_processed': 0,
            'contracts_created': 0,
            'files_organized': 0,
            'errors': 0
        }
```

#### Core Methods:

##### 1. `get_ready_emails(limit: int = 10) -> List[int]`

**Purpose:** Fetch batch of emails ready for processing.

**Query:**
```sql
SELECT email_id 
FROM email_ready_queue
WHERE processed = FALSE
ORDER BY ready_at ASC
LIMIT %s;
```

**Returns:** List of email_ids

---

##### 2. `get_contract_numbers(email_id: int) -> List[str]`

**Purpose:** Extract all contract numbers for an email's attachments.

**Query:**
```sql
SELECT DISTINCT contract_number
FROM email_attachments
WHERE email_id = %s
  AND contract_number IS NOT NULL
  AND contract_number != ''
ORDER BY contract_number;
```

**Returns:** List of contract numbers (e.g., ['50251006834', '50251007003'])

---

##### 3. `generate_contract_key(contract_numbers: List[str]) -> str`

**Purpose:** Create unique key from contract numbers.

**Logic:**
```python
def generate_contract_key(self, contract_numbers: List[str]) -> str:
    """
    Generate contract key from sorted contract numbers.
    
    Examples:
    ['50251006834'] -> '50251006834'
    ['50251007003', '50251006834'] -> '50251006834_50251007003'
    """
    if not contract_numbers:
        return None
    
    # Sort for consistency
    sorted_numbers = sorted(set(contract_numbers))
    
    # Concatenate with underscore
    return '_'.join(sorted_numbers)
```

**Returns:** Contract key string

---

##### 4. `get_next_index(contract_key: str) -> int`

**Purpose:** Get and increment folder index for contract key.

**Method:**
```python
def get_next_index(self, contract_key: str) -> int:
    """
    Get next sequential index for contract_key.
    Uses contract_folder_seq table with UPSERT pattern.
    """
    conn = psycopg2.connect(**self.db_config)
    cursor = conn.cursor()
    
    try:
        # UPSERT: Insert new or increment existing
        cursor.execute("""
            INSERT INTO contract_folder_seq (contract_key, last_index)
            VALUES (%s, 1)
            ON CONFLICT (contract_key)
            DO UPDATE SET last_index = contract_folder_seq.last_index + 1
            RETURNING last_index;
        """, (contract_key,))
        
        index = cursor.fetchone()[0]
        conn.commit()
        return index
        
    finally:
        cursor.close()
        conn.close()
```

**Returns:** Next index (1, 2, 3, ...)

**Note:** Thread-safe due to PostgreSQL UPSERT atomicity

---

##### 5. `generate_folder_name(contract_key: str, index: int) -> str`

**Purpose:** Create folder name from contract key and index.

**Logic:**
```python
def generate_folder_name(self, contract_key: str, index: int) -> str:
    """
    Generate folder name with zero-padded index.
    
    Examples:
    ('50251006834', 1) -> '50251006834_001'
    ('50251006834_50251007003', 12) -> '50251006834_50251007003_012'
    """
    return f"{contract_key}_{index:03d}"
```

**Returns:** Folder name string

---

##### 6. `create_folder_structure(folder_name: str) -> Path`

**Purpose:** Create physical directory structure.

**Method:**
```python
def create_folder_structure(self, folder_name: str) -> Path:
    """
    Create folder in contracts directory.
    
    Structure:
    BASE_OUTPUT_DIR/
        contracts/
            {folder_name}/
                [files will be copied here]
    """
    folder_path = self.contracts_dir / folder_name
    folder_path.mkdir(parents=True, exist_ok=True)
    
    self.logger.info(f"Created folder: {folder_path}")
    return folder_path
```

**Returns:** Path to created folder

---

##### 7. `get_email_attachments(email_id: int) -> List[Dict]`

**Purpose:** Get all attachment details for an email.

**Query:**
```sql
SELECT 
    id,
    attachment_name,
    file_path,
    file_size,
    content_type,
    document_category,
    contract_number
FROM email_attachments
WHERE email_id = %s
ORDER BY id;
```

**Returns:** List of attachment dictionaries

---

##### 8. `copy_files_to_folder(email_id: int, folder_path: Path) -> int`

**Purpose:** Copy all email attachments to organized folder.

**Method:**
```python
def copy_files_to_folder(self, email_id: int, folder_path: Path) -> int:
    """
    Copy files from CargoAttachments to organized folder.
    Preserves original filenames.
    """
    attachments = self.get_email_attachments(email_id)
    copied_count = 0
    
    for attachment in attachments:
        source_path = Path(attachment['file_path'])
        
        if not source_path.exists():
            self.logger.warning(f"Source file not found: {source_path}")
            continue
        
        # Preserve original filename
        dest_path = folder_path / attachment['attachment_name']
        
        try:
            shutil.copy2(source_path, dest_path)
            copied_count += 1
            self.logger.debug(f"Copied: {attachment['attachment_name']}")
        except Exception as e:
            self.logger.error(f"Error copying {attachment['attachment_name']}: {e}")
    
    return copied_count
```

**Returns:** Number of files copied

---

##### 9. `create_metadata_file(email_id: int, folder_path: Path)`

**Purpose:** Create JSON metadata file in organized folder.

**Method:**
```python
def create_metadata_file(self, email_id: int, folder_path: Path):
    """
    Create metadata.json with email and attachment info.
    """
    # Get email details
    email = self.get_email_details(email_id)
    attachments = self.get_email_attachments(email_id)
    
    metadata = {
        'email_id': email_id,
        'sender': email['sender_email'],
        'subject': email['subject'],
        'received_time': email['received_time'].isoformat(),
        'folder_name': email['folder_name'],
        'organized_at': datetime.now().isoformat(),
        'attachments': [
            {
                'name': att['attachment_name'],
                'category': att['document_category'],
                'contract_number': att['contract_number'],
                'size': att['file_size']
            }
            for att in attachments
        ]
    }
    
    metadata_path = folder_path / 'metadata.json'
    with open(metadata_path, 'w', encoding='utf-8') as f:
        json.dump(metadata, f, indent=2, ensure_ascii=False)
    
    self.logger.debug(f"Created metadata: {metadata_path}")
```

---

##### 10. `update_database(email_id: int, folder_name: str, contract_numbers: List[str])`

**Purpose:** Write processing results to database.

**Method:**
```python
def update_database(self, email_id: int, folder_name: str, contract_numbers: List[str]):
    """
    Update multiple tables:
    1. emails.folder_name
    2. contracts table (INSERT)
    3. email_attachments.processing_status
    4. email_ready_queue.processed
    """
    conn = psycopg2.connect(**self.db_config)
    cursor = conn.cursor()
    
    try:
        # 1. Update emails
        cursor.execute("""
            UPDATE emails
            SET folder_name = %s,
                organized_at = NOW()
            WHERE id = %s;
        """, (folder_name, email_id))
        
        # 2. Insert contracts
        for contract_number in contract_numbers:
            cursor.execute("""
                INSERT INTO contracts (
                    email_id,
                    contract_number,
                    folder_name,
                    folder_path,
                    created_at
                ) VALUES (%s, %s, %s, %s, NOW())
                ON CONFLICT (email_id, contract_number) DO NOTHING;
            """, (
                email_id,
                contract_number,
                folder_name,
                str(self.contracts_dir / folder_name)
            ))
        
        # 3. Update attachments
        cursor.execute("""
            UPDATE email_attachments
            SET processing_status = 'organized'
            WHERE email_id = %s;
        """, (email_id,))
        
        # 4. Mark email as processed
        cursor.execute("""
            UPDATE email_ready_queue
            SET processed = TRUE,
                processed_at = NOW()
            WHERE email_id = %s;
        """, (email_id,))
        
        conn.commit()
        
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        cursor.close()
        conn.close()
```

---

##### 11. `process_email(email_id: int) -> bool`

**Purpose:** Complete processing pipeline for one email.

**Method:**
```python
def process_email(self, email_id: int) -> bool:
    """
    Full processing workflow for single email.
    
    Returns: True if successful, False otherwise
    """
    try:
        self.logger.info(f"Processing email_id: {email_id}")
        
        # 1. Get contract numbers
        contract_numbers = self.get_contract_numbers(email_id)
        
        if not contract_numbers:
            self.logger.warning(f"No contract numbers for email_id {email_id}")
            # Mark as processed anyway
            self.mark_email_processed(email_id)
            return False
        
        # 2. Generate contract key
        contract_key = self.generate_contract_key(contract_numbers)
        
        # 3. Get next index
        index = self.get_next_index(contract_key)
        
        # 4. Generate folder name
        folder_name = self.generate_folder_name(contract_key, index)
        
        # 5. Create folder
        folder_path = self.create_folder_structure(folder_name)
        
        # 6. Copy files
        files_copied = self.copy_files_to_folder(email_id, folder_path)
        
        # 7. Create metadata
        self.create_metadata_file(email_id, folder_path)
        
        # 8. Update database
        self.update_database(email_id, folder_name, contract_numbers)
        
        # 9. Update stats
        self.stats['emails_processed'] += 1
        self.stats['contracts_created'] += 1
        self.stats['files_organized'] += files_copied
        
        self.logger.info(f"✅ Successfully processed email_id {email_id} → {folder_name}")
        return True
        
    except Exception as e:
        self.logger.error(f"❌ Error processing email_id {email_id}: {e}")
        self.stats['errors'] += 1
        return False
```

**Returns:** Success boolean

---

##### 12. `process_batch(limit: int = 10)`

**Purpose:** Process multiple emails in batch.

**Method:**
```python
def process_batch(self, limit: int = 10):
    """
    Process batch of ready emails.
    """
    email_ids = self.get_ready_emails(limit)
    
    if not email_ids:
        self.logger.info("No emails ready for processing")
        return
    
    self.logger.info(f"Processing batch of {len(email_ids)} emails")
    
    for email_id in email_ids:
        self.process_email(email_id)
    
    self.print_stats()
```

---

##### 13. `run_continuous(scan_interval: int = 30)`

**Purpose:** Run as background service.

**Method:**
```python
def run_continuous(self, scan_interval: int = 30):
    """
    Continuous processing mode.
    Scan for ready emails every {scan_interval} seconds.
    """
    self.logger.info("Starting continuous mode")
    self.logger.info(f"Scan interval: {scan_interval}s")
    
    try:
        while True:
            self.process_batch(limit=10)
            
            self.logger.debug(f"Sleeping {scan_interval}s...")
            time.sleep(scan_interval)
            
    except KeyboardInterrupt:
        self.logger.info("Shutting down gracefully...")
        self.print_stats()
```

---

### Helper Functions

#### 1. `setup_logger() -> logging.Logger`

**Purpose:** Configure logging with rotation.

**Configuration:**
```python
def setup_logger():
    logger = logging.getLogger('ContractProcessor')
    logger.setLevel(logging.INFO)
    
    handler = RotatingFileHandler(
        LOG_FILE,
        maxBytes=LOG_MAX_BYTES,
        backupCount=LOG_BACKUP_COUNT
    )
    
    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    handler.setFormatter(formatter)
    
    logger.addHandler(handler)
    logger.addHandler(logging.StreamHandler())
    
    return logger
```

---

## 🔍 Contract Detection Logic

### Regex Patterns

**Primary Patterns:**
```python
CONTRACT_PATTERNS = {
    'primary': [
        r'50\d{9,10}',  # 50 + 9-10 digits (total 11 digits)
        r'20\d{9,10}'   # 20 + 9-10 digits (total 11 digits)
    ]
}
```

**Valid Examples:**
```
50251006834  ✅ (11 digits, starts with 50)
50251007003  ✅ (11 digits, starts with 50)
20251005012  ✅ (11 digits, starts with 20)
502510068    ❌ (only 9 digits, too short)
30251006834  ❌ (starts with 30, not 50/20)
```

### Detection Process

**Already done by n8n workflows!**

Contract Processor **does NOT perform detection**. It relies on:
- `email_attachments.contract_number` (set by n8n)
- `email_attachments.confidence_score` (set by n8n)

**Processor's role:** Read existing contract numbers and organize files.

---

## 📁 Folder Organization System

### Directory Structure

**Base Path:**
```
C:\Users\Delta\Cargo Flow\Site de communication - Documents\Документи по договори\
```

**Organized Structure:**
```
Документи по договори/
├── contracts/                    # Files WITH contract numbers
│   ├── 50251006834_001/
│   │   ├── invoice.pdf
│   │   ├── cmr.pdf
│   │   ├── protocol.pdf
│   │   └── metadata.json
│   ├── 50251006834_002/
│   │   ├── invoice.pdf
│   │   └── metadata.json
│   ├── 50251007003_001/
│   │   ├── contract.pdf
│   │   ├── annex.pdf
│   │   └── metadata.json
│   └── 50251006834_50251007003_001/  # Multiple contracts
│       ├── invoice_A.pdf
│       ├── invoice_B.pdf
│       └── metadata.json
│
└── non_contracts/                # Files WITHOUT contract numbers (future)
    ├── by_sender/
    ├── by_date/
    └── by_type/
```

### Folder Naming Convention

**Pattern:** `{contract_key}_{index}`

**Components:**
- `contract_key` - Sorted contract numbers joined with underscore
- `index` - Zero-padded 3-digit sequential number (001, 002, ...)

**Examples:**

| Contract Numbers | contract_key | Index | Folder Name |
|------------------|--------------|-------|-------------|
| ['50251006834'] | '50251006834' | 1 | '50251006834_001' |
| ['50251006834'] | '50251006834' | 2 | '50251006834_002' |
| ['50251007003', '50251006834'] | '50251006834_50251007003' | 1 | '50251006834_50251007003_001' |
| ['20251005012'] | '20251005012' | 1 | '20251005012_001' |

**Index Auto-Increment:**
- Same contract_key → increments: _001, _002, _003, ...
- Different contract_key → starts at _001

---

### Metadata File Format

**File:** `metadata.json`

**Content:**
```json
{
  "email_id": 456,
  "sender": "e.raif@monolit-transport.com",
  "subject": "Re: 50251006834",
  "received_time": "2025-11-06T14:30:00",
  "folder_name": "50251006834_002",
  "organized_at": "2025-11-06T15:45:22",
  "attachments": [
    {
      "name": "invoice_2025_001.pdf",
      "category": "invoice",
      "contract_number": "50251006834",
      "size": 125440
    },
    {
      "name": "cmr_transport.pdf",
      "category": "cmr",
      "contract_number": "50251006834",
      "size": 89120
    }
  ]
}
```

**Purpose:**
- Traceability back to original email
- Document what files are in folder
- Timestamp of organization

---

## 🗄️ Database Integration

### Tables Modified

#### 1. emails

**UPDATE Operation:**
```sql
UPDATE emails
SET folder_name = '50251006834_002',
    organized_at = NOW()
WHERE id = 456;
```

**Columns Updated:**
- `folder_name` - Organized folder name
- `organized_at` - Timestamp

---

#### 2. contracts (INSERT)

**INSERT Operation:**
```sql
INSERT INTO contracts (
    email_id,
    contract_number,
    folder_name,
    folder_path,
    created_at
) VALUES (
    456,
    '50251006834',
    '50251006834_002',
    'C:\\Users\\Delta\\Cargo Flow\\...\\contracts\\50251006834_002',
    NOW()
)
ON CONFLICT (email_id, contract_number) DO NOTHING;
```

**Purpose:** Track all contract folders created

---

#### 3. email_attachments

**UPDATE Operation:**
```sql
UPDATE email_attachments
SET processing_status = 'organized'
WHERE email_id = 456;
```

**Status Transition:** `classified` → `organized`

---

#### 4. email_ready_queue

**UPDATE Operation:**
```sql
UPDATE email_ready_queue
SET processed = TRUE,
    processed_at = NOW()
WHERE email_id = 456;
```

**Purpose:** Mark email as fully processed

---

#### 5. contract_folder_seq (UPSERT)

**UPSERT Operation:**
```sql
INSERT INTO contract_folder_seq (contract_key, last_index)
VALUES ('50251006834', 1)
ON CONFLICT (contract_key)
DO UPDATE SET last_index = contract_folder_seq.last_index + 1
RETURNING last_index;
```

**Purpose:** Maintain sequential indices per contract_key

---

### Database Queries Used

#### Check Ready Emails

```sql
SELECT email_id 
FROM email_ready_queue
WHERE processed = FALSE
ORDER BY ready_at ASC
LIMIT 10;
```

---

#### Get Contract Numbers for Email

```sql
SELECT DISTINCT contract_number
FROM email_attachments
WHERE email_id = 456
  AND contract_number IS NOT NULL
ORDER BY contract_number;
```

---

#### Get Next Index

```sql
INSERT INTO contract_folder_seq (contract_key, last_index)
VALUES ('50251006834', 1)
ON CONFLICT (contract_key)
DO UPDATE SET last_index = contract_folder_seq.last_index + 1
RETURNING last_index;
```

---

## 📊 Status Management & Database State

### Overview

Contracts Processor is the **final module** in the pipeline. It reads categorized data from n8n workflows and produces the final organized folder structure.

### Tables & Status Columns

#### Table: email_ready_queue

**Columns MODIFIED:**

| Column | Contracts Processor READS | Contracts Processor WRITES |
|--------|---------------------------|----------------------------|
| `email_id` | ✅ (WHERE processed = FALSE) | ❌ |
| `ready_at` | ✅ (for ordering) | ❌ |
| `processed` | ✅ (check if FALSE) | ✅ (set to TRUE) |
| `processed_at` | ❌ | ✅ (NOW()) |

---

#### Table: emails

**Columns MODIFIED:**

| Column | Before | After | Purpose |
|--------|--------|-------|---------|
| `folder_name` | NULL | '50251006834_002' | Organized folder name |
| `organized_at` | NULL | NOW() | When organized |

---

#### Table: email_attachments

**Columns MODIFIED:**

| Column | Before | After | Purpose |
|--------|--------|-------|---------|
| `processing_status` | 'classified' | 'organized' | Status update |

---

### Status Flow: Contracts Processor

```
┌─────────────────────────────────────────────────────────────────────┐
│         CONTRACTS PROCESSOR - DATABASE STATUS LIFECYCLE             │
└─────────────────────────────────────────────────────────────────────┘

[n8n Workflows]
    ↓ Categorizes all attachments for email
    ↓ Extracts contract numbers
    ↓
[PostgreSQL Trigger: queue_email_for_folder_update()]
    ↓ IF all attachments classified
    ↓ INSERT INTO email_ready_queue (email_id, processed=FALSE)
    ↓
┌─────────────────┐
│ Email Queued    │ ← Contracts Processor DETECTS
└─────────────────┘
    ↓
DATABASE READ:
SELECT email_id FROM email_ready_queue
WHERE processed = FALSE              ← Contracts Processor READS
ORDER BY ready_at ASC
LIMIT 10
    ↓
[Contracts Processor - process_email()]
    ↓
DATABASE READ:
SELECT contract_number 
FROM email_attachments
WHERE email_id = 456                 ← Contracts Processor READS
  AND contract_number IS NOT NULL
    ↓
[Generate contract_key]
    ↓ contract_key = '50251006834'
    ↓
DATABASE UPSERT:
INSERT INTO contract_folder_seq (contract_key, last_index)
VALUES ('50251006834', 1)
ON CONFLICT (contract_key)
DO UPDATE SET last_index = last_index + 1
RETURNING last_index;                ← Contracts Processor WRITES
    ↓ last_index = 2
    ↓
[Generate folder_name]
    ↓ folder_name = '50251006834_002'
    ↓
[Create Physical Folder]
    ↓ C:\...\contracts\50251006834_002\
    ↓
[Copy Files to Folder]
    ↓ Copy all attachments
    ↓
DATABASE WRITE #1:
UPDATE emails
SET folder_name = '50251006834_002', ← Contracts Processor WRITES
    organized_at = NOW()             ← Contracts Processor WRITES
WHERE id = 456
    ↓
DATABASE WRITE #2:
INSERT INTO contracts (
    email_id, contract_number,
    folder_name, folder_path
) VALUES (456, '50251006834', ...)   ← Contracts Processor WRITES
    ↓
DATABASE WRITE #3:
UPDATE email_attachments
SET processing_status = 'organized'  ← Contracts Processor WRITES
WHERE email_id = 456
    ↓
DATABASE WRITE #4:
UPDATE email_ready_queue
SET processed = TRUE,                ← Contracts Processor WRITES
    processed_at = NOW()             ← Contracts Processor WRITES
WHERE email_id = 456
    ↓
┌─────────────────┐
│ Processing Done │ ← Contracts Processor's job complete
└─────────────────┘


FINAL STATE:
- emails.folder_name = '50251006834_002'
- contracts table has new record
- email_attachments.processing_status = 'organized'
- email_ready_queue.processed = TRUE
- Physical folder created with files
```

---

### Statuses READ by Contracts Processor

#### Query 1: Get Ready Emails

```sql
SELECT email_id FROM email_ready_queue
WHERE processed = FALSE;  -- READ this status
```

**Statuses READ:**
- `processed = FALSE` - Email ready for organization

---

#### Query 2: Get Contract Numbers

```sql
SELECT contract_number FROM email_attachments
WHERE email_id = 456
  AND contract_number IS NOT NULL;  -- READ non-null numbers
```

**Data READ:**
- `contract_number` - Set by n8n workflows

---

### Statuses WRITTEN by Contracts Processor

#### Write 1: emails table

```sql
UPDATE emails
SET folder_name = '50251006834_002',     -- WRITES folder name
    organized_at = NOW()                 -- WRITES timestamp
WHERE id = 456;
```

---

#### Write 2: contracts table

```sql
INSERT INTO contracts (
    email_id,
    contract_number,
    folder_name,                         -- WRITES folder name
    folder_path,                         -- WRITES path
    created_at                           -- WRITES timestamp
) VALUES (...);
```

---

#### Write 3: email_attachments table

```sql
UPDATE email_attachments
SET processing_status = 'organized'      -- WRITES final status
WHERE email_id = 456;
```

**Status Transition:** `classified` → `organized`

---

#### Write 4: email_ready_queue table

```sql
UPDATE email_ready_queue
SET processed = TRUE,                    -- WRITES processed flag
    processed_at = NOW()                 -- WRITES timestamp
WHERE email_id = 456;
```

---

### Module Dependency Chain

```
┌──────────────────┐
│ n8n Workflows    │ ← Modules 5A & 5B
│                  │
└──────────────────┘
         │
         │ WRITES:
         │ - email_attachments.contract_number
         │ - email_attachments.processing_status = 'classified'
         │
         │ TRIGGERS (via PostgreSQL function):
         │ - INSERT INTO email_ready_queue (processed=FALSE)
         │
         ↓
┌──────────────────┐
│Contracts         │ ← Module 6 - YOU ARE HERE (FINAL MODULE)
│Processor         │
└──────────────────┘
         │
         │ READS:
         │ - email_ready_queue.processed = FALSE
         │ - email_attachments.contract_number
         │
         │ PROCESSES:
         │ - Generate contract_key
         │ - Get next index
         │ - Create folders
         │ - Copy files
         │
         │ WRITES:
         │ - emails.folder_name
         │ - contracts table (INSERT)
         │ - email_attachments.processing_status = 'organized'
         │ - email_ready_queue.processed = TRUE
         │ - contract_folder_seq (UPSERT)
         │
         ↓
┌─────────────────┐
│ FINAL OUTPUT    │ ← End of Pipeline
│ Organized Folders│
└─────────────────┘
    
    Physical Folders:
    C:\...\Документи по договори\contracts\{contract}_{index}\
```

---

### Status Transition Timeline

**Example: Email with 2 Attachments**

| Time | Event | Actor | Status Change |
|------|-------|-------|---------------|
| T-30s | Attachment 1 categorized | n8n | email_attachments.processing_status = 'classified' |
| T-15s | Attachment 2 categorized | n8n | email_attachments.processing_status = 'classified' |
| T+0s | All attachments classified | PostgreSQL Trigger | **INSERT email_ready_queue (processed=FALSE)** |
| T+5s | Contracts Processor scans queue | Contracts Processor | - |
| T+6s | Read contract numbers | Contracts Processor | - |
| T+7s | Generate contract_key | Contracts Processor | - |
| T+8s | **UPSERT contract_folder_seq** | Contracts Processor | **last_index = 2** |
| T+9s | Generate folder_name | Contracts Processor | folder_name = '50251006834_002' |
| T+10s | Create physical folder | Contracts Processor | File system operation |
| T+12s | Copy 2 files | Contracts Processor | File system operations |
| T+13s | **UPDATE emails** | Contracts Processor | **folder_name = '50251006834_002'** |
| T+13s | **INSERT contracts** | Contracts Processor | New contract record |
| T+13s | **UPDATE email_attachments** | Contracts Processor | **processing_status = 'organized'** |
| T+14s | **UPDATE email_ready_queue** | Contracts Processor | **processed = TRUE** |

**Total Time:** ~14 seconds from queue to organized

---

### Checking Contracts Processor Activity

#### Method 1: Query Organized Emails

```sql
-- Recently organized emails
SELECT 
    id,
    subject,
    sender_email,
    folder_name,
    organized_at
FROM emails
WHERE folder_name IS NOT NULL
ORDER BY organized_at DESC
LIMIT 20;
```

**Purpose:** Verify Contracts Processor is organizing files

---

#### Method 2: Check Contracts Table

```sql
-- Contracts created
SELECT 
    contract_number,
    folder_name,
    COUNT(*) as email_count,
    MIN(created_at) as first_created,
    MAX(created_at) as last_created
FROM contracts
GROUP BY contract_number, folder_name
ORDER BY last_created DESC
LIMIT 10;
```

**Expected:** Growing number of contract records

---

#### Method 3: Check Email Ready Queue Status

```sql
-- Queue processing status
SELECT 
    processed,
    COUNT(*) as count,
    MIN(ready_at) as oldest,
    MAX(processed_at) as latest_processed
FROM email_ready_queue
GROUP BY processed;
```

**Expected (healthy system):**
```
processed | count | oldest              | latest_processed
----------+-------+---------------------+---------------------
TRUE      | 45    | 2025-10-30 10:00:00 | 2025-11-06 15:45:00
FALSE     | 2     | 2025-11-06 15:40:00 | NULL
```

**Warning signs:**
- Many FALSE (> 20) - Processor not running or slow
- Old FALSE (> 1 hour) - Processor stuck

---

#### Method 4: Check Physical Folders

```bash
# Windows
dir "C:\Users\Delta\Cargo Flow\Site de communication - Documents\Документи по договори\contracts"

# Linux/Mac
ls -la /mnt/c/Users/Delta/Cargo\ Flow/.../contracts/
```

**Expected:** Folders matching database `folder_name` values

---

### Troubleshooting: Contracts Processor Status Issues

#### Issue 1: email_ready_queue Growing (Many FALSE)

**Symptoms:**
- Many records with `processed = FALSE`
- But no new organized folders
- contracts table not growing

**Causes:**
1. Contracts Processor not running
2. No contract numbers in attachments
3. File copy errors
4. Database connection issues

**Solution:**

1. **Check if Contracts Processor running:**
   ```bash
   # Windows Task Manager: Look for "python.exe" with "main.py"
   tasklist | findstr python
   
   # Linux
   ps aux | grep main.py
   ```

2. **Check for contract numbers:**
   ```sql
   SELECT 
       email_id,
       COUNT(*) as attachment_count,
       COUNT(*) FILTER (WHERE contract_number IS NOT NULL) as with_contract_number
   FROM email_attachments
   WHERE email_id IN (
       SELECT email_id FROM email_ready_queue WHERE processed = FALSE
   )
   GROUP BY email_id;
   ```

3. **Check Contracts Processor logs:**
   ```bash
   tail -f C:\Python_project\CargoFlow\Cargoflow_Contracts\contract_processor.log
   ```

4. **Restart Contracts Processor:**
   ```bash
   cd C:\Python_project\CargoFlow\Cargoflow_Contracts
   venv\Scripts\activate
   python main.py --continuous
   ```

---

#### Issue 2: Folders Created But No Database Records

**Symptoms:**
- Physical folders exist
- But emails.folder_name is NULL
- contracts table empty

**Causes:**
1. Database UPDATE failed
2. Transaction rollback
3. Script crashed after folder creation

**Solution:**

1. **Check for orphan folders:**
   ```bash
   # List folders
   dir "C:\...\contracts"
   
   # Compare with database
   SELECT folder_name FROM emails WHERE folder_name IS NOT NULL;
   ```

2. **Check logs for errors:**
   ```bash
   grep "Error" contract_processor.log
   grep "UPDATE emails" contract_processor.log
   ```

3. **Manual cleanup if needed:**
   ```sql
   -- Delete orphan folders (careful!)
   -- First identify them, then manually delete from file system
   ```

---

#### Issue 3: Duplicate Folders Created

**Symptoms:**
- Same contract_key has multiple folders: _001, _002, _003
- But should be same email

**Causes:**
1. Email processed multiple times
2. email_ready_queue not marked as processed
3. Race condition (unlikely with single-threaded processor)

**Solution:**

1. **Check for duplicate email_ready_queue entries:**
   ```sql
   SELECT email_id, COUNT(*)
   FROM email_ready_queue
   GROUP BY email_id
   HAVING COUNT(*) > 1;
   ```

2. **Check emails.folder_name:**
   ```sql
   SELECT id, folder_name, organized_at
   FROM emails
   WHERE folder_name LIKE '50251006834%'
   ORDER BY organized_at;
   ```

3. **Cleanup duplicates:**
   ```sql
   -- Keep only latest
   DELETE FROM email_ready_queue
   WHERE email_id = 456
     AND processed = FALSE
     AND ready_at < (SELECT MAX(ready_at) FROM email_ready_queue WHERE email_id = 456);
   ```

---

### Summary: Contracts Processor Status Role

**Key Points:**

1. **Final Module:** Last step in CargoFlow pipeline
2. **Reads Categorization:** Uses data from n8n workflows (contract_number)
3. **Creates Folders:** Physical file system organization
4. **Database Writes:** Updates 4 tables (emails, contracts, email_attachments, email_ready_queue)
5. **Status Marker:** Changes processing_status to 'organized' (final state)

**Data Flow:**
```
email_ready_queue (processed=FALSE) → 
Contracts Processor → 
Organized Folders + Database Updates → 
email_ready_queue (processed=TRUE)
```

**Status Lifecycle:**
```
[n8n Workflow] → email_attachments.processing_status = 'classified' → 
[PostgreSQL Trigger] → email_ready_queue.processed = FALSE →
[Contracts Processor] → folder created + processed = TRUE + processing_status = 'organized'
```

---

## 🖥️ CLI Commands

### Command Line Interface

**Usage:**
```bash
python main.py [COMMAND] [OPTIONS]
```

### Available Commands

#### 1. `--status`

**Purpose:** Show current system status

**Usage:**
```bash
python main.py --status
```

**Output:**
```
=== CONTRACTS PROCESSOR STATUS ===

Email Ready Queue:
  Pending:    12 emails
  Processed:  45 emails
  Total:      57 emails

Contracts:
  Total:      38 unique contracts
  Folders:    45 folders created

Recent Activity:
  Last organized: 2025-11-06 15:45:22
  Last 10 folders:
    - 50251006834_002
    - 50251007003_001
    - 50251006834_50251007003_001
    ...

Database:
  Connection: OK
  Tables: OK
```

---

#### 2. `--process-batch [N]`

**Purpose:** Process N emails from queue

**Usage:**
```bash
python main.py --process-batch 10
```

**Output:**
```
Processing batch of 10 emails...
✅ Processed email_id 456 → 50251006834_002
✅ Processed email_id 457 → 50251007003_001
⚠️ No contract numbers for email_id 458
...

=== BATCH COMPLETE ===
Emails processed: 10
Contracts created: 8
Files organized: 42
Errors: 0
```

---

#### 3. `--process-single [EMAIL_ID]`

**Purpose:** Process specific email

**Usage:**
```bash
python main.py --process-single 456
```

**Output:**
```
Processing email_id 456...

Contract numbers: ['50251006834']
Contract key: 50251006834
Next index: 2
Folder name: 50251006834_002

Creating folder: C:\...\contracts\50251006834_002
Copying files: 3 files
Creating metadata: metadata.json
Updating database...

✅ Successfully processed email_id 456 → 50251006834_002
```

---

#### 4. `--continuous`

**Purpose:** Run as background service

**Usage:**
```bash
python main.py --continuous
```

**Output:**
```
Starting continuous mode...
Scan interval: 30s

[15:30:00] Processing batch of 5 emails...
[15:30:05] ✅ Processed 5 emails
[15:30:05] Sleeping 30s...

[15:30:35] Processing batch of 2 emails...
[15:30:38] ✅ Processed 2 emails
[15:30:38] Sleeping 30s...

[Ctrl+C]
Shutting down gracefully...
Total processed: 7 emails
```

---

#### 5. `--statistics`

**Purpose:** Show detailed statistics

**Usage:**
```bash
python main.py --statistics
```

**Output:**
```
=== CONTRACTS PROCESSOR STATISTICS ===

Processing Stats:
  Total emails in queue: 57
  Emails processed: 45
  Pending: 12
  Success rate: 100%

Contract Distribution:
  50251006834: 12 folders
  50251007003: 8 folders
  50251006834_50251007003: 3 folders
  20251005012: 5 folders
  ...

Files Organized:
  Total files: 187
  By category:
    - invoice: 62 files
    - cmr: 85 files
    - contract: 25 files
    - protocol: 15 files

Time Statistics:
  Average processing time: 8.5 seconds
  Fastest: 3.2 seconds
  Slowest: 15.8 seconds
```

---

#### 6. `--export-stats`

**Purpose:** Export statistics to JSON

**Usage:**
```bash
python main.py --export-stats
```

**Output:**
```
Exporting statistics to stats_2025-11-06_153045.json...
✅ Statistics exported
```

**File Content:**
```json
{
  "generated_at": "2025-11-06T15:30:45",
  "email_ready_queue": {
    "pending": 12,
    "processed": 45,
    "total": 57
  },
  "contracts": {
    "total_folders": 45,
    "unique_contracts": 38,
    "distribution": {
      "50251006834": 12,
      "50251007003": 8
    }
  },
  "files": {
    "total_organized": 187,
    "by_category": {
      "invoice": 62,
      "cmr": 85
    }
  }
}
```

---

#### 7. `--cleanup`

**Purpose:** Clean up duplicate or error records

**Usage:**
```bash
python main.py --cleanup
```

**Output:**
```
Running cleanup...

Checking for duplicates in email_ready_queue...
Found 3 duplicate entries
Removed 3 duplicates

Checking for orphan contract_folder_seq...
Found 0 orphans

Checking for inconsistent folder_name...
Found 0 inconsistencies

✅ Cleanup complete
```

---

#### 8. `--analyze-file [PATH]`

**Purpose:** Test contract detection on file (dry-run)

**Usage:**
```bash
python main.py --analyze-file "C:\test\document.pdf"
```

**Output:**
```
Analyzing file: C:\test\document.pdf

Would extract contract numbers from email_attachments...
(This is a placeholder - actual detection done by n8n)

Contract numbers found: ['50251006834']
Contract key: 50251006834
Next index would be: 3
Folder name would be: 50251006834_003

No changes made (dry-run)
```

---

## 🛡️ Error Handling & Resilience

### Error Types & Recovery

| Error Type | Detection | Recovery | Action |
|------------|-----------|----------|--------|
| **No Contract Numbers** | `contract_numbers == []` | Skip email, mark processed | Log warning |
| **Folder Creation Fails** | `mkdir()` exception | Log error, rollback DB | Manual intervention |
| **File Copy Error** | `shutil.copy2()` exception | Continue with other files | Log error |
| **Database Connection** | `psycopg2.OperationalError` | Retry with backoff | 3 retry attempts |
| **Database Transaction** | `cursor.execute()` exception | Rollback, log error | Email remains unprocessed |
| **Permission Error** | `PermissionError` | Log error, skip file | Check folder permissions |

### Graceful Degradation

**Scenario: Some files fail to copy**

```python
# Continue with partial success
files_copied = 0
for attachment in attachments:
    try:
        shutil.copy2(source, dest)
        files_copied += 1
    except Exception as e:
        logger.error(f"Failed to copy {attachment}: {e}")
        # Continue with next file

# Still create metadata and update database
if files_copied > 0:
    create_metadata_file(...)
    update_database(...)
```

**Result:** Folder created with whatever files succeeded

---

## 📊 Logging & Monitoring

### Log File

**Location:** `C:\Python_project\CargoFlow\Cargoflow_Contracts\contract_processor.log`

**Configuration:**
```python
RotatingFileHandler(
    'contract_processor.log',
    maxBytes=10*1024*1024,  # 10 MB
    backupCount=5
)
```

### Log Levels

**INFO:** Normal operations
```
Processing email_id 456
Created folder: 50251006834_002
Copied 3 files
Updated database
```

**WARNING:** Non-critical issues
```
No contract numbers for email_id 458
Source file not found: document.pdf
```

**ERROR:** Failures
```
Error copying file: PermissionError
Database transaction failed: IntegrityError
```

---

### Key Metrics to Monitor

#### 1. Processing Rate

```sql
-- Emails organized per day
SELECT 
    DATE(organized_at) as date,
    COUNT(*) as emails_organized
FROM emails
WHERE organized_at IS NOT NULL
GROUP BY DATE(organized_at)
ORDER BY date DESC
LIMIT 7;
```

---

#### 2. Queue Backlog

```sql
-- Pending vs processed
SELECT 
    processed,
    COUNT(*) as count
FROM email_ready_queue
GROUP BY processed;
```

**Target:** pending < 20

---

#### 3. Contract Distribution

```sql
-- Most common contracts
SELECT 
    contract_number,
    COUNT(DISTINCT folder_name) as folder_count
FROM contracts
GROUP BY contract_number
ORDER BY folder_count DESC
LIMIT 10;
```

---

## 🚀 Usage & Deployment

### Installation

**Prerequisites:**
- Python 3.11+
- PostgreSQL 17
- Access to CargoAttachments folder

**Steps:**

```bash
# 1. Navigate to module directory
cd C:\Python_project\CargoFlow\Cargoflow_Contracts

# 2. Create virtual environment
python -m venv venv

# 3. Activate
venv\Scripts\activate

# 4. Install dependencies
pip install -r requirements.txt

# 5. Configure paths in config.py
# Edit BASE_OUTPUT_DIR if needed

# 6. Test database connection
python -c "from config import DB_CONFIG; import psycopg2; psycopg2.connect(**DB_CONFIG); print('OK')"

# 7. Check status
python main.py --status
```

---

### Running the Module

#### One-Time Batch Processing

```bash
cd C:\Python_project\CargoFlow\Cargoflow_Contracts
venv\Scripts\activate
python main.py --process-batch 10
```

---

#### Continuous Mode (Recommended)

```bash
cd C:\Python_project\CargoFlow\Cargoflow_Contracts
venv\Scripts\activate
python main.py --continuous
```

**Runs indefinitely until Ctrl+C**

---

### System Integration

**Contracts Processor runs as part of 7-process CargoFlow system:**

```bash
# Terminal 1-6: [Previous modules]
# ...

# Terminal 7: Contracts Processor ← YOU ARE HERE (FINAL)
cd C:\Python_project\CargoFlow\Cargoflow_Contracts
venv\Scripts\activate
python main.py --continuous
```

---

## 🔧 Troubleshooting

### Common Issues

#### Issue 1: No Folders Being Created

**Symptoms:**
- Contracts Processor running
- But no new folders in contracts/

**Causes:**
1. email_ready_queue empty
2. No contract numbers in attachments
3. Path configuration wrong

**Solution:**

1. **Check queue:**
   ```sql
   SELECT * FROM email_ready_queue WHERE processed = FALSE LIMIT 5;
   ```

2. **Check contract numbers:**
   ```sql
   SELECT email_id, COUNT(*) FILTER (WHERE contract_number IS NOT NULL)
   FROM email_attachments
   GROUP BY email_id;
   ```

3. **Check path:**
   ```python
   # In config.py
   print(BASE_OUTPUT_DIR)
   # Should be accessible path
   ```

---

#### Issue 2: Permission Errors

**Symptoms:**
```
PermissionError: [WinError 5] Access is denied
```

**Cause:** No write permission to output directory

**Solution:**
```bash
# Check folder permissions
# Right-click folder → Properties → Security
# Ensure your user has "Full control"
```

---

## 🔗 Related Documentation

- [Database Schema](../DATABASE_SCHEMA.md) - All tables used
- [n8n Workflows](05_N8N_WORKFLOWS.md) - Previous module (provides contract numbers)
- [Status Flow Map](../docs/STATUS_FLOW_MAP.md) - Complete system flow
- [README](../README.md) - Full system overview

---

**Module Status:** ✅ Production Ready  
**Last Updated:** November 06, 2025  
**Maintained by:** CargoFlow DevOps Team
