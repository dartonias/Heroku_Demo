from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

from geopy.geocoders import GoogleV3
from geopy.exc import GeocoderTimedOut
import psycopg2
import urllib.parse
import os
from time import sleep
from time import time
import sys

import tensorflow as tf
import pandas as pd
import boto3
import botocore
import glob

HOUSE_KEYS = ["House", "Detached", "Att/Row/Twnhouse", "Duplex", "Apartment", "Single Family", "Townhouses", "Multi-Family", "Triplex", "Condominiums", "Condo Townhouse", "Condo Apt"]
FILTER_LOC = 999

def make_numerical(names):
  def f(col):
    if col in names:
      return names.index(col)
    return -1
  return f

def close(x,y):
  tol = 0.1
  if (x-y) < tol and (x-y) < tol:
    return True
  return False

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
  # Pruning data goes here
  #data = data.dropna(how='any', axis=0)
  # End pruning
  norms = {}
  tf_data = {}
  ids = data.iloc[:,ID].values.flatten().tolist()
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
  # Put houses where lookup failed in the average position
  data.iloc[:,LONGITUDE] = (data.iloc[:,LONGITUDE].apply(lambda x: norms['longitude_mean'] if close(x,FILTER_LOC) else x))
  data.iloc[:,LATITUDE] = (data.iloc[:,LATITUDE].apply(lambda x: norms['latitude_mean'] if close(x,FILTER_LOC) else x))
  data.iloc[:,LONGITUDE] = (data.iloc[:,LONGITUDE] - norms['longitude_mean'])/norms['longitude_std']
  data.iloc[:,LATITUDE] = (data.iloc[:,LATITUDE] - norms['latitude_mean'])/norms['latitude_std']
  tf_data['longitude'] = tf.reshape(tf.constant(data.iloc[:,LONGITUDE].values, dtype=tf.float32),[-1,1])
  tf_data['latitude'] = tf.reshape(tf.constant(data.iloc[:,LATITUDE].values, dtype=tf.float32),[-1,1])
  # Format the data
  keys = sorted(tf_data.keys())
  data_input = tf.concat([tf_data[i] for i in keys], 1)
  # Format the target
  norms['price_mean'] = data.iloc[:,PRICE].mean()
  norms['price_std'] = data.iloc[:,PRICE].std()
  data.iloc[:,PRICE] = (data.iloc[:,PRICE] - norms['price_mean'])/norms['price_std']
  data_output = tf.reshape(tf.constant(data.iloc[:,PRICE].values, dtype=tf.float32),[-1,1])
  return data_input, data_output, norms, ids

def save_data():
  s3 = boto3.client(
    's3',
    aws_access_key_id=os.environ["REMAX_AWS_ID"],
    aws_secret_access_key=os.environ["REMAX_AWS_KEY"],
    region_name=os.environ["REMAX_AWS_REGION"]
  )
  files = glob.glob('./model_params/dnn_relu6*')
  for f in files:
    name = os.path.basename(f)
    s3.upload_file(f,'dartonias-remax-model',name)

def download_data():
  s3 = boto3.client(
    's3',
    aws_access_key_id=os.environ["REMAX_AWS_ID"],
    aws_secret_access_key=os.environ["REMAX_AWS_KEY"],
    region_name=os.environ["REMAX_AWS_REGION"]
  )
  files = ['dnn_relu6.data-00000-of-00001', 'dnn_relu6.index', 'dnn_relu6.meta']
  for f in files:
    s3.download_file(Bucket='dartonias-remax-model', Key=f, Filename='./model_params/'+f)

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
  x, _y, rn, ids = format_data(results)
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
  # Training time in seconds, training will run for at least this long
  try:
    train_time = int(os.environ["REMAX_TRAIN_TIME"])
  except KeyError:
    train_time = 600
  with tf.Session() as sess:
    sess.run(init_op)
    print(W[0].eval())
    # Restore the previous data parameters if they exists on the Amazon S3 bucket
    try:
      download_data()
      print('Download succeeded')
      saver.restore(sess, './model_params/dnn_relu6')
    except botocore.exceptions.ClientError as e:
      print(e)
    print(W[0].eval())
    # Normal error loop
    initial_time = time()
    current_time = time()
    count = 0
    while (current_time - initial_time) < train_time:
      sess.run(train_step)
      count += 1
      if count % 10000 == 0:
        current_time = time()
        print("Elapsed time: {}".format(current_time - initial_time))
        print("Cost: {}".format(cost.eval()))
    # Log error loop
    #initial_time = time()
    #current_time = time()
    #count = 0
    #while (current_time - initial_time) < train_time:
    #  sess.run(train_step2)
    #  count += 1
    #  if count % 10000 == 0:
    #    current_time = time()
    #    print("Elapsed time: {}".format(current_time - initial_time))
    #    print("Cost2: {}".format(cost2.eval()))
    saver.save(sess, './model_params/dnn_relu6')
    predicted_prices = tf.reshape(y[-1]*rn['price_std']+rn['price_mean'],[-1]).eval().tolist()
  # Update the entries with predicted prices
  save_data()
  update_cur = conn.cursor()
  for id,pprice in zip(ids, predicted_prices):
    update_cur.execute("UPDATE public.remax_listings SET predicted_price=(%s) WHERE id=(%s);",(pprice, id))
  update_cur.close()
  conn.commit()
  conn.close() 

if __name__ == "__main__":
  main()