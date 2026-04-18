-- V6: Stored Procedure — place_order

CREATE OR REPLACE PROCEDURE place_order(
    p_customer_id     INT,
    p_address_id      INT,
    p_payment_id      INT,
    p_items           JSONB  -- [{"product_id": 1, "quantity": 2}, ...]
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id        INT;
    v_total           NUMERIC(12,2) := 0;
    v_item            JSONB;
    v_product_id      INT;
    v_quantity        INT;
    v_price           NUMERIC(12,2);
    v_stock           INT;
    v_item_total      NUMERIC(12,2);
BEGIN

    -- 1. REFERENTIAL INTEGRITY — validate customer, address, payment
    IF NOT EXISTS (SELECT 1 FROM customers WHERE customer_id = p_customer_id) THEN
        RAISE EXCEPTION 'Invalid Entity Reference: customer_id % does not exist.', p_customer_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM addresses WHERE address_id = p_address_id AND customer_id = p_customer_id) THEN
        RAISE EXCEPTION 'Invalid Entity Reference: address_id % does not exist for this customer.', p_address_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM payment_methods WHERE payment_id = p_payment_id AND customer_id = p_customer_id) THEN
        RAISE EXCEPTION 'Invalid Entity Reference: payment_id % does not exist for this customer.', p_payment_id;
    END IF;

    -- 2. CREATE ORDER HEADER (pending — total filled in later)
    INSERT INTO orders (
        customer_id,
        shipping_address_id,
        payment_method_id,
        order_status,
        total_amount
    )
    VALUES (
        p_customer_id,
        p_address_id,
        p_payment_id,
        'pending',
        0  -- temporary; updated after items are validated
    )
    RETURNING order_id INTO v_order_id;

    -- 3. LOOP OVER ITEMS
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_product_id := (v_item->>'product_id')::INT;
        v_quantity   := (v_item->>'quantity')::INT;

        -- Basic quantity sanity check
        IF v_quantity <= 0 THEN
            RAISE EXCEPTION 'Invalid quantity % for product_id %.', v_quantity, v_product_id;
        END IF;

        -- CONCURRENCY LOCKING — lock the product row before reading stock
        -- FOR UPDATE prevents two simultaneous checkouts racing on the same row
        SELECT price, stock_quantity
        INTO   v_price, v_stock
        FROM   products
        WHERE  product_id = v_product_id
        FOR UPDATE;

        -- Product existence check
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Invalid Entity Reference: product_id % does not exist.', v_product_id;
        END IF;

        -- INVENTORY EXHAUSTION check
        IF v_stock < v_quantity THEN
            RAISE EXCEPTION 'Insufficient Stock: product_id % has % units available, % requested.',
                v_product_id, v_stock, v_quantity;
        END IF;

        -- PRICE INTEGRITY — use price from DB, never from caller
        v_item_total := v_price * v_quantity;
        v_total      := v_total + v_item_total;

        -- Insert order item
        INSERT INTO order_items (
            order_id,
            product_id,
            quantity,
            price_at_purchase
        )
        VALUES (
            v_order_id,
            v_product_id,
            v_quantity,
            v_price
        );

        -- Decrement stock
        UPDATE products
        SET    stock_quantity = stock_quantity - v_quantity
        WHERE  product_id = v_product_id;

    END LOOP;

    -- 4. FINALISE ORDER — write the real total
    UPDATE orders
    SET    total_amount = v_total,
           order_status = 'paid'
    WHERE  order_id = v_order_id;

    RAISE NOTICE 'Order % placed successfully. Total: $%.', v_order_id, v_total;

END;
$$;