#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os, sys
from datetime import datetime, timedelta
import csv

import numpy
import cv2

def getParms(parms=sys.argv[1:]):
    """ Processes and parses parameters passed into Python script

    Required parameters:
        -f:     full or relative path to the mp4 file to be annotated
        -l:     full or relative path to the temperature log file (assume single file for now)

        Optional parameters:
        -o      full or relative path to the annotated video file
                defaults to same location as -f parameter, but with _Annotated
                appended to file name before its extension
        -g      grace period beyond which temperature is assumed to be the same
                as the last available temperature, in seconds
                defaults to 10 (double the default read interval in readMeter.py)
                value must be an integer
        -k      add this flag to get temperature output in Kelvin
                otherwise, values will be in °C
        -v      verbose output (this will NOT output readings but it will no longer fail silently)
        -t      test mode - does not call the meter but makes up fake readings between 20 and 25

        :param parms: the list of parameters passed to this script.  Defaults to sys.arg[1:]
        :return: a dictionary with output parameters, including defaults
        """
    out = {'useK': False,
           'grace': 10}
    opts, args = getopt(parms, 'f:l:o:g:kvt')
    for opt, arg in opts:
        if opt == '-f':
            out['vidIn'] = arg
        elif opt == '-l':
            out['tempLog'] = arg
        elif opt == '-o':
            out['vidOut'] = arg
        elif opt == '-g':
            out['grace'] = int(arg)
        elif opt == '-k':
            out['useK'] = True
        elif opt == '-v':
            global verbose
            verbose = True
        elif opt == '-t':
            global testMode
            testMode = True
            print '!!!!! TEST MODE !!!!!'
    return out

def getTempIter(tLogName, useK=False):
    """Returns an iterator that will cycle through temperature logs
    Assumes single log file already ordered by date/time
    with each log entry on a new line, temperatures in Celsius

    :param tlog: the path to the temperature log file
    :param useK: true to report temperatures in K rather than in C
    :return: a generator that gives temperatures
    """
    # TODO: handle multiple temp logs for a single video ( string them together here black-box style )
    with open(tLogName,'r',1) as tLog:
        tRdr = csv.reader(tLog, delimiter='\t')
        for r in tRdr:
            yield parseLogLine(r,useK)

def parseLogLine(ll, useK=False):
    """Parses a line of text from the temperature log
    Splits tab-delimited datetime and temp into a tuple

    :param ll: tab-delimited log line comprising date/time string (UTC) and temperature (in °C)
    :param useK: true to report temperatures in K rather than in C
    :return: a tuple with a datetime object and temperature string
    """
    # TODO: handle UTC or local time
    t = float(ll[1])
    if useK:
        t += C2K
    t = str(t) + (' K' if useK else ' C') # degree symbol not supported by library rendering image
    ts = datetime.strptime(ll[0],logTimeFormat)
    return (ts,t)


def annotateVideo(vidIn, vidOut, tempFile, graceSecs, useK, test):
    """Opens a video file, goes throught it frame by frame,
    adds a temperature to it if one is available, and writes
    frames to a new video file

    :param vidIn: name of the input video file
    :param vidOut: name of the output video file
    :param tempIter: a generator that goes through temperatures in a log file (output from getTempIter)
    :param graceSecs: float indicatings seconds that may elapse between a logged temp
                        and the time of a frame in the video
    :param test: a boolean indicating whether to run in test mode (displays video)
    """

    grace = timedelta(seconds=graceSecs)
    # get file creation date in UTC time (since temp logs are in UTC time)
    # TODO: handle UTC or local time
    # TODO: see if there's a better way to get the start date for a video
    vModDt = datetime.utcfromtimestamp(os.path.getmtime(vidIn))
    vid = cv2.VideoCapture(vidIn)
    vStartDt = vModDt - timedelta(seconds=vid.get(cv2.CAP_PROP_FRAME_COUNT)/vid.get(cv2.CAP_PROP_FPS))
    frameW = int(vid.get(cv2.CAP_PROP_FRAME_WIDTH))
    frameH = int(vid.get(cv2.CAP_PROP_FRAME_HEIGHT))
    if test:
        cv2.namedWindow(testWin, cv2.WINDOW_NORMAL)
        cv2.resizeWindow(testWin,frameW,frameH)
    # TODO: make this robust enough to ditch the assumption that the temp log starts before and ends after the video file
    try:
        for nt in getTempIter(tempFile, useK):
            if nt[0] >= vStartDt and nt[0] <= vModDt+grace:   # only pay attention to temp logs within the range of time of the video
                cont = True
                # process all frames between lt and nt
                while cont:
                    cont = processFrame(vid,vStartDt,frameW,frameH,lt[0],lt[1],nt[0],nt[1],grace,test)
            lt = nt
    finally:
        cv2.destroyWindow(testWin)
        vid.release()

