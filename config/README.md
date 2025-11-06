# Configuration Files

**Last Updated:** November 06, 2025  
**Purpose:** Example configuration files for CargoFlow system

---

## 📁 Folder Contents

```
config/
├── graph_config.json.example       # Microsoft Graph API config
├── queue_config.json.example       # Queue manager settings
├── .env.example                    # Environment variables
├── requirements.txt                # Python dependencies
└── README.md                       # This file
```

---

## 🔧 Configuration Files

### 1. graph_config.json.example

**Purpose:** Microsoft Graph API credentials and database connection

**Location:** Copy to `Cargoflow_mail/graph_config.json`

**Template:**
```json
{
  "client_id": "your-client-id-here",
  "client_secret": "your-client-secret-here",
  "tenant_id": "your-tenant-id-here",
  "user_email": "your-email@domain.com",
  "database": {
    "host": "localhost",
    "database": "Cargo_mail",
    "user": "postgres",
    "password": "your-password-here",
    "port": 5432
  },
  "attachment_folder": "C:\\CargoAttachments\\",
  "log_file": "graph_extraction.log",
  "check_interval": 60
}
```

**How to get Microsoft Graph API credentials:**
1. Go to https://portal.azure.com
2. Navigate to **Azure Active Directory** → **App registrations**
3. Create new app registration
4. Copy **Application (client) ID** → `client_id`
5. Copy **Directory (tenant) ID** → `tenant_id`
6. Create **Client Secret** → `client_secret`
7. Add API permissions:
   - `Mail.Read`
   - `Mail.ReadWrite`
   - `User.Read`

---

### 2. queue_config.json.example

**Purpose:** Queue manager settings for text and image processing

**Location:** Copy to `Cargoflow_Queue/queue_config.json`

**Template:**
```json
{
    "database": {
        "host": "localhost",
        "database": "Cargo_mail",
        "user": "postgres",
        "password": "your-password-here",
        "port": 5432
    },
    "text_queue": {
        "watch_path": "C:\\CargoProcessing\\processed_documents\\2025\\ocr_results",
        "webhook_url": "http://localhost:5678/webhook/analyze-text",
        "rate_limit_per_minute": 3,
        "scan_interval_seconds": 15,
        "file_pattern": "*_extracted.txt",
        "log_file": "text_queue_manager.log"
    },
    "image_queue": {
        "watch_path": "C:\\CargoProcessing\\processed_documents\\2025\\images",
        "webhook_url": "http://localhost:5678/webhook/analyze-image",
        "rate_limit_per_minute": 3,
        "scan_interval_seconds": 15,
        "file_pattern": "*.png",
        "min_file_size_kb": 50,
        "log_file": "image_queue_manager.log"
    }
}
```

**Parameters explained:**
- `watch_path` - Directory to monitor for new files
- `webhook_url` - n8n webhook endpoint
- `rate_limit_per_minute` - Max files to send per minute (prevent API rate limits)
- `scan_interval_seconds` - How often to check for new files
- `file_pattern` - File pattern to match
- `min_file_size_kb` - Minimum file size (filters out logos/banners)

---

### 3. .env.example

**Purpose:** Environment variables for all modules

**Location:** Copy to project root as `.env`

**Template:**
```bash
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=Cargo_mail
DB_USER=postgres
DB_PASSWORD=your-password-here

# Microsoft Graph API
GRAPH_CLIENT_ID=your-client-id-here
GRAPH_CLIENT_SECRET=your-client-secret-here
GRAPH_TENANT_ID=your-tenant-id-here
GRAPH_USER_EMAIL=your-email@domain.com

# n8n
N8N_HOST=localhost
N8N_PORT=5678
N8N_PROTOCOL=http

# AI APIs (choose one or both)
OPENAI_API_KEY=sk-your-openai-key-here
GOOGLE_GEMINI_API_KEY=your-gemini-key-here

# File Paths
CARGO_ATTACHMENTS_PATH=C:\CargoAttachments
CARGO_PROCESSING_PATH=C:\CargoProcessing
CARGO_CONTRACTS_PATH=C:\Users\Delta\Cargo Flow\Site de communication - Documents\Документи по договори

# Logging
LOG_LEVEL=INFO
LOG_FORMAT=%(asctime)s - %(name)s - %(levelname)s - %(message)s

# Queue Settings
QUEUE_RATE_LIMIT=3
QUEUE_SCAN_INTERVAL=15
```

**Usage in Python:**
```python
import os
from dotenv import load_dotenv

load_dotenv()

db_host = os.getenv('DB_HOST')
db_password = os.getenv('DB_PASSWORD')
openai_key = os.getenv('OPENAI_API_KEY')
```

---

### 4. requirements.txt

**Purpose:** Python package dependencies for all modules

**Location:** Project root

**Template:**
```txt
# Core dependencies
python-dotenv==1.0.0
psycopg2-binary==2.9.9

# Microsoft Graph
msal==1.24.1
requests==2.31.0

# OCR Processing
PyMuPDF==1.23.8
Pillow==10.1.0
pytesseract==0.3.10

# Office Processing
python-docx==1.1.0
openpyxl==3.1.2
pywin32==306

# Queue Management
watchdog==3.0.0

# n8n Integration
requests==2.31.0

# AI APIs
openai==1.3.5
google-generativeai==0.3.1

# Utilities
schedule==1.2.0
```

