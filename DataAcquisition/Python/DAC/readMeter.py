#!/usr/bin/env python

import pycurl, cStringIO, os, sys
from re import search
from getopt import getopt
from datetime import datetime, timedelta
from time import sleep

# used in testing only
from random import uniform

import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt
import matplotlib.dates as mdates


def getRawReading(url, device, timeout_ms=1000):
    """Gets a reading from Omega meter equipped with Ethernet card

    :param url: the URL (with optional port) of the meter
    :param device: the device (reading command in the web UI) from which to read
    :param timeout_ms: the max time allowed for each meter read, in ms (default 1000)
    :return: returns a 2-tuple containing the (1) time of the reading as a datetime object and
        (2) a string with the raw output from the meter
    """
    try:
        c = pycurl.Curl()
        c.setopt(c.URL, url)
        c.setopt(c.POSTFIELDS, '*' + device + '\r')
        c.setopt(c.TIMEOUT_MS, timeout_ms)
        c.setopt(c.HTTPHEADER, ['Pragma: no-cache'])
        buffer = cStringIO.StringIO()
        c.setopt(c.WRITEDATA, buffer)
        readTime = datetime.utcnow()
        c.perform()
    finally:
        rawReading = buffer.getvalue()  # timeout throws error - must do this in finally block
        c.close()
        buffer.close()
        return readTime, rawReading


def parseRawReading(rawReading, extractPattern, targetGroup=0):
    """ Parses the raw reading and returns the actual reading as a float

    :param rawReading: the meter's raw output from the curl call
    :param extractPattern: the regex used to extract data from the rawRead.  see also getParsePattern
    :param targetGroup: the index of the regex capture group containing the reading (default 0 - entire match)
    :return: returns the extracted meter reading as a float
    """

    meterRead = search(extractPattern, rawReading)
    return float(meterRead.group(targetGroup))


def getParsePattern(device, pattem='(?<=DEVICE)\d+\.\d+'):
    """ Turns a regex template into device-specific regex

    :param device: the device from which readings are taken
    :param pattem: the regex pattern template used to extract a reading from the meter output.
            Must include the string 'DEVICE', which will be replaced with the device parameter
    :return: returns the regex used to extract a reading from the raw meter output
    """
    return pattem.replace('DEVICE', device)


def mkExperimentDir(parentPath, expId):
    """Creates the experiment log directory if it doesn't already exist

    :param parentPath: the path where data for all experiments is stored
    :param expId: the identifier for the current experiment
    :return: a string giving the full directory path for the experiment's data
    """
    expDirStr = parentPath+'/'+expId
    if not os.path.isdir(expDirStr):
        os.mkdir(expDirStr)
    return expDirStr

def getLogFileName(expDir, device):
    """Returns the target file name for the log data

    :param expDir: the path in which data for the current experiment is logged
    :param device: the identifier for the device being read
    :return: the full path, including file name, to which data will be logged
    """
    logFileName = expDir+'/'
    return logFileName+'DP41-'+device+'_Uncorrected.txt'


def logReading(logFile, readTime, reading):
    """Appends new reading to a tab-delimited log

    :param logFile: full path of the log file (see getLogFileName)
    :param reading:
    :return:
    """
    ll = readTime.strftime(logTimeFormat)+'\t'+repr(reading)+'\n'
    try:
        with open(logFile, 'a') as lf:
            lf.write(ll)
    except:
        if verbose:
            print 'Adding new reading to log file failed at '+dt.datetime.now()


def getParms(parms=sys.argv[1:]):
    """ Processes and parses parameters passed into Python script

    Required parameters:
    -x:     experiment id, used to determine log file path
            option value string without spaces required

    Optional parameters:
    -p      parent path for meter logs.  (default is current working directory)
            experiment-specific paths will be created as subdirectories
    -u      url from which data will be read (default 192.168.1.200:2000)
            if used, option value string required
            protocol not required (only HTTP is supported)
    -r      device identifier from which data will be read (default X01)
            if used, option value string without spaces required
    -i      the read interval, in seconds (default 5)
            if used, option value integer required
    -l      lookback interval for plotting readings, in hours (default 2)
            float value is acceptable
    -y      label to use for y-axis on plot (default 'temp (C)')
    -v      verbose output (this will NOT output readings but it will no longer fail silently)
    -t      test mode - does not call the meter but makes up fake readings between 20 and 25

    :param parms: the list of parameters passed to this script.  Defaults to sys.arg[1:]
    :return: a dictionary with output parameters, including defaults
    """

    # set up defaults
    out = {'url': '192.168.1.200:2000',
           'logDir': os.getcwd(),
           'devId': 'X01',
           'readInt': 5,
           'lookback': 2.0,
           'yLabel': 'temp (C)'}
    opts, args = getopt(parms, 'x:p:u:r:i:l:y:vt')
    for opt, arg in opts:
        if opt == '-x':
            out['expId'] = arg
        elif opt == '-p':
            out['logDir'] = arg
        elif opt == '-u':
            out['url'] = arg
        elif opt == '-r':
            out['devId'] = arg
        elif opt == '-i':
            out['readInt'] = int(arg)
        elif opt == '-l':
            out['lookback'] = float(arg)
        elif opt == '-y':
            out['yLabel'] = arg
        elif opt == '-v':
            global verbose
            verbose = True
        elif opt == '-t':
            global testMode
            testMode = True
            print '!!!!! TEST MODE !!!!!'
    return out

