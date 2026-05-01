import threading
from collections import Counter
import psycopg2

DB_URL = "postgresql://neondb_owner:npg_nQRbXU4Hd5eK@ep-odd-night-ak0etruv-pooler.c-3.us-west-2.aws.neon.tech/neondb?sslmode=require&channel_binding=require"

THREADS = 50
PRODUCT_ID = 1
QUANTITY = 1

results = []
lock = threading.Lock()

def get_customer_data():
    conn = psycopg2.connect(DB_URL)
    cur = conn.cursor()
    cur.execute("""
        SELECT c.customer_id,
               MIN(a.address_id) AS address_id,
               MIN(p.payment_id) AS payment_id
        FROM customers c
        JOIN addresses a ON a.customer_id = c.customer_id
        JOIN payment_methods p ON p.customer_id = c.customer_id
        GROUP BY c.customer_id
        ORDER BY c.customer_id
    """)
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return rows

customer_data = get_customer_data()

def worker(i):
    customer_id, address_id, payment_id = customer_data[i % len(customer_data)]

    conn = psycopg2.connect(DB_URL)
    conn.autocommit = False
    cur = conn.cursor()

    try:
        cur.execute(
            f"CALL place_order(%s, %s, %s, ARRAY[ROW({PRODUCT_ID},{QUANTITY})::order_item_input]);",
            (customer_id, address_id, payment_id)
        )
        conn.commit()
        outcome = "success"
    except Exception as e:
        conn.rollback()
        outcome = str(e).splitlines()[0]
    finally:
        cur.close()
        conn.close()

    with lock:
        results.append(outcome)

threads = [threading.Thread(target=worker, args=(i,)) for i in range(THREADS)]

for t in threads:
    t.start()

for t in threads:
    t.join()

summary = Counter(results)
print("Results summary:")
for k, v in summary.items():
    print(f"{k}: {v}")