#!/usr/bin/env python

import pycurl, cStringIO, os, sys
from re import search
from getopt import getopt
from datetime import datetime, timedelta
from time import sleep

# used in testing only
from random import uniform

import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation


def getReading(url, device, timeout_ms=1000):
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
        c.close()
        rawReading = buffer.getvalue()
        buffer.close()
        return (readTime, rawReading)
    except Exception as e:
        if verbose:
            print 'Failed to read data from meter at '+dt.datetime.now()+':\n\t'+e


def parseReading(rawReading, extractPattern, targetGroup=0):
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
           'lookback': 2.0}
    opts, args = getopt(parms, 'x:p:u:r:i:l:vt')
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


def updateReadings(lookbackHrs, readings, newReadTime, newReading):
    """Updates an array of readings by adding a new reading and removing readings predating the lookback period

    :param lookbackHrs: float detailing the number of hours to keep
    :param readings: existing readings
    :param newReadTime: datetime of the newReading
    :param newReading: the latest reading as float
    :return: a new array of readings
    """
    readings.append((newReadTime,newReading))
    hrs = int(lookbackHrs)
    mins = int((lookbackHrs - hrs) * 60)
    earliestData = datetime.utcnow() - timedelta(hours=hrs, minutes=mins)
    return [r for r in readings if r[0] >= earliestData]

# def getReadings(logFileName, lookbackHrs):
#     """Reads data from the specified log file and add it to the data to be graphed
#     if it is within the lookbackHrs interval
#
#     :param logFileName:
#     :param lookbackHrs:
#     :return:
#     """
#     hrs = int(lookbackHrs)
#     lookback = timedelta(hours=hrs, minutes=int((lookbackHrs - hrs)*60))
#     with open(logFileName,'r') as lf:
#         data = []
#         while True:
#             line = lf.readline()
#             sleep(.1)
#             if line:
#                 (tm,tp) = line.split('\t')
#                 readTime = datetime.strptime(tm,logTimeFormat)
#                 if readTime >= (datetime.utcnow() - lookback):
#                     data.append((readTime, float(tp)))
#                     yield data

def read(logFile):
    with open(logFile,'r') as f:
        data = []
        while True:
            line = f.readline()
            sleep(0.1)
            if line:
                data.append(float(line.split('\t')[1]))
                yield data



# def animate(reading):
#     curve.set_ydata(reading)
#     #ax.set_xlim(x[0], x[-1])
#     ax.set_ylim(min(y), max(y))
#     return curve,

def animate(values):
    x = list(range(len(values)))
    line.set_data(x, values)
    ax.set_xlim(x[0], x[-1])
    ax.set_ylim(min(values), max(values))
    return line,

def getFakeReading(device):
    """FOR TESTING ONLY - Needs to return same output as getReading"""
    readTime = datetime.utcnow()
    fakeReading = '?43^M'+device+'00000'+repr(round(uniform(20,25),1))+'^M'
    return (readTime, fakeReading)

def main():
    parms = getParms()
    if 'expId' not in parms:
        raise ValueError('You must provide an experiment id (-x parameter).')
    devPattern = getParsePattern(parms['devId'])
    expDir = mkExperimentDir(parms['logDir'], parms['expId'])
    logFileName = getLogFileName(expDir, parms['devId'])
    if verbose:
        printOpts(parms, devPattern, expDir)

    global readings

    # keep reference to animation obj so not garbage collected
    ani = FuncAnimation(fig, animate, read(logFileName), interval=int(parms['readInt'])*1200)
    plt.show()

    try :
        while True:
            # take the reading
            (readTime, rawRead) = getReading(parms['url'], parms['devId']) if not testMode else getFakeReading(parms['devId'])
            reading = parseReading(rawRead, devPattern)
            logReading(logFileName, readTime, reading)
            # plot the reading
            sleep(parms['readInt'])
    except Exception as e:
        plt.close(fig)
        if testMode:
            raise e
        else:
            sys.exit('Some error occurred - try again, perhaps in test mode (-t)')

readings = []
verbose = False
testMode = False
logTimeFormat = '%Y-%m-%d %H:%M:%S UTC'

# set up plot, use date format for x-axis, create empty plot
# fig, ax = plt.subplots()
# fig.autofmt_xdate()
# line, = ax.plot([])
fig, ax = plt.subplots()
line, = ax.plot([])


if __name__ == "__main__":
    main()
