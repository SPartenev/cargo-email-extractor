# CargoFlow - TODO & Known Issues

**Last Updated:** November 12, 2025  
**Priority System:** 🔥 Critical | ⚠️ High | ℹ️ Medium | 📌 Low

---

## 🔥 CRITICAL (Must Do Immediately)

### 1. Restart Stalled Queue Managers
**Status:** ❌ Not Done  
**Priority:** 🔥 CRITICAL  
**Assigned:** DevOps

**Problem:**
- Queue managers stopped on 28 Oct 09:40
- 83 files pending in processing_queue
- No new AI categorization since stop

**Action:**
```bash
# Terminal 1
cd C:\Python_project\CargoFlow\Cargoflow_Queue
venv\Scripts\activate
python text_queue_manager.py

# Terminal 2
python image_queue_manager.py
```

**Expected Result:**
- processing_queue starts clearing pending items
- New files get AI categorization
- classification_timestamp updates in email_attachments

---

### 2. Verify n8n Workflows Active
**Status:** ❌ Not Done  
**Priority:** 🔥 CRITICAL  
**Assigned:** DevOps

**Action:**
1. Check n8n server: http://localhost:5678
2. Verify workflows are active:
   - `INV_Text_CargoFlow`
   - `INV_PNG_CargoFlow`
3. Test webhooks:
   ```bash
   curl http://localhost:5678/webhook/analyze-text
   curl http://localhost:5678/webhook/analyze-image
   ```

**Expected Result:**
- n8n responds with HTTP 200/404 (not connection refused)
- Workflows show as "Active" in n8n UI

---

### 3. Start Contract Processor
**Status:** ❌ Not Done  
**Priority:** 🔥 CRITICAL  
**Assigned:** DevOps

**Problem:**
- `contracts` table is empty (0 records)
- Contract detection not running
- Files not being organized

**Action:**
```bash
cd C:\Python_project\CargoFlow\Cargoflow_Contracts
venv\Scripts\activate
python main.py --continuous
```

**Expected Result:**
- email_ready_queue gets processed
- Contract numbers create entries in `contracts` table
- Files organized into folder structure

---

## 📚 DOCUMENTATION TASKS (Complete Project Documentation)

### 🎉 MAJOR MILESTONE: 89% DOCUMENTATION COMPLETE!

**Overall Progress:** 17/19 documents (89%)  
**Core Documentation:** 8/8 (100%) ✅ **COMPLETE!**  
**Module Documentation:** 6/6 (100%) ✅ **COMPLETE!**  
**Support Documentation:** 3/5 (60%)  

**Total Lines Written:** ~30,200+ lines of documentation

**🎯 Remaining:** Only 2 documents left!
- DEPLOYMENT_GUIDE.md (⚠️ HIGH priority - next task)
- TROUBLESHOOTING.md (ℹ️ MEDIUM priority)

### Doc 1: STATUS_FLOW_MAP.md
**Status:** ✅ Complete  
**Priority:** ⚠️ HIGH  
**Assigned:** Documentation Team

**Completed:** November 06, 2025

**Content:**
- Complete status flow diagrams
- All module dependencies mapped
- Database trigger points documented
- Error handling procedures
- Recovery procedures (5 detailed procedures)
- Health check commands

**Location:** `Documentation/docs/STATUS_FLOW_MAP.md`

---

### Doc 2: SYSTEM_ARCHITECTURE.md
**Status:** ✅ Complete  
**Priority:** ⚠️ HIGH  
**Assigned:** Documentation Team

**Completed:** November 06, 2025

**Content:**
- High-level system architecture (layered architecture)
- All 7 component architectures documented
- Complete technology stack
- Integration points (Microsoft Graph, PostgreSQL, n8n, AI APIs)
- Data flow architecture with timing estimates
- File system architecture
- Security & Authentication
- Scalability & Performance
- Deployment architecture
- Multiple architecture diagrams

**Location:** `Documentation/SYSTEM_ARCHITECTURE.md`
**Size:** 6000+ lines

**Dependencies:** STATUS_FLOW_MAP.md (✅ Complete), DATABASE_SCHEMA.md (✅ Complete)

---

