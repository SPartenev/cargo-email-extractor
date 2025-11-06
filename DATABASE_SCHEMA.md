# CargoFlow Database Schema Documentation

**Database Name:** `Cargo_mail`  
**Engine:** PostgreSQL 17  
**Server:** localhost:5432  
**Total Tables:** 19  
**Last Updated:** November 05, 2025

---

## 📊 Database Overview

### Total Size: ~11.8 MB

| Table | Size | Columns | Records | Purpose |
|-------|------|---------|---------|---------|
| **emails** | 8.7 MB | 42 | 226 | Email metadata and analysis |
| **processing_queue** | 1.1 MB | 16 | 213 | Queue for file processing |
| **processing_history** | 816 KB | 11 | Many | Processing logs |
| **email_attachments** | 440 KB | 17 | 296 | File attachments with AI categories |
| **invoice_base** | 208 KB | 35 | Few | Invoice data |
| **contract_detection_queue** | 120 KB | 7 | ? | Contract detection queue |
| **document_pages** | 112 KB | 9 | Few | Individual page categories |
| **contracts** | 112 KB | 9 | 0 | Detected contracts |
| **contract_documents** | 96 KB | 13 | Few | Contract-document relationships |
| **invoice_items** | 56 KB | 12 | Few | Invoice line items |
| Others | ~300 KB | Various | Various | Support tables |

---

## 🗂️ Core Tables (Detailed)

### 1. **emails** (Main Email Table)

**Purpose:** Stores all email metadata from Microsoft Graph API

**Key Columns:**
| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | integer | NO | Primary key |
| `subject` | text | YES | Email subject |
| `sender_name` | varchar | YES | Sender name |
| `sender_email` | varchar | YES | Sender email address |
| `recipients` | text | YES | To: recipients |
| `received_time` | timestamp | YES | When email was received |
| `sent_time` | timestamp | YES | When email was sent |
| `body_text` | text | YES | Plain text body |
| `body_html` | text | YES | HTML body |
| `has_attachments` | boolean | YES | Has attachments? |
| `attachment_count` | integer | YES | Number of attachments |
| `attachment_folder` | text | YES | Folder path for attachments |
| `attachment_paths` | jsonb | YES | JSON array of file paths |
| `entry_id` | varchar | YES | Unique message ID (UNIQUE) |
| `folder_name` | varchar | YES | Folder name |
| `created_at` | timestamp | YES | Record creation time |

**AI Analysis Columns:**
| Column | Type | Description |
|--------|------|-------------|
| `analysis_result` | jsonb | Full AI analysis result |
| `analysis_timestamp` | timestamp | When analyzed |
| `analysis_status` | varchar | 'pending', 'completed', 'failed' |
| `analysis_summary` | text | AI summary of email |
| `analysis_categories` | array | Detected categories |
| `analysis_priority` | varchar | Priority level |
| `analysis_action_items` | jsonb | Action items extracted |
| `needs_response` | boolean | Requires response? |

**Document Classification Columns:**
| Column | Type | Description |
|--------|------|-------------|
| `document_category` | varchar | Primary document type |
| `document_count` | integer | Number of documents |
| `classification_summary` | text | Classification summary |
| `classification_confidence` | numeric | Confidence score |
| `classification_timestamp` | timestamp | When classified |

**Invoice Columns:**
| Column | Type | Description |
|--------|------|-------------|
| `potential_invoice` | boolean | May contain invoice? |
| `invoice_processed` | boolean | Invoice extracted? |
| `extracted_invoice_text` | text | Extracted invoice text |
| `invoice_extraction_method` | varchar | Extraction method used |
| `invoice_extraction_timestamp` | timestamp | When extracted |

**Folder Organization:**
| Column | Type | Description |
|--------|------|-------------|
| `contract_folder_name` | varchar | Organized folder name |

**Indexes:**
- Primary key on `id`
- Unique index on `entry_id`
- Index on `sender_email`
- Index on `received_time`
- Index on `analysis_status`

---

### 2. **email_attachments** (File Attachments)

**Purpose:** Tracks all file attachments with AI classification

