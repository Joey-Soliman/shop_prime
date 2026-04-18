-- Prevent future-dated orders
ALTER TABLE orders
ADD CONSTRAINT chk_orders_not_future
CHECK (order_date <= NOW());

-- Email format
ALTER TABLE customers
ADD CONSTRAINT chk_customers_email_format
CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+.[A-Za-z]{2,}$');

-- Zip code format
ALTER TABLE addresses
ADD CONSTRAINT chk_addresses_zip_format
CHECK (zip_code ~ '^[0-9]{5}(-[0-9]{4})?$');

-- Restrict allowed values
ALTER TABLE orders
ADD CONSTRAINT chk_orders_status
CHECK (order_status IN ('pending', 'paid', 'shipped', 'delivered', 'cancelled'));

ALTER TABLE addresses
ADD CONSTRAINT chk_addresses_type
CHECK (address_type IN ('home', 'work', 'shipping', 'billing'));

-- Ensure no zero or negative values
ALTER TABLE orders
ADD CONSTRAINT chk_orders_total_positive
CHECK (total_amount > 0);

ALTER TABLE order_items
ADD CONSTRAINT chk_order_items_price_positive
CHECK (price_at_purchase > 0);

ALTER TABLE products
ADD CONSTRAINT chk_products_price_positive
CHECK (price > 0);