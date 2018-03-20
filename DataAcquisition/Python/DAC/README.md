# Using readMeter.py

`readMeter.py` is designed to poll readings from an Omega DP41-B-EI, but may work with other Omega models as well.
It is designed to work with Python 2, and has not been tested with Python 3.

Log files will be created in an experiment-specific directory.    
Output are tab-delimited text files with 2 columns: 
* date and time in UTC with format `yyyy-MM-dd hh:mm:ss z` (this is the Matlab format string)
* uncorrected meter reading

## Setup
1. Install Python and the [pycurl](http://pycurl.io/) and [matplotlib](https://matplotlib.org/) libraries.
2. Create or select a directory to store temperature logs for all experiments.  The computer on the DAC side of the lab currently uses `/Users/labimac/Documents/TLog`, but any location is acceptable. 
3. Copy readMeter.py script to this directory.  

## Usage
1. To call the script, open Terminal. 
2. Start the script with the following command in Terminal - values that must be specified by the user are enclosed in <>.  [Parameters](#parameters) are documented below.
    `python <relative path>/readMeter.py -x <expName> <optional parameters>`
3. A window will open that displays a graph of readings over the specified lookback interval.  Note that time in this graph is in local time of the computer where the script is running, although the log files will be in UTC time. 
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
| `-v`      | *off*     | toggles verbose output.  This is limited to echoing the parameters and reporting problems in reading data from the meter (which happens from time to time in the normal course of operations).  If this parameter is included, verbose output will be provided.  If the parameter is not provided, the script will run silently, although catastrophic failures will still be reported, and the plot will still be created.  Typically, use this parameter if logging is not occurring - it will let you know pretty quickly if every read attempt is failing. |
| `-y <lbl>`| 'temp (C)' | the label used on the y-axis on the plot created by this script.  This allows different units of measurement to be used or different quantities to be measured (since the DP41-B supports several different types of sensors). |  
| `-p <dir>`| current working directory (as given by `pwd`) | relative path to parent directory for meter logs.  Paths that include spaces may require escaping as well as quotes - test this first if you absolutely need to use a path with spaces. | 
| `-u <url>`| '192.168.1.200:2000' | url from which data will be read.  Do not use unless you have set up a non-default IP address for your meter. | 
| `-r <cmd>`| 'X01' | read command to send to meter.  Do not use without thorough understanding of commands sent to the meter.  See [the DP41-B-EI manual](https://www.omega.com/manuals/manualpdf/M2549.pdf) for details. |
| `-t`      | *off* | toggle that turns test mode on.  for use only during development - runs the script without calling the meter (so testing can be done away from the lab) and just makes up data to test other parts of the script. |

# Requested enhancements
* Matlab script to import logs for an experiment.  Should have option for imported time to be in the local time zone
* Plot should be 2 sub plot, one with total time record for the file and one with just the last 30 minutes.
* Make a script that incorporate the temperature in a video from a temperature logfile (add temperature reading to every frame from )

# Using annotateCrystalVideo.py

## Setup
1. Install XCode from the App Store, then run `xcode-select --install` in Terminal to install tools
1. [Install](https://superuser.com/questions/624561/install-ffmpeg-on-os-x#624562) [ffmpeg](https://ffmpeg.org/)
1. Install [Python 2](https://www.python.org/downloads/mac-osx/)
1. Install the [opencv](https://docs.opencv.org/master/index.html) library using `pip install opencv-python` (this also installs [numpy](http://www.numpy.org/))
1. Copy annotateCrystalVideo.py to your computer

## Usage
1. To call script, open Terminal
1. Start the script with the following command in Terminal - values that must be specified by the user are enclosed in <>.  [Parameters](#parameters) are documented below.
    `python <relative path>/annotateCrystalVideo.py -i <videoToAnnotate> -l <tempLog> <optional parameters>`

## Parameters
### Required parameters
* `-i` full or relative path to the mp4 file to be annotated
* `-l` full or relative path to the temperature log file that has the temperatures for the video.  __Warning__: the script assumes that the temperature log begins before and ends after the video.  It may not work properly if those conditions are not met.

### Optional parameters
| parameter | default | description |
|:---------:|:-------:|:----------- |
| `-o` <path> | same path as `-i` but with _Annotated appended to file name before its extension | full or relative path to the annotated video file |
| `-g` <int> | 10 | grace period beyond which temperature is assumed to be the same as the last available temperature, in seconds |
| `-m` <str> | 'n/a' | string to use for annotation if T is missing (usually because grace period is exceeded between two temperature logs |
| `-d` | *T only* | add this flag to include date and time in the annotation along with the temperature |
| `-k` | *°C* | add this flag to get temperature output in Kelvin |
| `-v` | *off* | verbose mode |
| `-t` | *off* | test mode - displays video with annotation but does not save it |


