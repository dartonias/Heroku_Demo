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

with conn.cursor() as cur:
  cur.execute("SELECT * FROM information_schema.tables ;")
  #cur.execute("SELECT * FROM pg_catalog.pg_tables;")
  results = cur.fetchall()
  for r in results:
    print(r)

hello = tf.constant('Hello, TensorFlow!')

with tf.Session() as sess:
  print(sess.run(hello))