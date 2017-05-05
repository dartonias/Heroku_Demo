from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

from geopy.geocoders import GoogleV3
from geopy.exc import GeocoderTimedOut
import psycopg2
import urllib.parse
import os

# Filter value for cases where the lookup server responded but the particular query failed
# Since 999 is never a valid latitude or longitude, this should be fine
FILTER_LOC = 999

def get_loc(geolocator):
  def f(name, address):
    if name is None or address is None:
      return None, None
    try:
      # For KW Region, expect something around -80, 43
      # Wait time for API service
      sleep(0.02)
      location = geolocator.geocode(data.loc[i,'name'] + ", " + data.loc[i,'address'][:-9] + ", Canada")
      if location is None:
        # Lookup failed, don't bother trying again
        return FILTER_LOC, FILTER_LOC
      else:
        return location.latitude, location.longitude
    except GeocoderTimedOut:
      # Timed out, we can try again next time
      return None, None
  return f

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
  find_cur.execute("SELECT id,name,address,longitude FROM public.remax_listings WHERE longitude IS NULL LIMIT 5;")
  results = find_cur.fetchall()
  find_cut.close()
  conn.commit()
  geo = get_loc(GoogleV3(os.environ["GOOGLE_V3_API_KEY"]))
  #update_cur = conn.cursor()
  for r in results:
    # Using the name and address, look up
    if r[3] is None:
      loc = geo(r[1],r[2])
      # Update the entries
      #update_cur.execute("UPDATE public.remax_listings SET longitude=(%s), latitude=(%s) WHERE id=(%s);",(loc[],loc[],r[0]))
      print("UPDATE public.remax_listings SET longitude={}, latitude={} WHERE id={};".format(loc[1],loc[0],r[0]))
      break
  #update_cut.close()
  conn.commit()
  conn.close()   

if __name__ == "__main__":
  main()