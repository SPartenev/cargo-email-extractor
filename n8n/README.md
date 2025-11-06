# n8n Workflows Documentation

**n8n Server:** localhost:5678  
**Last Updated:** November 06, 2025  
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

### 1. Category_ALL_text (Text Analysis)

**Purpose:** AI categorization of text documents

**Trigger:** PostgreSQL NOTIFY on `n8n_channel_text`

**Input:** Text files from OCR/Office processing
- Location: `C:\CargoProcessing\processed_documents\2025\ocr_results\`
- Format: `*_extracted.txt`

**Process:**
1. Listen to PostgreSQL NOTIFY
2. Read text file content
3. Send to AI (OpenAI or Google Gemini)
4. Parse AI response (category, confidence, contract_number)
5. UPDATE email_attachments table

**AI Categories (13):**
- contract, contract_amendment, contract_termination, contract_extension
- service_agreement, framework_agreement, cmr, protocol, annex
- insurance, invoice, credit_note, other

**Output:** Updates database with:
- `document_category`
- `confidence_score`
- `contract_number`
- `classification_timestamp`

**Webhook:** `http://localhost:5678/webhook/analyze-text`

---

### 2. Read_PNG_ (Image Analysis)

**Purpose:** AI categorization of PNG images

**Trigger:** PostgreSQL NOTIFY on `n8n_channel_image_ready`

**Input:** PNG images from OCR processing
- Location: `C:\CargoProcessing\processed_documents\2025\images\`
- Format: `*.png`

**Process:**
1. Listen to PostgreSQL NOTIFY
2. Read image file (base64)
3. Send to AI with vision capabilities
4. Parse AI response
5. UPDATE email_attachments table

**Output:** Same as text workflow + image analysis

**Webhook:** `http://localhost:5678/webhook/analyze-image`

---

### 3. INV_Text_CargoFlow (Invoice Extraction)

**Purpose:** Extract invoice data from classified invoices

**Trigger:** When `document_category = 'invoice'`

**Process:**
1. Extract invoice fields:
   - invoice_number
   - vendor_name
   - total_amount
   - invoice_date
   - line_items[]
2. INSERT INTO invoice_base
3. INSERT INTO invoice_items

**Output:** Structured invoice data in database

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

**Option 1: OpenAI**
```javascript
{
  "model": "gpt-4o",
  "temperature": 0.1,
  "max_tokens": 1000
}
```

**Option 2: Google Gemini**
```javascript
{
  "model": "gemini-pro",
  "temperature": 0.1,
  "maxOutputTokens": 1000
}
```

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
-- Trigger function
CREATE FUNCTION notify_n8n_text_queue()
RETURNS trigger AS $$
BEGIN
  PERFORM pg_notify('n8n_channel_text', 
    json_build_object(
      'file_path', NEW.file_path,
      'attachment_id', NEW.attachment_id,
      'email_id', NEW.email_id
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
CREATE FUNCTION notify_n8n_image_queue()
-- Trigger on n8n_channel_image_ready
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
3. Import JSON files from `workflows/` folder
4. Configure credentials:
   - OpenAI API key (or Google Gemini)
   - PostgreSQL connection
5. Activate workflows

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

**For OpenAI:**
1. Get API key from https://platform.openai.com
2. Add credential in n8n
3. Select model: gpt-4o

**For Google Gemini:**
1. Get API key from Google AI Studio
2. Add credential in n8n
3. Select model: gemini-pro

### 5. Test Workflows

```bash
# Test text webhook
curl -X POST http://localhost:5678/webhook/analyze-text

# Test image webhook
curl -X POST http://localhost:5678/webhook/analyze-image
```

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
LISTEN n8n_channel_text;
-- Should see: Asynchronous notification received

# Test manually:
SELECT pg_notify('n8n_channel_text', '{"test": "data"}');
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
```

---

## 🛠️ Workflow Export

### Export Workflow

**In n8n UI:**
1. Open workflow
2. Click **⋮** (three dots)
3. Select **Download**
4. Save to `workflows/` folder

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

---

## 🔄 Next Steps

1. **Verify n8n is running:** Visit http://localhost:5678
2. **Check workflow status:** All workflows should be Active
3. **Test webhooks:** Use curl commands above
4. **Export current workflows:** Save to `workflows/` folder

---

**Last Updated:** November 06, 2025  
**Status:** Documentation complete - n8n status verification needed
