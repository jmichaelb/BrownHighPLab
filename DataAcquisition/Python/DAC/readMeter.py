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

def getLogFileName(expDir, device, readTime, prependDate):
    """Returns the target file name for the log data

    :param expDir: the path in which data for the current experiment is logged
    :param device: the identifier for the device being read
    :param readTime: the datetime object for the time the reading was taken
    :param prependDate: True to prepend YYYYMMDD to the beginning of the log file
    :return: the full path, including file name, to which data will be logged
    """
    logFileName = expDir+'/'
    if prependDate:
        logFileName = logFileName + readTime.strftime('%Y%m%d') + '_'
    return logFileName+'DP41-'+device+'_Uncorrected.txt'


def logReading(logFile, readTime, reading):
    """Appends new reading to a tab-delimited log

    :param logFile: full path of the log file (see getLogFileName)
    :param readTime: datetime object with time of the reading being added
    :param reading:
    :return:
    """
    ll = readTime.strftime('%Y-%m-%d %H:%M:%S UTC')+'\t'+repr(reading)+'\n'
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
    -d      when present, indicates that YYYYMMDD will be prepended to log file names (default False)
            no option value supported
    -v      verbose output (this will NOT output readings but it will no longer fail silently)

    :param parms: the list of parameters passed to this script.  Defaults to sys.arg[1:]
    :return: a dictionary with output parameters, including defaults
    """

    # set up defaults
    out = {'url': '192.168.1.200:2000',
           'logDir': os.getcwd(),
           'devId': 'X01',
           'readInt': 5,
           'lookback': 2.0,
           'lfIncludesDate': False}
    opts, args = getopt(parms, 'x:p:u:r:i:l:dv')
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
        elif opt == '-d':
            out['lfIncludesDate'] = True
        elif opt == '-v':
            global verbose
            verbose = True
    return out

def printOpts(parms, parsePattern, expDir):
    print 'running with options:'
    for k in iter(parms.keys()):
        print '\t'+k+': '+repr(parms[k])
    print '\tparsePattern: '+parsePattern
    print '\texperiementLogDir: '+expDir

def updateReadings(lookbackHrs, readings, newReading):
    """Updates an array of readings by adding a new reading and removing readings predating the lookback period

    :param lookbackHrs: float detailing the number of hours to keep
    :param readings: existing readings
    :param newReading: the latest reading as a tuple (readTime:datetime, reading:float)
    :return: a new array of readings
    """
    readings.append(newReading)
    mins = (lookbackHrs - int(lookbackHrs))*60.0
    earliestData = datetime.utcnow() - timedelta(hours=int(lookbackHrs),minutes=int(mins))
    return [r for r in readings if r[0] >= earliestData]

# def animate(readings):
#     x = [r[0] for r in readings]
#     y = [r[1] for r in readings]
#     line.set_data(x,y)
#     ax.set_xlim(x[0], x[-1])
#     ax.set_ylim(min(y), max(y))
#     return line,


def main():
    parms = getParms()
    if 'expId' not in parms:
        raise ValueError('You must provide an experiment id (-x parameter).')
    devPattern = getParsePattern(parms['devId'])
    expDir = mkExperimentDir(parms['logDir'], parms['expId'])
    if verbose:
        printOpts(parms, devPattern, expDir)

    try :
        while True:
            (readTime, rawRead) = getReading(parms['url'], parms['devId'])
            reading = parseReading(rawRead, devPattern)
            logFileName = getLogFileName(expDir, parms['devId'], readTime, parms['lfIncludesDate'])
            logReading(logFileName, readTime, reading)
            # update plot
            sleep(parms['readInt'])
    except:
        # close plots
        print 'error'

def getFakeReading(device):
    """FOR TESTING ONLY - Needs to return same output as getReading"""
    readTime = datetime.utcnow()
    fakeReading = '?43^M'+device+'00000'+repr(round(uniform(20,25),1))+'^M'
    return (readTime, fakeReading)


def test():
    parms = getParms()
    if 'expId' not in parms:
        raise ValueError('You must provide an experiment id (-x parameter).')
    devPattern = getParsePattern(parms['devId'])
    expDir = mkExperimentDir(parms['logDir'], parms['expId'])
    if verbose:
        printOpts(parms, devPattern, expDir)

    readings = []
    # ani = FuncAnimation(fig, animate, frames=readings, interval=int(parms['readInt']))


    #try :
    while True:
        # take the reading
        (readTime, rawRead) = getFakeReading(parms['devId'])
        reading = parseReading(rawRead, devPattern)
        # log the reading
        logFileName = getLogFileName(expDir, parms['devId'], readTime, parms['lfIncludesDate'])
        logReading(logFileName, readTime, reading)
        # plot the reading
        readings = updateReadings(parms['lookback'], readings, (readTime, reading))
        print readings
        # plt.show()
        sleep(parms['readInt'])
    # except:
    #     # close plots
    #     print 'error'

verbose = False
# fig, ax = plt.subplots()
# fig.autofmt_xdate()
# line, = ax.plot([])

test()

# if __name__ == "__main__":
#     main()
