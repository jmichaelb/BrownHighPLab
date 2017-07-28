import sys, getopt, re
opts, args = getopt.getopt(sys.argv[1:],"r:o:")
for opt, arg in opts:
  if opt == '-r':
    extractPattern = arg
  elif opt == '-o':
    rawOutput = arg
meterRead = re.search(extractPattern,rawOutput)
print float(meterRead.group(0))

