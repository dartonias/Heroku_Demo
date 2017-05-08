from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

from geopy.geocoders import GoogleV3
from geopy.exc import GeocoderTimedOut
import psycopg2
import urllib.parse
import os
from time import sleep
import sys

import tensorflow as tf
import pandas as pd

HOUSE_KEYS = ["House", "Detached", "Att/Row/Twnhouse", "Duplex", "Apartment", "Single Family", "Townhouses", "Multi-Family", "Triplex", "Condominiums", "Condo Townhouse", "Condo Apt"]
FILTER_LOC = 999

def make_numerical(names):
  def f(col):
    if col in names:
      return names.index(col)
    return -1
  return f

def format_data(data):
  # Values held in the rows
  ID = 0
  DESCRIPTION = 1
  NAME = 2
  ADDRESS = 3
  PRICE = 4
  BEDS = 5
  BATHS = 6
  ROOMS = 7
  SQUARE = 8
  EXTRA_BED = 9
  EXTRA_BATH = 10
  LONGITUDE = 11
  LATITUDE = 12
  data = pd.DataFrame(data)
  norms = {}
  tf_data = {}
  data.iloc[:,DESCRIPTION] = (data.iloc[:,DESCRIPTION].apply(make_numerical(HOUSE_KEYS))).astype(int)
  tf_data['description'] = tf.one_hot(data.iloc[:,DESCRIPTION].values, len(HOUSE_KEYS), dtype=tf.float32)
  data.iloc[:,EXTRA_BED] = (data.iloc[:,EXTRA_BED]).astype(int)
  data.iloc[:,EXTRA_BATH] = (data.iloc[:,EXTRA_BATH]).astype(int)
  tf_data['extra_bed'] = tf.reshape(tf.constant(data.iloc[:,EXTRA_BED].values, dtype=tf.float32),[-1,1])
  tf_data['extra_bath'] = tf.reshape(tf.constant(data.iloc[:,EXTRA_BATH].values, dtype=tf.float32),[-1,1])
  norms['square_mean'] = data.iloc[:,SQUARE].mean()
  norms['square_std'] = data.iloc[:,SQUARE].std()
  data.iloc[:,SQUARE] = (data.iloc[:,SQUARE] - norms['square_mean'])/norms['square_std']
  tf_data['square'] = tf.reshape(tf.constant(data.iloc[:,SQUARE].values, dtype=tf.float32),[-1,1])
  tf_data['beds'] = tf.reshape(tf.constant(data.iloc[:,BEDS].values, dtype=tf.float32),[-1,1])
  tf_data['baths'] = tf.reshape(tf.constant(data.iloc[:,BATHS].values, dtype=tf.float32),[-1,1])
  tf_data['rooms'] = tf.reshape(tf.constant(data.iloc[:,ROOMS].values, dtype=tf.float32),[-1,1])
  data.iloc[:,LONGITUDE] = (data.iloc[:,LONGITUDE]).astype(float)
  data.iloc[:,LATITUDE] = (data.iloc[:,LATITUDE]).astype(float)
  norms['longitude_mean'] = data.iloc[:,LONGITUDE].mean()
  norms['longitude_std'] = data.iloc[:,LONGITUDE].std()
  norms['latitude_mean'] = data.iloc[:,LATITUDE].mean()
  norms['latitude_std'] = data.iloc[:,LATITUDE].std()
  data.iloc[:,LONGITUDE] = (data.iloc[:,LONGITUDE] - norms['longitude_mean'])/norms['longitude_std']
  data.iloc[:,LATITUDE] = (data.iloc[:,LATITUDE] - norms['latitude_mean'])/norms['latitude_std']
  tf_data['longitude'] = tf.reshape(tf.constant(data.iloc[:,LONGITUDE].values, dtype=tf.float32),[-1,1])
  tf_data['latitude'] = tf.reshape(tf.constant(data.iloc[:,LATITUDE].values, dtype=tf.float32),[-1,1])
  # Format the data
  keys = sorted(tf_data.keys())
  data_input = tf.concat([tf_data[i] for i in keys], 1)
  print(data_input)
  # Format the target
  norms['price_mean'] = data.iloc[:,PRICE].mean()
  norms['price_std'] = data.iloc[:,PRICE].std()
  data.iloc[:,PRICE] = (data.iloc[:,PRICE] - norms['price_mean'])/norms['price_std']
  data_output = tf.reshape(tf.constant(data.iloc[:,PRICE].values, dtype=tf.float32),[-1,1])
  return data_input, data_output, norms

def main():
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
  find_cur.execute("SELECT id,description,name,address,price,beds,baths,rooms,square,extra_bed,extra_bath,longitude,latitude FROM public.remax_listings;")
  results = find_cur.fetchall()
  find_cur.close()
  conn.commit()
  # Machine learn on the variables, and write back to database
  x, _y, rn = format_data(results)
  num_input = int(x.shape[1])
  layers = [num_input*2, num_input*1]
  W = []
  b = []
  y = []
  activation = tf.nn.relu6
  W.append(tf.Variable(tf.random_normal([num_input, layers[0]], stddev=0.35)))
  b.append(tf.Variable(tf.zeros([layers[0]])))
  y.append(activation(tf.matmul(x, W[-1]) + b[-1]))
  for l in range(len(layers)-1):
    W.append(tf.Variable(tf.random_normal([layers[l], layers[l+1]], stddev=0.35)))
    b.append(tf.Variable(tf.zeros([layers[l+1]])))
    y.append(activation(tf.matmul(y[-1], W[-1]) + b[-1]))
  W.append(tf.Variable(tf.random_normal([layers[-1], 1], stddev=0.35)))
  b.append(tf.Variable(tf.zeros(1)))
  y.append(tf.matmul(y[-1], W[-1]) + b[-1])
  # Normal squared error loss
  cost = tf.reduce_mean(tf.squared_difference(y[-1], _y))
  # Squared error of the percentage incorrect
  cost2 = tf.reduce_mean(tf.squared_difference(tf.log(y[-1]*rn['price_std']+rn['price_mean']), tf.log(_y*rn['price_std']+rn['price_mean'])))
  train_step = tf.train.GradientDescentOptimizer(0.002).minimize(cost)
  train_step2 = tf.train.GradientDescentOptimizer(0.002).minimize(cost2)
  init_op = tf.global_variables_initializer()
  saver = tf.train.Saver(W+b)
  with tf.Session() as sess:
    sess.run(init_op)
    for _ in range(1000):
      sess.run(train_step)
    print('Cost1 = ',cost.eval())
    for _ in range(1000):
      sess.run(train_step2)
    print('Cost2 = ',cost2.eval())
    saver.save(sess, './model_params/dnn_relu6')
  # Update the entries with predicted prices
  #update_cur = conn.cursor()
  #update_cur.close()
  #conn.commit()
  conn.close() 

if __name__ == "__main__":
  main()