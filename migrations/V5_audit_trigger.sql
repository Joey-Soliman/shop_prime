-- ============================================================
-- V5: AUTOMATED AUDITING — Price Change Audit Trigger
-- ============================================================

-- Step 1: Create the trigger function
CREATE OR REPLACE FUNCTION fn_audit_price_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.Price IS DISTINCT FROM NEW.Price THEN
        INSERT INTO Audit_Log (
            Table_Name,
            Column_Name,
            Old_Value,
            New_Value,
            Changed_At,
            Changed_By
        )
        VALUES (
            'Products',
            'Price',
            OLD.Price::TEXT,
            NEW.Price::TEXT,
            CURRENT_TIMESTAMP,
            CURRENT_USER
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 2: Attach the trigger to the Products table
CREATE TRIGGER trg_audit_price_change
    AFTER UPDATE OF Price
    ON Products
    FOR EACH ROW
    EXECUTE FUNCTION fn_audit_price_change();
