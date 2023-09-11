#!/bin/sh

# 2020-Jul-17
# This material is free and withhout warranty.  Use it in any way you see fit.

# "quick 'n dirty" script to capture the log from a RaceCapture unit that's
# connected via a USB port

# ------------------------------------------------------------------------------
# IMPORTANT: simultaneously press the control and C keys to end the capture
# ------------------------------------------------------------------------------
# CONFIGURATION ... set values as required

# define the directory into which logs are to be captured
DIR='logs'

# get a timestamp to be used for file creation -- format YYYY-MM-DD HH.MM.SS
# (can't use colons in Mac filenames!)
TIMESTAMP=`/bin/date '+%Y-%m-%d %H.%M.%S'`

# define the logfile name
LOG_FILENAME="Data ${TIMESTAMP}.txt"

# define the name (or file-naming expression) of the USB device that will be
# used to connect to the RaceCapture device
DEVICE='/dev/cu\.usbmodem*'

# END OF CONFIGURATION SETTINGS
# ------------------------------------------------------------------------------

# define the EOL sequence
EOL="\r"

# find the RaceCapture port
PORT=`/bin/ls $DEVICE`

# ensure the DEVICE resolved to a valid device
if test ! -c "$PORT"
then
   echo 'The DEVICE setting did not resolve to a valid (character special) file'
   exit 1
fi

SHOW_IN_TERMINAL='0'

# handle the options
while true
do
	if test "$1" = ''
	then
		break
	fi

	if test "$1" = '-h'
	then
		echo '
   Synopsis: captureRClog.sh [-h|-s]
      where: -h : prints this help message, then exits
             -s : also show the log-capture in the terminal window ... note that
                  this may cause problems for high-rate, long-duration captures
Description: Captures the log from a USB-connected RaceCapture unit
      NOTEs:
      - this command must be run with root-level privileges
      - simultaneously press the control and C keys to end the capture
'
		exit
	fi

	if test "$1" = '-s'
	then
		SHOW_IN_TERMINAL='1'
		shift
	fi
done

# define the interrupt/"quit receiving" handler
function doExit()
{
	echo "q$EOL" > "$PORT"
	exit
}
#
trap 'echo "${EOL}Quitting ..." ; doExit ; exit' TERM INT

# create an empty capture file
/bin/echo -n > "$DIR/$LOG_FILENAME"

# wake up the RaceCapture device
echo "$EOL" > "$PORT"
read R < "$PORT"

# send the viewLog command
echo "viewLog$EOL" > "$PORT"
read R < "$PORT"

# when the log is not being shown in the terminal, show a little to verify that
# the capture is working
if test "$SHOW_IN_TERMINAL" = '0'
then
	echo "Here's a bit of logging to see whether the capture is working ..."
	echo '----------------------------------------------------------------------'
	/usr/bin/head -n 5 < "$PORT"
	echo '----------------------------------------------------------------------'
	echo 'Now sending the log to the file ...'
	echo "Simultaneously press the control and C keys to end the capture ...\n"
else
	echo "\nSimultaneously press the control and C keys to end the capture ...\n"
fi

# read/save the log data until interrupted
while true
do
	if test "$SHOW_IN_TERMINAL" = '0'
	then
		/bin/cat < "$PORT" >> "$DIR/$LOG_FILENAME"
	else
		/bin/cat < "$PORT" | /usr/bin/tee -a "$DIR/$LOG_FILENAME"
	fi
done