### Doc 3: DATABASE_SCHEMA.md
**Status:** ✅ Complete  
**Priority:** ⚠️ HIGH  
**Assigned:** Documentation Team

**Completed:** November 05, 2025

**Content:**
- Complete table schemas (19 tables, all columns, types, constraints)
- Relationships (foreign keys, references)
- Indexes documented
- Triggers (8 triggers with conditions)
- Functions (13 functions with logic)
- Views (invoice_full_view)
- Sample queries for common operations
- Database maintenance procedures
- Troubleshooting queries

**Location:** `Documentation/DATABASE_SCHEMA.md`
**Size:** 650+ lines

---

### Doc 4: MODULE_DEPENDENCIES.md
**Status:** ✅ Complete  
**Priority:** ⚠️ HIGH  
**Assigned:** Documentation Team

**Completed:** November 06, 2025

**Content:**
- Comprehensive module dependency graph (all 7 modules)
- Inter-module communication (4 mechanisms documented)
- Complete API endpoints and webhooks
- File system dependencies with directory structure
- Configuration dependencies (all config files)
- External service dependencies (Microsoft Graph, AI APIs, PostgreSQL, n8n)
- Network & API dependencies (ports, firewall)
- Dependency matrix (7x7)
- Critical paths and failure impact analysis
- Troubleshooting guide

**Location:** `Documentation/MODULE_DEPENDENCIES.md`
**Size:** 13,000+ lines

**Dependencies:** 
- STATUS_FLOW_MAP.md (✅ Complete)
- SYSTEM_ARCHITECTURE.md (✅ Complete)

---

### Doc 5: DEPLOYMENT_GUIDE.md
**Status:** 📝 To Do  
**Priority:** ℹ️ MEDIUM  
**Assigned:** Documentation Team

**Planned Content:**
- Prerequisites and requirements
- Step-by-step installation
- Configuration file setup
- Database initialization
- n8n workflow import
- First-time startup checklist
- Verification procedures

**Dependencies:** 
- SYSTEM_ARCHITECTURE.md (📝 To Do)
- DATABASE_SCHEMA.md (📝 To Do)

---

### Doc 6: TROUBLESHOOTING.md
**Status:** 📝 To Do  
**Priority:** ℹ️ MEDIUM  
**Assigned:** Documentation Team

**Planned Content:**
- Common issues and solutions
- Error message reference
- Log file locations and interpretation
- Debug mode activation
- Performance troubleshooting
- Connection issues (Database, n8n, Microsoft Graph)

**Dependencies:** All other documentation

---

### Doc 7: README.md (Main Project Overview)
**Status:** ✅ Complete  
**Priority:** ℹ️ MEDIUM  
**Assigned:** Documentation Team

**Completed:** November 05, 2025

**Content:**
- Complete system overview
- Architecture diagram
- Project structure
- Configuration requirements
- Quick start guide (7 terminals)
- 13 document categories
- Maintenance and monitoring
- Links to all documentation

**Location:** `Documentation/README.md`
**Size:** 400+ lines

**Note:** Links to planned documentation (SYSTEM_ARCHITECTURE.md, DEPLOYMENT_GUIDE.md, module docs) exist but files not yet created.

---

### Doc 8: n8n Workflow Files
**Status:** ✅ Complete  
**Priority:** ⚠️ HIGH  
**Assigned:** Documentation Team

**Completed:** November 05, 2025 (or earlier)

**Content:**
- 2 n8n workflow JSON files
- `Contract_PNG_CargoFlow.json` - Image processing workflow
- `Contract_Text_CargoFlow.json` - Text processing workflow

**Location:** `Documentation/n8n/workflows/`

---

### Doc 9: Module Documentation (6 files)
**Status:** ✅ COMPLETE  
**Priority:** ⚠️ HIGH  
**Assigned:** Documentation Team

