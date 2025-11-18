-- Set Schema for the Project
CREATE SCHEMA IF NOT EXISTS retail_hackathon;
SET search_path TO retail_hackathon;

-- 1. stores (Store Information) 
CREATE TABLE stores (
    store_id VARCHAR(10) PRIMARY KEY, 
    store_name VARCHAR(100),
    store_city VARCHAR(50),
    store_region VARCHAR(50),
    opening_date DATE
);

-- 2. products (Product Catalog) 
CREATE TABLE products (
    product_id VARCHAR(20) PRIMARY KEY,
    product_name VARCHAR(100),
    product_category VARCHAR(50),
    price DECIMAL(10, 2), -- Selling price per unit [cite: 51]
    current_stock_level INT
);

-- 4. promotion_details (Promotion Rules) 
CREATE TABLE promotion_details (
    promotion_id VARCHAR(10) PRIMARY KEY,
    promotion_name VARCHAR(100),
    start_date DATE,
    end_date DATE,
    discount_percentage DECIMAL(5, 2),
    applicable_category VARCHAR(50)
);

-- 5. loyalty_rules (Point Earning Logic) 
CREATE TABLE loyalty_rules (
    rule_id SERIAL PRIMARY KEY, -- Added PK for rules table
    per_unit_spend DECIMAL(5, 2), -- Points earned per monetary unit 
    spend_threshold DECIMAL(10, 2),
    bonus_points INT
);

-- 3. customer_details (Customer and Loyalty Data) 
CREATE TABLE customer_details (
    customer_id VARCHAR(20) PRIMARY KEY,
    first_name VARCHAR(50),
    email VARCHAR(100), 
    loyalty_status VARCHAR(20),
    total_loyalty_points INT DEFAULT 0,
    last_purchase_date DATE, 
    segment_id VARCHAR(10),
    customer_phone BIGINT,
    customer_since DATE,
    
    -- OPTION 2: CLV Potential Score columns 
    clv_potential_score DECIMAL(10, 2),
    aov_trajectory DECIMAL(10, 2),
    product_diversity_score DECIMAL(5, 2)
);

-- 6. store_sales_header (Transaction Header) 
CREATE TABLE store_sales_header (
    transaction_id VARCHAR(30) PRIMARY KEY,
    customer_id VARCHAR(20), -- relationship to customer_details 
    store_id VARCHAR(10), -- Relationship to stores 
    transaction_date TIMESTAMP, -- DATETIME 
    total_amount DECIMAL(10, 2), -- Used for Loyalty Calc 
    customer_phone BIGINT,
    
    CONSTRAINT fk_header_customer FOREIGN KEY (customer_id) REFERENCES customer_details(customer_id),
    CONSTRAINT fk_header_store FOREIGN KEY (store_id) REFERENCES stores(store_id)
);

-- 7. store_sales_line_items (Transaction Details) [cite: 60, 61]
CREATE TABLE store_sales_line_items (
    line_item_id INT,
    transaction_id VARCHAR(30), -- Relationship to store_sales_header 
    product_id VARCHAR(20), -- relationship to products 
    promotion_id VARCHAR(10), -- Relationship to promotion_details 
    quantity INT,
    line_item_amount DECIMAL(10, 2),
    
    PRIMARY KEY (transaction_id, line_item_id),
    
    CONSTRAINT fk_line_transaction FOREIGN KEY (transaction_id) REFERENCES store_sales_header(transaction_id),
    CONSTRAINT fk_line_product FOREIGN KEY (product_id) REFERENCES products(product_id),
    CONSTRAINT fk_line_promotion FOREIGN KEY (promotion_id) REFERENCES promotion_details(promotion_id)
);

-- Data Quality Table: Segregate bad data (reject records) 
CREATE TABLE rejected_sales_header (
    original_transaction_id VARCHAR(30),
    rejection_reason VARCHAR(255),
    original_data JSONB 
);

-- OPTION 1: new_customer (Unidentified Customer Spends) 
CREATE TABLE new_customer (
    tracking_id SERIAL PRIMARY KEY,
    customer_phone BIGINT NOT NULL,
    source_transaction_id VARCHAR(30),
    total_spend DECIMAL(10, 2),
    first_seen_date DATE NOT NULL,
    last_seen_date DATE,
    transaction_count INT DEFAULT 1,
    predicted_segment VARCHAR(20),
    acquisition_channel VARCHAR(50),
    
    CONSTRAINT uq_phone UNIQUE (customer_phone), 
    CONSTRAINT fk_new_cust_trans FOREIGN KEY (source_transaction_id) REFERENCES store_sales_header(transaction_id)
);
COMMENT ON TABLE new_customer IS 'Temporary entity to track unidentified customers via phone number for future loyalty onboarding.'; [cite: 25]
COMMENT ON COLUMN new_customer.customer_phone IS 'Primary identifier extracted from sales header for non-loyalty transactions.'; [cite: 26]