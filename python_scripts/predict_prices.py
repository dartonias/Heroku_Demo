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
import numpy as np

HOUSE_KEYS = ["House", "Detached", "Att/Row/Twnhouse", "Duplex", "Apartment", "Single Family", "Townhouses", "Multi-Family", "Triplex", "Condominiums", "Condo Townhouse", "Condo Apt"]
FILTER_LOC = 999

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
  data = np.array(data)
  norms = {}
  tf_data = {}
  tf_data['description'] = tf.one_hot(data[:,DESCRIPTION], len(HOUSE_KEYS), dtype=tf.float32)
  tf_data['extra_bed'] = tf.reshape(tf.constant(data[:,EXTRA_BED], dtype=tf.float32),[-1,1])
  tf_data['extra_bath'] = tf.reshape(tf.constant(data[:,EXTRA_BATH], dtype=tf.float32),[-1,1])
  norms['square_mean'] = data[:,SQUARE].mean()
  norms['square_std'] = data[:,SQUARE].std()
  data[:,SQUARE] = (data[:,SQUARE] - norms['square_mean'])/norms['square_std']
  tf_data['square'] = tf.reshape(tf.constant(data[:,SQUARE], dtype=tf.float32),[-1,1])
  tf_data['beds'] = tf.reshape(tf.constant(data[:,BEDS], dtype=tf.float32),[-1,1])
  tf_data['baths'] = tf.reshape(tf.constant(data[:,BATHS], dtype=tf.float32),[-1,1])
  tf_data['rooms'] = tf.reshape(tf.constant(data[:,ROOMS], dtype=tf.float32),[-1,1])
  norms['longitude_mean'] = data[:,LONGITUDE].mean()
  norms['longitude_std'] = data[:,LONGITUDE].std()
  norms['latitude_mean'] = data[:,LATITUDE].mean()
  norms['latitude_std'] = data[:,LATITUDE].std()
  data[:,LONGITUDE] = (data[:,LONGITUDE] - norms['longitude_mean'])/norms['longitude_std']
  data[:,LATITUDE] = (data[:,LATITUDE] - norms['latitude_mean'])/norms['latitude_std']
  tf_data['longitude'] = tf.reshape(tf.constant(data[:,LONGITUDE], dtype=tf.float32),[-1,1])
  tf_data['latitude'] = tf.reshape(tf.constant(data[:,LATITUDE], dtype=tf.float32),[-1,1])
  # Format the data
  keys = sorted(tf_data.keys())
  data_input = tf.concat([tf_data[i] for i in keys], 1)
  # Format the target
  norms['price_mean'] = data[:,PRICE].mean()
  norms['price_std'] = data[:,PRICE].std()
  data[:,PRICE] = (data[:,PRICE] - norms['price_mean'])/norms['price_std']
  data_output = tf.reshape(tf.constant(data[:,PRICE], dtype=tf.float32),[-1,1])
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
  x, _y, norms = format_data(results)
  num_input = x.shape[1]
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