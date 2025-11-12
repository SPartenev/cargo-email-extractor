# n8n Workflows Module - AI Document Categorization

**Module:** Cargoflow_n8n  
**Workflows:** `Category_ALL_text`, `Read_PNG_`  
**Status:** ✅ Production Ready  
**Last Updated:** November 12, 2025

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Architecture & Data Flow](#architecture--data-flow)
3. [Configuration](#configuration)
4. [Workflow 1: Category_ALL_text (Text Analysis)](#workflow-1-category_all_text-text-analysis)
5. [Workflow 2: Read_PNG_ (Image Analysis)](#workflow-2-read_png_-image-analysis)
6. [AI Agent Instructions](#ai-agent-instructions)
7. [Database Integration](#database-integration)
8. [Status Management & Database State](#status-management--database-state)
9. [Document Categories](#document-categories)
10. [Contract Number Extraction](#contract-number-extraction)
11. [Error Handling & Resilience](#error-handling--resilience)
12. [Logging & Monitoring](#logging--monitoring)
13. [Usage & Deployment](#usage--deployment)
14. [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

### Purpose

The n8n Workflows module consists of **two AI-powered workflows** (Modules 5A and 5B) that analyze documents and extract metadata. This is the **intelligence layer** of the CargoFlow system, using Large Language Models (LLMs) to categorize documents and extract contract numbers.

**Primary Functions:**
1. **Text Analysis** - AI categorization of extracted text files
2. **Image Analysis** - AI categorization of scanned document images
3. **Category Assignment** - 13 document categories (invoice, CMR, contract, etc.)
4. **Contract Number Extraction** - Regex pattern matching (50XXXXXXXXX, 20XXXXXXXXX)
5. **Database Updates** - Write results to `email_attachments` and `document_pages`
6. **Invoice Processing** - Extract invoice data to `invoice_base` and `invoice_items`
7. **Page-Level Analysis** - Individual page categorization for multi-page documents

### Key Features

- ✅ **Dual Workflow System** - Separate workflows for text and images
- ✅ **AI-Powered Categorization** - OpenAI GPT or Google Gemini
- ✅ **PostgreSQL NOTIFY/LISTEN** - Instant activation on new queue items
- ✅ **13 Document Categories** - From contracts to invoices
- ✅ **Contract Number Extraction** - Pattern matching with confidence scoring
- ✅ **Page-Level Analysis** - Each page categorized separately
- ✅ **Invoice Data Extraction** - Full invoice parsing with line items
- ✅ **Confidence Scoring** - 0.0-1.0 reliability metric
- ✅ **Error Recovery** - Retry mechanism with exponential backoff

---

## 🏗️ Architecture & Data Flow

### High-Level Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                  N8N WORKFLOWS MODULE (5A + 5B)                 │
└─────────────────────────────────────────────────────────────────┘

[WORKFLOW 5A: Category_ALL_text - Text Analysis]
    ↓ Trigger: PostgreSQL NOTIFY n8n_text_channel
    ↓
[1] PostgreSQL LISTEN:
    └─ Receive notification from processing_queue INSERT
    ↓
[2] Read Queue Record:
    └─ SELECT * FROM processing_queue WHERE id = X
    ↓
[3] Read Text File:
    ├─ Read file_path from disk
    └─ Extract text content (after ---TEXT_CONTENT--- marker)
    ↓
[4] AI Analysis (OpenAI GPT / Google Gemini):
    ├─ Send text to LLM
    ├─ Request: category, confidence, contract_number
    └─ Response: JSON with categorization
    ↓
[5] Parse AI Response:
    ├─ Extract category (e.g., "invoice")
    ├─ Extract confidence (e.g., 0.95)
    ├─ Extract contract_number (e.g., "50251006834")
    └─ Extract summary
    ↓
[6] Database UPDATE:
    ├─ UPDATE email_attachments SET
    │   document_category = 'invoice',
    │   confidence_score = 0.95,
    │   contract_number = '50251006834',
    │   classification_timestamp = NOW()
    │   WHERE attachment_id = X
    ├─ UPDATE processing_queue SET
    │   status = 'completed',
    │   processed_at = NOW()
    │   WHERE id = X
    └─ IF category = 'invoice':
        └─ INSERT INTO invoice_base (...invoice data...)
    ↓
[7] Optional: Contract Detection Trigger
    └─ If all attachments for email categorized
        → INSERT INTO email_ready_queue


[WORKFLOW 5B: Read_PNG_ - Image Analysis]
    ↓ Trigger: PostgreSQL NOTIFY n8n_image_channel
    ↓
[1] PostgreSQL LISTEN:
    └─ Receive notification from processing_queue INSERT
    ↓
[2] Read Queue Record:
    └─ SELECT * FROM processing_queue WHERE id = X
    ↓
[3] Read Image File:
    ├─ Read PNG from disk
    └─ Encode as base64 (for AI API)
    ↓
[4] AI Vision Analysis (OpenAI GPT-4V / Google Gemini Vision):
    ├─ Send image to vision model
    ├─ Request: category per page, contract_number
    └─ Response: JSON array with per-page categories
    ↓
[5] Parse AI Response (Array):
    ├─ FOR EACH page in response:
    │   ├─ Extract page_number, category, confidence
    │   └─ Extract contract_number
    └─ Handle multi-page documents
    ↓
[6] Database UPDATE:
    ├─ FOR EACH page:
    │   └─ INSERT INTO document_pages (
    │       attachment_id, page_number, category,
    │       confidence, contract_number
    │     )
    ├─ UPDATE email_attachments SET
    │   document_category = (most common category),
    │   contract_number = (extracted number)
    └─ UPDATE processing_queue SET
        status = 'completed'
```

### Component Interaction

```
┌──────────────────┐       ┌──────────────────┐       ┌──────────────────┐
│ Queue Managers   │──────►│ n8n Workflows    │──────►│   Database       │
│ (add to queue)   │       │ (AI analysis)    │       │   (results)      │
└──────────────────┘       └──────────────────┘       └──────────────────┘
         │                          │                           │
         │                          ↓                           │
         │              ┌──────────────────┐                   │
         │              │   PostgreSQL     │                   │
         │              │ NOTIFY/LISTEN    │                   │
         │              │ (instant trigger)│                   │
         │              └──────────────────┘                   │
         │                          │                           │
         ↓                          ↓                           ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Data Sources                                 │
│  Input: processing_queue (id, file_path, attachment_id)        │
│  Files: Text files (.txt) or Images (.png)                     │
│  AI: OpenAI API / Google Gemini API                            │
│  Output: email_attachments, document_pages, invoice_base       │
└─────────────────────────────────────────────────────────────────┘
```

### Workflow Comparison

| Aspect | Category_ALL_text | Read_PNG_ |
|--------|-------------------|-----------|
| **Input** | Text files (*_extracted.txt) | PNG images (*.png) |
| **Trigger** | NOTIFY n8n_text_channel | NOTIFY n8n_image_channel |
| **AI Model** | GPT-4 / Gemini Pro | GPT-4V / Gemini Vision |
| **Processing** | Text parsing | Image OCR + analysis |
| **Output** | Single category per file | Array of categories (per page) |
| **Database** | email_attachments + document_pages | email_attachments + document_pages |
| **Invoice** | Full extraction (items) | Basic extraction |
| **Speed** | Fast (1-3 seconds) | Slower (3-10 seconds) |

---

## ⚙️ Configuration

### n8n Server Configuration

**Location:** n8n installation (typically `~/.n8n/` or C:\Users\[User]\.n8n\)

**Environment Variables:**

```bash
# n8n Server
N8N_HOST=localhost
N8N_PORT=5678
N8N_PROTOCOL=http

# Database Connection
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=localhost
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=Cargo_mail
DB_POSTGRESDB_USER=postgres
DB_POSTGRESDB_PASSWORD=Lora24092004

# AI API Keys
OPENAI_API_KEY=sk-...  # If using OpenAI
GEMINI_API_KEY=...     # If using Google Gemini
```

### Workflow Configuration

**Category_ALL_text Workflow Settings:**

```json
{
  "name": "Category_ALL_text",
  "active": true,
  "nodes": [
    {
      "type": "n8n-nodes-base.postgresqlTrigger",
      "parameters": {
        "trigger": "listen",
        "channelName": "n8n_text_channel"
      }
    },
    {
      "type": "n8n-nodes-base.postgres",
      "parameters": {
        "operation": "executeQuery",
        "query": "SELECT * FROM processing_queue WHERE id = {{ $json.id }}"
      }
    },
    {
      "type": "n8n-nodes-base.readFile",
      "parameters": {
        "filePath": "{{ $json.file_path }}"
      }
    },
    {
      "type": "n8n-nodes-base.openAi",
      "parameters": {
        "operation": "message",
        "model": "gpt-4",
        "prompt": "[AI_INSTRUCTIONS]"
      }
    },
    {
      "type": "n8n-nodes-base.postgres",
      "parameters": {
        "operation": "update",
        "table": "email_attachments"
      }
    }
  ]
}
```

**Read_PNG_ Workflow Settings:**

```json
{
  "name": "Read_PNG_",
  "active": true,
  "nodes": [
    {
      "type": "n8n-nodes-base.postgresqlTrigger",
      "parameters": {
        "trigger": "listen",
        "channelName": "n8n_image_channel"
      }
    },
    {
      "type": "n8n-nodes-base.postgres",
      "parameters": {
        "operation": "executeQuery",
        "query": "SELECT * FROM processing_queue WHERE id = {{ $json.id }}"
      }
    },
    {
      "type": "n8n-nodes-base.readBinaryFile",
      "parameters": {
        "filePath": "{{ $json.file_path }}",
        "encoding": "base64"
      }
    },
    {
      "type": "n8n-nodes-base.openAi",
      "parameters": {
        "operation": "vision",
        "model": "gpt-4-vision-preview"
      }
    },
    {
      "type": "n8n-nodes-base.postgres",
      "parameters": {
        "operation": "insert",
        "table": "document_pages"
      }
    }
  ]
}
```

---

## 📝 Workflow 1: Category_ALL_text (Text Analysis)

### Purpose

Analyzes extracted text files and assigns document categories using AI.

### Node Structure

#### Node 1: PostgreSQL Trigger

**Type:** PostgreSQL Trigger (LISTEN)  
**Function:** Receive notifications from processing_queue

**Configuration:**
```javascript
{
  "operation": "listen",
  "channelName": "n8n_text_channel",
  "credentials": "PostgreSQL Cargo_mail"
}
```

**Trigger Payload Example:**
```json
{
  "id": 123,
  "file_path": "C:\\CargoProcessing\\...\\file_extracted.txt",
  "email_id": 456,
  "attachment_id": 789
}
```

---

#### Node 2: Read Queue Record

**Type:** PostgreSQL Query  
**Function:** Get full queue record details

**Query:**
```sql
SELECT 
  id,
  file_path,
  file_type,
  email_id,
  attachment_id,
  created_at
FROM processing_queue
WHERE id = {{ $json.id }}
LIMIT 1;
```

**Output:**
```json
{
  "id": 123,
  "file_path": "C:\\CargoProcessing\\...\\file_extracted.txt",
  "file_type": "text",
  "email_id": 456,
  "attachment_id": 789,
  "created_at": "2025-11-06T14:30:00Z"
}
```

---

#### Node 3: Read Text File

**Type:** Read File  
**Function:** Load text content from disk

**Configuration:**
```javascript
{
  "operation": "read",
  "filePath": "{{ $json.file_path }}",
  "encoding": "utf-8"
}
```

**File Content Structure:**
```
{
  "file_metadata": {
    "email_id": 456,
    ...
  }
}
---TEXT_CONTENT---

[Actual document text here]
```

**Code Function:**
```javascript
// Extract text after ---TEXT_CONTENT--- marker
const fileContent = $input.first().json.data;
const parts = fileContent.split('---TEXT_CONTENT---');

if (parts.length > 1) {
  const textContent = parts[1].trim();
  return { text: textContent };
} else {
  throw new Error('TEXT_CONTENT marker not found');
}
```

---

#### Node 4: AI Categorization

**Type:** OpenAI / Google Gemini  
**Function:** Send text to LLM for categorization

**OpenAI Configuration:**
```javascript
{
  "operation": "message",
  "model": "gpt-4",
  "temperature": 0.3,
  "maxTokens": 500,
  "messages": [
    {
      "role": "system",
      "content": "[AI_INSTRUCTIONS - see below]"
    },
    {
      "role": "user",
      "content": "{{ $json.text }}"
    }
  ]
}
```

**Google Gemini Configuration:**
```javascript
{
  "operation": "generateContent",
  "model": "gemini-pro",
  "temperature": 0.3,
  "maxOutputTokens": 500,
  "systemInstruction": "[AI_INSTRUCTIONS]",
  "prompt": "{{ $json.text }}"
}
```

**Expected AI Response:**
```json
{
  "category": "invoice",
  "confidence": 0.95,
  "summary": "Фактура за транспортни услуги",
  "contract_number": "50251006834",
  "contract_number_confidence": 0.90
}
```

---

#### Node 5: Parse AI Response

**Type:** Code (JavaScript)  
**Function:** Extract and validate AI categorization

**Code:**
```javascript
const aiOutput = $json.output;

// Remove markdown code blocks if present
const cleanJson = aiOutput
  .replace(/```json\n?/g, '')
  .replace(/```\n?/g, '')
  .trim();

// Parse JSON
let parsed;
try {
  parsed = JSON.parse(cleanJson);
} catch (e) {
  throw new Error(`Failed to parse AI response: ${e.message}`);
}

// Handle array response (should be single object for text)
const result = Array.isArray(parsed) ? parsed[0] : parsed;

// Validate required fields
if (!result.category) {
  throw new Error('AI response missing category field');
}

// Get trigger data
const triggerData = $('PostgreSQL Trigger').first().json;

return {
  json: {
    category: result.category,
    confidence: result.confidence || 0.5,
    summary: result.summary || '',
    contract_number: result.contract_number || null,
    contract_number_confidence: result.contract_number_confidence || null,
    attachment_id: triggerData.attachment_id,
    email_id: triggerData.email_id,
    queue_id: triggerData.id
  }
};
```

---

#### Node 6: Update email_attachments

**Type:** PostgreSQL Update  
**Function:** Write categorization results to database

**Query:**
```sql
UPDATE email_attachments
SET 
  document_category = '{{ $json.category }}',
  confidence_score = {{ $json.confidence }},
  contract_number = {{ $json.contract_number ? "'" + $json.contract_number + "'" : 'NULL' }},
  summary = '{{ $json.summary }}',
  classification_timestamp = NOW()
WHERE id = {{ $json.attachment_id }};
```

---

#### Node 7: Update processing_queue

**Type:** PostgreSQL Update  
**Function:** Mark queue item as completed

**Query:**
```sql
UPDATE processing_queue
SET 
  status = 'completed',
  processed_at = NOW()
WHERE id = {{ $json.queue_id }};
```

---

#### Node 8 (Conditional): Invoice Extraction

**Type:** IF Node  
**Condition:** `{{ $json.category === 'invoice' }}`

**If TRUE → Extract Invoice Data:**

**Node 8A: AI Invoice Extraction**
```javascript
{
  "operation": "message",
  "model": "gpt-4",
  "messages": [
    {
      "role": "system",
      "content": "Extract invoice data: number, date, amount, vendor, items"
    },
    {
      "role": "user",
      "content": "{{ $json.text }}"
    }
  ]
}
```

**Expected Response:**
```json
{
  "invoice_number": "INV-2025-001",
  "invoice_date": "2025-11-06",
  "total_amount": 1500.00,
  "currency": "BGN",
  "vendor_name": "Transport Company Ltd",
  "line_items": [
    {
      "description": "Transport services",
      "quantity": 1,
      "unit_price": 1200.00,
      "amount": 1200.00
    },
    {
      "description": "Fuel surcharge",
      "quantity": 1,
      "unit_price": 300.00,
      "amount": 300.00
    }
  ]
}
```

**Node 8B: Insert invoice_base**
```sql
INSERT INTO invoice_base (
  email_id,
  attachment_id,
  invoice_number,
  invoice_date,
  total_amount,
  currency,
  vendor_name,
  extracted_at
) VALUES (
  {{ $json.email_id }},
  {{ $json.attachment_id }},
  '{{ $json.invoice_number }}',
  '{{ $json.invoice_date }}',
  {{ $json.total_amount }},
  '{{ $json.currency }}',
  '{{ $json.vendor_name }}',
  NOW()
)
RETURNING id;
```

**Node 8C: Insert invoice_items (Loop)**
```sql
-- FOR EACH line_item in line_items array
INSERT INTO invoice_items (
  invoice_id,
  line_number,
  description,
  quantity,
  unit_price,
  amount
) VALUES (
  {{ $json.invoice_id }},
  {{ $json.line_number }},
  '{{ $json.description }}',
  {{ $json.quantity }},
  {{ $json.unit_price }},
  {{ $json.amount }}
);
```

---

### Complete Workflow Summary

**Workflow: Category_ALL_text**

```
[PostgreSQL LISTEN n8n_text_channel]
    ↓
[Read processing_queue record]
    ↓
[Read text file from disk]
    ↓
[Extract text content (after ---TEXT_CONTENT---)]
    ↓
[AI Categorization (GPT-4 / Gemini)]
    ↓
[Parse AI response]
    ↓
[UPDATE email_attachments]
    ↓
[UPDATE processing_queue status='completed']
    ↓
[IF invoice → Extract invoice data]
    ↓
[IF invoice → INSERT invoice_base + invoice_items]
```

**Execution Time:** 1-5 seconds per file

---

## 🖼️ Workflow 2: Read_PNG_ (Image Analysis)

### Purpose

Analyzes PNG images (scanned document pages) and assigns categories per page using AI vision models.

### Node Structure

#### Node 1: PostgreSQL Trigger

**Type:** PostgreSQL Trigger (LISTEN)  
**Function:** Receive notifications from processing_queue

**Configuration:**
```javascript
{
  "operation": "listen",
  "channelName": "n8n_image_channel",
  "credentials": "PostgreSQL Cargo_mail"
}
```

**Trigger Payload Example:**
```json
{
  "id": 124,
  "file_path": "C:\\CargoProcessing\\...\\document_1.png",
  "email_id": 456,
  "attachment_id": 789
}
```

---

#### Node 2: Read Queue Record

**Type:** PostgreSQL Query  
**Function:** Get full queue record with metadata

**Query:**
```sql
SELECT 
  pq.id,
  pq.file_path,
  pq.email_id,
  pq.attachment_id,
  ea.attachment_name,
  ea.original_filename
FROM processing_queue pq
LEFT JOIN email_attachments ea ON pq.attachment_id = ea.id
WHERE pq.id = {{ $json.id }}
LIMIT 1;
```

---

#### Node 3: Read Image File

**Type:** Read Binary File  
**Function:** Load PNG image and encode as base64

**Configuration:**
```javascript
{
  "operation": "readBinary",
  "filePath": "{{ $json.file_path }}",
  "encoding": "base64"
}
```

**Output:**
```json
{
  "data": "iVBORw0KGgoAAAANSUhEUgAA...[base64 image data]...",
  "mimeType": "image/png",
  "fileName": "document_1.png"
}
```

---

#### Node 4: Read JSON Sidecar (Optional)

**Type:** Read File  
**Function:** Load metadata from JSON sidecar file

**Configuration:**
```javascript
{
  "operation": "read",
  "filePath": "{{ $json.file_path.replace('.png', '.json') }}",
  "encoding": "utf-8"
}
```

**JSON Sidecar Content:**
```json
{
  "file_metadata": {
    "email_id": 456,
    "original_file_path": "C:\\CargoAttachments\\...\\document.pdf",
    "page_number": 1,
    "total_pages": 3
  }
}
```

---

#### Node 5: AI Vision Analysis

**Type:** OpenAI Vision / Google Gemini Vision  
**Function:** Analyze image with vision-capable LLM

**OpenAI GPT-4V Configuration:**
```javascript
{
  "operation": "vision",
  "model": "gpt-4-vision-preview",
  "temperature": 0.3,
  "maxTokens": 1000,
  "messages": [
    {
      "role": "system",
      "content": "[AI_INSTRUCTIONS for images - see below]"
    },
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "Analyze this document page"
        },
        {
          "type": "image_url",
          "image_url": {
            "url": "data:image/png;base64,{{ $json.data }}"
          }
        }
      ]
    }
  ]
}
```

**Google Gemini Vision Configuration:**
```javascript
{
  "operation": "generateContent",
  "model": "gemini-pro-vision",
  "temperature": 0.3,
  "parts": [
    {
      "text": "Analyze this document page"
    },
    {
      "inlineData": {
        "mimeType": "image/png",
        "data": "{{ $json.data }}"
      }
    }
  ]
}
```

**Expected AI Response (Array for multi-page):**
```json
[
  {
    "page_number": 1,
    "category": "invoice",
    "confidence": 0.98,
    "summary": "Фактура за международен транспорт",
    "contract_number": "50251007003",
    "contract_number_confidence": 0.95
  },
  {
    "page_number": 2,
    "category": "cmr",
    "confidence": 0.98,
    "summary": "CMR за транспортни услуги",
    "contract_number": "50251007003",
    "contract_number_confidence": 0.95
  },
  {
    "page_number": 3,
    "category": "cmr",
    "confidence": 0.98,
    "summary": "CMR за транспортни услуги",
    "contract_number": "50251007003",
    "contract_number_confidence": 0.95
  }
]
```

---

#### Node 6: Parse AI Response (Array Handling)

**Type:** Code (JavaScript)  
**Function:** Parse and validate AI vision response

**Code:**
```javascript
const aiOutput = $json.output;

// Clean markdown
const cleanJson = aiOutput
  .replace(/```json\n?/g, '')
  .replace(/```\n?/g, '')
  .trim();

// Parse JSON
const parsed = JSON.parse(cleanJson);

// Get trigger data
const triggerData = $('PostgreSQL Trigger').first().json;

// Ensure array format
const results = Array.isArray(parsed) ? parsed : [parsed];

// Process each page
return results.map((pageData, index) => ({
  json: {
    page_number: pageData.page_number || (index + 1),
    category: pageData.category,
    confidence: pageData.confidence || 0.5,
    summary: pageData.summary || '',
    contract_number: pageData.contract_number || null,
    contract_number_confidence: pageData.contract_number_confidence || null,
    attachment_id: triggerData.attachment_id,
    email_id: triggerData.email_id,
    queue_id: triggerData.id,
    original_document: triggerData.file_path
  }
}));
```

**Output (Multiple Items):**
```json
[
  {
    "page_number": 1,
    "category": "invoice",
    "confidence": 0.98,
    "attachment_id": 789,
    "contract_number": "50251007003"
  },
  {
    "page_number": 2,
    "category": "cmr",
    "confidence": 0.98,
    "attachment_id": 789,
    "contract_number": "50251007003"
  },
  {
    "page_number": 3,
    "category": "cmr",
    "confidence": 0.98,
    "attachment_id": 789,
    "contract_number": "50251007003"
  }
]
```

---

#### Node 7: Insert document_pages (Loop)

**Type:** PostgreSQL Insert (Loop)  
**Function:** Create record for each page

**Query (executed for EACH page):**
```sql
INSERT INTO document_pages (
  attachment_id,
  page_number,
  category,
  confidence_score,
  summary,
  contract_number,
  contract_number_confidence,
  created_at
) VALUES (
  {{ $json.attachment_id }},
  {{ $json.page_number }},
  '{{ $json.category }}',
  {{ $json.confidence }},
  '{{ $json.summary }}',
  {{ $json.contract_number ? "'" + $json.contract_number + "'" : 'NULL' }},
  {{ $json.contract_number_confidence || 'NULL' }},
  NOW()
);
```

---

#### Node 8: Aggregate Page Categories

**Type:** Code (JavaScript)  
**Function:** Determine overall document category from pages

**Logic:**
```javascript
// Get all page results
const pages = $input.all().map(item => item.json);

// Find most common category
const categoryCounts = {};
pages.forEach(page => {
  categoryCounts[page.category] = (categoryCounts[page.category] || 0) + 1;
});

const mostCommonCategory = Object.entries(categoryCounts)
  .sort(([,a], [,b]) => b - a)[0][0];

// Get first contract_number found
const contractNumber = pages.find(p => p.contract_number)?.contract_number || null;

// Calculate average confidence
const avgConfidence = pages.reduce((sum, p) => sum + p.confidence, 0) / pages.length;

return {
  json: {
    attachment_id: pages[0].attachment_id,
    document_category: mostCommonCategory,
    confidence_score: avgConfidence,
    contract_number: contractNumber,
    total_pages: pages.length
  }
};
```

**Example Output:**
```json
{
  "attachment_id": 789,
  "document_category": "cmr",
  "confidence_score": 0.98,
  "contract_number": "50251007003",
  "total_pages": 3
}
```

---

#### Node 9: Update email_attachments

**Type:** PostgreSQL Update  
**Function:** Write aggregated categorization

**Query:**
```sql
UPDATE email_attachments
SET 
  document_category = '{{ $json.document_category }}',
  confidence_score = {{ $json.confidence_score }},
  contract_number = {{ $json.contract_number ? "'" + $json.contract_number + "'" : 'NULL' }},
  classification_timestamp = NOW()
WHERE id = {{ $json.attachment_id }};
```

---

#### Node 10: Update processing_queue

**Type:** PostgreSQL Update  
**Function:** Mark queue item as completed

**Query:**
```sql
UPDATE processing_queue
SET 
  status = 'completed',
  processed_at = NOW()
WHERE id = {{ $json.queue_id }};
```

---

### Complete Workflow Summary

**Workflow: Read_PNG_**

```
[PostgreSQL LISTEN n8n_image_channel]
    ↓
[Read processing_queue record]
    ↓
[Read PNG image from disk (base64)]
    ↓
[Optional: Read JSON sidecar metadata]
    ↓
[AI Vision Analysis (GPT-4V / Gemini Vision)]
    ↓
[Parse AI response (array of pages)]
    ↓
[FOR EACH page → INSERT document_pages]
    ↓
[Aggregate: Find most common category]
    ↓
[UPDATE email_attachments (aggregated)]
    ↓
[UPDATE processing_queue status='completed']
```

**Execution Time:** 3-15 seconds per image (depending on size and pages)

---

## 🤖 AI Agent Instructions

### Text Analysis Prompt

**System Role:**
```
Act as an intelligent document classifier for business and transport documents.
```

**Task:**
```
Analyze the provided text and determine:
1. Document category (from predefined list)
2. Confidence score (0.0 to 1.0)
3. Contract number (if present)
4. Brief summary in Bulgarian

IMPORTANT: Always search for contract numbers. Look for patterns:
- "50xxxxxxxxx" (10-11 digits, starts with 50)
- "20xxxxxxxxx" (10-11 digits, starts with 20)
- "Договор № 50xxxxxxxxx" / "Contract No. 20xxxxxxxxx"
- "№ 50xxxxxxxxx" / "No. 20xxxxxxxxx"
```

**Categories (Pick Only One):**
```
- contract (договор)
- contract_amendment (допълнително споразумение)
- contract_termination (прекратяване на договор)
- contract_extension (удължаване на договор)
- service_agreement (споразумение за услуги)
- framework_agreement (рамков договор)
- cmr (CMR товарителница)
- protocol (протокол)
- annex (приложение)
- insurance (застраховка)
- invoice (фактура)
- credit_note (кредитно известие)
- other (друго)
```

**Output Format:**
```json
{
  "category": "invoice",
  "confidence": 0.95,
  "summary": "Фактура за транспортни услуги от София до Варна",
  "contract_number": "50251006834",
  "contract_number_confidence": 0.90
}
```

**Examples:**
```
Input: "ФАКТУРА № INV-2025-001\nДоговор № 50251006834\nОбщо: 1500 лв"
Output: {
  "category": "invoice",
  "confidence": 0.98,
  "summary": "Фактура INV-2025-001 по договор 50251006834",
  "contract_number": "50251006834",
  "contract_number_confidence": 0.95
}

Input: "CMR\nОт: София\nДо: Варна\nДоговор 20251007003"
Output: {
  "category": "cmr",
  "confidence": 0.99,
  "summary": "CMR за транспорт София-Варна",
  "contract_number": "20251007003",
  "contract_number_confidence": 0.90
}
```

---

### Image Analysis Prompt

**System Role:**
```
Act as an intelligent document classifier for scanned business documents.
Analyze EACH PAGE separately.
```

**Task:**
```
Analyze the provided image and determine for EACH PAGE:
1. Page number
2. Document category
3. Confidence score
4. Contract number (if visible)
5. Brief summary

IMPORTANT: If multiple pages are visible, return an ARRAY with one object per page.
```

**Output Format (Array):**
```json
[
  {
    "page_number": 1,
    "category": "invoice",
    "confidence": 0.98,
    "summary": "Фактура за международен транспорт",
    "contract_number": "50251007003",
    "contract_number_confidence": 0.90
  },
  {
    "page_number": 2,
    "category": "cmr",
    "confidence": 0.98,
    "summary": "CMR за транспортни услуги",
    "contract_number": "50251007003",
    "contract_number_confidence": 0.95
  }
]
```

**Single Page Format:**
```json
[
  {
    "page_number": 1,
    "category": "contract",
    "confidence": 0.95,
    "summary": "Договор за транспортни услуги",
    "contract_number": "50251006834",
    "contract_number_confidence": 0.90
  }
]
```

---

## 🗄️ Database Integration

### Tables Modified

#### 1. email_attachments (PRIMARY UPDATE TARGET)

**UPDATE Operations:**

```sql
UPDATE email_attachments
SET 
  document_category = 'invoice',
  confidence_score = 0.95,
  contract_number = '50251006834',
  summary = 'Фактура за транспорт',
  classification_timestamp = NOW(),
  processing_status = 'classified'
WHERE id = 789;
```

**Columns Updated:**
- `document_category` - AI-assigned category
- `confidence_score` - 0.0-1.0 reliability metric
- `contract_number` - Extracted contract number
- `summary` - Brief description
- `classification_timestamp` - When AI categorized
- `processing_status` - 'classified' (from 'completed')

---

#### 2. document_pages (FOR ALL DOCUMENT TYPES - TEXT AND IMAGE)

**INSERT Operations:**

```sql
INSERT INTO document_pages (
  attachment_id,
  page_number,
  category,
  confidence_score,
  summary,
  contract_number,
  contract_number_confidence,
  created_at
) VALUES (
  789,
  1,
  'invoice',
  0.98,
  'Фактура за международен транспорт',
  '50251007003',
  0.95,
  NOW()
);
```

**Purpose:** Store per-page categorization for multi-page documents

**Usage:**
- **Text files:** INV_Text_CargoFlow.json workflow inserts records for text documents
- **Image files:** Contract_PNG_ CargoFlow.json workflow inserts records for image documents
- Both workflows use the same table structure and process documents identically regarding database operations

---

#### 3. processing_queue (STATUS UPDATE)

**UPDATE Operations:**

```sql
UPDATE processing_queue
SET 
  status = 'completed',
  processed_at = NOW(),
  attempts = attempts + 1
WHERE id = 123;
```

**Status Transition:** `pending` → `completed`

---

#### 4. invoice_base (CONDITIONAL - IF INVOICE)

**INSERT Operations:**

```sql
INSERT INTO invoice_base (
  email_id,
  attachment_id,
  invoice_number,
  invoice_date,
  total_amount,
  currency,
  vendor_name,
  extracted_at
) VALUES (
  456,
  789,
  'INV-2025-001',
  '2025-11-06',
  1500.00,
  'BGN',
  'Transport Company Ltd',
  NOW()
)
RETURNING id;
```

---

#### 5. invoice_items (CONDITIONAL - IF INVOICE)

**INSERT Operations (Multiple Rows):**

```sql
INSERT INTO invoice_items (
  invoice_id,
  line_number,
  description,
  quantity,
  unit_price,
  amount
) VALUES
  (10, 1, 'Transport services', 1, 1200.00, 1200.00),
  (10, 2, 'Fuel surcharge', 1, 300.00, 300.00);
```

---

#### 6. email_ready_queue (OPTIONAL TRIGGER)

**Trigger Condition:** All attachments for an email are classified

**INSERT Operation:**

```sql
-- Triggered by function: queue_email_for_folder_update()
INSERT INTO email_ready_queue (
  email_id,
  ready_at,
  processed
) VALUES (
  456,
  NOW(),
  FALSE
)
ON CONFLICT (email_id) DO NOTHING;
```

**Purpose:** Queue email for contract folder organization (Module 6)

---

## 📊 Status Management & Database State

### Overview

n8n Workflows are the **core processing engine** of CargoFlow. They read from `processing_queue`, analyze files with AI, and write results to multiple tables.

### Tables & Status Columns

#### Table: processing_queue

**Columns MODIFIED by n8n:**

| Column | n8n READS | n8n WRITES | Purpose |
|--------|-----------|------------|---------|
| `id` | ✅ (via NOTIFY payload) | ❌ | Unique identifier |
| `file_path` | ✅ | ❌ | Path to file for analysis |
| `file_type` | ✅ | ❌ | 'text' or 'image' |
| `status` | ✅ (check if pending) | ✅ ('completed' or 'failed') | Processing status |
| `email_id` | ✅ | ❌ | Link to email |
| `attachment_id` | ✅ | ❌ | Link to attachment |
| `attempts` | ✅ | ✅ (increment) | Retry counter |
| `processed_at` | ❌ | ✅ (NOW()) | Completion timestamp |
| `error_message` | ❌ | ✅ (if failed) | Error details |

---

#### Table: email_attachments

**Columns MODIFIED by n8n:**

| Column | Before n8n | After n8n | Purpose |
|--------|------------|-----------|---------|
| `document_category` | NULL | 'invoice' / 'cmr' / etc. | AI-assigned category |
| `confidence_score` | NULL | 0.0-1.0 | Confidence metric |
| `contract_number` | NULL | '50251006834' | Extracted number |
| `summary` | NULL | 'Фактура за транспорт' | Brief description |
| `classification_timestamp` | NULL | NOW() | When categorized |
| `processing_status` | 'completed' | 'classified' | Status update |

---

### Status Flow: n8n Workflows

```
┌─────────────────────────────────────────────────────────────────────┐
│         N8N WORKFLOWS - DATABASE STATUS LIFECYCLE                   │
└─────────────────────────────────────────────────────────────────────┘

[Queue Manager]
    ↓ INSERT INTO processing_queue
    ↓ status = 'pending'
    ↓ Triggers PostgreSQL NOTIFY
    ↓
┌─────────────────┐
│ NOTIFY Received │ ← n8n LISTENS
└─────────────────┘
    ↓
[n8n Workflow - Category_ALL_text or Read_PNG_]
    ↓
DATABASE READ:
SELECT * FROM processing_queue
WHERE id = 123
  AND status = 'pending'          ← n8n READS status
    ↓
[Read File from Disk]
    ↓ file_path from database
    ↓
[AI Analysis]
    ↓ Send to GPT-4 / Gemini
    ↓ Receive categorization
    ↓
DATABASE WRITE #1:
UPDATE email_attachments
SET document_category = 'invoice',    ← n8n WRITES
    confidence_score = 0.95,          ← n8n WRITES
    contract_number = '50251006834',  ← n8n WRITES
    classification_timestamp = NOW()  ← n8n WRITES
WHERE id = 789
    ↓
DATABASE WRITE #2:
UPDATE processing_queue
SET status = 'completed',             ← n8n WRITES status
    processed_at = NOW(),             ← n8n WRITES
    attempts = attempts + 1           ← n8n WRITES
WHERE id = 123
    ↓
┌─────────────────┐
│ Processing Done │ ← n8n Workflow ENDS
└─────────────────┘


IF ERROR (AI timeout, parse error, etc.):
UPDATE processing_queue
SET status = 'failed',                ← n8n WRITES status
    error_message = 'AI timeout',     ← n8n WRITES
    attempts = attempts + 1           ← n8n WRITES
WHERE id = 123

IF attempts >= 3:
    → status remains 'failed'
    → Manual intervention required
```

---

### Statuses READ by n8n Workflows

**Query:** Check queue status before processing

```sql
SELECT * FROM processing_queue
WHERE id = {{ $json.id }}
  AND status = 'pending';  -- Only process pending items
```

**Statuses READ:**
- `pending` - Item ready for processing

**Purpose:** Ensure item hasn't been processed already (idempotency)

---

### Statuses WRITTEN by n8n Workflows

#### Success Path:

**processing_queue:**
```sql
UPDATE processing_queue
SET status = 'completed',      ← WRITES: 'completed'
    processed_at = NOW()       ← WRITES: timestamp
WHERE id = 123;
```

**email_attachments:**
```sql
UPDATE email_attachments
SET document_category = 'invoice',     ← WRITES: category
    confidence_score = 0.95,           ← WRITES: confidence
    contract_number = '50251006834',   ← WRITES: number
    classification_timestamp = NOW()   ← WRITES: timestamp
WHERE id = 789;
```

#### Error Path:

**processing_queue:**
```sql
UPDATE processing_queue
SET status = 'failed',                      ← WRITES: 'failed'
    error_message = 'AI parsing failed',    ← WRITES: error
    attempts = attempts + 1                 ← WRITES: increment
WHERE id = 123;
```

**Impact:**
- **Downstream:** Contract Processor (Module 6) waits for `classification_timestamp` before organizing
- **Trigger:** If all attachments classified → `email_ready_queue` INSERT

---

### Module Dependency Chain

```
┌──────────────────┐
│ Queue Managers   │ ← Modules 4A & 4B
│                  │
└──────────────────┘
         │
         │ WRITES:
         │ - processing_queue.status = 'pending'
         │
         │ TRIGGERS:
         │ - PostgreSQL NOTIFY n8n_text_channel (or image)
         │
         ↓
┌──────────────────┐
│ n8n Workflows    │ ← Modules 5A & 5B - YOU ARE HERE
│                  │
└──────────────────┘
         │
         │ READS:
         │ - processing_queue.status = 'pending'
         │ - File content (via file_path)
         │
         │ PROCESSES:
         │ - AI categorization
         │ - Contract number extraction
         │
         │ WRITES:
         │ - processing_queue.status = 'completed' or 'failed'
         │ - email_attachments (category, confidence, contract_number)
         │ - document_pages (per-page categories)
         │ - invoice_base + invoice_items (if invoice)
         │
         │ TRIGGERS (conditional):
         │ - email_ready_queue INSERT (if all attachments classified)
         │
         ↓
┌──────────────────┐
│Contract Processor│ ← Module 6
│                  │
└──────────────────┘
         │
         │ READS:
         │ - email_ready_queue.processed = FALSE
         │ - email_attachments.contract_number
         │
         │ WRITES:
         │ - emails.folder_name
         │ - contracts table
         │
         ↓
    [Files Organized]
```

---

### Status Transition Timeline

**Example: Text File AI Analysis**

| Time | Event | Actor | Status Change |
|------|-------|-------|---------------|
| T+0s | Queue Manager adds file | Queue Manager | processing_queue.status = 'pending' |
| T+0s | PostgreSQL NOTIFY sent | PostgreSQL | NOTIFY n8n_text_channel |
| T+1s | n8n receives notification | n8n | - |
| T+2s | Read processing_queue record | n8n | - |
| T+3s | Read text file from disk | n8n | - |
| T+4s | Send to AI API (GPT-4) | n8n | - |
| T+7s | AI returns categorization | OpenAI/Gemini | - |
| T+8s | Parse AI response | n8n | - |
| T+9s | **UPDATE email_attachments** | n8n | **document_category = 'invoice'** |
| T+9s | **UPDATE email_attachments** | n8n | **confidence_score = 0.95** |
| T+9s | **UPDATE email_attachments** | n8n | **contract_number = '50251006834'** |
| T+10s | **UPDATE processing_queue** | n8n | **status = 'completed'** |
| T+10s | Check if all attachments classified | PostgreSQL Trigger | - |
| T+11s | **INSERT email_ready_queue** | PostgreSQL Trigger | (if all classified) |

**Total Time:** ~10 seconds from queue to categorization

---

### Checking n8n Workflow Activity

#### Method 1: Query Recent Categorizations

```sql
-- Files categorized in last hour
SELECT 
    id,
    attachment_name,
    document_category,
    confidence_score,
    contract_number,
    classification_timestamp
FROM email_attachments
WHERE classification_timestamp > NOW() - INTERVAL '1 hour'
ORDER BY classification_timestamp DESC
LIMIT 20;
```

**Purpose:** Verify n8n is actively categorizing files

---

#### Method 2: Check Processing Queue Status

```sql
-- Queue status breakdown
SELECT 
    file_type,
    status,
    COUNT(*) as count,
    MIN(created_at) as oldest,
    MAX(processed_at) as latest_completed
FROM processing_queue
GROUP BY file_type, status
ORDER BY file_type, status;
```

**Expected (healthy system):**
```
file_type | status    | count | oldest              | latest_completed
----------+-----------+-------+---------------------+---------------------
text      | completed | 150   | 2025-10-27 10:00:00 | 2025-11-06 14:45:00
text      | pending   | 2     | 2025-11-06 14:40:00 | NULL
image     | completed | 120   | 2025-10-27 10:00:00 | 2025-11-06 14:44:00
image     | pending   | 5     | 2025-11-06 14:35:00 | NULL
```

**Warning signs:**
- Many `pending` items (> 20)
- Old `pending` items (> 1 hour)
- No recent `completed` items
- High `failed` count

---

#### Method 3: Check n8n Executions

**Via n8n Web UI:**
```
1. Open http://localhost:5678
2. Click on workflow (Category_ALL_text or Read_PNG_)
3. Click "Executions" tab
4. Review recent executions
```

**Look for:**
- ✅ Success count (green)
- ❌ Error count (red)
- ⏱️ Average execution time
- 📊 Execution frequency

---

#### Method 4: Check Categorization Coverage

```sql
-- Percentage of attachments categorized
SELECT 
    COUNT(*) as total_attachments,
    COUNT(*) FILTER (WHERE document_category IS NOT NULL) as categorized,
    COUNT(*) FILTER (WHERE document_category IS NULL) as uncategorized,
    ROUND(100.0 * COUNT(*) FILTER (WHERE document_category IS NOT NULL) / COUNT(*), 1) as percent_categorized
FROM email_attachments;
```

**Target:** > 80% categorized

---

### Troubleshooting: n8n Status Issues

#### Issue 1: Files Stuck in 'pending' Status

**Symptoms:**
- processing_queue has many `pending` items
- But n8n not processing them
- No new `classification_timestamp` updates

**Causes:**
1. n8n workflows not active
2. PostgreSQL NOTIFY not reaching n8n
3. AI API errors (timeout, rate limit)
4. Database connection issues

**Solution:**

1. **Check n8n workflow status:**
   ```
   Open http://localhost:5678
   Workflows → Category_ALL_text → Check "Active" toggle
   Workflows → Read_PNG_ → Check "Active" toggle
   ```

2. **Check n8n logs:**
   ```
   # In n8n terminal
   # Look for errors like:
   # - "OpenAI API timeout"
   # - "Database connection failed"
   # - "Failed to parse AI response"
   ```

3. **Test PostgreSQL NOTIFY manually:**
   ```sql
   -- Terminal 1: Check if n8n is listening
   SELECT * FROM pg_stat_activity 
   WHERE query LIKE '%LISTEN%';
   
   -- Terminal 2: Send test notification
   NOTIFY n8n_text_channel, '{"id": 123}';
   ```

4. **Restart n8n:**
   ```bash
   # Ctrl+C to stop
   n8n start
   ```

---

#### Issue 2: AI Categorization Errors

**Symptoms:**
- processing_queue status = 'failed'
- error_message = 'AI parsing failed' or similar

**Causes:**
1. AI response not in expected JSON format
2. AI API timeout
3. Invalid API key
4. Rate limit exceeded

**Solution:**

1. **Check error messages:**
   ```sql
   SELECT 
       file_path,
       error_message,
       attempts,
       created_at
   FROM processing_queue
   WHERE status = 'failed'
   ORDER BY created_at DESC
   LIMIT 10;
   ```

2. **Check AI API keys:**
   ```bash
   # In n8n environment variables
   echo $OPENAI_API_KEY
   echo $GEMINI_API_KEY
   ```

3. **Test AI API manually:**
   ```bash
   # OpenAI test
   curl https://api.openai.com/v1/chat/completions \
     -H "Authorization: Bearer $OPENAI_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{"model": "gpt-4", "messages": [{"role": "user", "content": "test"}]}'
   ```

4. **Check rate limits:**
   ```
   # OpenAI: https://platform.openai.com/account/rate-limits
   # Gemini: https://console.cloud.google.com/apis/api/generativelanguage.googleapis.com
   ```

5. **Retry failed files:**
   ```sql
   UPDATE processing_queue
   SET status = 'pending',
       attempts = 0,
       error_message = NULL
   WHERE status = 'failed'
     AND error_message LIKE '%timeout%';
   ```

---

#### Issue 3: Wrong Categories Assigned

**Symptoms:**
- Files categorized
- But wrong category (e.g., CMR labeled as "other")

**Causes:**
1. AI instructions unclear
2. Document text quality poor
3. Low confidence threshold

**Solution:**

1. **Check confidence scores:**
   ```sql
   SELECT 
       attachment_name,
       document_category,
       confidence_score
   FROM email_attachments
   WHERE confidence_score < 0.5
   ORDER BY confidence_score
   LIMIT 20;
   ```

2. **Review AI prompt:**
   - Is category list clear?
   - Are examples provided?
   - Is contract number extraction emphasized?

3. **Improve text extraction:**
   - Check OCR quality (see OCR Processor docs)
   - Ensure full text is sent to AI (not truncated)

4. **Add human review for low confidence:**
   ```sql
   -- Flag low-confidence categorizations
   UPDATE email_attachments
   SET needs_review = TRUE
   WHERE confidence_score < 0.7;
   ```

---

#### Issue 4: Contract Numbers Not Extracted

**Symptoms:**
- Files categorized
- But `contract_number` is NULL

**Causes:**
1. Contract number not in document
2. Non-standard format
3. AI not detecting pattern

**Solution:**

1. **Check documents manually:**
   ```
   Open a few categorized files
   Search for "договор", "contract", numbers starting with 50/20
   ```

2. **Review extraction patterns:**
   ```
   Current patterns:
   - 50XXXXXXXXX (10-11 digits)
   - 20XXXXXXXXX (10-11 digits)
   - "Договор № 50..."
   - "Contract No. 20..."
   ```

3. **Add new patterns if needed:**
   ```
   Update AI instructions to include:
   - Your company-specific formats
   - Alternative keywords
   ```

4. **Check confidence:**
   ```sql
   SELECT 
       attachment_name,
       contract_number,
       contract_number_confidence
   FROM email_attachments
   WHERE contract_number IS NOT NULL
   ORDER BY contract_number_confidence
   LIMIT 20;
   ```

---

### Summary: n8n Workflows Status Role

**Key Points:**

1. **AI Intelligence Layer:** n8n workflows are the "brain" of CargoFlow
2. **Database Writes:** Primary writer to `email_attachments` categorization fields
3. **Status Transitions:** Changes `processing_queue` from 'pending' → 'completed'/'failed'
4. **Multi-Table Impact:** Also writes to `document_pages`, `invoice_base`, `invoice_items`
5. **Trigger Next Module:** Completion triggers contract folder organization (Module 6)

**Data Flow:**
```
processing_queue (pending) → n8n AI Analysis → 
email_attachments (categorized) → 
email_ready_queue → Contract Processor
```

**Status Lifecycle:**
```
[Queue Manager] → status='pending' → 
[n8n Workflow] → AI Analysis → 
[n8n Workflow] → status='completed' + category data written
```

---

## 📂 Document Categories

### 13 Predefined Categories

| Category | Bulgarian | Use Case | Typical Keywords |
|----------|-----------|----------|------------------|
| `contract` | Договор | Main contracts | договор, contract, съгласие |
| `contract_amendment` | Допълнително споразумение | Contract changes | допълнително споразумение, amendment |
| `contract_termination` | Прекратяване | Contract termination | прекратяване, termination |
| `contract_extension` | Удължаване | Contract extension | удължаване, extension, продължение |
| `service_agreement` | Споразумение за услуги | Service contracts | услуги, services agreement |
| `framework_agreement` | Рамков договор | Framework agreements | рамков договор, framework |
| `cmr` | CMR товарителница | Transport documents | CMR, товарителница, consignment |
| `protocol` | Протокол | Protocols | протокол, protocol |
| `annex` | Приложение | Attachments | приложение, annex, допълнение |
| `insurance` | Застраховка | Insurance docs | застраховка, insurance, полица |
| `invoice` | Фактура | Invoices | фактура, invoice, данъчна фактура |
| `credit_note` | Кредитно известие | Credit notes | кредитно известие, credit note |
| `other` | Друго | Uncategorized | - |

### Category Usage Statistics (Example)

```sql
-- Category distribution
SELECT 
    document_category,
    COUNT(*) as count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) as percentage
FROM email_attachments
WHERE document_category IS NOT NULL
GROUP BY document_category
ORDER BY count DESC;
```

**Example Output:**
```
document_category      | count | percentage
-----------------------+-------+-----------
cmr                    | 85    | 35.4%
invoice                | 62    | 25.8%
contract               | 45    | 18.8%
protocol               | 28    | 11.7%
contract_amendment     | 12    | 5.0%
insurance              | 8     | 3.3%
other                  | 0     | 0.0%
```

---

## 🔢 Contract Number Extraction

### Pattern Matching

**Primary Patterns:**
```
50XXXXXXXXX  (10-11 digits, starts with 50)
20XXXXXXXXX  (10-11 digits, starts with 20)
```

**Context Patterns:**
```
Договор № 50251006834
Contract No. 20251007003
№ 50251006834
No. 20251007003
```

### Extraction Process

1. **AI Detection:** LLM searches text/image for patterns
2. **Confidence Scoring:** 0.0-1.0 based on context
3. **Validation:** Basic format check (digits, length)
4. **Database Write:** Store number + confidence

### Contract Number Statistics

```sql
-- Count of contract numbers extracted
SELECT 
    COUNT(*) FILTER (WHERE contract_number IS NOT NULL) as with_contract_number,
    COUNT(*) FILTER (WHERE contract_number IS NULL) as without_contract_number,
    ROUND(100.0 * COUNT(*) FILTER (WHERE contract_number IS NOT NULL) / COUNT(*), 1) as extraction_rate
FROM email_attachments
WHERE document_category IS NOT NULL;
```

**Target Extraction Rate:** > 60% (not all documents have contract numbers)

---

### Contract Number Distribution

```sql
-- Most common contract numbers
SELECT 
    contract_number,
    COUNT(*) as file_count,
    STRING_AGG(DISTINCT document_category, ', ') as categories,
    AVG(contract_number_confidence) as avg_confidence
FROM email_attachments
WHERE contract_number IS NOT NULL
GROUP BY contract_number
ORDER BY file_count DESC
LIMIT 10;
```

**Example Output:**
```
contract_number  | file_count | categories           | avg_confidence
-----------------+------------+----------------------+---------------
50251006834      | 12         | cmr, invoice, protocol| 0.92
50251007003      | 8          | invoice, cmr         | 0.88
20251005012      | 5          | contract, amendment  | 0.85
```

---

## 🛡️ Error Handling & Resilience

### Error Types & Recovery

| Error Type | Detection | Recovery | Retry |
|------------|-----------|----------|-------|
| **AI API Timeout** | `requests.Timeout` | Update status='failed', log error | Yes (3x) |
| **AI Parsing Error** | `JSON.parse()` exception | Log raw response, status='failed' | Yes (3x) |
| **Invalid Response** | Missing required fields | Log validation error, status='failed' | Yes (3x) |
| **Database Connection** | `psycopg2.OperationalError` | Retry connection, exponential backoff | Yes (5x) |
| **File Not Found** | `FileNotFoundError` | Log error, status='failed' | No |
| **Rate Limit (AI API)** | HTTP 429 | Wait and retry with backoff | Yes (3x) |
| **Out of Quota** | AI API error | Alert admin, pause workflow | No |

### Retry Mechanism

**Configuration (in workflow):**
```javascript
{
  "retry": {
    "maxAttempts": 3,
    "waitBetween": 5000,  // 5 seconds
    "backoffStrategy": "exponential"
  }
}
```

**Retry Schedule:**
- Attempt 1: Immediate
- Attempt 2: Wait 5 seconds
- Attempt 3: Wait 10 seconds
- Attempt 4: Wait 20 seconds
- Give up after 4 attempts

**Database Tracking:**
```sql
UPDATE processing_queue
SET attempts = attempts + 1
WHERE id = 123;
```

### Error Logging

**n8n Execution Logs:**
- Stored in n8n database
- Viewable in web UI (http://localhost:5678)
- Includes full error stack trace

**Database Error Messages:**
```sql
SELECT 
    file_path,
    error_message,
    attempts,
    created_at
FROM processing_queue
WHERE status = 'failed'
ORDER BY created_at DESC;
```

---

## 📊 Logging & Monitoring

### n8n Execution Logs

**Access:** http://localhost:5678 → Workflows → [Workflow] → Executions

**Log Information:**
- Execution ID
- Start time
- Duration
- Status (success/error)
- Input data
- Output data
- Error details (if failed)

### Key Metrics to Monitor

#### 1. Execution Success Rate

```sql
-- Success vs failure rate (last 24 hours)
SELECT 
    file_type,
    status,
    COUNT(*) as count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY file_type), 1) as percentage
FROM processing_queue
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY file_type, status
ORDER BY file_type, status;
```

**Target:** > 95% success rate

---

#### 2. Processing Time

```sql
-- Average processing time
SELECT 
    file_type,
    AVG(EXTRACT(EPOCH FROM (processed_at - created_at))) as avg_seconds,
    MIN(EXTRACT(EPOCH FROM (processed_at - created_at))) as min_seconds,
    MAX(EXTRACT(EPOCH FROM (processed_at - created_at))) as max_seconds
FROM processing_queue
WHERE status = 'completed'
  AND created_at > NOW() - INTERVAL '24 hours'
GROUP BY file_type;
```

**Expected:**
- Text: 1-5 seconds
- Images: 3-15 seconds

---

#### 3. Categorization Coverage

```sql
-- Percentage categorized per day
SELECT 
    DATE(classification_timestamp) as date,
    COUNT(*) as categorized_count
FROM email_attachments
WHERE classification_timestamp IS NOT NULL
GROUP BY DATE(classification_timestamp)
ORDER BY date DESC
LIMIT 7;
```

---

#### 4. Contract Number Extraction Rate

```sql
-- Extraction rate by category
SELECT 
    document_category,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE contract_number IS NOT NULL) as with_number,
    ROUND(100.0 * COUNT(*) FILTER (WHERE contract_number IS NOT NULL) / COUNT(*), 1) as extraction_rate
FROM email_attachments
WHERE document_category IS NOT NULL
GROUP BY document_category
ORDER BY total DESC;
```

---

## 🚀 Usage & Deployment

### Installation

**Prerequisites:**
- Node.js 18+ (for n8n)
- PostgreSQL 17 with NOTIFY/LISTEN
- OpenAI API key OR Google Gemini API key

**Steps:**

```bash
# 1. Install n8n globally
npm install -g n8n

# 2. Set environment variables
export N8N_HOST=localhost
export N8N_PORT=5678
export N8N_PROTOCOL=http

# Database connection
export DB_TYPE=postgresdb
export DB_POSTGRESDB_HOST=localhost
export DB_POSTGRESDB_PORT=5432
export DB_POSTGRESDB_DATABASE=Cargo_mail
export DB_POSTGRESDB_USER=postgres
export DB_POSTGRESDB_PASSWORD=Lora24092004

# AI API keys
export OPENAI_API_KEY=sk-...  # If using OpenAI
export GEMINI_API_KEY=...     # If using Google Gemini

# 3. Start n8n
n8n start

# 4. Open web interface
# http://localhost:5678

# 5. Import workflows
# - Click "Workflows" → "Import from File"
# - Select: Documentation/n8n/workflows/Contract_Text_CargoFlow.json
# - Select: Documentation/n8n/workflows/Contract_PNG_CargoFlow.json

# 6. Activate workflows
# - Category_ALL_text → Toggle "Active"
# - Read_PNG_ → Toggle "Active"
```

---

### Running the Module

**Terminal: n8n Server**

```bash
n8n start
```

**Expected Output:**
```
n8n ready on 0.0.0.0, port 5678
Version: 1.x.x

Editor is now accessible via:
http://localhost:5678/

Press "o" to open in Browser.
Waiting for changes to restart...
```

---

### Verifying Workflows Active

**Via Web UI:**
```
1. Open http://localhost:5678
2. Click "Workflows"
3. Check both workflows have green "Active" indicator:
   - Category_ALL_text
   - Read_PNG_
```

**Via Database:**
```sql
-- Test notification to check if n8n is listening
NOTIFY n8n_text_channel, '{"id": 999, "test": true}';

-- Check n8n execution logs in web UI
-- Should see new execution (may error due to invalid ID, but confirms listening)
```

---

### System Integration

**n8n runs as part of 7-process CargoFlow system:**

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
venv\Scripts\activate
python image_queue_manager.py

# Terminal 6: n8n Workflows ← YOU ARE HERE
n8n start

# Terminal 7: Contract Processor
cd C:\Python_project\CargoFlow\Cargoflow_Contracts
venv\Scripts\activate
python main.py --continuous
```

---

## 🔧 Troubleshooting

### Common Issues

#### Issue 1: n8n Not Starting

**Symptoms:**
```
Error: Cannot find module 'n8n'
```

**Cause:** n8n not installed

**Solution:**
```bash
npm install -g n8n
```

---

#### Issue 2: Workflows Not Receiving Notifications

**Symptoms:**
- Queue Managers adding files
- But n8n workflows not executing

**Cause:** PostgreSQL NOTIFY not reaching n8n

**Solution:**

1. **Check PostgreSQL connection in n8n:**
   ```
   Open http://localhost:5678
   Settings → Credentials → PostgreSQL
   Test connection
   ```

2. **Check triggers are LISTEN:**
   ```
   Open workflow → Edit
   First node should be "PostgreSQL Trigger"
   Operation: "listen"
   Channel: "n8n_text_channel" (or "n8n_image_channel")
   ```

3. **Test manually:**
   ```sql
   NOTIFY n8n_text_channel, '{"id": 123}';
   ```

4. **Restart n8n**

---

#### Issue 3: AI API Errors

**Symptoms:**
```
Error: OpenAI API error: Unauthorized
```

**Cause:** Invalid or missing API key

**Solution:**

1. **Check environment variables:**
   ```bash
   echo $OPENAI_API_KEY
   echo $GEMINI_API_KEY
   ```

2. **Set in n8n credentials:**
   ```
   Settings → Credentials → OpenAI / Google PaLM
   Add API key
   ```

3. **Test API key:**
   ```bash
   curl https://api.openai.com/v1/models \
     -H "Authorization: Bearer $OPENAI_API_KEY"
   ```

---

#### Issue 4: Parsing Errors

**Symptoms:**
```
Failed to parse AI response: Unexpected token
```

**Cause:** AI returned non-JSON or malformed JSON

**Solution:**

1. **Check AI response in execution logs:**
   ```
   n8n Web UI → Executions → Failed → View details
   Look at "AI" node output
   ```

2. **Common issues:**
   - Markdown code blocks (```json)
   - Extra text before/after JSON
   - Unescaped quotes in strings

3. **Improve prompt:**
   ```
   Add to AI instructions:
   "IMPORTANT: Return ONLY valid JSON, no markdown, no additional text"
   ```

---

## 🔗 Related Documentation

- [Database Schema](../DATABASE_SCHEMA.md) - All tables modified by n8n
- [Queue Managers](04_QUEUE_MANAGERS.md) - Previous modules (trigger n8n)
- [Contract Processor](06_CONTRACTS_PROCESSOR.md) - Next module (uses categorization)
- [Status Flow Map](../docs/STATUS_FLOW_MAP.md) - Complete system status flow
- [n8n Workflows (JSON)](../n8n/workflows/) - Importable workflow files

---

**Module Status:** ✅ Production Ready  
**Last Updated:** November 12, 2025  
**Maintained by:** CargoFlow DevOps Team
