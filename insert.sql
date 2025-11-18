SET search_path TO retail_hackathon;

-- Load 1. stores data
COPY stores (store_id, store_name, store_city, store_region, opening_date)
FROM 'C:\path\to\stores_normalized.csv'  
DELIMITER ','
CSV HEADER;

-- Load 2. products data
COPY products (product_id, product_name, product_category, price, current_stock_level)
FROM 'C:\path\to\products_normalized.csv' 
DELIMITER ','
CSV HEADER;

-- Load initial loyalty rule (e.g., 0.10 points per 1 unit spent, or 1 point per 10 spent, assuming per_unit_spend is 0.10)
INSERT INTO loyalty_rules (per_unit_spend, spend_threshold, bonus_points)
VALUES (0.10, 10.00, 0);

-- Load 3. customer_details data (Handles potential NULL values for loyalty-specific columns)
COPY customer_details (customer_id, first_name, email, loyalty_status, total_loyalty_points, last_purchase_date, segment_id, customer_phone, customer_since)
FROM 'C:\path\to\customer_details_normalized.csv' 
DELIMITER ','
CSV HEADER NULL ''; 

-- Load 4. store_sales_header data
COPY store_sales_header (transaction_id, customer_id, store_id, transaction_date, total_amount, customer_phone)
FROM 'C:\path\to\store_sales_header_normalized.csv' 
DELIMITER ','
CSV HEADER NULL ''; 

-- Load 5. store_sales_line_items data
COPY store_sales_line_items (line_item_id, transaction_id, product_id, promotion_id, quantity, line_item_amount)
FROM 'C:\path\to\store_sales_line_items_normalized.csv' 
DELIMITER ','
CSV HEADER NULL '';