def printOpts(parms, parsePattern, expDir):
    print 'running with options:'
    for k in iter(parms.keys()):
        print '\t'+k+': '+repr(parms[k])

def getEarliestTimeToPlot(lookbackHrs):
    hrs = int(lookbackHrs)
    mins = int((lookbackHrs - hrs) * 60)
    return datetime.utcnow() - timedelta(hours=hrs, minutes=mins)


def updateReadings(lookbackHrs, readings, newReadTime, newReading):
    """Updates an array of readings by adding a new reading and removing readings predating the lookback period

    :param lookbackHrs: float detailing the number of hours to keep
    :param readings: existing readings
    :param newReadTime: datetime of the newReading
    :param newReading: the latest reading as float
    :return: a new array of readings
    """
    earliestData = getEarliestTimeToPlot(lookbackHrs)
    for r in readings:
        if r[0] <= earliestData:
            readings.remove(r)
        else:
            break   # ok to break after first reading in lookback range
    # always at least include the latest reading
    readings.append((newReadTime, newReading))
    return readings

def takeReading(parms, devPattern, logFileName):
    try:
        readTime, rawRead = getRawReading(parms['url'], parms['devId']) if not testMode else getFakeReading(parms['devId'])
        reading = parseRawReading(rawRead, devPattern)  # if reading failed, will probably be in this function
        logReading(logFileName, readTime, reading)
        return readTime, reading
    except Exception as e:
        print 'Failed to read at {0}\n\t{1}'.format(readTime.strftime(errTimeFormat), e)
        return None, None

def getFakeReading(device):
    """FOR TESTING ONLY - Needs to return same output as getRawReading"""
    readTime = datetime.utcnow()
    fakeReading = '?43^M'+device+'00000'+repr(round(uniform(20,25),1))+'^M'
    return readTime, fakeReading

def plotReadings(readings, line):
    x = [r[0] for r in readings]
    y = [r[1] for r in readings]
    line.set_data(x, y)
    line.axes.relim()
    line.axes.autoscale_view()
    line.axes.get_figure().canvas.flush_events()
    # plt.plot(x, y, 'b')
    # plt.draw()
    # plt.pause(0.00001)
    sleep(.00001)


def main():
    parms = getParms()
    if 'expId' not in parms:
        raise ValueError('You must provide an experiment id (-x parameter).')
    devPattern = getParsePattern(parms['devId'])
    expDir = mkExperimentDir(parms['logDir'], parms['expId'])
    logFileName = getLogFileName(expDir, parms['devId'])

    if verbose:
        printOpts(parms, devPattern, expDir)

    readings = []

    plt.ion()
    fig, ax,  = plt.subplots()
    fig.autofmt_xdate()
    fig.canvas.set_window_title('DP41 Readings')
    ax.set_xlabel('time')
    ax.set_ylabel(parms['yLabel'])
    ax.xaxis.set_major_formatter(mdates.DateFormatter(plotTimeFormat))
    line, = ax.plot([],[],'b')
    fig.show()

    try :
        while True:
            sleep(parms['readInt'])
            readTime, reading = takeReading(parms, devPattern, logFileName)
            # if read failed, just skip the rest of the loop
            if readTime is not None and reading is not None:
                readings = updateReadings(parms['lookback'], readings, readTime, reading)
                plotReadings(readings, line)
    except Exception as e:
        plt.close(fig)
        if testMode:
            raise e
        else:
            sys.exit('Some error occurred - try again, perhaps in test mode (-t)')


verbose = False
testMode = False
logTimeFormat = '%Y-%m-%d %H:%M:%S UTC'
errTimeFormat = '%Y-%m-%d %H:%M'
plotTimeFormat = '%H:%M:%S'



if __name__ == "__main__":
    main()
