-- Supplier Address Table
CREATE TABLE XXBCM_SUPPLIER_ADDRESS (
    address_id NUMBER GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) PRIMARY KEY,
    address_line1 VARCHAR2(200),
    address_line2 VARCHAR2(200),
    address_line3 VARCHAR2(200),
    address_line4 VARCHAR2(200),
    address_line5 VARCHAR2(200)
);

-- Suppliers Table
CREATE TABLE XXBCM_SUPPLIERS (
    supplier_id NUMBER GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) PRIMARY KEY,
    supplier_name VARCHAR2(200),
    supplier_contact_name VARCHAR2(200),
    supplier_address_id NUMBER,
    supplier_email VARCHAR2(200),
    CONSTRAINT XXBCM_fk_address_id FOREIGN KEY (supplier_address_id) REFERENCES XXBCM_SUPPLIER_ADDRESS(address_id)
);

-- Supplier Contacts Table
CREATE TABLE XXBCM_SUPPLIER_CONTACTS (
    contact_id NUMBER GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) PRIMARY KEY,
    supplier_id NUMBER,
    contact_number VARCHAR2(200),
    CONSTRAINT XXBCM_fk_con_supplier_id FOREIGN KEY (supplier_id) REFERENCES XXBCM_SUPPLIERS(supplier_id)
);

-- Order Headers Table
CREATE TABLE XXBCM_ORDER_HEADERS (
    order_header_id NUMBER GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) PRIMARY KEY,
    order_ref_number VARCHAR2(100),
    order_date DATE,
    order_desc VARCHAR2(500),
    order_total_amount NUMBER(15, 2),
    order_status VARCHAR2(100),
    supplier_id NUMBER,
    CONSTRAINT XXBCM_fk_supplier_id FOREIGN KEY (supplier_id) REFERENCES XXBCM_SUPPLIERS(supplier_id)
);

-- Order Lines Table
CREATE TABLE XXBCM_ORDER_LINES (
    order_ref VARCHAR2(100),
    order_header_id NUMBER,
    order_line_id NUMBER GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) PRIMARY KEY,
    order_line_num VARCHAR2(100),
    order_line_desc VARCHAR2(500),
    order_line_amount NUMBER(15, 2),
    order_line_status VARCHAR2(100),
    CONSTRAINT XXBCM_fk_order_header_id FOREIGN KEY (order_header_id) REFERENCES XXBCM_ORDER_HEADERS(order_header_id)
);

-- Invoice Headers Table
CREATE TABLE XXBCM_INVOICE_HEADERS (
    invoice_header_id NUMBER GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) PRIMARY KEY,
    invoice_number VARCHAR2(100)
);

-- Invoice Lines Table
CREATE TABLE XXBCM_INVOICE_LINES (
    invoice_header_id NUMBER,
    invoice_line_id NUMBER GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) PRIMARY KEY,
    invoice_number NUMBER,
    invoice_reference VARCHAR2(100),
    order_line_id NUMBER,
    invoice_date DATE,
    invoice_desc VARCHAR2(500),
    invoice_amount NUMBER(15, 2),
    invoice_status VARCHAR2(100),
    invoice_hold_id NUMBER,
    CONSTRAINT XXBCM_fk_invoice_header_id FOREIGN KEY (invoice_header_id) REFERENCES XXBCM_INVOICE_HEADERS(invoice_header_id),
    CONSTRAINT XXBCM_fk_order_line_id FOREIGN KEY (order_line_id) REFERENCES XXBCM_ORDER_LINES(order_line_id),
    CONSTRAINT XXBCM_fk_invoice_hold_id FOREIGN KEY (invoice_hold_id) REFERENCES XXBCM_INVOICE_HOLDS(invoice_hold_id)
);

-- Invoice Holds Table
CREATE TABLE XXBCM_INVOICE_HOLDS (
    invoice_hold_id NUMBER GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) PRIMARY KEY,
    invoice_hold_reason VARCHAR2(200)
);
