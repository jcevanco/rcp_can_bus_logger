#!/bin/sh
# RCP CAN Bus Logger Scripts
# Copyright (c) 2023 The SECRET Ingredient!
# GNU General Public License v3.0
#
# https://thesecretingredient.neocities.org
# https://github.com/jcevanco/rcp_can_bus_logger.git
#
# This is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# 
# See the GNU General Public License for more details. You should
# have received a copy of the GNU General Public License along with
# this code. If not, see <http://www.gnu.org/licenses/>.
#
# This script captures the device log from a RaceCapture device that
# is connected to a USB serial port.
#
# ------------------------------------------------------------------------------
# IMPORTANT: Simultaneously Press the Control and C Keys to End the Capture
# ------------------------------------------------------------------------------
# CONFIGURATION ... Set Values as Required

# Set the Log Directory (Relative Path from Execution Directory)
dir='./logs'

# Get a Timestamp to be Used for File Creation -- Format YYYY-MM-DD HH.MM.SS
time_stamp=`date '+%Y-%m-%d %H.%M.%S'`

# Define the Full Log Filename with Date/Timestamp
filename="rcp_cap ${time_stamp}.txt"

# Define the Name (or File Naming Expression) of the USB Device that will be
# Used to Connect to the RaceCapture Device
device='/dev/cu\.usbmodem*'

#Define End-of-Line Chracter
eol="\r"

# ------------------------------------------------------------------------------
# END OF USER CONFIGURATION SETTINGS
# ------------------------------------------------------------------------------

# Process Command Line Options
show_in_terminal='0'
while true
do
	# Test Parameters
	case $1 in 
		('') 
			break
			;;

		('-h')
			echo \
'
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
			;;

		('-s') 
			show_in_terminal='1'
			shift
			;;
	esac
done

# Get the RaceCapture Device Port
port=`ls $device`

# Test the RaceCapture Port Device
if test ! -c $port
then
   echo 'The DEVICE setting did not resolve to a valid (character special) file'
   exit 1
fi

# Create the Log File and Start RaceCapture LogViewer
touch "$dir/$filename"

# Wake Up the RaceCapture Device and Initiate the Log Capture
echo $eol > $port; read R < $port
echo "viewLog$eol" > $port; read R < $port

# Display Header Information when Logging Starts
case $show_in_terminal in
	('0')
		echo "Here's a bit of logging to see whether the capture is working ..."
		echo '----------------------------------------------------------------------'
		head -n 5 < $port
		echo '----------------------------------------------------------------------'
		echo 'Now sending the log to the file ...'
		echo "Simultaneously press the control and C keys to end the capture ...\n"
		;;
	('1')
		echo "\nSimultaneously press the control and C keys to end the capture ...\n"
		;;
esac

# Interrupt Handler
function doExit()
{
	echo "\nQuitting ..."
	echo "q$eol" > $port
	exit 0
}

# Trap [ctrl]+c Signal to End Log Capture
trap doExit TERM INT

# Push the Port Data Stream to the Log File Untill Interrupted
while true
do
	case $show_in_terminal in
		('0') 
			cat < $port >> "$dir/$filename"
			;;
		('1') 
			cat < $port | tee -a "$dir/$filename"
			;;
	esac
done
