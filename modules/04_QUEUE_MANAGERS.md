# Queue Managers Module - File-to-n8n Queue Processing

**Module:** Cargoflow_Queue  
**Scripts:** `text_queue_manager.py`, `image_queue_manager.py`  
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
7. [Rate Limiting & Throttling](#rate-limiting--throttling)
8. [Error Handling & Resilience](#error-handling--resilience)
9. [Logging & Monitoring](#logging--monitoring)
10. [Usage & Deployment](#usage--deployment)
11. [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

### Purpose

The Queue Managers module consists of **two parallel components** in the CargoFlow system (Modules 4A and 4B). They act as the **bridge between file processing and AI analysis**, watching for processed text and image files and sending them to n8n webhooks for AI categorization.

**Primary Functions:**
1. **Text Queue Manager** - Monitors `ocr_results/` for extracted text files
2. **Image Queue Manager** - Monitors `images/` for PNG page images
3. **Database Queue Management** - INSERT into `processing_queue` table
4. **Rate Limiting** - Controls flow to n8n (3 files/minute)
5. **Webhook Communication** - POST files to n8n for AI analysis
6. **PostgreSQL NOTIFY Triggers** - Activates n8n workflows via database events

### Key Features

- ✅ **Dual Queue System** - Separate managers for text and images
- ✅ **File System Monitoring** - Continuous directory watching
- ✅ **Database Queue** - `processing_queue` table as central coordination
- ✅ **PostgreSQL NOTIFY** - Triggers activate n8n workflows instantly
- ✅ **Rate Limiting** - Prevents n8n overload (3 files/minute)
- ✅ **Retry Mechanism** - Automatic retry with exponential backoff
- ✅ **Attachment ID Linking** - Links files to email_attachments records
- ✅ **Error Recovery** - Moves failed files, logs errors
- ✅ **Health Checks** - n8n connectivity verification

---

## 🏗️ Architecture & Data Flow

### High-Level Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                  QUEUE MANAGERS MODULE (4A + 4B)                │
└─────────────────────────────────────────────────────────────────┘

[TEXT QUEUE MANAGER - Module 4A]
    ↓ Watches: C:\CargoProcessing\...\ocr_results\
    ↓ Filter: *_extracted.txt
    ↓
[1] File Detection:
    ├─ New file created by OCR/Office Processor
    ├─ Extract email_id from JSON metadata
    └─ Match attachment_id from email_attachments
    ↓
[2] Database INSERT:
    └─ INSERT INTO processing_queue (
         file_path, file_type='text',
         status='pending', email_id, attachment_id
       )
    ↓
[3] PostgreSQL NOTIFY Trigger:
    └─ trigger_notify_text_queue() → NOTIFY n8n_text_channel
    ↓
[4] n8n Webhook Activated:
    └─ POST http://localhost:5678/webhook/analyze-text
    ↓
[5] AI Analysis (n8n workflow):
    └─ Category_ALL_text workflow processes file
    ↓
[6] Database UPDATE (by n8n):
    └─ email_attachments SET document_category, contract_number
    

[IMAGE QUEUE MANAGER - Module 4B]
    ↓ Watches: C:\CargoProcessing\...\images\
    ↓ Filter: *.png
    ↓
[1] File Detection:
    ├─ New PNG created by OCR Processor
    ├─ Extract email_id from JSON sidecar
    ├─ Match attachment_id with fuzzy logic
    └─ Skip small images (< 50KB, logos/signatures)
    ↓
[2] Database INSERT:
    └─ INSERT INTO processing_queue (
         file_path, file_type='image',
         status='pending', email_id, attachment_id
       )
    ↓
[3] PostgreSQL NOTIFY Trigger:
    └─ trigger_notify_image_queue() → NOTIFY n8n_image_channel
    ↓
[4] n8n Webhook Activated:
    └─ POST http://localhost:5678/webhook/analyze-image
    ↓
[5] AI Analysis (n8n workflow):
    └─ Read_PNG_ workflow processes image
    ↓
[6] Database UPDATE (by n8n):
    └─ email_attachments SET document_category, contract_number
```

### Component Interaction

```
┌──────────────────┐       ┌──────────────────┐       ┌──────────────────┐
│ OCR/Office       │──────►│ Queue Managers   │──────►│   n8n Workflows  │
│ Processors       │       │ (Text + Image)   │       │   (AI Analysis)  │
│ (create files)   │       │ (queue files)    │       │                  │
└──────────────────┘       └──────────────────┘       └──────────────────┘
         │                          │                           │
         │                          ↓                           │
         │              ┌──────────────────┐                   │
         │              │   PostgreSQL     │                   │
         │              │ processing_queue │                   │
         │              │   (coordination) │                   │
         │              │  NOTIFY triggers │                   │
         │              └──────────────────┘                   │
         │                          │                           │
         ↓                          ↓                           ↓
┌─────────────────────────────────────────────────────────────────┐
│                    File System                                  │
│  Input: C:\CargoProcessing\...\{ocr_results|images}\            │
│  Database: processing_queue table                               │
│  Output: n8n webhooks (HTTP POST)                               │
└─────────────────────────────────────────────────────────────────┘
```

### Dual Queue Architecture

**Why Two Separate Managers?**

| Aspect | Text Queue Manager | Image Queue Manager |
|--------|-------------------|---------------------|
| **Input Files** | `*_extracted.txt` (from OCR/Office) | `*.png` (from OCR only) |
| **File Size** | Small (5-500 KB) | Large (100-2000 KB) |
| **Processing Time** | Fast (1-3 seconds) | Slower (3-10 seconds) |
| **n8n Workflow** | Category_ALL_text | Read_PNG_ |
| **Webhook** | /webhook/analyze-text | /webhook/analyze-image |
| **Rate Limit** | 3 files/minute | 3 files/minute |
| **Complexity** | Text parsing only | OCR + image analysis |

**Benefits of Separation:**
1. **Independent Rate Limits** - Text and images don't compete for queue slots
2. **Different Retry Logic** - Images may need more retries (larger, slower)
3. **Isolated Failures** - Text queue failure doesn't affect image queue
4. **Optimized Processing** - Each queue tuned for its file type

---

## ⚙️ Configuration

### Configuration File: `queue_config.json`

**Location:** `C:\Python_project\CargoFlow\Cargoflow_Queue\queue_config.json`

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
        "port": 5432,
        "database": "Cargo_mail",
        "user": "postgres",
        "password": "Lora24092004"
    },
    "retry": {
        "max_attempts": 3,
        "initial_delay_seconds": 5,
        "backoff_multiplier": 2
    },
    "image_filters": {
        "min_file_size_kb": 50,
        "skip_small_images": true
    }
}
```

### Configuration Parameters Explained

#### Text Queue Settings

| Parameter | Default | Description |
|-----------|---------|-------------|
| `watch_path` | `C:\CargoProcessing\...\ocr_results` | Directory to monitor for text files |
| `webhook_url` | `http://localhost:5678/webhook/analyze-text` | n8n text analysis endpoint |
| `rate_limit_per_minute` | 3 | Maximum files sent per minute |
| `scan_interval_seconds` | 15 | How often to scan directory |
| `file_pattern` | `*_extracted.txt` | File pattern to match |

#### Image Queue Settings

| Parameter | Default | Description |
|-----------|---------|-------------|
| `watch_path` | `C:\CargoProcessing\...\images` | Directory to monitor for images |
| `webhook_url` | `http://localhost:5678/webhook/analyze-image` | n8n image analysis endpoint |
| `rate_limit_per_minute` | 3 | Maximum images sent per minute |
| `scan_interval_seconds` | 15 | How often to scan directory |
| `file_pattern` | `*.png` | File pattern to match |

#### Retry Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `max_attempts` | 3 | Maximum retry attempts before giving up |
| `initial_delay_seconds` | 5 | Wait time before first retry |
| `backoff_multiplier` | 2 | Exponential backoff multiplier (5s → 10s → 20s) |

#### Image Filters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `min_file_size_kb` | 50 | Skip images smaller than this (logos, signatures) |
| `skip_small_images` | true | Enable/disable small image filtering |

---

### Database Configuration

**Embedded in scripts** (same as other modules):

```python
DB_CONFIG = {
    'host': 'localhost',
    'port': 5432,
    'database': 'Cargo_mail',
    'user': 'postgres',
    'password': 'Lora24092004'
}
```

### Dependencies

**Python Packages:**

```
psycopg2-binary>=2.9.9  # PostgreSQL
requests>=2.31.0        # HTTP requests to n8n
watchdog>=3.0.0         # File system monitoring (optional)
pathlib>=1.0.1
```

**System Requirements:**

- **Python 3.11+**
- **PostgreSQL 17** with NOTIFY/LISTEN support
- **n8n running** on localhost:5678
- **Network access** to n8n webhooks

---

## 🔧 Key Components

### Class: `QueueManager` (Base Class)

Base class for both Text and Image queue managers.

**Attributes:**

```python
@dataclass
class QueueManager:
    watch_path: Path              # Directory to monitor
    webhook_url: str              # n8n webhook endpoint
    rate_limit: int               # Files per minute
    scan_interval: int            # Seconds between scans
    file_pattern: str             # File matching pattern
    db_config: dict               # PostgreSQL connection
    retry_config: dict            # Retry settings
```

#### Core Methods:

##### 1. `scan_directory() -> List[Path]`

**Purpose:** Find unprocessed files in watch directory.

**Method:**
```python
def scan_directory(self) -> List[Path]:
    """Find all files matching pattern that aren't in processing_queue"""
    all_files = list(self.watch_path.rglob(self.file_pattern))
    
    # Query database for already queued files
    conn = psycopg2.connect(**self.db_config)
    cursor = conn.cursor()
    cursor.execute("""
        SELECT file_path FROM processing_queue
        WHERE status IN ('pending', 'completed')
    """)
    queued_files = {row[0] for row in cursor.fetchall()}
    
    # Filter out already queued
    new_files = [f for f in all_files if str(f) not in queued_files]
    
    return new_files
```

**Returns:** List of new files to process

---

##### 2. `extract_email_id(file_path: Path) -> Optional[int]`

**Purpose:** Extract email_id from file metadata (JSON header in text files or JSON sidecar for images).

**Text Files Method:**
```python
def extract_email_id(self, file_path: Path) -> Optional[int]:
    """Extract email_id from JSON metadata in text file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            # Read first 500 chars (metadata section)
            header = f.read(500)
            
            # Find JSON metadata before ---TEXT_CONTENT---
            if '---TEXT_CONTENT---' in header:
                json_str = header.split('---TEXT_CONTENT---')[0]
                metadata = json.loads(json_str)
                return metadata.get('file_metadata', {}).get('email_id')
    except Exception as e:
        logger.error(f"Error extracting email_id: {e}")
    return None
```

**Image Files Method:**
```python
def extract_email_id(self, file_path: Path) -> Optional[int]:
    """Extract email_id from JSON sidecar file"""
    # Look for matching JSON file: image_1.png → image_1.json
    json_path = file_path.with_suffix('.json')
    
    if json_path.exists():
        try:
            with open(json_path, 'r', encoding='utf-8') as f:
                metadata = json.load(f)
                return metadata.get('file_metadata', {}).get('email_id')
        except Exception as e:
            logger.error(f"Error reading JSON sidecar: {e}")
    
    return None
```

**Returns:** `email_id` (int) or None

---

##### 3. `get_attachment_id(file_path: Path, email_id: int) -> Optional[int]`

**Purpose:** Match file to `email_attachments` record using multiple strategies.

**Matching Strategies:**

```python
def get_attachment_id(self, file_path: Path, email_id: int) -> Optional[int]:
    """Find attachment_id using multiple matching strategies"""
    
    conn = psycopg2.connect(**self.db_config)
    cursor = conn.cursor()
    
    # Strategy 1: Exact filename match
    filename = file_path.stem.replace('_extracted', '')
    cursor.execute("""
        SELECT id FROM email_attachments
        WHERE email_id = %s
        AND attachment_name = %s
        LIMIT 1
    """, (email_id, filename))
    
    result = cursor.fetchone()
    if result:
        return result[0]
    
    # Strategy 2: Pattern matching (for numbered files like "2.png")
    # Extract number from filename
    match = re.search(r'(\d+)', filename)
    if match:
        number = match.group(1)
        # Try matching "image002.png" or "page_2.pdf"
        cursor.execute("""
            SELECT id FROM email_attachments
            WHERE email_id = %s
            AND (attachment_name LIKE %s OR attachment_name LIKE %s)
            LIMIT 1
        """, (email_id, f'%{number}.%', f'%image{number:03d}%'))
        
        result = cursor.fetchone()
        if result:
            return result[0]
    
    # Strategy 3: Fuzzy match (LIKE with base name)
    cursor.execute("""
        SELECT id FROM email_attachments
        WHERE email_id = %s
        AND attachment_name LIKE %s
        LIMIT 1
    """, (email_id, f'%{filename[:10]}%'))
    
    result = cursor.fetchone()
    return result[0] if result else None
```

**Returns:** `attachment_id` (int) or None

**CRITICAL:** If no attachment_id found, file is **NOT added to queue** (prevents orphan records).

---

##### 4. `add_to_queue(file_path: Path, email_id: int, attachment_id: int) -> bool`

**Purpose:** INSERT file into `processing_queue` table.

**Method:**
```python
def add_to_queue(self, file_path: Path, email_id: int, attachment_id: int) -> bool:
    """Add file to processing_queue database table"""
    try:
        conn = psycopg2.connect(**self.db_config)
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT INTO processing_queue (
                file_path,
                file_type,
                status,
                priority,
                email_id,
                attachment_id,
                created_at
            ) VALUES (%s, %s, %s, %s, %s, %s, NOW())
        """, (
            str(file_path),
            'text',  # or 'image'
            'pending',
            1,  # Default priority
            email_id,
            attachment_id
        ))
        
        conn.commit()
        logger.info(f"✅ Added to queue: {file_path.name}")
        return True
        
    except Exception as e:
        logger.error(f"❌ Error adding to queue: {e}")
        conn.rollback()
        return False
    finally:
        cursor.close()
        conn.close()
```

**Returns:** True if successful, False otherwise

**Triggers PostgreSQL NOTIFY:**
- Text files → `trigger_notify_text_queue()` → NOTIFY n8n_text_channel
- Image files → `trigger_notify_image_queue()` → NOTIFY n8n_image_channel

---

##### 5. `send_to_webhook(file_path: Path, email_id: int, attachment_id: int) -> bool`

**Purpose:** Send file to n8n webhook for AI analysis.

**Method:**
```python
def send_to_webhook(self, file_path: Path, email_id: int, attachment_id: int) -> bool:
    """POST file to n8n webhook with metadata"""
    try:
        # Prepare payload
        with open(file_path, 'rb') as f:
            file_content = f.read()
        
        payload = {
            'file_path': str(file_path),
            'email_id': email_id,
            'attachment_id': attachment_id,
            'file_type': 'text' if file_path.suffix == '.txt' else 'image',
            'filename': file_path.name
        }
        
        # For text files, send text content
        if file_path.suffix == '.txt':
            payload['text_content'] = file_content.decode('utf-8')
        
        # For images, send base64 encoded
        else:
            import base64
            payload['image_data'] = base64.b64encode(file_content).decode('utf-8')
        
        # POST to n8n
        response = requests.post(
            self.webhook_url,
            json=payload,
            timeout=30
        )
        
        if response.status_code == 200:
            logger.info(f"✅ Webhook success: {file_path.name}")
            return True
        else:
            logger.error(f"❌ Webhook error {response.status_code}: {file_path.name}")
            return False
            
    except requests.exceptions.Timeout:
        logger.error(f"⏱️ Webhook timeout: {file_path.name}")
        return False
    except Exception as e:
        logger.error(f"❌ Webhook error: {e}")
        return False
```

**Returns:** True if HTTP 200, False otherwise

**Note:** Actual webhook implementation may vary. Some workflows use PostgreSQL NOTIFY instead of direct HTTP POST.

---

##### 6. `run_continuous()`

**Purpose:** Main event loop - continuously monitor and process files.

**Method:**
```python
def run_continuous(self):
    """Main event loop"""
    logger.info(f"Starting {self.__class__.__name__}")
    logger.info(f"Watching: {self.watch_path}")
    logger.info(f"Webhook: {self.webhook_url}")
    logger.info(f"Rate limit: {self.rate_limit} files/minute")
    
    files_sent_this_minute = 0
    minute_start = time.time()
    
    while True:
        try:
            # Reset rate limiter every minute
            if time.time() - minute_start >= 60:
                files_sent_this_minute = 0
                minute_start = time.time()
            
            # Check rate limit
            if files_sent_this_minute >= self.rate_limit:
                wait_time = 60 - (time.time() - minute_start)
                if wait_time > 0:
                    logger.info(f"⏳ Rate limit reached, waiting {wait_time:.0f}s")
                    time.sleep(wait_time)
                continue
            
            # Scan for new files
            new_files = self.scan_directory()
            
            if not new_files:
                logger.debug(f"No new files, sleeping {self.scan_interval}s")
                time.sleep(self.scan_interval)
                continue
            
            # Process files (up to rate limit)
            for file_path in new_files[:self.rate_limit - files_sent_this_minute]:
                # Extract metadata
                email_id = self.extract_email_id(file_path)
                if not email_id:
                    logger.warning(f"⚠️ No email_id: {file_path.name}")
                    continue
                
                attachment_id = self.get_attachment_id(file_path, email_id)
                if not attachment_id:
                    logger.warning(f"⚠️ No attachment_id: {file_path.name}")
                    continue
                
                # Add to database queue
                if self.add_to_queue(file_path, email_id, attachment_id):
                    files_sent_this_minute += 1
                    
                    # Optional: Send directly to webhook (if not using NOTIFY)
                    # self.send_to_webhook(file_path, email_id, attachment_id)
            
            # Sleep before next scan
            time.sleep(self.scan_interval)
            
        except KeyboardInterrupt:
            logger.info("Shutting down...")
            break
        except Exception as e:
            logger.error(f"Error in main loop: {e}")
            time.sleep(60)  # Wait 1 minute before retry
```

**Loop Behavior:**
1. Check rate limit (reset every minute)
2. Scan directory for new files
3. Extract email_id and attachment_id
4. Add to database queue (triggers PostgreSQL NOTIFY)
5. Sleep for scan_interval seconds
6. Repeat

---

### Text Queue Manager Specific

#### `TextQueueManager(QueueManager)`

**Specialization for text files:**

```python
class TextQueueManager(QueueManager):
    def __init__(self, config: dict):
        super().__init__(
            watch_path=Path(config['text_queue']['watch_path']),
            webhook_url=config['text_queue']['webhook_url'],
            rate_limit=config['text_queue']['rate_limit_per_minute'],
            scan_interval=config['text_queue']['scan_interval_seconds'],
            file_pattern=config['text_queue']['file_pattern'],
            db_config=config['database'],
            retry_config=config['retry']
        )
    
    def extract_email_id(self, file_path: Path) -> Optional[int]:
        """Text-specific: read JSON from first 500 chars"""
        # Implementation above
```

**Text File Structure Expected:**
```
{
  "file_metadata": {
    "email_id": 123,
    ...
  }
}
---TEXT_CONTENT---

Actual text content here...
```

---

### Image Queue Manager Specific

#### `ImageQueueManager(QueueManager)`

**Specialization for image files:**

```python
class ImageQueueManager(QueueManager):
    def __init__(self, config: dict):
        super().__init__(
            watch_path=Path(config['image_queue']['watch_path']),
            webhook_url=config['image_queue']['webhook_url'],
            rate_limit=config['image_queue']['rate_limit_per_minute'],
            scan_interval=config['image_queue']['scan_interval_seconds'],
            file_pattern=config['image_queue']['file_pattern'],
            db_config=config['database'],
            retry_config=config['retry']
        )
        
        self.min_file_size = config['image_filters']['min_file_size_kb'] * 1024
        self.skip_small = config['image_filters']['skip_small_images']
    
    def should_process_image(self, file_path: Path) -> bool:
        """Filter out small images (logos, signatures)"""
        if not self.skip_small:
            return True
        
        file_size = file_path.stat().st_size
        if file_size < self.min_file_size:
            logger.debug(f"Skipping small image: {file_path.name} ({file_size} bytes)")
            return False
        
        return True
    
    def extract_email_id(self, file_path: Path) -> Optional[int]:
        """Image-specific: read from JSON sidecar"""
        # Implementation above
```

**Image File + JSON Sidecar:**
```
images/
├── document_1.png       ← Image file
├── document_1.json      ← JSON sidecar with email_id
├── document_2.png
└── document_2.json
```

**Small Image Filtering:**
- **Purpose:** Skip logos, signatures, banners (< 50KB)
- **Configurable:** `min_file_size_kb` in config
- **Default:** 50KB threshold

---

## 🗄️ Database Integration

### Tables Modified

#### 1. `processing_queue` (PRIMARY TABLE)

**INSERT Operations:**

```sql
INSERT INTO processing_queue (
    file_path,
    file_type,           -- 'text' or 'image'
    status,              -- 'pending'
    priority,            -- 1 (default)
    email_id,
    attachment_id,
    created_at
) VALUES (
    'C:\CargoProcessing\...\file_extracted.txt',
    'text',
    'pending',
    1,
    123,
    456,
    NOW()
);
```

**Status Values:**
- `pending` - Queued, waiting for n8n processing
- `completed` - Successfully processed by n8n
- `failed` - Processing failed after max retries

**Key Columns:**
- `file_path` - Full path to file
- `file_type` - 'text' or 'image'
- `email_id` - Link to emails table
- `attachment_id` - Link to email_attachments table
- `attempts` - Retry counter (0-3)
- `processed_at` - When n8n completed processing

---

### PostgreSQL Triggers

#### Trigger 1: `trigger_notify_text_queue`

**Trigger Definition:**
```sql
CREATE TRIGGER trigger_notify_text_queue
AFTER INSERT ON processing_queue
FOR EACH ROW
WHEN (NEW.file_type = 'text' AND NEW.status = 'pending')
EXECUTE FUNCTION notify_n8n_text_queue();
```

**Function:**
```sql
CREATE OR REPLACE FUNCTION notify_n8n_text_queue()
RETURNS TRIGGER AS $$
BEGIN
    -- Send notification to n8n
    PERFORM pg_notify(
        'n8n_text_channel',
        json_build_object(
            'id', NEW.id,
            'file_path', NEW.file_path,
            'email_id', NEW.email_id,
            'attachment_id', NEW.attachment_id
        )::text
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

**Purpose:** When Text Queue Manager adds a file, this trigger immediately notifies n8n via PostgreSQL NOTIFY/LISTEN.

---

#### Trigger 2: `trigger_notify_image_queue`

**Trigger Definition:**
```sql
CREATE TRIGGER trigger_notify_image_queue
AFTER INSERT ON processing_queue
FOR EACH ROW
WHEN (NEW.file_type = 'image' AND NEW.status = 'pending')
EXECUTE FUNCTION notify_n8n_image_queue();
```

**Function:**
```sql
CREATE OR REPLACE FUNCTION notify_n8n_image_queue()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM pg_notify(
        'n8n_image_channel',
        json_build_object(
            'id', NEW.id,
            'file_path', NEW.file_path,
            'email_id', NEW.email_id,
            'attachment_id', NEW.attachment_id
        )::text
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

**Purpose:** When Image Queue Manager adds a file, this trigger immediately notifies n8n for image processing.

---

### Database Queries Used

#### Check for Already Queued Files

```sql
SELECT file_path 
FROM processing_queue
WHERE status IN ('pending', 'completed')
  AND file_type = 'text';  -- or 'image'
```

**Purpose:** Prevent duplicate queue entries

---

#### Find Attachment ID

```sql
-- Strategy 1: Exact match
SELECT id FROM email_attachments
WHERE email_id = 123
  AND attachment_name = 'document.pdf'
LIMIT 1;

-- Strategy 2: Pattern match (for numbered files)
SELECT id FROM email_attachments
WHERE email_id = 123
  AND (attachment_name LIKE '%2.%' OR attachment_name LIKE '%image002%')
LIMIT 1;

-- Strategy 3: Fuzzy match
SELECT id FROM email_attachments
WHERE email_id = 123
  AND attachment_name LIKE '%document%'
LIMIT 1;
```

**Purpose:** Link queue entry to email_attachments record

---

## 📊 Status Management & Database State

### Overview

Queue Managers are the **gateway between file processing and AI analysis**. They read files from disk, write to `processing_queue` table, and trigger n8n workflows via PostgreSQL NOTIFY.

### Tables & Status Columns

#### Table: `processing_queue`

**Columns Modified:**

| Column | Type | Queue Managers WRITE | n8n Workflows WRITE |
|--------|------|----------------------|---------------------|
| `id` | SERIAL | ✅ (auto-increment on INSERT) | ❌ |
| `file_path` | TEXT | ✅ (INSERT) | ❌ |
| `file_type` | TEXT | ✅ ('text' or 'image') | ❌ |
| `status` | TEXT | ✅ ('pending') | ✅ ('completed' or 'failed') |
| `priority` | INTEGER | ✅ (1) | ❌ |
| `email_id` | INTEGER | ✅ (from file metadata) | ❌ |
| `attachment_id` | INTEGER | ✅ (from database lookup) | ❌ |
| `attempts` | INTEGER | ✅ (0 initially) | ✅ (increment on retry) |
| `created_at` | TIMESTAMP | ✅ (NOW()) | ❌ |
| `processed_at` | TIMESTAMP | ❌ | ✅ (when completed) |
| `error_message` | TEXT | ❌ | ✅ (if failed) |

---

### Status Flow: Queue Managers

```
┌─────────────────────────────────────────────────────────────────────┐
│         QUEUE MANAGERS - DATABASE STATUS LIFECYCLE                  │
└─────────────────────────────────────────────────────────────────────┘

[OCR/Office Processor]
    ↓ Creates: text file in C:\CargoProcessing\...\ocr_results\
    ↓ OR: PNG image in C:\CargoProcessing\...\images\
    ↓
┌─────────────────┐
│ File Created    │ ← Queue Manager DETECTS (via scan_directory)
└─────────────────┘
    ↓
[Queue Manager - Text or Image]
    ├─ Extract: email_id (from JSON metadata/sidecar)
    ├─ Lookup: attachment_id (3-strategy match from email_attachments)
    ├─ Filter: Skip if no attachment_id found
    └─ Check: Rate limit (3 files/minute)
    ↓
DATABASE WRITE:
INSERT INTO processing_queue (
    file_path = 'C:\...\file_extracted.txt',
    file_type = 'text',              ← Queue Manager WRITES
    status = 'pending',              ← Queue Manager WRITES
    priority = 1,                    ← Queue Manager WRITES
    email_id = 123,                  ← Queue Manager WRITES
    attachment_id = 456,             ← Queue Manager WRITES
    created_at = NOW()               ← Queue Manager WRITES
)
    ↓
┌─────────────────┐
│ TRIGGER FIRES   │ ← PostgreSQL trigger_notify_text_queue (or image)
└─────────────────┘
    ↓
PostgreSQL NOTIFY:
    ↓ NOTIFY n8n_text_channel (or n8n_image_channel)
    ↓ Payload: { id, file_path, email_id, attachment_id }
    ↓
[n8n Workflow - Category_ALL_text or Read_PNG_]
    ↓ LISTEN n8n_text_channel
    ↓ Receives: queue record details
    ↓ Processes: AI analysis
    ↓
DATABASE UPDATE (by n8n):
UPDATE processing_queue
SET status = 'completed',            ← n8n WRITES
    processed_at = NOW(),            ← n8n WRITES
    attempts = attempts + 1          ← n8n WRITES (if retry)
WHERE id = 123
    ↓
[n8n Workflow]
    ↓ Also updates: email_attachments
    ↓ SET document_category, contract_number, etc.
    ↓
┌─────────────────┐
│ Processing Done │ ← Queue Manager's job complete
└─────────────────┘


IF ERROR (n8n workflow fails):
UPDATE processing_queue
SET status = 'failed',               ← n8n WRITES
    error_message = 'AI timeout',    ← n8n WRITES
    attempts = attempts + 1          ← n8n WRITES
WHERE id = 123

IF max_attempts reached:
    → status remains 'failed'
    → Queue Manager may move file to error directory (optional)
```

---

### Statuses READ by Queue Managers

**Query:** Check if file already in queue

```sql
SELECT file_path 
FROM processing_queue
WHERE status IN ('pending', 'completed')
  AND file_path = 'C:\...\file_extracted.txt';
```

**Statuses READ:**
- `pending` - File is in queue, skip
- `completed` - File already processed, skip
- (Implicitly: `failed` files are NOT re-queued automatically)

**Purpose:** Prevent duplicate queue entries

---

### Statuses WRITTEN by Queue Managers

**INSERT Operation:**

```sql
INSERT INTO processing_queue (
    file_path,
    file_type,
    status,           ← WRITES: 'pending'
    priority,         ← WRITES: 1
    email_id,         ← WRITES: from file metadata
    attachment_id,    ← WRITES: from database lookup
    created_at        ← WRITES: NOW()
) VALUES (...);
```

**Status WRITTEN:** `pending`

**Impact:**
1. **Immediate:** PostgreSQL trigger fires → NOTIFY n8n_text_channel (or image)
2. **Downstream:** n8n workflow receives notification → starts AI analysis
3. **Final:** n8n updates status to `completed` or `failed`

---

### Module Dependency Chain

```
┌──────────────────┐
│ OCR Processor    │ ← Module 2
│ Office Processor │ ← Module 3
│                  │
└──────────────────┘
         │
         │ Creates:
         │ - Text files: C:\CargoProcessing\...\ocr_results\*_extracted.txt
         │ - Images: C:\CargoProcessing\...\images\*.png
         │
         ↓
┌──────────────────┐
│ Queue Managers   │ ← Modules 4A & 4B - YOU ARE HERE
│                  │
└──────────────────┘
         │
         │ READS:
         │ - Files on disk (via scan_directory)
         │ - processing_queue.status (to skip duplicates)
         │ - email_attachments (to find attachment_id)
         │
         │ WRITES:
         │ - processing_queue.status = 'pending'
         │ - processing_queue.file_type, email_id, attachment_id
         │
         │ TRIGGERS:
         │ - PostgreSQL NOTIFY (via database triggers)
         │
         ↓
┌──────────────────┐
│ n8n Workflows    │ ← Modules 5A & 5B
│                  │
└──────────────────┘
         │
         │ LISTENS:
         │ - PostgreSQL NOTIFY n8n_text_channel
         │ - PostgreSQL NOTIFY n8n_image_channel
         │
         │ READS:
         │ - processing_queue.status = 'pending'
         │ - File content (via file_path)
         │
         │ WRITES:
         │ - processing_queue.status = 'completed' or 'failed'
         │ - email_attachments (document_category, contract_number)
         │
         ↓
    [AI Analysis Complete]
```

---

### Status Transition Timeline

**Example: Text File Processing**

| Time | Event | Actor | Status Change |
|------|-------|-------|---------------|
| T+0s | OCR creates `file_extracted.txt` | OCR Processor | - |
| T+5s | Text Queue Manager detects file | Text Queue Manager | - |
| T+6s | Extract email_id = 123 | Text Queue Manager | - |
| T+7s | Lookup attachment_id = 456 | Text Queue Manager | - |
| T+8s | **INSERT processing_queue** | Text Queue Manager | **status = 'pending'** |
| T+8s | **Trigger fires** | PostgreSQL | NOTIFY n8n_text_channel |
| T+9s | n8n receives notification | n8n | - |
| T+10s | n8n starts AI analysis | n8n | - |
| T+15s | AI completes categorization | n8n | - |
| T+16s | **UPDATE processing_queue** | n8n | **status = 'completed'** |
| T+16s | **UPDATE email_attachments** | n8n | document_category = 'invoice' |

**Total Time:** ~16 seconds from file creation to AI categorization

---

### Checking Queue Manager Activity

#### Method 1: Query Processing Queue Status

```sql
-- Current queue status
SELECT 
    file_type,
    status,
    COUNT(*) as count,
    MIN(created_at) as oldest,
    MAX(created_at) as newest
FROM processing_queue
GROUP BY file_type, status
ORDER BY file_type, status;
```

**Expected Output:**
```
file_type | status    | count | oldest              | newest
----------+-----------+-------+---------------------+---------------------
text      | pending   | 5     | 2025-11-06 14:00:00 | 2025-11-06 14:30:00
text      | completed | 120   | 2025-10-27 10:00:00 | 2025-11-06 14:25:00
image     | pending   | 12    | 2025-11-06 14:00:00 | 2025-11-06 14:30:00
image     | completed | 95    | 2025-10-27 10:00:00 | 2025-11-06 14:28:00
```

---

#### Method 2: Recent Queue Activity

```sql
-- Last 10 files added to queue
SELECT 
    id,
    file_type,
    status,
    email_id,
    attachment_id,
    created_at,
    processed_at
FROM processing_queue
ORDER BY created_at DESC
LIMIT 10;
```

**Purpose:** Verify Queue Managers are actively adding files

---

#### Method 3: Check for Stuck Files

```sql
-- Files pending for more than 1 hour
SELECT 
    id,
    file_path,
    file_type,
    status,
    attempts,
    created_at,
    NOW() - created_at as age
FROM processing_queue
WHERE status = 'pending'
  AND created_at < NOW() - INTERVAL '1 hour'
ORDER BY created_at;
```

**Action:** If files stuck:
1. Check n8n workflows are active
2. Check PostgreSQL NOTIFY/LISTEN connection
3. Restart n8n or queue managers

---

#### Method 4: Check Retry Attempts

```sql
-- Files with multiple retry attempts
SELECT 
    file_path,
    status,
    attempts,
    error_message
FROM processing_queue
WHERE attempts > 1
ORDER BY attempts DESC, created_at DESC
LIMIT 20;
```

**Purpose:** Identify problematic files or recurring errors

---

### Troubleshooting: Queue Status Issues

#### Issue 1: Files Not Being Added to Queue

**Symptoms:**
- New files in `ocr_results/` or `images/`
- But `processing_queue` not growing
- Queue Manager running

**Causes:**
1. No email_id in file metadata
2. No attachment_id match found
3. Rate limit reached
4. Files already in queue (duplicate prevention)

**Solution:**

1. **Check email_id extraction:**
   ```python
   # Manually test
   from pathlib import Path
   file_path = Path(r'C:\CargoProcessing\...\file_extracted.txt')
   
   # Read first 500 chars
   with open(file_path, 'r') as f:
       print(f.read(500))
   # Look for "email_id": XXX in JSON
   ```

2. **Check attachment_id lookup:**
   ```sql
   SELECT id, email_id, attachment_name
   FROM email_attachments
   WHERE email_id = 123;
   ```

3. **Check rate limit:**
   ```
   # In logs: "⏳ Rate limit reached, waiting Xs"
   ```

4. **Check for duplicates:**
   ```sql
   SELECT * FROM processing_queue
   WHERE file_path = 'C:\...\file_extracted.txt';
   ```

---

#### Issue 2: Files Added But Status Stuck on 'pending'

**Symptoms:**
- Files added to `processing_queue`
- But status remains 'pending' for hours
- n8n not processing

**Causes:**
1. n8n workflows not active
2. PostgreSQL NOTIFY not reaching n8n
3. n8n webhook not responding
4. Database connection issues

**Solution:**

1. **Check n8n workflows:**
   ```
   Open http://localhost:5678
   Verify workflows are "Active":
   - Category_ALL_text
   - Read_PNG_
   ```

2. **Test PostgreSQL NOTIFY:**
   ```sql
   -- In psql terminal
   LISTEN n8n_text_channel;
   
   -- In another terminal, insert test record
   INSERT INTO processing_queue (file_path, file_type, status) 
   VALUES ('/test/path.txt', 'text', 'pending');
   
   -- Should see: Asynchronous notification "n8n_text_channel" received
   ```

3. **Check n8n logs:**
   ```bash
   # n8n terminal output
   # Look for: "Received notification from PostgreSQL"
   ```

4. **Restart n8n:**
   ```bash
   # Stop n8n (Ctrl+C)
   n8n start
   ```

---

#### Issue 3: Files Failing Repeatedly

**Symptoms:**
- Files processed but status = 'failed'
- attempts = 3 (max retries)
- error_message in database

**Causes:**
1. AI timeout (large files)
2. Invalid file format
3. Missing API keys (OpenAI, Gemini)
4. Network issues

**Solution:**

1. **Check error messages:**
   ```sql
   SELECT file_path, error_message, attempts
   FROM processing_queue
   WHERE status = 'failed'
   ORDER BY created_at DESC
   LIMIT 10;
   ```

2. **Check n8n workflow errors:**
   ```
   Open http://localhost:5678
   Click on workflow → Executions → Failed
   Review error details
   ```

3. **Test file manually:**
   ```bash
   # Try processing file outside queue
   # Check if file is valid/readable
   ```

4. **Reset failed files** (if issue resolved):
   ```sql
   UPDATE processing_queue
   SET status = 'pending', attempts = 0, error_message = NULL
   WHERE status = 'failed'
     AND error_message LIKE '%timeout%';
   ```

---

### Summary: Queue Managers Status Role

**Key Points:**

1. **Gateway Function:** Queue Managers bridge file processing → AI analysis
2. **Database Writes:** Only write to `processing_queue` (status='pending')
3. **Triggers:** INSERTs activate PostgreSQL NOTIFY → n8n workflows
4. **No Updates:** Queue Managers don't UPDATE statuses (n8n does that)
5. **Coordination:** `processing_queue` table is central coordination hub
6. **Rate Limited:** 3 files/minute prevents n8n overload

**Data Flow:**
```
File on Disk → Queue Manager → processing_queue (INSERT) → 
PostgreSQL NOTIFY → n8n → AI Analysis → 
processing_queue (UPDATE) → email_attachments (UPDATE)
```

**Status Lifecycle:**
```
[Queue Manager] → status='pending' → 
[n8n Workflow] → status='completed' or 'failed'
```

---

## ⏱️ Rate Limiting & Throttling

### Rate Limit Configuration

**Default:** 3 files per minute (configurable per queue)

```json
{
    "text_queue": {
        "rate_limit_per_minute": 3
    },
    "image_queue": {
        "rate_limit_per_minute": 3
    }
}
```

### Rate Limit Logic

```python
files_sent_this_minute = 0
minute_start = time.time()

while True:
    # Reset counter every 60 seconds
    if time.time() - minute_start >= 60:
        files_sent_this_minute = 0
        minute_start = time.time()
    
    # Check limit
    if files_sent_this_minute >= self.rate_limit:
        wait_time = 60 - (time.time() - minute_start)
        logger.info(f"⏳ Rate limit reached, waiting {wait_time:.0f}s")
        time.sleep(wait_time)
        continue
    
    # Process files
    for file_path in new_files[:self.rate_limit - files_sent_this_minute]:
        self.add_to_queue(file_path, email_id, attachment_id)
        files_sent_this_minute += 1
```

### Why Rate Limiting?

**Problems Without Rate Limiting:**
1. **n8n Overload** - Too many concurrent workflows crash n8n
2. **API Limits** - OpenAI/Gemini rate limits exceeded
3. **Database Locks** - Too many concurrent UPDATEs block each other
4. **Memory Issues** - Processing large images in parallel exhausts RAM

**Benefits:**
- ✅ Stable n8n performance
- ✅ Predictable processing times
- ✅ No API rate limit errors
- ✅ Lower resource usage

### Adjusting Rate Limits

**Increase rate limit** (if system can handle more):
```json
{
    "text_queue": {
        "rate_limit_per_minute": 10
    }
}
```

**Decrease rate limit** (if n8n struggling):
```json
{
    "image_queue": {
        "rate_limit_per_minute": 1
    }
}
```

**Consider:**
- Text files process faster (1-3s) → can handle higher rate
- Images process slower (3-10s) → need lower rate
- Monitor n8n CPU/memory usage

---

## 🛡️ Error Handling & Resilience

### Error Types & Recovery

| Error Type | Detection | Recovery | Retry |
|------------|-----------|----------|-------|
| **File Not Found** | `FileNotFoundError` | Skip file, log error | No |
| **No email_id** | `extract_email_id() == None` | Skip file, log warning | No |
| **No attachment_id** | `get_attachment_id() == None` | Skip file, log warning | No |
| **Database Connection** | `psycopg2.OperationalError` | Reconnect, retry | Yes (3x) |
| **Duplicate Entry** | `psycopg2.IntegrityError` | Skip (already queued) | No |
| **n8n Webhook Down** | `requests.ConnectionError` | Log error, queue persists | No (n8n will process when up) |
| **Rate Limit Hit** | Counter check | Wait until next minute | Automatic |
| **Small Image** | File size < 50KB | Skip (filter), log debug | No |

### Retry Mechanism

**Configuration:**
```json
{
    "retry": {
        "max_attempts": 3,
        "initial_delay_seconds": 5,
        "backoff_multiplier": 2
    }
}
```

**Retry Logic:**
```python
def add_to_queue_with_retry(self, file_path: Path, email_id: int, attachment_id: int):
    """Add to queue with exponential backoff retry"""
    max_attempts = self.retry_config['max_attempts']
    delay = self.retry_config['initial_delay_seconds']
    multiplier = self.retry_config['backoff_multiplier']
    
    for attempt in range(max_attempts):
        try:
            return self.add_to_queue(file_path, email_id, attachment_id)
        except psycopg2.OperationalError as e:
            if attempt < max_attempts - 1:
                wait = delay * (multiplier ** attempt)
                logger.warning(f"Database error, retry {attempt+1}/{max_attempts} in {wait}s")
                time.sleep(wait)
            else:
                logger.error(f"Failed after {max_attempts} attempts: {e}")
                return False
```

**Retry Schedule:**
- Attempt 1: Immediate
- Attempt 2: Wait 5 seconds
- Attempt 3: Wait 10 seconds
- Attempt 4: Wait 20 seconds
- Give up after 4 attempts

### Graceful Shutdown

```python
def run_continuous(self):
    try:
        while True:
            # Main loop
            pass
    except KeyboardInterrupt:
        logger.info("Shutting down gracefully...")
        self.close_database_connection()
        logger.info("Shutdown complete")
```

**Ctrl+C behavior:**
- Finish current file processing
- Close database connections
- Log shutdown message
- Exit cleanly

---

## 📊 Logging & Monitoring

### Log Files

Queue Managers maintain separate log files:

#### 1. Text Queue Manager Log

**Location:** `C:\Python_project\CargoFlow\Cargoflow_Queue\text_queue_manager.log`

**Configuration:**
```python
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        RotatingFileHandler(
            'text_queue_manager.log',
            maxBytes=10*1024*1024,
            backupCount=5
        ),
        logging.StreamHandler()  # Also print to console
    ]
)
```

**Example Output:**
```
2025-11-06 14:30:22 - INFO - Starting TextQueueManager
2025-11-06 14:30:22 - INFO - Watching: C:\CargoProcessing\...\ocr_results
2025-11-06 14:30:22 - INFO - Webhook: http://localhost:5678/webhook/analyze-text
2025-11-06 14:30:22 - INFO - Rate limit: 3 files/minute
2025-11-06 14:30:30 - INFO - Found 5 new files
2025-11-06 14:30:31 - INFO - ✅ Found email_id 123 for file_extracted.txt
2025-11-06 14:30:32 - INFO - ✅ Found attachment_id 456 for file_extracted.txt
2025-11-06 14:30:33 - INFO - ✅ Added to queue: file_extracted.txt
2025-11-06 14:31:00 - INFO - ⏳ Rate limit reached, waiting 27s
```

---

#### 2. Image Queue Manager Log

**Location:** `C:\Python_project\CargoFlow\Cargoflow_Queue\image_queue_manager.log`

**Example Output:**
```
2025-11-06 14:30:22 - INFO - Starting ImageQueueManager
2025-11-06 14:30:22 - INFO - Watching: C:\CargoProcessing\...\images
2025-11-06 14:30:22 - INFO - Webhook: http://localhost:5678/webhook/analyze-image
2025-11-06 14:30:22 - INFO - Min file size: 50 KB
2025-11-06 14:30:30 - DEBUG - Skipping small image: logo.png (15 KB)
2025-11-06 14:30:31 - INFO - ✅ Found email_id 123 for document_1.png
2025-11-06 14:30:32 - INFO - ✅ Found attachment_id 456 for document_1.png
2025-11-06 14:30:33 - INFO - ✅ Added to queue: document_1.png
2025-11-06 14:30:34 - WARNING - ⚠️ No attachment_id for document_2.png, skipping
```

---

### Key Log Messages

**Startup:**
```
Starting TextQueueManager (or ImageQueueManager)
Watching: [directory path]
Webhook: [n8n webhook URL]
Rate limit: X files/minute
Min file size: X KB (images only)
```

**File Processing:**
```
Found X new files
✅ Found email_id XXX for file.txt
✅ Found attachment_id XXX for file.txt
✅ Added to queue: file.txt
```

**Warnings:**
```
⚠️ No email_id for file.txt, skipping
⚠️ No attachment_id for file.txt, skipping
Skipping small image: logo.png (15 KB)
```

**Rate Limiting:**
```
⏳ Rate limit reached, waiting Xs
```

**Errors:**
```
❌ Error adding to queue: [error message]
❌ Database connection failed: [error]
Error in main loop: [exception]
```

---

### Monitoring Queries

#### Queue Health Check

```sql
-- Overall queue status
SELECT 
    file_type,
    status,
    COUNT(*) as count,
    MIN(created_at) as oldest_pending,
    MAX(created_at) as latest_pending
FROM processing_queue
GROUP BY file_type, status;
```

#### Processing Rate

```sql
-- Files processed per hour (last 24 hours)
SELECT 
    DATE_TRUNC('hour', created_at) as hour,
    file_type,
    COUNT(*) as files_queued
FROM processing_queue
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY DATE_TRUNC('hour', created_at), file_type
ORDER BY hour DESC;
```

#### Success Rate

```sql
-- Success vs failure rate
SELECT 
    file_type,
    status,
    COUNT(*) as count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY file_type), 1) as percentage
FROM processing_queue
GROUP BY file_type, status
ORDER BY file_type, status;
```

---

## 🚀 Usage & Deployment

### Installation

**Prerequisites:**
- Python 3.11+
- PostgreSQL 17 with NOTIFY/LISTEN
- n8n running on localhost:5678

**Steps:**

```bash
# 1. Navigate to module directory
cd C:\Python_project\CargoFlow\Cargoflow_Queue

# 2. Create virtual environment
python -m venv venv

# 3. Activate virtual environment
venv\Scripts\activate  # Windows
# source venv/bin/activate  # Linux/Mac

# 4. Install dependencies
pip install -r requirements.txt

# 5. Configure queue_config.json
# Edit paths, webhook URLs if needed

# 6. Test database connection
python -c "import psycopg2; conn = psycopg2.connect(host='localhost', database='Cargo_mail', user='postgres', password='Lora24092004'); print('✅ Database OK')"

# 7. Verify n8n is running
curl http://localhost:5678/webhook/analyze-text
curl http://localhost:5678/webhook/analyze-image
```

---

### Running the Modules

#### Terminal 1: Text Queue Manager

```bash
cd C:\Python_project\CargoFlow\Cargoflow_Queue
venv\Scripts\activate
python text_queue_manager.py
```

**Expected Output:**
```
Starting TextQueueManager
Watching: C:\CargoProcessing\processed_documents\2025\ocr_results
Webhook: http://localhost:5678/webhook/analyze-text
Rate limit: 3 files/minute
Scanning directory for existing files...
File watcher started. Press Ctrl+C to stop.
```

---

#### Terminal 2: Image Queue Manager

```bash
cd C:\Python_project\CargoFlow\Cargoflow_Queue
venv\Scripts\activate
python image_queue_manager.py
```

**Expected Output:**
```
Starting ImageQueueManager
Watching: C:\CargoProcessing\processed_documents\2025\images
Webhook: http://localhost:5678/webhook/analyze-image
Rate limit: 3 files/minute
Min file size: 50 KB
Scanning directory for existing files...
File watcher started. Press Ctrl+C to stop.
```

---

### System Integration

**Queue Managers run as part of 7-process CargoFlow system:**

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

# Terminal 4: Text Queue Manager ← YOU ARE HERE
cd C:\Python_project\CargoFlow\Cargoflow_Queue
venv\Scripts\activate
python text_queue_manager.py

# Terminal 5: Image Queue Manager ← YOU ARE HERE
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

#### Issue 1: Queue Managers Not Finding Files

**Symptoms:**
- OCR/Office creates files
- But Queue Managers report "No new files"

**Causes:**
1. watch_path incorrect in config
2. File pattern doesn't match
3. Files already in processing_queue

**Solution:**

1. **Verify watch_path:**
   ```json
   // In queue_config.json
   "watch_path": "C:\\CargoProcessing\\processed_documents\\2025\\ocr_results"
   // Check if this directory exists and has files
   ```

2. **Check file pattern:**
   ```bash
   # Windows
   dir /s "C:\CargoProcessing\processed_documents\2025\ocr_results\*_extracted.txt"
   
   # Linux
   find /path/to/ocr_results -name "*_extracted.txt"
   ```

3. **Check if already queued:**
   ```sql
   SELECT COUNT(*) FROM processing_queue
   WHERE file_path LIKE '%extracted.txt%';
   ```

---

#### Issue 2: No email_id or attachment_id Found

**Symptoms:**
```
⚠️ No email_id for file.txt, skipping
⚠️ No attachment_id for file.txt, skipping
```

**Causes:**
1. File metadata missing or malformed
2. Email not in database
3. Attachment name doesn't match

**Solution:**

1. **Check file metadata:**
   ```bash
   # Read first 500 chars of text file
   head -c 500 file_extracted.txt
   # Look for JSON with email_id
   ```

2. **Check if email exists:**
   ```sql
   SELECT id, sender_email, subject
   FROM emails
   WHERE id = [email_id from file];
   ```

3. **Check attachment records:**
   ```sql
   SELECT id, attachment_name
   FROM email_attachments
   WHERE email_id = [email_id];
   ```

4. **Verify path structure:**
   ```
   Expected: C:\CargoProcessing\...\sender@company.com\Subject\file_extracted.txt
   Actual: [check your file path]
   ```

---

#### Issue 3: Rate Limit Too Restrictive

**Symptoms:**
- Many files pending
- But Queue Manager stuck waiting
- "⏳ Rate limit reached" in logs

**Cause:** Rate limit too low for file volume

**Solution:**

1. **Check pending files:**
   ```sql
   SELECT COUNT(*) FROM processing_queue WHERE status = 'pending';
   ```

2. **Increase rate limit:**
   ```json
   // In queue_config.json
   {
       "text_queue": {
           "rate_limit_per_minute": 10  // Was 3
       }
   }
   ```

3. **Restart Queue Manager** (to apply new config)

4. **Monitor n8n performance:**
   - If n8n struggles with higher rate, decrease again
   - Check CPU/memory usage

---

#### Issue 4: PostgreSQL NOTIFY Not Working

**Symptoms:**
- Files added to processing_queue
- But n8n not receiving notifications
- Status stuck on 'pending'

**Causes:**
1. Trigger not created
2. n8n not listening
3. Database connection issues

**Solution:**

1. **Check trigger exists:**
   ```sql
   SELECT tgname, tgenabled 
   FROM pg_trigger 
   WHERE tgname LIKE '%notify%queue%';
   ```

2. **Test NOTIFY manually:**
   ```sql
   -- Terminal 1: Listen
   LISTEN n8n_text_channel;
   
   -- Terminal 2: Notify
   NOTIFY n8n_text_channel, 'test message';
   
   -- Terminal 1 should show: Asynchronous notification "n8n_text_channel"
   ```

3. **Check n8n logs:**
   ```
   # n8n terminal output
   # Look for: "PostgreSQL notification received"
   ```

4. **Restart n8n:**
   ```bash
   # Ctrl+C to stop
   n8n start
   ```

---

#### Issue 5: Small Images Being Queued

**Symptoms:**
- Logos, signatures, banners in queue
- Wasting AI processing time

**Cause:** Image filter disabled or threshold too low

**Solution:**

1. **Enable filter:**
   ```json
   {
       "image_filters": {
           "min_file_size_kb": 50,
           "skip_small_images": true  // Enable
       }
   }
   ```

2. **Adjust threshold** (if needed):
   ```json
   {
       "image_filters": {
           "min_file_size_kb": 100  // Increase threshold
       }
   }
   ```

3. **Restart Image Queue Manager**

---

#### Issue 6: Database Connection Lost

**Symptoms:**
```
❌ Error adding to queue: connection already closed
Database connection failed: could not connect to server
```

**Causes:**
1. PostgreSQL server down
2. Network issues
3. Connection timeout

**Solution:**

1. **Check PostgreSQL status:**
   ```bash
   # Windows
   sc query postgresql-x64-17
   
   # Linux
   systemctl status postgresql
   ```

2. **Test connection:**
   ```bash
   psql -h localhost -U postgres -d Cargo_mail
   # Enter password: Lora24092004
   ```

3. **Restart PostgreSQL:**
   ```bash
   # Windows
   sc stop postgresql-x64-17
   sc start postgresql-x64-17
   
   # Linux
   sudo systemctl restart postgresql
   ```

4. **Restart Queue Managers** (they will reconnect)

---

## 🔗 Related Documentation

- [Database Schema](../DATABASE_SCHEMA.md) - `processing_queue` table structure
- [OCR Processor](02_OCR_PROCESSOR.md) - Creates files for text queue
- [Office Processor](03_OFFICE_PROCESSOR.md) - Creates files for text queue
- [n8n Workflows](05_N8N_WORKFLOWS.md) - Next modules (AI analysis)
- [Status Flow Map](../docs/STATUS_FLOW_MAP.md) - Complete system status flow

---

**Module Status:** ✅ Production Ready  
**Last Updated:** November 06, 2025  
**Maintained by:** CargoFlow DevOps Team
