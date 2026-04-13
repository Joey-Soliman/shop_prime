-- ============================================================
-- V4: Add Vendor_Monthly_Rollup materialized view
-- ============================================================

CREATE MATERIALIZED VIEW Vendor_Monthly_Rollup AS
SELECT
    s.Supplier_ID                            AS Vendor_ID,
    TO_CHAR(o.Order_Date, 'YYYY-MM')         AS Month_Year,
    SUM(oi.Price_At_Purchase * oi.Quantity)   AS Total_Revenue,
    SUM(oi.Quantity)                          AS Total_Units_Sold
FROM
    Order_Items  oi
    JOIN Products p  ON oi.Product_ID  = p.Product_ID
    JOIN Suppliers s ON p.Supplier_ID  = s.Supplier_ID
    JOIN Orders   o  ON oi.Order_ID    = o.Order_ID
WHERE
    o.Order_Status NOT IN ('Cancelled', 'Returned')
GROUP BY
    s.Supplier_ID,
    TO_CHAR(o.Order_Date, 'YYYY-MM')
ORDER BY
    s.Supplier_ID,
    Month_Year;

-- Unique index for CONCURRENTLY refresh support
CREATE UNIQUE INDEX idx_vendor_rollup_pk
    ON Vendor_Monthly_Rollup (Vendor_ID, Month_Year);

-- Grant read access to roles
GRANT SELECT ON Vendor_Monthly_Rollup TO vendor_role;
GRANT SELECT ON Vendor_Monthly_Rollup TO audit_role;
