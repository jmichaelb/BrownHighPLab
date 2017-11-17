# Using readMeter.py

`readMeter.py` is designed to poll readings from an Omega DP41-B-EI, but may work with other Omega models as well.
It is designed to work with Python 2, and has not been tested with Python 3.

Log files will be created in an experiment-specific directory.  Each calendar day (per UTC time) will have a different file in the directory.  
Output are tab-delimited text files with 2 columns: 
* date and time in UTC with format `yyyy-MM-dd hh:mm:ss z` (this is the Matlab format string)
* uncorrected temperature

## Setup
1. Install Python and [the pycurl library](http://pycurl.io/).
2. Create or select a directory to store temperature logs for all experiments.  The computer on the DAC side of the lab currently uses `/Users/labimac/Documents/TLog`, but any location is acceptable. 
3. Copy readMeter.py script to this directory.  

## Usage
1. To call the script, open Terminal. 
2. Start the script with the following command in Terminal - values that must be specified by the user are enclosed in <>.  [Parameters](#parameters) are documented below.
    `python <relative path>/readMeter.py -x <expName> <optional parameters>`
3. A window will open 
4. To stop the script, hit ⌘-C

## Parameters
### Required
The only required parameter is `-x <exp_name>`. With this parameter, you specify the experiment for which temperatures are being stored.  There should be no spaces in the parameter value, as temperature logs will be stored in a subdirectory of the current directory with the provided experiment name.

### Optional
Optional parameters are listed below, with the most likely to be used listed first.  Most parameters require a value, but a few are just toggles and do not require (indeed, do not allow) values.
*For parameters that take a string value, be sure to enclose in quotes if the string includes spaces.*

| parameter | default | description | 
|:---------:|:-------:|:----------- |
| `-i <int>`| 5       | the read interval in seconds.  value must be an integer |
| `-l <lkb>`| 2       | the lookback interval for plotting readings, in hours.  The value may be a float. |
| `-v`      | *off*     | toggles verbose output.  This is limited to echoing the parameters and reporting problems in reading data from the meter (which happens from time to time in the normal course of things.  If specified, verbose output will be provided.  If the parameter is not provided, the script will run silently, although catastrophic failures will still be reported, and the plot will still be created.  Typically, use this parameter if logging is not occurring - it will let you know pretty quickly if no every read attempt is failing. |
| `-y <lbl>`| 'temp (C)' | the label used on the y-axis on the plot created by this script.  This allows different units of measurement or different quantities to be measured. |  
| `-p <dir>`| current working directory (as given by `pwd`) | relative path to parent directory for meter logs.  Paths that include spaces may require escaping as well as quotes.  This has not been tested. | 
| `-u <url>`| '192.168.1.200:2000' | url from which data will be read.  Do not use unless you have set up a non-default IP address for your meter. | 
| `-r <cmd>`| 'X01' | read command to send to meter.  Do not use without thorough understanding of commands sent to the meter.  See [the DP41-B-EI manual](https://www.omega.com/manuals/manualpdf/M2549.pdf) for details. |
| `-t`      | *off* | Turns test mode on.  for use only during development - runs the script without calling the meter and just makes up data to test other parts of the logic. |

# Requested enhancements
* plot should display latest reading and time
* Matlab script to import logs for an experiment.  Should have option for imported time to be in the local time zone
