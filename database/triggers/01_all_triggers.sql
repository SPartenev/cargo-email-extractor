-- CargoFlow Database Triggers
-- All Triggers CREATE Statements
-- Generated: November 12, 2025

-- ============================================
-- TRIGGER: contract_detection_trigger
-- Table: email_attachments
-- ============================================
CREATE TRIGGER contract_detection_trigger 
AFTER UPDATE OF document_category ON public.email_attachments 
FOR EACH ROW 
WHEN (((new.document_category IS NOT NULL) AND ((old.document_category IS NULL) OR ((old.document_category)::text IS DISTINCT FROM (new.document_category)::text)))) 
EXECUTE FUNCTION queue_contract_detection();

-- ============================================
-- TRIGGER: trigger_process_email_contracts
-- Table: email_attachments
-- ============================================
CREATE TRIGGER trigger_process_email_contracts 
AFTER UPDATE OF processing_status ON public.email_attachments 
FOR EACH ROW 
WHEN (((new.processing_status)::text = 'completed'::text)) 
EXECUTE FUNCTION process_email_contracts();

-- ============================================
-- TRIGGER: trigger_queue_email
-- Table: email_attachments
-- ============================================
CREATE TRIGGER trigger_queue_email 
AFTER UPDATE ON public.email_attachments 
FOR EACH ROW 
EXECUTE FUNCTION queue_email_for_folder_update();

-- ============================================
-- TRIGGER: trigger_update_queue_attachment_id
-- Table: email_attachments
-- ============================================
CREATE TRIGGER trigger_update_queue_attachment_id 
AFTER INSERT OR UPDATE OF attachment_name, email_id ON public.email_attachments 
FOR EACH ROW 
EXECUTE FUNCTION update_queue_attachment_id();

-- ============================================
-- TRIGGER: trigger_match_attachment_on_insert
-- Table: processing_queue
-- ============================================
CREATE TRIGGER trigger_match_attachment_on_insert 
BEFORE INSERT ON public.processing_queue 
FOR EACH ROW 
EXECUTE FUNCTION match_attachment_on_queue_insert();

-- ============================================
-- TRIGGER: trigger_notify_image
-- Table: processing_queue
-- ============================================
CREATE TRIGGER trigger_notify_image 
AFTER INSERT ON public.processing_queue 
FOR EACH ROW 
EXECUTE FUNCTION notify_n8n_image_queue();

-- ============================================
-- TRIGGER: trigger_notify_image_group_ready
-- Table: processing_queue
-- ============================================
CREATE TRIGGER trigger_notify_image_group_ready 
AFTER UPDATE ON public.processing_queue 
FOR EACH ROW 
WHEN ((((new.file_type)::text = 'image'::text) AND ((new.group_processing_status)::text = 'ready_for_group'::text) AND ((old.group_processing_status IS NULL) OR ((old.group_processing_status)::text <> 'ready_for_group'::text)))) 
EXECUTE FUNCTION notify_n8n_image_group_ready();

-- ============================================
-- TRIGGER: trigger_notify_text
-- Table: processing_queue
-- ============================================
CREATE TRIGGER trigger_notify_text 
AFTER INSERT ON public.processing_queue 
FOR EACH ROW 
EXECUTE FUNCTION notify_n8n_text_queue();