**Planned Files:**
1. `modules/01_EMAIL_FETCHER.md` - Email extraction module ✅ COMPLETE (700+ lines)
2. `modules/02_OCR_PROCESSOR.md` - OCR processing module ✅ COMPLETE (600+ lines)
3. `modules/03_OFFICE_PROCESSOR.md` - Office document processing ✅ COMPLETE (1000+ lines)
4. `modules/04_QUEUE_MANAGERS.md` - Queue management system ✅ COMPLETE (1500+ lines)
5. `modules/05_N8N_WORKFLOWS.md` - n8n workflow details ✅ COMPLETE (2000+ lines)
6. `modules/06_CONTRACTS_PROCESSOR.md` - Contract detection and organization ✅ COMPLETE (1000+ lines)

**Completion Date:** November 06, 2025
**Total Lines:** ~7,800+ lines of module documentation
**Status:** ✅ ALL MODULE DOCUMENTATION COMPLETE!

**CRITICAL REQUIREMENT - Status Management Section:**

Each module documentation MUST include a dedicated section:
**"Status Management & Database State"**

This section must document:

1. **Statuses READ by this module:**
   - Which table(s) and column(s)
   - What values trigger action
   - Query examples

2. **Statuses WRITTEN by this module:**
   - Which table(s) and column(s)
   - From what → To what (state transitions)
   - When/why the change happens
   - Code references

3. **Impact on other modules:**
   - Which downstream modules depend on these status changes
   - What actions are triggered
   - PostgreSQL triggers involved

4. **Status transition examples:**
   - Before/After SQL query results
   - Real data examples
   - Timeline of changes

5. **Troubleshooting status issues:**
   - Common stuck states
   - How to detect issues
   - Recovery procedures

**Example Structure (from 01_EMAIL_FETCHER.md):**
```
## Status Management & Database State
### Tables Modified
- emails (INSERT)
- email_attachments (INSERT with processing_status='pending')

### Status Flow
pending → [Next Module]

### Module Dependency Chain
Email Fetcher → OCR/Office Processor

### Queries for Verification
[SQL examples]
```

**Goal:** Create complete end-to-end status flow map across all modules

**Progress:** 6/6 modules complete (100%) ✅ **COMPLETE!**
- ✅ 01_EMAIL_FETCHER.md (700+ lines)
- ✅ 02_OCR_PROCESSOR.md (600+ lines)
- ✅ 03_OFFICE_PROCESSOR.md (1000+ lines)
- ✅ 04_QUEUE_MANAGERS.md (1500+ lines)
- ✅ 05_N8N_WORKFLOWS.md (2000+ lines)
- ✅ 06_CONTRACTS_PROCESSOR.md (1000+ lines)

**Dependencies:** 
- SYSTEM_ARCHITECTURE.md (📝 To Do)
- DATABASE_SCHEMA.md (✅ Complete)
- STATUS_FLOW_MAP.md (✅ Complete)

---

### Doc 10: Config Example Files
**Status:** ⏳ Partially Started  
**Priority:** ⚠️ HIGH  
**Assigned:** Documentation Team

**Needed Files:**
1. `config/graph_config.json.example` - Microsoft Graph API config template
2. `config/queue_config.json.example` - Queue manager config template
3. `config/.env.example` - Environment variables template
4. `config/requirements.txt` - Python dependencies

**Purpose:** Allow easy setup for new deployments without exposing credentials

---

### Doc 11: Database Detail Files
**Status:** 📝 To Do  
**Priority:** ℹ️ MEDIUM  
**Assigned:** Documentation Team

**Planned Content:**
- `database/schema/` - Individual SQL files for each table (19 files)
- `database/triggers/` - Individual SQL files for each trigger (8 files)
- `database/functions/` - Individual SQL files for each function (13 files)

**Purpose:** Modular database documentation for easier maintenance

**Note:** Folders exist but are empty.

---

## ⚠️ HIGH PRIORITY (Do This Week)

### 4. Monitor AI Categorization Progress
**Status:** ⏳ Ongoing  
**Priority:** ⚠️ HIGH

**Target:** 80%+ of attachments categorized

**Current:**
- Categorized: 102/296 (34%)
- Remaining: 194 files

**Monitoring Query:**
```sql
SELECT 
    COUNT(*) FILTER (WHERE document_category IS NOT NULL) as categorized,
    COUNT(*) FILTER (WHERE document_category IS NULL) as uncategorized,
    ROUND(100.0 * COUNT(*) FILTER (WHERE document_category IS NOT NULL) / COUNT(*), 1) as pct_complete
FROM email_attachments;
```

