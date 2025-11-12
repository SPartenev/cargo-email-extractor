# Configuration Files Documentation

**Last Updated:** November 12, 2025  
**Purpose:** Documentation for CargoFlow system configuration files

---

## 📁 Configuration Files Location

**Note:** This folder contains only documentation. Actual configuration files are located in their respective module folders.

```
CargoFlow/
├── Cargoflow_mail/
│   └── graph_config.json          # Microsoft Graph API config
├── Cargoflow_Queue/
│   └── queue_config.json          # Queue manager settings
└── Cargoflow_Contracts/
    └── config/
        ├── settings.py            # Contract processor settings
        └── database.py            # Database connection
```

---

## 🔧 Configuration Files

### 1. graph_config.json

**Purpose:** Microsoft Graph API credentials and database connection

**Location:** `Cargoflow_mail/graph_config.json` (actual file)

**Structure:**
```json
{
  "client_id": "Azure AD Application ID",
  "client_secret": "Azure AD Client Secret",
  "tenant_id": "Azure AD Tenant ID",
  "user_email": "pa@cargo-flow.fr",
  "database": {
    "host": "localhost",
    "database": "Cargo_mail",
    "user": "postgres",
    "password": "your-password",
    "port": 5432
  },
  "monitoring": {
    "check_interval_minutes": 3,
    "bootstrap_email_count": 100
  },
  "paths": {
    "attachments_base": "C:/CargoAttachments",
    "processing_base": "C:/CargoProcessing"
  }
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

### 2. queue_config.json

**Purpose:** Queue manager settings for text and image processing

**Location:** `Cargoflow_Queue/queue_config.json` (actual file)

**Structure:**
```json
{
    "text_queue": {
        "watch_path": "C:\\CargoProcessing\\processed_documents\\2025\\ocr_results",
        "webhook_url": "http://localhost:5678/webhook/analyze-text",
        "rate_limit_per_minute": 5,
        "scan_interval_seconds": 10,
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
        "database": "Cargo_mail",
        "user": "postgres",
        "password": "your-password",
        "port": 5432
    },
    "retry": {
        "max_attempts": 3,
        "retry_delay_seconds": 60
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

### 3. settings.py (Contract Processor)

**Purpose:** Contract processor configuration settings

**Location:** `Cargoflow_Contracts/config/settings.py` (actual file)

**Key Settings:**
```python
# Database Configuration
DB_CONFIG = {
    'host': 'localhost',
    'port': 5432,
    'database': 'Cargo_mail',
    'user': 'postgres',
    'password': 'your-password'
}

# Folder Organization Paths
CONTRACTS_BASE_PATH = Path(
    r'C:\Users\Delta\Cargo Flow\Site de communication - Documents\Документи по договори'
)

# Processing Settings
BATCH_SIZE = 10
SCAN_INTERVAL = 30  # seconds

# Logging
LOG_LEVEL = 'INFO'
LOG_FILE = 'contract_processor.log'
```

**See also:** `Cargoflow_Contracts/docs/config.md` for detailed documentation

---

## 🛠️ Configuration Management

### Editing Configuration Files

**Important:** Configuration files contain sensitive data (passwords, API keys). Never commit them to Git.

**Files to edit:**
1. `Cargoflow_mail/graph_config.json` - Microsoft Graph API credentials
2. `Cargoflow_Queue/queue_config.json` - Queue manager settings
3. `Cargoflow_Contracts/config/settings.py` - Contract processor settings

### Verify Paths

Make sure these directories exist (they are created automatically by the system):
- `C:\CargoAttachments\` - Email attachments storage
- `C:\CargoProcessing\` - Processed documents
- `C:\Users\Delta\Cargo Flow\Site de communication - Documents\Документи по договори\` - Organized contracts

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

**Configuration files should be in `.gitignore`:**

```gitignore
# Configuration files (sensitive data)
Cargoflow_mail/graph_config.json
Cargoflow_Queue/queue_config.json
Cargoflow_Contracts/config/settings.py  # If contains passwords

# Logs
*.log

# Python
__pycache__/
*.py[cod]
venv/
env/

# Data folders
CargoAttachments/
CargoProcessing/
```

---

## 🧪 Testing Configuration

### Validate JSON Files

```bash
# Test JSON syntax
python -m json.tool Cargoflow_mail/graph_config.json
python -m json.tool Cargoflow_Queue/queue_config.json
```

### Test Database Connection

```python
# From Cargoflow_Contracts
from config.database import test_connection
test_connection()
```

---

## 📚 Related Documentation

- **[DEPLOYMENT_GUIDE.md](../DEPLOYMENT_GUIDE.md)** - Full setup guide
- **[SYSTEM_ARCHITECTURE.md](../SYSTEM_ARCHITECTURE.md)** - System overview
- **[TROUBLESHOOTING.md](../TROUBLESHOOTING.md)** - Common issues
- **[Cargoflow_Contracts/docs/config.md](../../Cargoflow_Contracts/docs/config.md)** - Contract processor config details

---

## 🆘 Common Issues

### Issue 1: "Database connection refused"
- Check PostgreSQL is running
- Verify credentials in config files
- Check firewall settings

### Issue 2: "Invalid Graph API credentials"
- Verify credentials in Azure Portal
- Make sure app has correct permissions (Mail.Read, Mail.ReadWrite)
- Try regenerating client secret

### Issue 3: "Configuration file not found"
- Check file paths in this documentation
- Verify files exist in their respective module folders

---

**Last Updated:** November 12, 2025  
**Status:** Documentation for actual configuration files
