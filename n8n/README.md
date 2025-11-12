# n8n Workflows Documentation

**n8n Server:** localhost:5678  
**Last Updated:** November 12, 2025  
**Status:** ⚠️ Status unknown - needs verification

---

## 📁 Folder Structure

```
n8n/
├── workflows/       # n8n workflow JSON files
└── README.md        # This file
```

---

## 🔄 Active Workflows

### 1. Contract_Text_CargoFlow (Text Document Analysis)

**Workflow File:** `Contract_Text_CargoFlow.json`  
**Purpose:** AI categorization and data extraction from text documents

**Trigger:** PostgreSQL NOTIFY on `n8n_channel_contract_text`

**Input:** Text files from OCR/Office processing
- Location: `C:\CargoProcessing\processed_documents\2025\ocr_results\`
- Format: `*_extracted.txt`
- Source: `processing_queue` table where `file_type = 'text'`

**AI Model:** OpenAI GPT-4o-mini-2024-07-18

**Process Flow:**
1. **PostgreSQL Trigger** → Listens on `n8n_channel_contract_text`
2. **Switch Node** → Routes based on file extension (.txt vs .png)
3. **Read File** → Loads text content from file system
4. **AI Category Agent** → Analyzes document and extracts:
   - Document category (13 types)
   - Confidence score
   - Contract number (patterns: 50XXXXXXXXX, 20XXXXXXXXX)
   - Document grouping information
   - Page numbering
5. **Code Parser** → Parses AI JSON response, handles markdown cleanup
6. **Update email_attachments** → Updates with category, confidence, contract_number
7. **Insert document_pages** → Creates page-level records for multi-page documents
8. **Invoice Extraction** (if category = 'invoice'):
   - **Information Extractor** → Extracts structured invoice data
   - **Format Dates** → Converts DD/MM/YYYY to YYYY-MM-DD
   - **Insert invoice_base** → Saves invoice details

**AI Categories (13):**
- contract — договор
- contract_amendment — изменение на договор
- contract_termination — прекратяване на договор
- contract_extension — продължаване на договор
- service_agreement — споразумение за услуги
- framework_agreement — рамково споразумение
- cmr — CMR (международен товарителски документ)
- protocol — протокол
- annex — анекс
- insurance — застраховка
- invoice — фактура
- credit_note — кредитно известие
- other — друго

**Database Updates:**
- `email_attachments`: `document_category`, `confidence_score`, `contract_number`, `classification_timestamp`, `total_pages`
- `document_pages`: Individual page records with category, confidence, contract_number
- `invoice_base`: Invoice details (if invoice category detected)

**Contract Number Extraction:**
- Searches for patterns: `50XXXXXXXXX`, `20XXXXXXXXX` (10-11 digits)
- Looks for prefixes: "Договор №", "Contract No.", "№", "No."
- Extracts full contract number including prefixes/suffixes

---

### 2. Contract_PNG_ CargoFlow (Image/Page Analysis)

**Workflow File:** `Contract_PNG_ CargoFlow.json`  
**Purpose:** AI categorization of individual PNG pages from multi-page documents

**Trigger:** PostgreSQL NOTIFY on `n8n_channel_contract_png` (or similar)

**Input:** PNG images from OCR processing
- Location: `C:\CargoProcessing\processed_documents\2025\images\`
- Format: `*.png`
- Source: `processing_queue` table where `file_type = 'image'` and `group_processing_status = 'ready_for_group'`

**AI Model:** Google Gemini (gemini-pro) with vision capabilities

**Process Flow:**
1. **PostgreSQL Trigger** → Listens for image processing notifications
2. **Execute SQL Query** → Fetches all PNG pages for the same document:
   ```sql
   SELECT id, file_path, email_id, attachment_id, 
          file_metadata->>'page_number' as page_number,
          file_metadata->>'total_pages' as total_pages
   FROM processing_queue
   WHERE original_document = '{original_document}'
     AND attachment_id = {attachment_id}
     AND file_type = 'image'
     AND group_processing_status = 'ready_for_group'
   ORDER BY (file_metadata->>'page_number')::int
   ```
3. **Read All Files** → Loads all PNG files for the document
4. **Aggregate** → Combines all pages into single input
5. **AI Category Agent** → Analyzes EACH PAGE separately:
   - Returns array with one object per page
   - Each page gets its own category
   - Contract number extraction per page
6. **Code Parser** → Parses AI response array, maps to page structure
7. **If Invoice** → Conditional branch for invoice extraction
8. **Invoice Extraction** (if any page = 'invoice'):
   - **Information Extractor** → Extracts structured invoice data
   - **Format Dates** → Converts dates
   - **Insert invoice_base** → Saves invoice details
9. **Update email_attachments** → Updates main attachment record
10. **Insert document_pages** → Creates individual page records with:
    - `attachment_id`
    - `page_number`
    - `category` (per page)
    - `confidence_score`
    - `contract_number`
    - `summary`

**Key Features:**
- **Page-by-Page Analysis:** Each PNG page analyzed individually
- **Multi-Category Support:** Different pages can have different categories
- **Group Processing:** All pages from same document processed together
- **Contract Number per Page:** Each page can have its own contract number

**Database Updates:**
- `email_attachments`: Main document category (from first page or most common)
- `document_pages`: Individual page records (one per PNG)
- `invoice_base`: Invoice details (if invoice pages detected)

---

### 4. XLSX Generator (Future - Optional)

**Purpose:** Generate XML/XLSX files for accounting software

**Trigger:** Manual or scheduled

**Process:**
1. Collect processed invoices
2. Generate XML/XLSX format
3. Send via email or save to folder

**Status:** 📝 Planned for future implementation

---

## 🔧 Workflow Configuration

### AI Model Settings

**Contract_Text_CargoFlow:**
- **Model:** OpenAI GPT-4o-mini-2024-07-18
- **Temperature:** Default (typically 0.1-0.3)
- **Max Tokens:** Default
- **Purpose:** Text document categorization and contract number extraction

**Contract_PNG_ CargoFlow:**
- **Model:** Google Gemini (gemini-pro)
- **Max Output Tokens:** 32768
- **Purpose:** Image/vision analysis for PNG pages
- **Capabilities:** Multi-page document analysis, per-page categorization

### Rate Limiting

**Current Settings:**
- **Text Queue:** 3 files/minute
- **Image Queue:** 3 files/minute

**Reason:** Prevent AI API rate limit errors

**Configured in:** `config/queue_config.json`

---

## 📊 PostgreSQL Integration

### NOTIFY/LISTEN Mechanism

**Text Processing:**
```sql
-- Trigger function (actual implementation)
CREATE FUNCTION notify_n8n_text_queue()
RETURNS trigger AS $$
BEGIN
  PERFORM pg_notify('n8n_channel_contract_text', 
    json_build_object(
      'file_path', NEW.file_path,
      'attachment_id', NEW.attachment_id,
      'email_id', NEW.email_id,
      'original_document', NEW.original_document,
      'file_metadata', NEW.file_metadata
    )::text
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER trigger_notify_text
AFTER INSERT ON processing_queue
FOR EACH ROW
WHEN (NEW.status = 'pending' AND NEW.file_type = 'text')
EXECUTE FUNCTION notify_n8n_text_queue();
```

**Image Processing:**
```sql
-- Similar structure for images
-- Channel: n8n_channel_contract_png (or similar)
-- Triggered when group_processing_status = 'ready_for_group'
CREATE FUNCTION notify_n8n_image_queue()
RETURNS trigger AS $$
BEGIN
  PERFORM pg_notify('n8n_channel_contract_png', 
    json_build_object(
      'file_path', NEW.file_path,
      'attachment_id', NEW.attachment_id,
      'email_id', NEW.email_id,
      'original_document', NEW.original_document,
      'file_metadata', NEW.file_metadata
    )::text
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

---

## 🚀 Setup Instructions

### 1. Install n8n

```bash
# Global installation
npm install -g n8n

# Or with Docker
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n
```

### 2. Import Workflows

1. Access n8n: `http://localhost:5678`
2. Navigate to **Workflows** → **Import from File**
3. Import JSON files from `Cargoflow_n8n/` folder:
   - `Contract_Text_CargoFlow.json`
   - `Contract_PNG_ CargoFlow.json`
4. Configure credentials:
   - **OpenAI API** (for Contract_Text_CargoFlow)
     - Credential name: "OpenAi account"
     - Model: gpt-4o-mini-2024-07-18
   - **Google Gemini API** (for Contract_PNG_ CargoFlow)
     - Credential name: "Invoice_Email" or "Teka" or "Gemini(PaLM) Api 1"
     - Model: gemini-pro
   - **PostgreSQL** (for both workflows)
     - Credential name: "Cargo_mail"
     - Database: Cargo_mail
5. Activate workflows (toggle switch in n8n UI)

### 3. Configure PostgreSQL Connection

**In n8n:**
1. Go to **Credentials** → **New**
2. Select **Postgres**
3. Enter connection details:
   - Host: localhost
   - Port: 5432
   - Database: Cargo_mail
   - User: postgres
   - Password: [your password]
4. Enable **SSL: Disable**
5. Test connection

### 4. Configure AI API

**For OpenAI (Contract_Text_CargoFlow):**
1. Get API key from https://platform.openai.com
2. In n8n: **Credentials** → **New** → **OpenAI API**
3. Enter API key
4. Credential name: "OpenAi account"
5. Model used: `gpt-4o-mini-2024-07-18`

**For Google Gemini (Contract_PNG_ CargoFlow):**
1. Get API key from Google AI Studio (https://aistudio.google.com/)
2. In n8n: **Credentials** → **New** → **Google Gemini API**
3. Enter API key
4. Credential name: "Invoice_Email" or "Teka" or "Gemini(PaLM) Api 1"
5. Model used: `gemini-pro`
6. Max Output Tokens: 32768

### 5. Test Workflows

**Note:** These workflows use PostgreSQL NOTIFY/LISTEN, not webhooks.

**Test PostgreSQL Trigger:**
```sql
-- Test text channel
LISTEN n8n_channel_contract_text;
SELECT pg_notify('n8n_channel_contract_text', 
  '{"file_path": "test.txt", "attachment_id": 1, "email_id": 1, "original_document": "test.pdf"}'
);

-- Test image channel
LISTEN n8n_channel_contract_png;
SELECT pg_notify('n8n_channel_contract_png', 
  '{"file_path": "test.png", "attachment_id": 1, "email_id": 1, "original_document": "test.pdf"}'
);
```

**Check Workflow Execution:**
1. In n8n UI, open workflow
2. Check **Executions** tab
3. Verify successful runs

---

## 🔍 Monitoring

### Check Workflow Status

**In n8n UI:**
- Green indicator = Active
- Red indicator = Inactive
- Yellow = Error

### Check Execution History

**In n8n:**
1. Click workflow name
2. View **Executions** tab
3. Check for errors

### Common Issues

**Issue 1: Workflow not receiving signals**
```bash
# Check PostgreSQL NOTIFY/LISTEN
psql -U postgres -d Cargo_mail

# In psql:
LISTEN n8n_channel_contract_text;
-- Should see: Asynchronous notification received

# Test manually:
SELECT pg_notify('n8n_channel_contract_text', 
  '{"file_path": "test.txt", "attachment_id": 1, "email_id": 1, "original_document": "test.pdf"}'
);

# Check if processing_queue has pending items
SELECT COUNT(*) FROM processing_queue 
WHERE status = 'pending' AND file_type = 'text';
```

**Issue 2: AI API errors**
- Check API key validity
- Check rate limits
- Check API credit balance

**Issue 3: Database connection lost**
- Restart n8n
- Check PostgreSQL is running
- Verify credentials

---

## 📈 Workflow Statistics

### Performance Metrics (Target)

| Metric | Target | Current |
|--------|--------|---------|
| Text Processing | < 5s/file | ⚠️ Check |
| Image Processing | < 10s/file | ⚠️ Check |
| AI Accuracy | > 90% | ⚠️ Check |
| Uptime | > 99% | ⚠️ Check |

### Monitor with SQL

```sql
-- Recent AI classifications
SELECT 
    attachment_name,
    document_category,
    confidence_score,
    contract_number,
    classification_timestamp
FROM email_attachments
WHERE classification_timestamp > NOW() - INTERVAL '24 hours'
ORDER BY classification_timestamp DESC
LIMIT 20;

-- AI accuracy by category
SELECT 
    document_category,
    COUNT(*) as count,
    AVG(confidence_score) as avg_confidence
FROM email_attachments
WHERE document_category IS NOT NULL
GROUP BY document_category
ORDER BY count DESC;

-- Document pages analysis (multi-page documents)
SELECT 
    dp.attachment_id,
    ea.attachment_name,
    dp.page_number,
    dp.category,
    dp.contract_number,
    dp.confidence_score
FROM document_pages dp
JOIN email_attachments ea ON dp.attachment_id = ea.id
ORDER BY dp.attachment_id, dp.page_number
LIMIT 50;

-- Invoice extraction status
SELECT 
    ib.invoice_number,
    ib.supplier_name,
    ib.total_amount,
    ib.currency,
    ea.attachment_name
FROM invoice_base ib
JOIN email_attachments ea ON ib.email_id = ea.email_id
WHERE ib.invoice_number IS NOT NULL
ORDER BY ib.created_at DESC
LIMIT 20;
```

---

## 🛠️ Workflow Export

### Export Workflow

**In n8n UI:**
1. Open workflow
2. Click **⋮** (three dots) → **Download**
3. Save to `Cargoflow_n8n/` folder
4. Also backup to `Documentation/n8n/workflows/` folder

**Current Workflow Files:**
- `Cargoflow_n8n/Contract_Text_CargoFlow.json`
- `Cargoflow_n8n/Contract_PNG_ CargoFlow.json`

### Backup Workflows

```bash
# Manual backup
cp ~/.n8n/workflows.json workflows/backup_$(date +%Y%m%d).json

# Or export all workflows via n8n UI
```

---

## 📚 Related Documentation

- **[STATUS_FLOW_MAP.md](../docs/STATUS_FLOW_MAP.md)** - Complete workflow integration
- **[SYSTEM_ARCHITECTURE.md](../docs/SYSTEM_ARCHITECTURE.md)** - System overview (planned)
- **[TROUBLESHOOTING.md](../docs/TROUBLESHOOTING.md)** - Common issues (planned)

---

## 🚨 Important Notes

### Security
- **Never commit API keys to Git!**
- Use n8n credential encryption
- Rotate API keys regularly

### Performance
- Rate limiting prevents API overuse
- Queue managers control flow
- Monitor execution times

### Known Issues
- Queue managers stopped on 28 Oct 09:40
- Last AI categorization: 28 Oct 13:30
- Need to verify n8n status

### Workflow-Specific Notes

**Contract_Text_CargoFlow:**
- Processes text files (.txt) from OCR/Office extraction
- Single document analysis (not split by pages)
- Creates one `document_pages` record per text file
- Invoice extraction integrated in same workflow

**Contract_PNG_ CargoFlow:**
- Processes PNG images (pages from multi-page documents)
- Groups pages by `original_document` and `attachment_id`
- Analyzes each page separately
- Creates multiple `document_pages` records (one per PNG)
- Supports different categories per page (e.g., invoice + CMR in same document)

---

## 🔄 Next Steps

1. **Verify n8n is running:** Visit http://localhost:5678
2. **Check workflow status:** All workflows should be Active
3. **Test webhooks:** Use curl commands above
4. **Export current workflows:** Save to `workflows/` folder

---

**Last Updated:** November 12, 2025  
**Status:** Documentation complete - n8n status verification needed