**Action:** Check daily until 80%+ complete

---

### 5. Verify Contract Number Extraction
**Status:** ❌ Not Done  
**Priority:** ⚠️ HIGH

**Verification Query:**
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

**Expected:**
- Contract numbers like "50251006834", "50251007003"
- Multiple files per contract
- Mostly CMR, invoice, contract categories

**If Empty:**
- AI agent instructions may need update
- n8n workflow may not be extracting contract_number
- Check n8n logs for errors

---

### 6. Process Email Ready Queue
**Status:** ❌ Not Done  
**Priority:** ⚠️ HIGH

**Check Queue:**
```sql
SELECT * FROM email_ready_queue WHERE processed = FALSE;
```

**Expected:**
- ~9 emails ready (as of 30 Oct 2025)
- Should create ~9 entries in `contracts` table
- Should create organized folder structure

**Monitor:**
```sql
SELECT COUNT(*) FROM contracts; -- Should increase
```

---

## ℹ️ MEDIUM PRIORITY (Next 2 Weeks)

### 7. Analyze Processing History Failures
**Status:** 📊 Analysis Needed  
**Priority:** ℹ️ MEDIUM

**Problem:**
- processing_history shows 86% failure rate (historical data)

**Analysis Query:**
```sql
SELECT 
    file_type,
    success,
    COUNT(*) as count,
    ROUND(AVG(processing_time_ms), 0) as avg_time_ms
FROM processing_history
GROUP BY file_type, success
ORDER BY file_type, success DESC;
```

**Action:** Identify common error patterns and fix

---

### 8. Implement Monitoring Dashboard
**Status:** 💡 Idea  
**Priority:** ℹ️ MEDIUM

**Components:**
- Real-time queue status
- AI categorization progress
- Contract detection status
- Error alerts

**Technology Options:**
- Grafana + PostgreSQL datasource
- Custom Python dashboard (Streamlit)
- n8n dashboard workflow

---

### 9. Optimize Database Indexes
**Status:** 📊 Analysis Needed  
**Priority:** ℹ️ MEDIUM

**Check Slow Queries:**
```sql
SELECT query, calls, total_exec_time, mean_exec_time
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;
```

**Add Indexes If Needed:**
- `email_attachments(email_id, processing_status)`
- `document_pages(attachment_id, page_number)`
- Composite indexes based on query patterns

---

### 10. Document Folder Organization Logic
**Status:** 📝 Documentation Needed  
**Priority:** ℹ️ MEDIUM

**Current Behavior (Needs Verification):**
- Folders created by contract_key
- Indices from contract_folder_seq
- Format: `{contract_number}_{index}/`

**Documentation Needed:**
- Folder naming convention
- Index increment logic
- Handling of multiple contracts per email
- File moving vs copying behavior

---

## 📌 LOW PRIORITY (Future Enhancements)

### 11. Implement Contract Folder Reassembly
**Status:** ✅ **COMPLETED** (November 12, 2025)  
**Priority:** 📌 LOW

**Implementation:**
- ✅ Multi-page documents split by page category
- ✅ PNG pages grouped by category from `document_pages` table
- ✅ Separate PDF files created for each category group
- ✅ Example: 7-page document → `other_50251007351.pdf` (5 pages) + `protocol_50251007351.pdf` (2 pages)
- ✅ Text files remain as single documents (not split)
- ✅ Automatic page orientation correction (EXIF + 180° rotation)

**Location:** `Cargoflow_Contracts/services/file_organizer.py` - `_process_png_pages_by_category()` method

---

### 12. Add Email Analysis System
**Status:** 💡 Idea  
**Priority:** 📌 LOW

**Features:**
- Analyze email body text (not just attachments)
- Extract action items from email content
- Priority detection
- Response urgency classification

**Implementation:**
- New n8n workflow for email body
- Update `emails.analysis_*` columns
- Trigger on email INSERT

---

### 13. Create Backup and Recovery Procedures
**Status:** 📝 Documentation Needed  
**Priority:** 📌 LOW