**Columns:**
| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | integer | NO | Primary key |
| `email_id` | integer | YES | Foreign key to emails |
| `attachment_name` | varchar | YES | Original filename |
| `attachment_path` | text | YES | Full file path |
| `attachment_size` | bigint | YES | File size in bytes |
| `attachment_type` | varchar | YES | File extension/MIME type |
| `created_at` | timestamp | YES | Record creation time |
| `document_category` | varchar | YES | AI-assigned category (13 types) |
| `confidence_score` | numeric | YES | AI confidence (0.0-1.0) |
| `classification_timestamp` | timestamp | YES | When AI categorized |
| `extracted_data` | jsonb | YES | AI-extracted data |
| `processing_status` | varchar | YES | 'pending', 'completed', 'failed' |
| `processed_at` | timestamp | YES | When processed |
| `error_message` | text | YES | Error if failed |
| `classification_summary` | text | YES | AI summary |
| `total_pages` | integer | YES | Number of pages (PDF) |
| `contract_number` | varchar | YES | Extracted contract number |

**Document Categories (13 Types):**
1. `contract` - Main contracts
2. `contract_amendment` - Contract amendments
3. `contract_termination` - Contract terminations
4. `contract_extension` - Contract extensions
5. `service_agreement` - Service agreements
6. `framework_agreement` - Framework agreements
7. `cmr` - CMR transport documents
8. `protocol` - Protocols
9. `annex` - Annexes/attachments
10. `insurance` - Insurance documents
11. `invoice` - Invoices
12. `credit_note` - Credit notes
13. `other` - Uncategorized

**Indexes:**
- Primary key on `id`
- Foreign key on `email_id`
- Index on `processing_status`
- Index on `document_category`
- Index on `contract_number`

---

### 3. **processing_queue** (Processing Queue)

**Purpose:** Queue for document processing workflow

**Columns:**
| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | integer | NO | Primary key |
| `file_path` | text | NO | Full file path |
| `file_type` | varchar | NO | 'text' or 'image' |
| `status` | varchar | YES | 'pending', 'completed', 'failed' |
| `priority` | integer | YES | Priority (higher = more important) |
| `attempts` | integer | YES | Number of processing attempts |
| `max_attempts` | integer | YES | Maximum attempts (default: 3) |
| `created_at` | timestamp | YES | When queued |
| `processed_at` | timestamp | YES | When completed |
| `last_attempt_at` | timestamp | YES | Last attempt time |
| `error_message` | text | YES | Error message if failed |
| `email_id` | integer | YES | Related email ID |
| `attachment_id` | integer | YES | Related attachment ID |
| `file_metadata` | jsonb | YES | Additional metadata |
| `original_document` | varchar | YES | Original document name |
| `group_processing_status` | varchar | YES | Group processing status |

**Status Values:**
- `pending` - Waiting to be processed
- `completed` - Successfully processed
- `failed` - Processing failed

**Indexes:**
- Primary key on `id`
- Unique index on `file_path`
- Index on `status`
- Index on `file_type`
- Index on `email_id`
- Index on `attachment_id`

---

### 4. **document_pages** (Individual Pages)

**Purpose:** Tracks categories for individual pages in multi-page documents

**Columns:**
| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | integer | NO | Primary key |
| `attachment_id` | integer | YES | Foreign key to email_attachments |
| `page_number` | integer | NO | Page number (1-based) |
| `category` | varchar | YES | Page category |
| `confidence_score` | numeric | YES | AI confidence |
| `summary` | text | YES | Page summary |
| `contract_number` | varchar | YES | Contract number on this page |
| `contract_number_confidence` | numeric | YES | Contract number confidence |
| `created_at` | timestamp | YES | Record creation time |

**Purpose:**
- Allows different pages in a PDF to have different categories
- Example: Page 1 = invoice, Page 2-3 = CMR
- Enables better document organization

---

### 5. **contracts** (Detected Contracts)

**Purpose:** Stores detected contract information

