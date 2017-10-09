#!/usr/local/bin/python3

import os
from glob import glob
from csv import reader, writer
from datetime import datetime

dtFormat = '%I:%M:%S.%f %p %m/%d/%Y ' # '12:48:03.486 PM 5/18/2016'
corrFileTemplate = '_CH1_CH2_Corr.txt'
aTdT = 5.4545E-3
zeroCinK = 273.15

def loadTabDelim(fName, floatCols, dtCol=0):
    with open(fName) as f:
        rdr = reader(f, delimiter='\t')
        tmp = list(rdr)
        return [(datetime.strptime(t[dtCol],dtFormat),) + tuple([f for f in map(float,t[floatCols])]) for t in tmp]

def getTsOutput(dt):
    return dt.strftime('%-I:%M:%S.')+('%03d' % (dt.microsecond/1000))+' '+dt.strftime('%p %-m/%-d/%Y')

# load all CH0 files for the experiment
p0 = os.getcwd()+'/*_CH0.txt'
ch0Files = glob(p0)
ch0 = list()
for fp in ch0Files:
    ch0.extend(loadTabDelim(fp,floatCols=slice(3,4)))
ch0 = sorted(ch0, key=lambda t: t[0])

# for each CH1_CH2 file in the experiment
p2 = os.getcwd()+'/*_CH1_CH2.txt'
ch2Files = glob(p2)
for fp in ch2Files:
    print('Working on file '+fp.rsplit('/',1)[1])
    corrFName = fp[0:len(fp)-12]+corrFileTemplate
    # only proceed if a correction file hasn't already been created
    if not os.path.isfile(corrFName):
        ch1ch2 = loadTabDelim(fp,floatCols=slice(1,4))
        # skip if file has 4 cols (correction already exists)
        if len(ch1ch2[1]) == 3:
            # find the CH0 data that immediately precedes the CH1/CH2 timestamp
            refTemps = [max([ct for ct in ch0 if ct[0] < ch2[0]], key=lambda t: t[0]) for ch2 in ch1ch2]
            # ch0Ts, ch0, ch12Ts, ch1, ch2, ch2ConstCorr = ch2 - (ch1 - ch0)
            ch0ch1ch2 = [(td[0][0], td[0][1], td[1][0], td[1][1], td[1][2], td[1][2] - (td[1][1] - td[0][1]))  for td in list(zip(refTemps,ch1ch2))]
            # double check that none of the timestamps are more than 3 sec apart
            if max([(cd[2]-cd[0]).seconds for cd in ch0ch1ch2]) > 2:
                raise ValueError('At least one temperature lacks a reference in file {0}'.format(fp))
            # calculate correction ch2ConstCorr - aTdT * (ch2ConstCorr - ch0) - zeroCinK
            ch1ch2Corr = [(getTsOutput(td[2]), str(td[3]), str(td[4]), '%.6f' % (td[5] - aTdT*(td[5]-td[1])-zeroCinK)) for td in ch0ch1ch2]
            # export file
            with open(corrFName,'w') as f:
                try:
                    f.writelines('\t'.join(c)+'\n' for c in ch1ch2Corr)
                    print('\tAdded correction file '+corrFName.rsplit('/', 1)[1])
                except:
                    os.remove(corrFName)
        else:
            print('\tFile already contains corrected ch2')
    else:
        print('\tCorrection file already exists')

