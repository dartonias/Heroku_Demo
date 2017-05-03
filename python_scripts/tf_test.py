import tensorflow as tf
import os
import psycopg2
import urllib.parse

urlparse.uses_netloc.append("postgres")
url = urllib.parse.urlparse(os.environ["DATABASE_URL"])

conn = psycopg2.connect(
    database=url.path[1:],
    user=url.username,
    password=url.password,
    host=url.hostname,
    port=url.port
)

hello = tf.constant('Hello, TensorFlow!')

with tf.Session() as sess:
  print(sess.run(hello))