**Installation:**
```bash
pip install -r requirements.txt
```

---

## 🛠️ Setup Instructions

### Step 1: Copy Example Files

```bash
# Copy Graph API config
cp config/graph_config.json.example Cargoflow_mail/graph_config.json

# Copy Queue config
cp config/queue_config.json.example Cargoflow_Queue/queue_config.json

# Copy environment variables
cp config/.env.example .env
```

### Step 2: Edit Configuration Files

**Edit each file and replace:**
- `your-client-id-here` → Your actual Microsoft Graph Client ID
- `your-client-secret-here` → Your actual Client Secret
- `your-tenant-id-here` → Your Azure AD Tenant ID
- `your-email@domain.com` → Your Microsoft 365 email
- `your-password-here` → Your PostgreSQL password
- `sk-your-openai-key-here` → Your OpenAI API key (if using OpenAI)
- `your-gemini-key-here` → Your Google Gemini key (if using Gemini)

### Step 3: Verify Paths

Make sure these directories exist:
- `C:\CargoAttachments\`
- `C:\CargoProcessing\`
- `C:\Users\Delta\Cargo Flow\Site de communication - Documents\Документи по договори\`

Create them if needed:
```bash
mkdir C:\CargoAttachments
mkdir C:\CargoProcessing
```

### Step 4: Test Configuration

```python
# Test database connection
python -c "from config.database import test_connection; test_connection()"

# Test Graph API
python -c "from Cargoflow_mail.graph_email_extractor_v5 import test_graph_connection; test_graph_connection()"
```

---

## 🔐 Security Best Practices

### DO ✅
- Use environment variables for sensitive data
- Keep `.env` and config files out of Git (use `.gitignore`)
- Rotate credentials regularly (every 90 days)
- Use different credentials for dev/staging/production
- Enable MFA on Microsoft 365 accounts
- Use strong, unique passwords

### DON'T ❌
- Commit passwords or API keys to Git
- Share credentials in plain text
- Use the same password across environments
- Leave default passwords unchanged
- Store credentials in code files
- Share `.env` files via email or chat

---

## 📝 .gitignore

**Add these to your `.gitignore`:**

```gitignore
# Configuration files (sensitive data)
.env
graph_config.json
queue_config.json
*.config.json

# Logs
*.log

# Python
__pycache__/
*.py[cod]
*$py.class
venv/
env/

# Data folders
CargoAttachments/
CargoProcessing/

# Database
*.db
*.sqlite
```

---

## 🔄 Environment-Specific Configs

### Development
```bash
# .env.development
DB_NAME=Cargo_mail_dev
LOG_LEVEL=DEBUG
QUEUE_RATE_LIMIT=10  # Higher for testing
```

### Production
```bash
# .env.production
DB_NAME=Cargo_mail
LOG_LEVEL=INFO
QUEUE_RATE_LIMIT=3  # Lower to prevent API rate limits
```

**Usage:**
```bash
# Load specific environment
export ENV=production
python script.py
```

---

## 🧪 Testing Configuration

### Validate JSON Files

```bash
# Test JSON syntax
python -m json.tool graph_config.json

# Or with jq
jq . graph_config.json
```

### Test Database Connection

```python
import psycopg2

try:
    conn = psycopg2.connect(
        host="localhost",
        database="Cargo_mail",
        user="postgres",
        password="your-password",
        port=5432
    )
    print("✅ Database connection successful!")
    conn.close()
except Exception as e:
    print(f"❌ Database connection failed: {e}")
```

### Test n8n Webhooks

```bash
# Test text webhook
curl -X POST http://localhost:5678/webhook/analyze-text

# Test image webhook
curl -X POST http://localhost:5678/webhook/analyze-image
```

---

## 📚 Related Documentation

- **[DEPLOYMENT_GUIDE.md](../docs/DEPLOYMENT_GUIDE.md)** - Full setup guide (planned)
- **[SYSTEM_ARCHITECTURE.md](../docs/SYSTEM_ARCHITECTURE.md)** - System overview (planned)
- **[TROUBLESHOOTING.md](../docs/TROUBLESHOOTING.md)** - Common issues (planned)

---

## 🆘 Common Issues

### Issue 1: "Module not found"
```bash
# Solution: Install requirements
pip install -r config/requirements.txt
```

### Issue 2: "Database connection refused"
```bash
# Solution: Check PostgreSQL is running
pg_ctl status

# Start PostgreSQL if needed
pg_ctl start
```

### Issue 3: "Invalid Graph API credentials"
```bash
# Solution: Verify credentials in Azure Portal
# Make sure app has correct permissions
# Try regenerating client secret
```

---

## 📞 Support

For configuration help:
1. Check example files in this folder
2. Verify credentials in respective portals
3. Test connections with provided scripts
4. Review [TROUBLESHOOTING.md](../docs/TROUBLESHOOTING.md) (planned)

---

**Last Updated:** November 06, 2025  
**Status:** Example files ready - waiting for actual configs to be created