**Components:**
- Database backup script (pg_dump)
- File attachment backup (C:\CargoAttachments\)
- Recovery testing procedure
- Disaster recovery plan

---

### 14. Performance Testing and Optimization
**Status:** 🧪 Testing Needed  
**Priority:** 📌 LOW

**Tests:**
- Process 1000+ emails
- Concurrent queue processing
- Database connection pooling
- Rate limiting effectiveness

**Optimization Areas:**
- Batch processing improvements
- Parallel n8n workflow execution
- Database query optimization

---

## 🐛 KNOWN ISSUES

### Issue #1: Queue Managers Stop Randomly
**Severity:** ⚠️ HIGH  
**Status:** ⏳ Monitoring

**Symptoms:**
- Queue managers stop processing without error
- Last occurred: 28 Oct 2025, 09:40

**Workaround:**
- Manual restart of queue managers

**Root Cause:**
- Unknown - needs investigation
- Possible causes:
  - Memory leak
  - Unhandled exception
  - Network timeout to n8n
  - Database connection loss

**Next Steps:**
- Add more detailed logging
- Implement health check ping
- Auto-restart on failure

---

### Issue #2: AI Categorization Inconsistent
**Severity:** ℹ️ MEDIUM  
**Status:** 📊 Under Investigation

**Symptoms:**
- Some files get categorized immediately
- Others stay pending for extended time
- No clear pattern

**Possible Causes:**
- n8n webhook delays
- PostgreSQL NOTIFY not reaching n8n
- Rate limiting too aggressive
- Network issues

**Monitoring:**
```sql
SELECT 
    file_type,
    status,
    COUNT(*),
    MIN(created_at) as oldest_pending,
    MAX(created_at) as newest_pending
FROM processing_queue
WHERE status = 'pending'
GROUP BY file_type, status;
```

---

### Issue #3: contracts Table Never Populated
**Severity:** 🔥 CRITICAL  
**Status:** ⏳ In Progress

**Problem:**
- 0 contracts in database
- Folder organization not working

**Root Causes (Identified):**
1. Contract processor not running
2. email_ready_queue not being processed
3. Dependency on AI categorization completion