def processFrame(vid, vidStartDt, fw,fh,prevTempDt, prevTemp, currTempDt, currTemp, grace,test):
    """Processes the next frame of the video

    :param vid: video
    :param vidStartDt: the datetime representing the start of the video
    :param fw: width in pixels of frames in this video
    :param fh: height in pixels of frames in this video
    :param prevTempDt: the datetime for the previous temperature log
    :param prevTemp: the temp string for the previous temperature log
    :param currTempDt: the datetime for the current temperature log
    :param currTemp: the temperature string for the current temperature log
    :param grace: a timedelta object indicating the grace period for a temperature reading
    :return: true if the frame is still within the window of the previous and current temperature logs
            false if the frame could not be read or if the frame is later than the current temp log
    """
    rv, frame = vid.read()
    frameDt = vidStartDt + timedelta(milliseconds=vid.get(cv2.CAP_PROP_POS_MSEC))
    # use previous temp if frame is between previous and current temp logs
    if rv and prevTempDt < frameDt and frameDt < currTempDt and frameDt < prevTempDt + grace:
        cont = True # still between previous and current logs - keep reading frames for same temp log
        annotateFrame(frame, prevTemp, getTempLoc(fw, fh, prevTemp), test)
    else:  # once you advance to a frame later than nt (or run out of frames), stop advancing
        cont = False    # TODO: better handle running out of frames
        # TODO: plug this hole that may result in unannotated frames
        # still need to write a temp to the last frame read - check still w/in grace period of current log
        if rv and currTempDt <= frameDt and frameDt <= currTempDt + grace:
            annotateFrame(frame, currTemp, getTempLoc(fw, fh, currTemp), test)
    return cont

def getTempLoc(frameWidth, frameHeight, tempStr):
    """Calculates the location for temp string given a frame size and temperature string

    :param frameWidth: int giving width of frame in pixels
    :param frameHeight: int giving height of frame in pixels
    :param tempStr: string with temperature and unit
    :return: tuple with the location for the text in a frame
    """
    (w,h),_ = cv2.getTextSize(tempStr, font, fScale, fThickness)
    return (frameWidth - w - 10,frameHeight - h) # pad the width a bit so the last character doesn't look chopped off


def annotateFrame(frame, tempStr, tempLoc, test):
    """Annotates a single frame of a video - temp in lower right corner of the frame

    :param frame: the frame object to be annotated
    :param tempStr: the string to add to the frame
    :param tempLoc: the pixel location of the lower left corner of the text
    :param test: true to run in test mode and show images as they are amended
    """
    cv2.putText(frame, tempStr, tempLoc, font, fScale, blue, fThickness)
    if test:
        cv2.imshow(testWin, frame)
        cv2.waitKey(10)

# def main():
#     parms = getParms()





verbose = False
testMode = False
logTimeFormat = '%Y-%m-%d %H:%M:%S %Z'
C2K = 273.15
blue = (255,0,0)
font = cv2.FONT_HERSHEY_SIMPLEX
fScale = 2
fThickness = 3
testWin = 'annotation test'

# if __name__ == '__main__':
#     main()

