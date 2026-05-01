import random
import psycopg2

DB_URL = "postgresql://neondb_owner:npg_nQRbXU4Hd5eK@ep-odd-night-ak0etruv-pooler.c-3.us-west-2.aws.neon.tech/neondb?sslmode=require&channel_binding=require"

NUM_CUSTOMERS = 200
NUM_SUPPLIERS = 20
NUM_CATEGORIES = 20
NUM_PRODUCTS = 1000
NUM_ORDERS = 10000

def get_count(cur, table):
    cur.execute(f"SELECT COUNT(*) FROM {table}")
    return cur.fetchone()[0]

def main():
    conn = psycopg2.connect(DB_URL)
    conn.autocommit = False
    cur = conn.cursor()

    created_orders = 0
    skipped_orders = 0

    try:
        existing_customers = get_count(cur, "customers")
        for i in range(existing_customers + 1, NUM_CUSTOMERS + 1):
            cur.execute("""
                INSERT INTO customers (first_name, last_name, email, phone, created_at)
                VALUES (%s, %s, %s, %s, NOW())
            """, (
                f"First{i}",
                f"Last{i}",
                f"user{i}@example.com",
                f"555-{1000+i}"
            ))

        cur.execute("SELECT customer_id FROM customers ORDER BY customer_id")
        customer_ids = [r[0] for r in cur.fetchall()]

        cur.execute("SELECT customer_id FROM addresses")
        have_address = {r[0] for r in cur.fetchall()}

        for cid in customer_ids:
            if cid not in have_address:
                cur.execute("""
                    INSERT INTO addresses
                    (customer_id, address_line1, address_line2, city, state, zip_code, address_type)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                """, (
                    cid, f"{cid} Main St", None, "New York", "NY",
                    f"{10000 + (cid % 89999):05d}", "home"
                ))

        cur.execute("SELECT customer_id FROM payment_methods")
        have_payment = {r[0] for r in cur.fetchall()}

        for cid in customer_ids:
            if cid not in have_payment:
                cur.execute("""
                    INSERT INTO payment_methods
                    (customer_id, payment_type, provider, account_number_masked, expiry_date, is_default)
                    VALUES (%s, %s, %s, %s, %s, %s)
                """, (
                    cid, "Card", "Visa", f"****{1000 + cid}", "2028-12-01", True
                ))

        existing_suppliers = get_count(cur, "suppliers")
        for i in range(existing_suppliers + 1, NUM_SUPPLIERS + 1):
            cur.execute("""
                INSERT INTO suppliers (supplier_name, contact_email, location_country)
                VALUES (%s, %s, %s)
            """, (
                f"Supplier {i}",
                f"supplier{i}@example.com",
                random.choice(["USA", "Canada", "UK"])
            ))

        existing_categories = get_count(cur, "categories")
        for i in range(existing_categories + 1, NUM_CATEGORIES + 1):
            cur.execute("""
                INSERT INTO categories (category_name, parent_category_id)
                VALUES (%s, NULL)
            """, (f"Category {i}",))

        cur.execute("SELECT supplier_id FROM suppliers ORDER BY supplier_id")
        supplier_ids = [r[0] for r in cur.fetchall()]

        cur.execute("SELECT category_id FROM categories ORDER BY category_id")
        category_ids = [r[0] for r in cur.fetchall()]

        existing_products = get_count(cur, "products")
        for i in range(existing_products + 1, NUM_PRODUCTS + 1):
            cur.execute("""
                INSERT INTO products
                (supplier_id, category_id, product_name, product_description, price, stock_quantity, product_color, product_size)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                random.choice(supplier_ids),
                random.choice(category_ids),
                f"Product {i}",
                f"Description for product {i}",
                round(random.uniform(10, 500), 2),
                random.randint(1000, 2000),
                random.choice(["Black", "Blue", "Red", "White"]),
                random.choice(["S", "M", "L", "XL"])
            ))

        conn.commit()

        cur.execute("""
            SELECT customer_id, MIN(address_id)
            FROM addresses
            GROUP BY customer_id
        """)
        address_map = dict(cur.fetchall())

        cur.execute("""
            SELECT customer_id, MIN(payment_id)
            FROM payment_methods
            GROUP BY customer_id
        """)
        payment_map = dict(cur.fetchall())

        cur.execute("SELECT product_id FROM products ORDER BY product_id")
        product_ids = [r[0] for r in cur.fetchall()]

        existing_orders = get_count(cur, "orders")
        orders_to_create = max(0, NUM_ORDERS - existing_orders)

        for i in range(orders_to_create):
            customer_id = random.choice(customer_ids)
            address_id = address_map[customer_id]
            payment_id = payment_map[customer_id]

            item_count = random.randint(1, 4)
            chosen_products = random.sample(product_ids, item_count)

            items = []
            for pid in chosen_products:
                qty = random.randint(1, 2)
                items.append(f"ROW({pid},{qty})::order_item_input")

            items_sql = "ARRAY[" + ",".join(items) + "]"

            try:
                cur.execute(
                    f"CALL place_order(%s, %s, %s, {items_sql});",
                    (customer_id, address_id, payment_id)
                )
                created_orders += 1
            except Exception as e:
                conn.rollback()
                conn.autocommit = False
                skipped_orders += 1
                continue

            if created_orders > 0 and created_orders % 500 == 0:
                conn.commit()
                print(f"Created {created_orders} orders... skipped {skipped_orders}")

        cur.execute("ANALYZE;")
        conn.commit()
        print(f"Seeding complete. Created: {created_orders}, Skipped: {skipped_orders}")

    except Exception as e:
        conn.rollback()
        print("Error:", e)
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    main()