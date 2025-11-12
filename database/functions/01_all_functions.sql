-- CargoFlow Database Functions
-- All Functions CREATE Statements
-- Generated: November 12, 2025

-- ============================================
-- FUNCTION: generate_microinvest_csv_for_email
-- ============================================
CREATE OR REPLACE FUNCTION public.generate_microinvest_csv_for_email(p_email_id integer)
 RETURNS TABLE(csv_line text, line_type character varying, inv_id integer, inv_number character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    invoice_rec RECORD;
    vat_type_code VARCHAR(100);
    supplier_account VARCHAR(20);
    expense_account VARCHAR(20) := '602/4';  -- ← HARDCODED: Консултантски услуги
BEGIN
    FOR invoice_rec IN 
        SELECT 
            ib.id as rec_id,
            ib.invoice_number as rec_invoice_number,
            ib.supplier_name,
            ib.supplier_id_number,
            ib.supplier_vat,
            ib.iban,
            ib.issue_date,
            ib.tax_event_date,
            ib.subtotal,
            ib.tax_amount,
            ib.tax_rate,
            ib.original_link,
            (SELECT description FROM invoice_items WHERE invoice_id = ib.id ORDER BY line_number LIMIT 1) as first_item_desc
        FROM invoice_base ib
        WHERE ib.email_id = p_email_id
        ORDER BY ib.invoice_number
    LOOP
        -- Определи сметка на доставчик
        IF invoice_rec.supplier_vat LIKE 'BG%' THEN
            supplier_account := '401/1';
        ELSE
            supplier_account := '401/2';
        END IF;
        
        -- Определи вид сделка
        IF invoice_rec.supplier_vat LIKE 'BG%' AND invoice_rec.tax_rate = 20 THEN
            vat_type_code := '2 - Получени доставки, ВОП с право на ПДК';
        ELSIF invoice_rec.supplier_vat LIKE 'BG%' AND (invoice_rec.tax_rate = 0 OR invoice_rec.tax_rate IS NULL) THEN
            vat_type_code := '3 - Получени доставки по чл.82 и без право на ДК';
        ELSIF NOT invoice_rec.supplier_vat LIKE 'BG%' AND invoice_rec.tax_rate > 0 THEN
            vat_type_code := '8 - Вътреобщностни придобивания';
        ELSE
            vat_type_code := '1 - Вътрешен оборот';
        END IF;
        
        -- РЕД 1: Разход (602/4-401/x)
        csv_line := 
            COALESCE(invoice_rec.subtotal::TEXT, '') || ';' ||
            expense_account || '-' || supplier_account || ';' ||  -- ← 602/4-401/1 или 602/4-401/2
            COALESCE(TO_CHAR(invoice_rec.issue_date, 'YYYY-MM-DD'), '') || ';' ||
            COALESCE(invoice_rec.supplier_name, '') || ';' ||
            COALESCE(invoice_rec.supplier_id_number, '') || ';' ||
            COALESCE(invoice_rec.supplier_vat, '') || ';' ||
            COALESCE(invoice_rec.iban, '') || ';' ||
            COALESCE(invoice_rec.rec_invoice_number, '') || ';' ||
            'Ф-ра' || ';' ||
            COALESCE(TO_CHAR(invoice_rec.issue_date, 'YYYY-MM-DD'), '') || ';' ||
            COALESCE(LEFT(invoice_rec.first_item_desc, 100), '') || ';' ||
            'Фактура ' || COALESCE(invoice_rec.rec_invoice_number, '') || ';' ||
            COALESCE(invoice_rec.original_link, '') || ';' ||
            vat_type_code || ';' ||
            '1' || ';' ||
            COALESCE(TO_CHAR(invoice_rec.tax_event_date, 'YYYY-MM-DD'), '') || ';' ||
            ';;;;;;;;;';
        
        line_type := 'expense';
        inv_id := invoice_rec.rec_id;
        inv_number := invoice_rec.rec_invoice_number;
        
        RETURN NEXT;
        
        -- РЕД 2: ДДС (453/1-401/x)
        IF invoice_rec.tax_amount > 0 THEN
            csv_line := 
                COALESCE(invoice_rec.tax_amount::TEXT, '') || ';' ||
                '453/1-' || supplier_account || ';' ||
                COALESCE(TO_CHAR(invoice_rec.issue_date, 'YYYY-MM-DD'), '') || ';' ||
                COALESCE(invoice_rec.supplier_name, '') || ';' ||
                COALESCE(invoice_rec.supplier_id_number, '') || ';' ||
                COALESCE(invoice_rec.supplier_vat, '') || ';' ||
                COALESCE(invoice_rec.iban, '') || ';' ||
                COALESCE(invoice_rec.rec_invoice_number, '') || ';' ||
                'Ф-ра' || ';' ||
                COALESCE(TO_CHAR(invoice_rec.issue_date, 'YYYY-MM-DD'), '') || ';' ||
                'ДДС по фактура ' || COALESCE(invoice_rec.rec_invoice_number, '') || ';' ||
                ';;' ||
                vat_type_code || ';' ||
                '1' || ';' ||
                COALESCE(TO_CHAR(invoice_rec.tax_event_date, 'YYYY-MM-DD'), '') || ';' ||
                ';;;;;;;;2;' ||
                COALESCE(TO_CHAR(invoice_rec.tax_event_date, 'YYYY-MM-DD'), '') || ';';
            
            line_type := 'vat';
            inv_id := invoice_rec.rec_id;
            inv_number := invoice_rec.rec_invoice_number;
            
            RETURN NEXT;
        END IF;
        
    END LOOP;
    
    RETURN;
END;
$function$;

-- ============================================
-- FUNCTION: get_contracts_by_email
-- ============================================
CREATE OR REPLACE FUNCTION public.get_contracts_by_email(p_email_id integer)
 RETURNS TABLE(contract_number character varying, folder_path text, detected_in text[], status character varying, document_count bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        c.contract_number,
        c.folder_path,
        c.detected_in,
        c.status,
        COUNT(cd.id) as document_count
    FROM contracts c
    LEFT JOIN contract_documents cd ON cd.id = c.id
    WHERE c.email_id = p_email_id
    GROUP BY c.id, c.contract_number, c.folder_path, c.detected_in, c.status;
END;
$function$;

-- ============================================
-- FUNCTION: get_invoice_json
-- ============================================
CREATE OR REPLACE FUNCTION public.get_invoice_json(p_invoice_id integer)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'general_data', jsonb_build_object(
            'Получател', ib.customer_name,
            'ДДС получател', ib.customer_vat,
            'Доставчик', ib.supplier_name,
            'ДДС издател', ib.supplier_vat,
            'IBAN', ib.iban,
            'ИН', ib.supplier_id_number,
            'дата на падеж', TO_CHAR(ib.due_date, 'DD.MM.YYYY'),
            'начин на плащане', ib.payment_method,
            'Дата на данъчно събитие', TO_CHAR(ib.tax_event_date, 'DD.MM.YYYY'),
            'Дата на издаване', TO_CHAR(ib.issue_date, 'DD.MM.YYYY'),
            'Фактура номер', ib.invoice_number,
            'Сума без ДДС', ib.subtotal,
            'ДДС', ib.tax_amount,
            'Сума за плащане', ib.total_amount,
            'валута', ib.currency,
            'име на файл', SUBSTRING(ib.original_file_path FROM '[^/\\\\]+$'),
            'дата на създаване на файл', TO_CHAR(ib.created_at, 'DD.MM.YYYY HH24:MI'),
            'Линк към оригинал', ib.original_link
        ),
        'line_items', COALESCE((
            SELECT jsonb_agg(line_item ORDER BY line_number)
            FROM (
                SELECT 
                    ii.line_number,
                    jsonb_build_object(
                        'Доставчик', ib.supplier_name,
                        'Дата на издаване', TO_CHAR(ib.issue_date, 'DD.MM.YYYY'),
                        'Фактура номер', ib.invoice_number,
                        '№ ред', ii.line_number,
                        'Парт №', ii.product_code,
                        'стоки и услуги', ii.description,
                        'мярка', ii.unit,
                        'количество', ii.quantity,
                        'ед.цена', ii.unit_price,
                        'общо за реда', ii.line_total,
                        'ддс за реда', ii.tax_amount,
                        'валута', ib.currency,
                        'име на файл', SUBSTRING(ib.original_file_path FROM '[^/\\\\]+$'),
                        'дата на създаване на файл', TO_CHAR(ib.created_at, 'DD.MM.YYYY HH24:MI'),
                        'Линк към оригинал', ib.original_link
                    ) as line_item
                FROM invoice_items ii
                WHERE ii.invoice_id = ib.id
            ) sorted_items
        ), '[]'::jsonb)
    ) INTO result
    FROM invoice_base ib
    WHERE ib.id = p_invoice_id;
    
    RETURN result;
END;
$function$;

-- ============================================
-- FUNCTION: get_pending_contract_detections
-- ============================================
CREATE OR REPLACE FUNCTION public.get_pending_contract_detections(p_limit integer DEFAULT 10)
 RETURNS TABLE(queue_id integer, email_id integer, attachment_id integer, sender_email text, subject text, attachment_name text, document_category text)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        cdq.id as queue_id,
        cdq.email_id,
        cdq.attachment_id,
        e.sender_email,
        e.subject,
        ea.attachment_name,
        ea.document_category
    FROM contract_detection_queue cdq
    JOIN emails e ON e.id = cdq.email_id
    JOIN email_attachments ea ON ea.id = cdq.attachment_id
    WHERE cdq.status = 'pending'
    ORDER BY cdq.queued_at ASC
    LIMIT p_limit;
END;
$function$;

-- ============================================
-- FUNCTION: mark_detection_completed
-- ============================================
CREATE OR REPLACE FUNCTION public.mark_detection_completed(p_queue_id integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE contract_detection_queue
    SET status = 'completed',
        processed_at = CURRENT_TIMESTAMP
    WHERE id = p_queue_id;
END;
$function$;

-- ============================================
-- FUNCTION: mark_detection_error
-- ============================================
CREATE OR REPLACE FUNCTION public.mark_detection_error(p_queue_id integer, p_error_message text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE contract_detection_queue
    SET status = 'error',
        processed_at = CURRENT_TIMESTAMP,
        error_message = p_error_message
    WHERE id = p_queue_id;
END;
$function$;

-- ============================================
-- FUNCTION: match_attachment_on_queue_insert
-- ============================================
CREATE OR REPLACE FUNCTION public.match_attachment_on_queue_insert()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    matched_attachment_id INTEGER;
    clean_filename TEXT;
    attachment_base TEXT;
BEGIN
    -- Извлечи името на файла от пътя
    clean_filename := substring(NEW.file_path from '[^\\\\\\/]+$');
    
    -- Премахни _extracted.txt или _extracted.png
    clean_filename := regexp_replace(clean_filename, '_extracted\\.(txt|png)$', '', 'i');
    
    -- Премахни САМО известни extensions (.txt, .png, .pdf, .docx, etc.)
    clean_filename := regexp_replace(clean_filename, '\\.(txt|png|pdf|docx|xlsx|doc|xls|msg)$', '', 'i');
    
    -- Търси match в email_attachments
    SELECT ea.id INTO matched_attachment_id
    FROM email_attachments ea
    WHERE ea.email_id = NEW.email_id
    AND regexp_replace(ea.attachment_name, '\\.(txt|png|pdf|docx|xlsx|doc|xls|msg)$', '', 'i') = clean_filename
    LIMIT 1;
    
    IF matched_attachment_id IS NOT NULL THEN
        NEW.attachment_id := matched_attachment_id;
    END IF;
    
    RETURN NEW;
END;
$function$;

-- ============================================
-- FUNCTION: notify_n8n_image_group_ready
-- ============================================
CREATE OR REPLACE FUNCTION public.notify_n8n_image_group_ready()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    total_pages_count INTEGER;
    ready_pages_count INTEGER;
BEGIN
    -- Изпращаме нотификация само когато group_processing_status стане 'ready_for_group'
    IF NEW.file_type = 'image' 
       AND NEW.group_processing_status = 'ready_for_group'
       AND (OLD.group_processing_status IS NULL OR OLD.group_processing_status != 'ready_for_group') THEN
        
        -- Проверка дали ВСИЧКИ страници са готови
        SELECT 
            COUNT(DISTINCT (file_metadata->>'page_number')::int),
            COUNT(DISTINCT CASE WHEN group_processing_status = 'ready_for_group' THEN (file_metadata->>'page_number')::int END)
        INTO total_pages_count, ready_pages_count
        FROM processing_queue
        WHERE original_document = NEW.original_document
        AND file_type = 'image'
        AND file_metadata IS NOT NULL;
        
        -- Изпращаме нотификация само ако ВСИЧКИ страници са готови
        -- И само веднъж (използвайки проверка дали вече е изпратена)
        IF total_pages_count > 0 
           AND ready_pages_count = total_pages_count
           AND NOT EXISTS (
               SELECT 1 FROM processing_queue 
               WHERE original_document = NEW.original_document 
               AND file_type = 'image'
               AND group_processing_status = 'ready_for_group'
               AND id < NEW.id
           ) THEN
            
            PERFORM pg_notify(
                'n8n_channel_contract_image',
                json_build_object(
                    'original_document', NEW.original_document,
                    'attachment_id', NEW.attachment_id,
                    'email_id', NEW.email_id,
                    'total_pages', total_pages_count
                )::text
            );
            
            RAISE NOTICE 'Notified n8n for image group ready: original_document=%, attachment_id=%, total_pages=%', 
                NEW.original_document, NEW.attachment_id, total_pages_count;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$function$;

-- ============================================
-- FUNCTION: notify_n8n_image_queue
-- ============================================
CREATE OR REPLACE FUNCTION public.notify_n8n_image_queue()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NEW.file_type = 'image' THEN
        PERFORM pg_notify(
            'n8n_channel_contract_image',
            row_to_json(NEW)::text
        );
    END IF;
    RETURN NEW;
END;
$function$;

-- ============================================
-- FUNCTION: notify_n8n_text_queue
-- ============================================
CREATE OR REPLACE FUNCTION public.notify_n8n_text_queue()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NEW.file_type = 'text' THEN
        PERFORM pg_notify(
            'n8n_channel_contract_text',
            row_to_json(NEW)::text
        );
    END IF;
    RETURN NEW;
END;
$function$;

-- ============================================
-- FUNCTION: process_email_contracts
-- ============================================
CREATE OR REPLACE FUNCTION public.process_email_contracts()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_email_id INTEGER;
    v_contract_numbers TEXT[];
    v_folder_name TEXT;
    v_folder_path TEXT;
    v_base_path TEXT := 'C:\Users\Delta\Cargo Flow\Site de communication - Documents\Документи по договори\';
    v_email_subject TEXT;
    v_unique_contracts TEXT[];
    v_contract_num TEXT;
    v_email_data RECORD;
BEGIN
    -- Вземаме email_id от attachment
    v_email_id := NEW.email_id;
    
    -- Проверяваме дали всички attachments на този мейл са обработени
    IF NOT EXISTS (
        SELECT 1 FROM email_attachments ea
        WHERE ea.email_id = v_email_id 
        AND (ea.processing_status IS NULL OR ea.processing_status != 'completed')
    ) THEN
        
        -- Вземаме данни за мейла
        SELECT id, subject, sender_email, attachment_folder
        INTO v_email_data
        FROM emails 
        WHERE id = v_email_id;
        
        -- Вземаме всички уникални contract numbers за този мейл
        SELECT ARRAY_AGG(DISTINCT dp.contract_number)
        INTO v_unique_contracts
        FROM document_pages dp
        JOIN email_attachments ea ON dp.attachment_id = ea.id
        WHERE ea.email_id = v_email_id 
        AND dp.contract_number IS NOT NULL 
        AND dp.contract_number != '';
        
        -- Формираме име на папката
        IF array_length(v_unique_contracts, 1) > 0 THEN
            v_folder_name := array_to_string(v_unique_contracts, '_');
        ELSE
            v_folder_name := 'NoContract_' || COALESCE(
                LEFT(REGEXP_REPLACE(v_email_data.subject, '[^a-zA-Z0-9]', '_', 'g'), 50), 
                'Unknown'
            );
        END IF;
        
        -- Обновяваме emails таблицата
        UPDATE emails 
        SET contract_folder_name = v_folder_name
        WHERE id = v_email_id;
        
        -- Записваме всеки договор в contracts таблицата
        IF array_length(v_unique_contracts, 1) > 0 THEN
            FOREACH v_contract_num IN ARRAY v_unique_contracts
            LOOP
                IF NOT EXISTS (
                    SELECT 1 FROM contracts 
                    WHERE contract_number = v_contract_num
                ) THEN
                    INSERT INTO contracts (
                        contract_number,
                        email_id,
                        folder_path,
                        detected_in,
                        detected_at,
                        status
                    ) VALUES (
                        v_contract_num,
                        v_email_id,
                        v_base_path || v_folder_name,
                        ARRAY['email_processing'],
                        NOW(),
                        'detected'
                    );
                END IF;
            END LOOP;
        END IF;
        
        -- Изпращаме уведомление на n8n за създаване на папката
        PERFORM pg_notify(
            'email_contract_ready',
            json_build_object(
                'email_id', v_email_id,
                'folder_name', v_folder_name,
                'folder_path', v_base_path || v_folder_name,
                'contract_numbers', v_unique_contracts,
                'subject', v_email_data.subject,
                'sender_email', v_email_data.sender_email,
                'attachment_folder', v_email_data.attachment_folder
            )::text
        );
        
        RAISE NOTICE 'Email % processed: folder_name=%, contracts=%', 
            v_email_id, v_folder_name, v_unique_contracts;
    END IF;
    
    RETURN NEW;
END;
$function$;

-- ============================================
-- FUNCTION: queue_contract_detection
-- ============================================
CREATE OR REPLACE FUNCTION public.queue_contract_detection()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Проверка дали attachment-а вече е в опашката
    IF NOT EXISTS (
        SELECT 1 FROM contract_detection_queue
        WHERE attachment_id = NEW.id
        AND status IN ('pending', 'processing')
    ) THEN
        -- Добавяме в опашката
        INSERT INTO contract_detection_queue (email_id, attachment_id)
        VALUES (NEW.email_id, NEW.id);
        
        RAISE NOTICE 'Queued attachment % (category: %) for contract detection', NEW.id, NEW.document_category;
    END IF;
    
    RETURN NEW;
END;
$function$;

-- ============================================
-- FUNCTION: queue_email_for_folder_update
-- ============================================
CREATE OR REPLACE FUNCTION public.queue_email_for_folder_update()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NEW.processing_status = 'completed' AND 
       (OLD.processing_status IS NULL OR OLD.processing_status != 'completed') THEN
        
        INSERT INTO email_ready_queue (email_id) 
        VALUES (NEW.email_id)
        ON CONFLICT (email_id) DO NOTHING;
        
    END IF;
    RETURN NEW;
END;
$function$;

-- ============================================
-- FUNCTION: update_queue_attachment_id
-- ============================================
CREATE OR REPLACE FUNCTION public.update_queue_attachment_id()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    queue_record RECORD;
    matched_count INTEGER := 0;
BEGIN
    FOR queue_record IN 
        SELECT id, file_path
        FROM processing_queue
        WHERE email_id = NEW.email_id
        AND attachment_id IS NULL
    LOOP
        IF queue_record.file_path ILIKE '%' || 
           regexp_replace(NEW.attachment_name, '\.[^.]*$', '') || '%' THEN
            
            UPDATE processing_queue
            SET attachment_id = NEW.id
            WHERE id = queue_record.id;
            
            matched_count := matched_count + 1;
        END IF;
    END LOOP;
    
    RETURN NEW;
END;
$function$;

