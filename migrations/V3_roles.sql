-- Create Roles
CREATE ROLE customer_role;
CREATE ROLE vendor_role;
CREATE ROLE audit_role;

REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;

-- Admin 
GRANT SELECT ON audit_log TO audit_role;
REVOKE INSERT, UPDATE, DELETE ON audit_log FROM audit_role;

-- Customer
GRANT SELECT ON customers TO customer_role;
GRANT SELECT ON orders TO customer_role;
GRANT SELECT ON order_items TO customer_role;

-- Vendor
GRANT SELECT ON products TO vendor_role;
GRANT UPDATE (price, stock_quantity) ON products TO vendor_role;


-- Enable RLS
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Customer Policies
CREATE POLICY customer_select_own_orders
ON orders
FOR SELECT
TO customer_role
USING (
    customer_id = current_setting('app.current_customer_id')::INT
);

CREATE POLICY customer_select_own_order_items
ON order_items
FOR SELECT
TO customer_role
USING (
    order_id IN (
        SELECT order_id
        FROM orders
        WHERE customer_id = current_setting('app.current_customer_id')::INT
    )
);
-- Vendor Policy
CREATE POLICY vendor_select_own_products
ON products
FOR SELECT
TO vendor_role
USING (
    supplier_id = current_setting('app.current_supplier_id')::INT
);

CREATE POLICY vendor_update_own_products
ON products
FOR UPDATE
TO vendor_role
USING (
    supplier_id = current_setting('app.current_supplier_id')::INT
)
WITH CHECK (
    supplier_id = current_setting('app.current_supplier_id')::INT
);