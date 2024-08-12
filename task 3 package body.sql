CREATE OR REPLACE PACKAGE BODY XXBCM_DATA_MIGRATION_PKG
IS
    -- Global Variables
    gd_sysdate DATE := SYSDATE;
    -- Global Variables

    PROCEDURE XXBCM_ADD_SUPPLIER_ADDRESS
    IS
    BEGIN
        FOR supp_add IN (
            SELECT DISTINCT
                regexp_substr(adds,'[^,]+',1,1) AS add1,
                regexp_substr(adds,'[^,]+',1,2) AS add2,
                regexp_substr(adds,'[^,]+',1,3) AS add3,
                regexp_substr(adds,'[^,]+',1,4) AS add4,
                regexp_substr(adds,'[^,]+',1,5) AS add5
            FROM
            (
                SELECT regexp_substr(SUPP_ADDRESS,'[^,]+,[^,]+,[^,]+,[^,]+,[^,]+',1, LEVEL) adds 
                FROM XXBCM_ORDER_MGT
                CONNECT BY regexp_substr(SUPP_ADDRESS,'[^,]+,[^,]+,[^,]+,[^,]+,[^,]+',1, LEVEL) IS NOT NULL
            )
        )
        LOOP
            INSERT INTO XXBCM_SUPPLIER_ADDRESS (Address_line1,
                                                Address_line2,
                                                Address_line3,
                                                Address_line4,
                                                Address_line5) 
            VALUES (supp_add.add1,
                    supp_add.add2,
                    supp_add.add3,
                    supp_add.add4,
                    supp_add.add5);
        END LOOP;
        COMMIT;
    END XXBCM_ADD_SUPPLIER_ADDRESS;

    PROCEDURE XXBCM_ADD_SUPPLIER
    IS
    BEGIN
        FOR supp IN (
            SELECT DISTINCT SUPPLIER_NAME,
                            SUPP_CONTACT_NAME,
                            SUPP_EMAIL,
                            (SELECT address_id 
                             FROM XXBCM_SUPPLIER_ADDRESS a
                             WHERE REPLACE(x.SUPP_ADDRESS,', ',' ') = a.ADDRESS_LINE1||a.ADDRESS_LINE2||a.ADDRESS_LINE3||a.ADDRESS_LINE4||a.ADDRESS_LINE5) address_id
            FROM XXBCM_ORDER_MGT x
        )
        LOOP
            INSERT INTO XXBCM_SUPPLIERS (supplier_name,
                                          supplier_contact_name,
                                          supplier_email,
                                          supplier_address_id) 
            VALUES (supp.SUPPLIER_NAME,
                    supp.SUPP_CONTACT_NAME,
                    supp.SUPP_EMAIL,
                    supp.address_id);
        END LOOP;
        COMMIT;
    END XXBCM_ADD_SUPPLIER;

    PROCEDURE XXBCM_ADD_SUPPLIER_CONTACT
    IS
    BEGIN
        FOR supp_con IN (
            SELECT DISTINCT 
                   REPLACE(REPLACE(REPLACE(REPLACE(TRIM(REGEXP_SUBSTR(SUPP_CONTACT_NUMBER,'[^,]+',1,LEVEL)),'S','5'),'o','0'),'I','1'),'.','') CONTACT_NUMBER,
                   (SELECT supplier_id 
                    FROM XXBCM_SUPPLIERS 
                    WHERE SUPPLIER_NAME = x.SUPPLIER_NAME
                      AND supplier_contact_name = x.SUPP_CONTACT_NAME) supplier_id
            FROM XXBCM_ORDER_MGT x
            CONNECT BY REGEXP_SUBSTR(SUPP_CONTACT_NUMBER,'[^,]+',1,LEVEL) IS NOT NULL
        )
        LOOP
            INSERT INTO XXBCM_SUPPLIER_CONTACTS (supplier_id,
                                                 contact_number) 
            VALUES (supp_con.supplier_id,
                    supp_con.CONTACT_NUMBER);
        END LOOP;
        COMMIT;
    END XXBCM_ADD_SUPPLIER_CONTACT;

    PROCEDURE XXBCM_ADD_ORDER_HEADERS
    IS
    BEGIN
        FOR odr IN (
            SELECT DISTINCT 
                   ORDER_REF,
                   TO_DATE(ORDER_DATE,'DD-MM-YYYY') ORDER_DATE,
                   ORDER_DESCRIPTION,
                   TO_NUMBER(REPLACE(ORDER_TOTAL_AMOUNT,',','')) ORDER_TOTAL_AMOUNT,
                   ORDER_STATUS,
                   (SELECT supplier_id 
                    FROM XXBCM_SUPPLIERS s
                    WHERE s.supplier_name = x.SUPPLIER_NAME) supplier_id 
            FROM XXBCM_ORDER_MGT x
            WHERE ORDER_REF NOT LIKE '%-%'
            ORDER BY ORDER_REF
        )
        LOOP
            INSERT INTO XXBCM_ORDER_HEADERS (order_ref_number,
                                             order_date,
                                             order_desc,
                                             order_total_amount,
                                             order_status,
                                             supplier_id) 
            VALUES (odr.ORDER_REF,
                    odr.ORDER_DATE,
                    odr.ORDER_DESCRIPTION,
                    odr.ORDER_TOTAL_AMOUNT,
                    odr.ORDER_STATUS,
                    odr.supplier_id);
        END LOOP;
        COMMIT;
    END XXBCM_ADD_ORDER_HEADERS;

    PROCEDURE XXBCM_ADD_ORDER_LINES
    IS
    BEGIN
        FOR odrl IN (
            SELECT DISTINCT ORDER_REF,
                            (SELECT order_header_id 
                             FROM XXBCM_ORDER_HEADERS 
                             WHERE order_ref_number = SUBSTR(x.ORDER_REF,1,INSTR(x.ORDER_REF,'-',1)-1)) order_header_id,
                            ROW_NUMBER() OVER (PARTITION BY SUBSTR(ORDER_REF,1,INSTR(ORDER_REF,'-',1)-1) ORDER BY ORDER_REF) ln_num,
                            ORDER_DESCRIPTION,
                            REPLACE(REPLACE(REPLACE(REPLACE(ORDER_LINE_AMOUNT,',',''),'I','1'),'S','5'),'o','0') ORDER_LINE_AMOUNT,
                            ORDER_STATUS
            FROM XXBCM_ORDER_MGT x
            WHERE ORDER_REF LIKE '%-%'
            ORDER BY ORDER_REF
        )
        LOOP
            INSERT INTO XXBCM_ORDER_LINES (order_ref,
                                           order_header_id,
                                           order_line_num,
                                           order_line_desc,
                                           order_line_amount,
                                           order_line_status) 
            VALUES (odrl.ORDER_REF,
                    odrl.order_header_id,
                    odrl.ln_num,
                    odrl.ORDER_DESCRIPTION,
                    odrl.ORDER_LINE_AMOUNT,
                    odrl.ORDER_STATUS);
        END LOOP;
        COMMIT;
    END XXBCM_ADD_ORDER_LINES;

    PROCEDURE XXBCM_ADD_INVOICE_HOLDS
    IS
    BEGIN
        FOR inv_hold IN (
            SELECT DISTINCT INVOICE_HOLD_REASON 
            FROM XXBCM_ORDER_MGT 
            WHERE INVOICE_HOLD_REASON IS NOT NULL
        )
        LOOP
            INSERT INTO XXBCM_INVOICE_HOLDS (invoice_hold_reason) 
            VALUES (inv_hold.invoice_hold_reason);
        END LOOP;
        COMMIT;
    END XXBCM_ADD_INVOICE_HOLDS;

    PROCEDURE XXBCM_ADD_INVOICE_HEADERS
    IS
    BEGIN
        FOR invh IN (
            SELECT DISTINCT a.inv 
            FROM (
                SELECT INVOICE_REFERENCE,
                       SUBSTR(x.INVOICE_REFERENCE,1,INSTR(x.INVOICE_REFERENCE,'.',1)-1) INV
                FROM XXBCM_ORDER_MGT x
            ) a
            WHERE a.inv IS NOT NULL
            ORDER BY a.inv
        )
        LOOP
            INSERT INTO XXBCM_INVOICE_HEADERS (invoice_number) 
            VALUES (invh.inv);
        END LOOP;
        COMMIT;
    END XXBCM_ADD_INVOICE_HEADERS;

    PROCEDURE XXBCM_ADD_INVOICE_LINES
    IS
    BEGIN
        FOR invl IN (
            SELECT DISTINCT 
                   INVOICE_REFERENCE,
                   (SELECT invoice_header_id 
                    FROM XXBCM_INVOICE_HEADERS
                    WHERE invoice_number = SUBSTR(x.INVOICE_REFERENCE,1,INSTR(x.INVOICE_REFERENCE,'.',1)-1)) invoice_header_id,
                   ROW_NUMBER() OVER (PARTITION BY SUBSTR(INVOICE_REFERENCE,1,INSTR(INVOICE_REFERENCE,'.',1)-1) ORDER BY INVOICE_REFERENCE) inv_num,
                   odr.order_line_id,
                   TO_DATE(INVOICE_DATE,'DD-MM-YYYY') INVOICE_DATE,
                   INVOICE_DESCRIPTION,
                   REPLACE(REPLACE(REPLACE(REPLACE(INVOICE_AMOUNT,',',''),'I','1'),'S','5'),'o','0') INVOICE_AMOUNT,
                   INVOICE_STATUS,
                   (SELECT invoice_hold_id 
                    FROM XXBCM_INVOICE_HOLDS 
                    WHERE INVOICE_HOLD_REASON = x.INVOICE_HOLD_REASON) invoice_hold_id
            FROM XXBCM_ORDER_MGT x
            JOIN XXBCM_ORDER_LINES odr
              ON odr.order_ref = x.order_ref
             AND odr.order_line_desc = x.ORDER_DESCRIPTION
            WHERE INVOICE_REFERENCE LIKE '%.%'
            ORDER BY INVOICE_REFERENCE
        )
        LOOP
            INSERT INTO XXBCM_INVOICE_LINES (invoice_reference,
                                             invoice_header_id,
                                             invoice_number,
                                             order_line_id,
                                             invoice_date,
                                             invoice_desc,
                                             invoice_amount,
                                             invoice_status,
                                             invoice_hold_id) 
            VALUES (invl.INVOICE_REFERENCE,
                    invl.invoice_header_id,
                    invl.inv_num,
                    invl.order_line_id,
                    invl.INVOICE_DATE,
                    invl.INVOICE_DESCRIPTION,
                    invl.INVOICE_AMOUNT,
                    invl.INVOICE_STATUS,
                    invl.invoice_hold_id);
        END LOOP;
        COMMIT;
    END XXBCM_ADD_INVOICE_LINES;

END XXBCM_DATA_MIGRATION_PKG;