**Columns:**
| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | integer | NO | Primary key |
| `contract_number` | varchar | YES | Contract number |
| `email_id` | integer | YES | Source email |
| `attachment_id` | integer | YES | Source attachment |
| `contract_type` | varchar | YES | Type of contract |
| `confidence_score` | numeric | YES | Detection confidence |
| `detected_at` | timestamp | YES | When detected |
| `folder_path` | text | YES | Organized folder path |
| `metadata` | jsonb | YES | Additional metadata |

---

### 6. **email_ready_queue** (Email Organization Queue)

**Purpose:** Queue for emails ready for folder organization

**Columns:**
| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `email_id` | integer | NO | Email to organize (UNIQUE) |
| `ready_at` | timestamp | YES | When marked ready |
| `processed` | boolean | YES | Organization completed? |
| `processed_at` | timestamp | YES | When organized |

**Purpose:**
- Lightweight queue for folder organization
- Replaces heavy trigger that caused performance issues
- Processed by contract processor

---

### 7. **contract_folder_seq** (Contract Folder Sequencing)

**Purpose:** Tracks folder indices for contract organization

**Columns:**
| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `contract_key` | varchar | NO | Contract number(s) key (PRIMARY KEY) |
| `last_index` | integer | YES | Last used index |
| `updated_at` | timestamp | YES | Last update time |

**Purpose:**
- Generates unique folder names for same contract
- Example: `50251006834_001`, `50251006834_002`
- Avoids file system conflicts

---

### 8. **invoice_base** (Invoice Data)

**Purpose:** Stores extracted invoice information

**35 Columns** including:
- Invoice number, date, amount
- Vendor details
- Payment terms
- Tax information
- Related email/attachment IDs

---

### 9. **invoice_items** (Invoice Line Items)

**Purpose:** Stores individual line items from invoices

**12 Columns** including:
- Item description
- Quantity, unit price
- Line total
- Tax details

---

## 🔧 Database Functions (13 Total)

### Trigger Functions

| Function | Return Type | Purpose |
|----------|-------------|---------|
| `notify_n8n_text_queue()` | trigger | Sends PostgreSQL NOTIFY for text files |
| `notify_n8n_image_queue()` | trigger | Sends PostgreSQL NOTIFY for images |
| `match_attachment_on_queue_insert()` | trigger | Matches queue items with attachments |
| `update_queue_attachment_id()` | trigger | Updates attachment IDs in queue |
| `queue_email_for_folder_update()` | trigger | Queues emails for folder organization |
| `process_email_contracts()` | trigger | Processes email contracts |
| `queue_contract_detection()` | trigger | Queues contract detection |

### Utility Functions

| Function | Return Type | Purpose |
|----------|-------------|---------|
| `get_contracts_by_email()` | record | Gets contracts for an email |
| `get_pending_contract_detections()` | record | Gets pending detections |
| `mark_detection_completed()` | void | Marks detection as complete |
| `mark_detection_error()` | void | Marks detection as error |
| `get_invoice_json()` | jsonb | Returns invoice as JSON |
| `generate_microinvest_csv_for_email()` | record | Exports invoice to CSV |

---

## ⚡ Database Triggers (8 Total)

| Trigger Name | Table | Event | Function | Purpose |
|--------------|-------|-------|----------|---------|
| `trigger_notify_text` | processing_queue | INSERT | notify_n8n_text_queue | Notifies n8n for text analysis |
| `trigger_notify_image` | processing_queue | INSERT | notify_n8n_image_queue | Notifies n8n for image analysis |
| `trigger_match_attachment_on_insert` | processing_queue | INSERT | match_attachment_on_queue_insert | Links queue items to attachments |
| `trigger_update_queue_attachment_id` | email_attachments | INSERT, UPDATE | update_queue_attachment_id | Updates queue with attachment IDs |
| `trigger_queue_email` | email_attachments | UPDATE | queue_email_for_folder_update | Queues for folder organization |
| `trigger_process_email_contracts` | email_attachments | UPDATE | process_email_contracts | Processes contracts |
| `contract_detection_trigger` | email_attachments | UPDATE | queue_contract_detection | Triggers contract detection |

---

