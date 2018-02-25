#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
from getopt import getopt
from os import path
from datetime import datetime, timedelta
import csv

import numpy
import cv2


def getParms(parms=sys.argv[1:]):
    """ Processes and parses parameters passed into Python script

    Required parameters:
        -i:     full or relative path to the mp4 file to be annotated
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
        -v      verbose output
        -t      test mode - shows annotated video rather than writing it

        :param parms: the list of parameters passed to this script.  Defaults to sys.arg[1:]
        :return: a dictionary with output parameters, including defaults
        """
    out = {'useK': False,
           'grace': 10}
    opts, args = getopt(parms, 'i:l:o:g:kvt')
    for opt, arg in opts:
        if opt == '-i':
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
    if not 'vidOut' in out:
        out['vidOut'] = getOutputFile(out['vidIn'])
    return out


def getOutputFile(vidIn):
    """Outputs default output file name for annotated video
    same as original file but with _Annotated appended before extension

    :param vidIn: full or relative path to the input video file
    :return: full or relative path to the output video file
    """
    fPath,fExt = path.splitext(vidIn)
    return fPath + '_Annotated' + fExt


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
    ts = datetime.strptime(ll[0], logTimeFmt)
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
    # TODO: see if there's a better way to get the start date for a video - prob need to have user input it
    vModDt = datetime.utcfromtimestamp(path.getmtime(vidIn)) # assuming this is date of end of file
    vidIn = cv2.VideoCapture(vidIn)
    fps = vidIn.get(cv2.CAP_PROP_FPS)
    frameW = int(vidIn.get(cv2.CAP_PROP_FRAME_WIDTH))
    frameH = int(vidIn.get(cv2.CAP_PROP_FRAME_HEIGHT))
    vDuration = timedelta(seconds=vidIn.get(cv2.CAP_PROP_FRAME_COUNT)/fps)
    vStartDt = vModDt - vDuration
    vidOut = cv2.VideoWriter(vidOut,cv2.CAP_FFMPEG,cv2.VideoWriter_fourcc(*'mp4v'),fps,(frameW,frameH),isColor=1)
    if verbose:
        len = vModDt - vStartDt
        print 'File starts at '+str(vStartDt)+', ends at '+str(vModDt)+' ('+str(int(len.total_seconds()/6.0)/10.0)+' mins long)'
    if test:
        cv2.namedWindow(testWin, cv2.WINDOW_NORMAL)
        cv2.resizeWindow(testWin,frameW,frameH)
    # TODO: make this robust enough to ditch the assumption that the temp log starts before and ends after the video file
    try:
        for nt in getTempIter(tempFile, useK):
            # only pay attention to temp logs within the range of time of the video
            # once nt is in range of video, lt will still be available for first few frames
            # at end, include grace period in end so that nt will be properly processed as lt on a few extra loops
            if nt[0] >= vStartDt and nt[0] <= vModDt+grace:
                cont = True
                # process all frames between lt and nt
                while cont:
                    cont = processFrame(vidIn,vStartDt,vidOut,frameW,frameH,lt[0],lt[1],nt[0],nt[1],grace,test)
            lt = nt
    finally:
        if test:
            cv2.destroyWindow(testWin)
        vidIn.release()
        vidOut.release()


