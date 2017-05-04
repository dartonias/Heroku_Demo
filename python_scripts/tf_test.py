import tensorflow as tf
import os
import psycopg2
import urllib.parse

urllib.parse.uses_netloc.append("postgres")
url = urllib.parse.urlparse(os.environ["DATABASE_URL"])

conn = psycopg2.connect(
    database=url.path[1:],
    user=url.username,
    password=url.password,
    host=url.hostname,
    port=url.port
)

find_cur = conn.cursor()
#cur.execute("SELECT * FROM information_schema.tables ;")
#cur.execute("SELECT * FROM pg_catalog.pg_tables;")
find_cur.execute("SELECT id,name,address,longitude FROM public.remax_listings")
results = find_cur.fetchall()
find_cur.close()
conn.commit()
for r in results:
  print(r)
conn.close()    

hello = tf.constant('Hello, TensorFlow!')

with tf.Session() as sess:
  print(sess.run(hello))