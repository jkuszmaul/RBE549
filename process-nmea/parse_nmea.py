#!/usr/bin/python3
import numpy as np
import sys

if len(sys.argv) < 3:
  print("First argument should contain video lengths, in ms; second should be NMEA logs")
  sys.exit(1)

fnames = []
flens = []

with open(sys.argv[1]) as f:
  lines = f.readlines()
  mid = int(len(lines) / 2)
  # Process fnames to swap out file extension
  fnames = [fn.split('.')[0] + ".csv" for fn in lines[0:mid]]
  flens = [int(n) for n in lines[mid:]]

# Start hour/min from Michalson's phone at start of logs
# I will not account for
day = 19 # Day of month
start_hr = 10
start_min = 12

start_hr += 6 # UTC vs. EST

next_file = (start_hr * 60. + start_min) * 60.
cur_file = None

# Line Format:
# YYYYMMDDTHHMMSS.SSS: [NMEA 0183 MSG]

with open(sys.argv[2]) as nmea:
  for line in nmea:
    if len(line) < 20 or len(line.split()) < 2:
      # Invalid line
      continue
    if int(line[6:8]) != day:
      # Wrong day of month (or past midnight UTC...)
      continue
    time = float(line[9:11]) * 3600. + float(line[11:13]) * 60. + float(line[13:19])
    if time > next_file:
      if cur_file:
        cur_file.close()
      if len(fnames) == 0:
        break
      cur_file = open(fnames.pop(0), 'w')
      cur_file.write("#Time(sec since midnight),Speed(Kts)\n")
      next_file += flens.pop(0) / 1000.

    # Assumes no empty spots between commas...
    nmea_msg = line.split()[1].split(',')
    msg_type = nmea_msg[0][1:]
    if msg_type == "GPRMC":
      # Format:
      # $GPRMC,HHMMSS.SS,Status,Latitude,N/S,Longitude,E/W,knots,degrees,DDMMYY,MagVar,E/W,Chksum
      speed_knots = float(nmea_msg[7])

      if cur_file:
        cur_file.write("%f,%f\n" % (time, speed_knots))
  if cur_file:
    cur_file.close()