## 📈 Status Flow Map

### Email Processing Status Flow

```
emails.analysis_status:
  pending → (AI analysis) → completed / failed
```

### Attachment Processing Status Flow

```
email_attachments.processing_status:
  pending → (OCR/Office) → completed → (AI categorization) → completed
                        ↘ failed
```

### Queue Processing Status Flow

```
processing_queue.status:
  pending → (Queue manager) → completed (→ n8n workflows)
         ↘ failed (after max_attempts)
```

### Group Processing Status Flow

```
processing_queue.group_processing_status:
  pending → (All pages ready) → ready_for_group → (n8n processes all) → completed
```

---

## 🔍 Important Queries

### System Health Check

```sql
-- Overall status
SELECT 
    'emails' as table_name, COUNT(*) as count FROM emails
UNION ALL
SELECT 'attachments', COUNT(*) FROM email_attachments
UNION ALL
SELECT 'categorized', COUNT(*) FROM email_attachments WHERE document_category IS NOT NULL
UNION ALL
SELECT 'queue_pending', COUNT(*) FROM processing_queue WHERE status = 'pending'
UNION ALL
SELECT 'contracts', COUNT(*) FROM contracts;
```

### Processing Queue Status

```sql
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

### AI Categorization Progress

```sql
SELECT 
    document_category,
    COUNT(*) as count,
    ROUND(AVG(confidence_score), 2) as avg_confidence
FROM email_attachments
WHERE document_category IS NOT NULL
GROUP BY document_category
ORDER BY count DESC;
```

### Recent Activity

```sql
SELECT 
    'last_email' as event,
    MAX(received_time)::text as timestamp
FROM emails
UNION ALL
SELECT 'last_categorization', MAX(classification_timestamp)::text
FROM email_attachments
UNION ALL
SELECT 'last_queue_process', MAX(processed_at)::text
FROM processing_queue;
```

### Contract Numbers Extracted

```sql
SELECT 
    contract_number,
    COUNT(*) as file_count,
    STRING_AGG(DISTINCT document_category, ', ') as categories
FROM email_attachments
WHERE contract_number IS NOT NULL
GROUP BY contract_number
ORDER BY file_count DESC;
```

---

## 🔐 Database Credentials

**Connection String:**
```
host: localhost
port: 5432
database: Cargo_mail
user: postgres
password: [REDACTED - see graph_config.json]
```

---

## 📊 Database Maintenance

### Vacuum and Analyze

```sql
-- Regular maintenance
VACUUM ANALYZE emails;
VACUUM ANALYZE email_attachments;
VACUUM ANALYZE processing_queue;
```

### Check Table Sizes

```sql
SELECT 
    table_name,
    pg_size_pretty(pg_total_relation_size(quote_ident(table_name)::regclass)) as size
FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
ORDER BY pg_total_relation_size(quote_ident(table_name)::regclass) DESC;
```

### Check Active Connections

```sql
SELECT count(*) as connections 
FROM pg_stat_activity 
WHERE datname = 'Cargo_mail';
```

---

## 🚨 Troubleshooting

### Kill Long-Running Queries

```sql
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state = 'active' 
AND query_start < NOW() - INTERVAL '5 minutes'
AND datname = 'Cargo_mail';
```

### Reset Failed Queue Items

```sql
UPDATE processing_queue
SET status = 'pending', attempts = 0
WHERE status = 'failed' AND attempts >= max_attempts;
```

### Find Blocking Queries

```sql
SELECT 
    blocked_locks.pid AS blocked_pid,
    blocked_activity.usename AS blocked_user,
    blocking_locks.pid AS blocking_pid,
    blocking_activity.usename AS blocking_user,
    blocked_activity.query AS blocked_statement,
    blocking_activity.query AS blocking_statement
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks 
    ON blocking_locks.locktype = blocked_locks.locktype
    AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
    AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
    AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
    AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
    AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
    AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
    AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
    AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
    AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
    AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;
```

---

**Last Updated:** November 05, 2025  
**Database Version:** PostgreSQL 17  
**Schema Version:** 2.0