**Fix:** Start contract processor (See Critical #3)

---

### Issue #4: Some Attachments Not in Database
**Severity:** ⚠️ HIGH  
**Status:** 🔍 Investigation Needed

**Observation:**
- Files exist in C:\CargoAttachments\
- Not all have email_attachments records

**Possible Causes:**
- Small images filtered out (logos, signatures)
- Database insert errors
- Graph API attachment fetch failures

**Verification Query:**
```sql
SELECT 
    e.id,
    e.subject,
    e.attachment_count,
    COUNT(ea.id) as db_attachment_count
FROM emails e
LEFT JOIN email_attachments ea ON e.id = ea.email_id
WHERE e.has_attachments = TRUE
GROUP BY e.id, e.subject, e.attachment_count
HAVING e.attachment_count != COUNT(ea.id)
LIMIT 20;
```

---

## 📅 Timeline

### Week 1 (Current Week)
- [x] Create documentation (✅ 17/19 complete, 89%)
- [x] Core documentation (✅ 8/8 complete, 100%)
- [x] Module documentation (✅ 6/6 complete, 100%)
- [x] MODULE_DEPENDENCIES.md (✅ Complete - 13,000+ lines)
- [ ] Restart queue managers
- [ ] Verify n8n workflows
- [ ] Start contract processor
- [ ] Monitor AI categorization

### Week 2
- [ ] Process email_ready_queue
- [ ] Verify contract number extraction
- [ ] Analyze processing history failures

### Week 3-4
- [ ] Optimize database performance
- [ ] Document folder organization
- [ ] Implement monitoring dashboard

### Month 2+
- [ ] Contract reassembly feature
- [ ] Email analysis system
- [ ] Backup procedures
- [ ] Performance testing

---

## 📊 Success Metrics

### Current Status (Nov 06, 2025)
- [x] Email extraction: 100% (226 emails)
- [ ] Attachment storage: 100% (296 files)
- [ ] AI categorization: 34% (102/296) - **Target: 80%**
- [ ] Queue processing: 61% (130/213) - **Target: 95%**
- [ ] Contract detection: 0% - **Target: 100% of applicable docs**

### Definition of "Fully Operational"
- [ ] Email extraction running 24/7
- [ ] AI categorization > 80% within 24 hours
- [ ] Queue processing > 95% within 24 hours
- [ ] Contract detection working for all contract docs
- [ ] Folder organization automated
- [ ] Zero critical errors in logs

---

## 🔄 Regular Maintenance Tasks

### Daily
- [ ] Check all 7 processes are running
- [ ] Monitor AI categorization progress
- [ ] Review error logs
- [ ] Check processing_queue status

### Weekly
- [ ] Database VACUUM ANALYZE
- [ ] Review processing_history for patterns
- [ ] Check disk space (C:\CargoAttachments\)
- [ ] Update TODO list

### Monthly
- [ ] Database backup
- [ ] Review and archive old logs
- [ ] Performance testing
- [ ] Update documentation

---

**Status Legend:**
- ❌ Not Done
- ⏳ In Progress / Ongoing
- 📊 Analysis/Investigation Needed
- 💡 Idea/Proposal
- 📝 Documentation Needed
- 🧪 Testing Needed
- 🔍 Investigation Needed
- ✅ Complete

---

**Last Updated:** November 12, 2025  
**Next Review:** After queue managers and contract processor restart

---

## 📊 Documentation Progress Summary

**Total Planned Documents:** 19 (8 core + 6 module + 5 support)

**Core Documentation (8/8 - 100%) ✅ COMPLETE:**
- ✅ docs/STATUS_FLOW_MAP.md (650+ lines)
- ✅ DATABASE_SCHEMA.md (650+ lines)
- ✅ README.md (400+ lines)
- ✅ SYSTEM_ARCHITECTURE.md (6000+ lines)
- ✅ MODULE_DEPENDENCIES.md (13000+ lines) 🎉 **NEW!**
- ✅ CONTEXT_FOR_NEW_CHAT.md (~200 lines)
- ✅ TODO.md (~800 lines)
- ✅ PROJECT_STATUS.md (~800 lines)

**Module Documentation (6/6 - 100%) ✅ COMPLETE:**
- ✅ 01_EMAIL_FETCHER.md (700+ lines)
- ✅ 02_OCR_PROCESSOR.md (600+ lines)
- ✅ 03_OFFICE_PROCESSOR.md (1000+ lines)
- ✅ 04_QUEUE_MANAGERS.md (1500+ lines)
- ✅ 05_N8N_WORKFLOWS.md (2000+ lines)
- ✅ 06_CONTRACTS_PROCESSOR.md (1000+ lines)

**Support Documentation (4/6 - 67%):**
- ✅ database/README.md
- ✅ n8n/README.md
- ✅ modules/README.md
- ✅ config/README.md
- ✅ 2x n8n workflow JSON files
- ⏳ Config example files (partially started)

**Remaining:** 2 documents (11%)
- 📝 DEPLOYMENT_GUIDE.md (⚠️ HIGH - next priority)
- 📝 TROUBLESHOOTING.md (ℹ️ MEDIUM)

**Total Lines Written:** ~30,200+ lines of documentation 🎉🎉

**Overall Progress:** 17/19 documents (89%) 🎉

---

## 🔄 Status Flow Documentation Plan

### Vision

Create a **complete, traceable status flow map** across all 7 modules showing:
- Which module reads which statuses
- Which module writes which statuses  
- State transitions (from → to)
- Triggers and dependencies
- Impact on downstream modules

### Modules & Their Status Responsibilities

| Module | Status READ | Status WRITE | Tables Modified |
|--------|-------------|--------------|----------------|
| **1. Email Fetcher** | None (entry point) | `processing_status='pending'` | `emails`, `email_attachments` |
| **2. OCR Processor** | `processing_status='pending'` | `processing_status='completed'` | `email_attachments` |
| **3. Office Processor** | `processing_status='pending'` | `processing_status='completed'` | `email_attachments` |
| **4. Queue Managers** | Files on disk | `status='pending'` | `processing_queue` |
| **5. n8n Workflows** | `processing_queue.status='pending'` | `document_category`, `contract_number`, `processing_status='classified'` | `email_attachments`, `invoice_base`, `document_pages` |
| **6. Contract Processor** | `email_ready_queue.processed=FALSE` | `processing_status='organized'`, `folder_name` | `email_attachments`, `emails`, `contracts` |

### Status Progression Map (Target)

```
Module 1: Email Fetcher
  └─ WRITES: email_attachments.processing_status = 'pending'
      ↓
Module 2/3: OCR/Office Processor  
  ├─ READS: WHERE processing_status = 'pending'
  └─ WRITES: processing_status = 'processing' → 'completed'
      ↓
Module 4: Queue Managers
  ├─ READS: Files in C:\CargoProcessing\
  └─ WRITES: processing_queue.status = 'pending'
      ↓ (PostgreSQL NOTIFY trigger)
Module 5: n8n Workflows
  ├─ READS: processing_queue.status = 'pending'
  └─ WRITES: 
      ├─ document_category = 'invoice'/'cmr'/etc.
      ├─ contract_number = '50251006834'
      └─ processing_status = 'classified'
      ↓ (Trigger: all attachments classified)
Module 6: Contract Processor
  ├─ READS: email_ready_queue.processed = FALSE
  └─ WRITES:
      ├─ processing_status = 'organized'
      ├─ emails.folder_name = '{contract}_{index}'
      └─ contracts table populated
```

### Documentation Progress

**Completed Modules:**
- ✅ 01_EMAIL_FETCHER.md - Full status documentation (700+ lines)
  - Statuses WRITTEN: `processing_status='pending'`
  - Impact: Triggers OCR/Office Processor
  - Complete with queries and troubleshooting

- ✅ 02_OCR_PROCESSOR.md - Full status documentation (600+ lines)
  - Statuses READ: `processing_status='pending'`
  - Statuses WRITTEN: `processing_status='processing'` → `'completed'`
  - Impact: Triggers Queue Managers
  - Complete with queries and troubleshooting

**Completed Modules:**
- ✅ 03_OFFICE_PROCESSOR.md - Full status documentation (1000+ lines)
  - Statuses READ: None (uses file system watcher)
  - Statuses WRITTEN: None (independent operation)
  - Impact: Creates text files for Queue Managers
  - Complete with queries and troubleshooting

- ✅ 04_QUEUE_MANAGERS.md - Full status documentation (1500+ lines)
  - Statuses READ: `processing_queue.status='pending'` (to check duplicates)
  - Statuses WRITTEN: `processing_queue.status='pending'` (INSERT)
  - Impact: Triggers n8n workflows via PostgreSQL NOTIFY
  - Complete with queries and troubleshooting

- ✅ 05_N8N_WORKFLOWS.md - Full status documentation (2000+ lines)
  - Statuses READ: `processing_queue.status='pending'`
  - Statuses WRITTEN: Multiple tables (email_attachments, processing_queue, document_pages, invoice_base)
  - Impact: Categorizes documents, triggers Contract Processor
  - Complete with AI prompts and troubleshooting

- ✅ 06_CONTRACTS_PROCESSOR.md - Full status documentation (1000+ lines)
  - Statuses READ: `email_ready_queue.processed=FALSE`
  - Statuses WRITTEN: `emails.folder_name`, `contracts`, `processing_status='organized'`
  - Impact: Creates organized folder structure (final output)
  - Complete with CLI commands and troubleshooting

### Final Deliverable

Once all 6 module documents are complete, create:

**`docs/COMPLETE_STATUS_FLOW.md`**

A master document that:
1. Aggregates all status information from all modules
2. Shows complete end-to-end flow with timing
3. Includes all SQL queries for status verification
4. Documents all PostgreSQL triggers and their effects
5. Provides troubleshooting guide for each status transition
6. Visual diagrams showing status progression

**Status:**
- Current: 6/6 modules (100%) ✅ **COMPLETE!**
- All modules have comprehensive status documentation
- End-to-end status flow fully documented
- Ready for final aggregation document

**Next Step:**
- Create `docs/COMPLETE_STATUS_FLOW.md` master document
- Aggregate all status information from all 6 modules
- Include complete end-to-end flow diagrams
