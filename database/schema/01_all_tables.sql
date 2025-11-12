-- CargoFlow Database Schema
-- All Tables CREATE Statements
-- Generated: November 12, 2025

-- ============================================
-- TABLE: contract_analysis
-- ============================================
CREATE TABLE contract_analysis (
    id INTEGER NOT NULL DEFAULT nextval('contract_analysis_id_seq'::regclass),
    attachment_id INTEGER NOT NULL,
    is_contract BOOLEAN NOT NULL DEFAULT false,
    confidence_score NUMERIC NOT NULL DEFAULT 0.00,
    contract_numbers ARRAY,
    analysis_details JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLE: contract_details
-- ============================================
CREATE TABLE contract_details (
    contract_id INTEGER,
    contract_number VARCHAR(11),
    folder_path TEXT,
    detected_in ARRAY,
    contract_status VARCHAR(20),
    detected_at TIMESTAMP,
    processed_at TIMESTAMP,
    sender_email VARCHAR(255),
    email_subject TEXT,
    received_time TIMESTAMP,
    document_count BIGINT,
    copied_documents BIGINT,
    total_size_bytes NUMERIC
);

-- ============================================
-- TABLE: contract_detection_queue
-- ============================================
CREATE TABLE contract_detection_queue (
    id INTEGER NOT NULL DEFAULT nextval('contract_detection_queue_id_seq'::regclass),
    email_id INTEGER,
    attachment_id INTEGER,
    queued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP,
    status VARCHAR(20) DEFAULT 'pending'::character varying,
    error_message TEXT
);

-- ============================================
-- TABLE: contract_documents
-- ============================================
CREATE TABLE contract_documents (
    id INTEGER NOT NULL DEFAULT nextval('contract_documents_id_seq'::regclass),
    contract_id INTEGER,
    attachment_id INTEGER,
    original_file_path TEXT,
    pdf_file_path TEXT,
    file_type VARCHAR(20),
    document_category VARCHAR(50),
    conversion_needed BOOLEAN DEFAULT true,
    converted_at TIMESTAMP,
    copied_at TIMESTAMP,
    file_size_bytes BIGINT,
    status VARCHAR(20) DEFAULT 'pending'::character varying,
    error_message TEXT
);

-- ============================================
-- TABLE: contract_folder_seq
-- ============================================
CREATE TABLE contract_folder_seq (
    contract_key TEXT NOT NULL,
    last_index INTEGER DEFAULT 0,
    updated_at TIMESTAMP DEFAULT now()
);

-- ============================================
-- TABLE: contract_processing_log
-- ============================================
CREATE TABLE contract_processing_log (
    id INTEGER NOT NULL DEFAULT nextval('contract_processing_log_id_seq'::regclass),
    contract_id INTEGER,
    action VARCHAR(50),
    details JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLE: contract_statistics
-- ============================================
CREATE TABLE contract_statistics (
    detection_date DATE,
    total_contracts BIGINT,
    total_emails BIGINT,
    completed_contracts BIGINT,
    processing_contracts BIGINT,
    error_contracts BIGINT
);

-- ============================================
-- TABLE: contracts
-- ============================================
CREATE TABLE contracts (
    id INTEGER NOT NULL DEFAULT nextval('contracts_id_seq'::regclass),
    contract_number VARCHAR(11) NOT NULL,
    email_id INTEGER,
    folder_path TEXT,
    detected_in ARRAY,
    detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP,
    status VARCHAR(20) DEFAULT 'detected'::character varying,
    error_message TEXT
);

-- ============================================
-- TABLE: document_pages
-- ============================================
CREATE TABLE document_pages (
    id INTEGER NOT NULL DEFAULT nextval('document_pages_id_seq'::regclass),
    attachment_id INTEGER,
    page_number INTEGER NOT NULL,
    category VARCHAR(50),
    confidence_score NUMERIC,
    summary TEXT,
    contract_number VARCHAR(50),
    contract_number_confidence NUMERIC,
    created_at TIMESTAMP DEFAULT now()
);

-- ============================================
-- TABLE: email_attachments
-- ============================================
CREATE TABLE email_attachments (
    id INTEGER NOT NULL DEFAULT nextval('email_attachments_id_seq'::regclass),
    email_id INTEGER,
    attachment_name VARCHAR(255),
    attachment_path TEXT,
    attachment_size BIGINT,
    attachment_type VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    document_category VARCHAR(50),
    confidence_score NUMERIC,
    classification_timestamp TIMESTAMP,
    extracted_data JSONB,
    processing_status VARCHAR(20) DEFAULT 'pending'::character varying,
    processed_at TIMESTAMP,
    error_message TEXT,
    classification_summary TEXT,
    total_pages INTEGER,
    contract_number VARCHAR(20)
);

-- ============================================
-- TABLE: email_ready_queue
-- ============================================
CREATE TABLE email_ready_queue (
    email_id INTEGER NOT NULL,
    ready_at TIMESTAMP DEFAULT now(),
    processed BOOLEAN DEFAULT false,
    processed_at TIMESTAMP
);

-- ============================================
-- TABLE: emails
-- ============================================
CREATE TABLE emails (
    id INTEGER NOT NULL DEFAULT nextval('emails_id_seq'::regclass),
    subject TEXT,
    sender_name VARCHAR(255),
    sender_email VARCHAR(255),
    recipients TEXT,
    cc_recipients TEXT,
    bcc_recipients TEXT,
    received_time TIMESTAMP,
    sent_time TIMESTAMP,
    body_text TEXT,
    body_html TEXT,
    has_attachments BOOLEAN DEFAULT false,
    attachment_count INTEGER DEFAULT 0,
    attachment_names TEXT,
    importance VARCHAR(10),
    message_class VARCHAR(50),
    entry_id VARCHAR(255),
    folder_name VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    attachment_folder TEXT,
    attachment_paths JSONB,
    analysis_result JSONB,
    analysis_timestamp TIMESTAMP,
    analysis_status VARCHAR(50) DEFAULT 'pending'::character varying,
    analysis_summary TEXT,
    analysis_categories ARRAY,
    analysis_priority VARCHAR(20),
    analysis_action_items JSONB,
    needs_response BOOLEAN DEFAULT false,
    extracted_data JSONB,
    potential_invoice BOOLEAN DEFAULT false,
    invoice_processed BOOLEAN DEFAULT false,
    extracted_invoice_text TEXT,
    invoice_extraction_method VARCHAR(50),
    invoice_extraction_timestamp TIMESTAMP,
    document_category VARCHAR(50),
    document_count INTEGER DEFAULT 0,
    classification_summary TEXT,
    classification_confidence NUMERIC,
    classification_timestamp TIMESTAMP,
    email_body_summary TEXT,
    contract_folder_name VARCHAR(255)
);

-- ============================================
-- TABLE: invoice_base
-- ============================================
CREATE TABLE invoice_base (
    id INTEGER NOT NULL DEFAULT nextval('invoice_base_id_seq'::regclass),
    email_id INTEGER NOT NULL,
    invoice_number VARCHAR(100),
    invoice_date DATE,
    due_date DATE,
    supplier_name VARCHAR(255),
    supplier_vat VARCHAR(50),
    supplier_address TEXT,
    customer_name VARCHAR(255),
    customer_vat VARCHAR(50),
    customer_address TEXT,
    subtotal NUMERIC,
    tax_amount NUMERIC,
    tax_rate NUMERIC,
    total_amount NUMERIC,
    currency VARCHAR(3) DEFAULT 'BGN'::character varying,
    original_file_path TEXT,
    extracted_data JSONB,
    confidence_score NUMERIC,
    validation_status VARCHAR(20) DEFAULT 'pending'::character varying,
    validation_errors JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP,
    sender_email VARCHAR(255),
    iban VARCHAR(34),
    payment_method VARCHAR(50),
    tax_event_date DATE,
    issue_date DATE,
    supplier_id_number VARCHAR(50),
    original_link TEXT,
    sync_status VARCHAR(20) DEFAULT 'pending'::character varying,
    synced_at TIMESTAMP,
    mysql_accounting_id INTEGER,
    sync_error TEXT
);

-- ============================================
-- TABLE: invoice_full_view (VIEW)
-- ============================================
-- Note: This is a view, not a table
-- CREATE VIEW invoice_full_view AS ...

-- ============================================
-- TABLE: invoice_items
-- ============================================
CREATE TABLE invoice_items (
    id INTEGER NOT NULL DEFAULT nextval('invoice_items_id_seq'::regclass),
    invoice_id INTEGER NOT NULL,
    line_number INTEGER,
    description TEXT,
    quantity NUMERIC,
    unit_price NUMERIC,
    unit VARCHAR(20),
    tax_rate NUMERIC,
    tax_amount NUMERIC,
    line_total NUMERIC,
    product_code VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLE: processing_history
-- ============================================
CREATE TABLE processing_history (
    id INTEGER NOT NULL DEFAULT nextval('processing_history_id_seq'::regclass),
    file_path TEXT NOT NULL,
    file_type VARCHAR(10),
    webhook_url TEXT,
    response_status INTEGER,
    response_body TEXT,
    processing_time_ms INTEGER,
    timestamp TIMESTAMP DEFAULT now(),
    success BOOLEAN,
    error_message TEXT,
    queue_id INTEGER
);

-- ============================================
-- TABLE: processing_queue
-- ============================================
CREATE TABLE processing_queue (
    id INTEGER NOT NULL DEFAULT nextval('processing_queue_id_seq'::regclass),
    file_path TEXT NOT NULL,
    file_type VARCHAR(10) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending'::character varying,
    priority INTEGER DEFAULT 0,
    attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,
    created_at TIMESTAMP DEFAULT now(),
    processed_at TIMESTAMP,
    last_attempt_at TIMESTAMP,
    error_message TEXT,
    email_id INTEGER,
    attachment_id INTEGER,
    file_metadata JSONB,
    original_document VARCHAR(500),
    group_processing_status VARCHAR(50) DEFAULT 'pending'::character varying
);

-- ============================================
-- TABLE: schema_changes
-- ============================================
CREATE TABLE schema_changes (
    id INTEGER NOT NULL DEFAULT nextval('schema_changes_id_seq'::regclass),
    snapshot_id INTEGER,
    change_date TIMESTAMP DEFAULT now(),
    change_type VARCHAR(20),
    object_type VARCHAR(20),
    object_name VARCHAR(255),
    table_name VARCHAR(255),
    old_value JSONB,
    new_value JSONB,
    change_description TEXT
);

-- ============================================
-- TABLE: schema_snapshots
-- ============================================
CREATE TABLE schema_snapshots (
    id INTEGER NOT NULL DEFAULT nextval('schema_snapshots_id_seq'::regclass),
    snapshot_date TIMESTAMP DEFAULT now(),
    snapshot_data JSONB NOT NULL,
    tables_count INTEGER,
    views_count INTEGER,
    total_columns INTEGER,
    snapshot_hash VARCHAR(64),
    notes TEXT
);