def processFrame(vidIn, vidStartDt, vidOut, fw, fh, prevTempDt, prevTemp, currTempDt, currTemp, grace, test):
    """Processes the next frame of the video

    :param vidIn: VideoCapture object representing the original unannotated video
    :param vidStartDt: the datetime representing the start of the video
    :param vidOut: VideoWriter object representing the file to which frames should be written
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
    rv, frame = vidIn.read()
    frameDt = vidStartDt + timedelta(milliseconds=vidIn.get(cv2.CAP_PROP_POS_MSEC))
    # use previous temp if frame is between previous and current temp logs
    if rv and prevTempDt < frameDt and frameDt < currTempDt:
        cont = True # still between previous and current logs - keep reading frames for same temp log
        annotateFrame(frame, frameDt, prevTemp, fw, fh) if frameDt < prevTempDt+grace else warnMissingTemp(prevTempDt,currTempDt,frameDt)
    else:  # once you advance to a frame later than nt (or run out of frames), stop advancing
        cont = False;
        # still need to write a temp to the last frame read - check still w/in grace period of current log
        if rv and currTempDt <= frameDt and frameDt <= currTempDt + grace:
            annotateFrame(frame, frameDt, currTemp, fw, fh)
    # if you got a frame, write to output whether you annotated or not
    if rv:
        writeFrame(vidOut,frame) if not test else showFrame(frame)
    return cont


def warnMissingTemp(prevTempDt, currTempDt, frameDt):
    if verbose:
        print 'Frame at '+frameDt.strftime(warnFmt)+' not annotated'
        print '\tprevious log at '+prevTempDt.strftime(warnFmt)
        print '\tcurrent log at '+currTempDt.strftime(warnFmt)


def getAnnotationLoc(fw, fh, ar, ab, annotation, aScale, aThickness):
    """Calculates the location for temp string given a frame size and temperature string
    Places annotations at the bottom right of the adjusted frame size

    :param fw: width  of frame in pixels
    :param fh: height of frame in pixels
    :param ar: the total width of any annotations to the right of this one, in pixels
    :param ab: the total height of any annotations below this one, in pixels
    :param annotation: string with annotation to be added
    :param aScale: scale of the annotation text
    :param aThickness: thickness of the annotation text
    :return: tuple with the location for the text in a frame plus the width and height of the text
    """
    (w,h),_ = cv2.getTextSize(annotation, font, aScale, aThickness)
    # pad the width a bit so the last character doesn't look chopped off
    return (fw - ar - w - 10, fh - ab - h), w, h


def annotateFrame(frame, frameDt, tempStr, fw, fh):
    """Annotates a single frame of a video - temp in lower right corner of the frame

    :param frame: the frame object to be annotated
    :param frameDt: the calculated date of the frame
    :param tempStr: the string to add to the frame
    :param fw: width in pixels of frames in this video
    :param fh: height in pixels of frames in this video
    """
    # add date string at very bottom
    dStr = frameDt.strftime(annotateFmt)
    dloc,_,dh = getAnnotationLoc(fw,fh,0,0,dStr,dfScale,dfThickness)
    cv2.putText(frame,dStr,dloc,font,dfScale,blue,dfThickness)
    # add temp string just above the date
    tloc,_,_ = getAnnotationLoc(fw,fh,0,dh,tempStr,tfScale,tfThickness)
    cv2.putText(frame, tempStr, tloc, font, tfScale, blue, tfThickness)


def writeFrame(vidOut, frame):
    """Writes a frame to the specified video file

    :param vidOut: a VideoWriter object representing the output file
    :param frame: the annotated frame to write
    """
    vidOut.write(frame)


def showFrame(frame):
    """Displays the annotated frame in the test window
    Waits 10 ms before returning (this will display annotated video at ~3x speed)

    :param frame: the frame to display
    """
    cv2.imshow(testWin, frame)
    cv2.waitKey(10)


def main():
    parms = getParms()
    # TODO: figure out a way to stop immediately for a file that is already annotated
    annotateVideo(parms['vidIn'],parms['vidOut'],parms['tempLog'],parms['grace'],parms['useK'],testMode)


verbose = False
testMode = False
logTimeFmt = '%Y-%m-%d %H:%M:%S %Z'
annotateFmt = '%-d %b %H:%M:%S UTC'
warnFmt = '%Y-%m-%d %H:%M:%S'
C2K = 273.15
blue = (255,0,0)
font = cv2.FONT_HERSHEY_SIMPLEX
tfScale = 2
tfThickness = 3
dfScale=.5
dfThickness=2
testWin = 'annotation test'


if __name__ == '__main__':
    main()

