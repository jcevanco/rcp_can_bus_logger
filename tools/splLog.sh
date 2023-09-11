#!/bin/sh
#set -x  ## Uncomment to get a trace
# (tabs are 3-spaces in width)

# 2020-Sep-12
# This material is free and withhout warranty.  Use it in any way you see fit.

# This script is designed to split a collection of CAN-message records that have
# been sorted and grouped by CAN ID or PID into a collection of files where each
# file contains the CAN messages for a single CAN ID or PID.

# ------------------------------------------------------------------------------
# set regular expressions (REs) for valid CAN-message and time-sync line formats
# ------------------------------------------------------------------------------
# valid hexadecimal-format CAN message without date/time-stamp (short format)
HEX_CAN='[0-9]{4}(-[0-9]{2}){2} ([0-9]{2}:){2}[0-9]{2}\.[0-9]{3} [0-9 ]{8}[0-9]  [12]  [0-9 ]*[0-9]  0x[0-9A-F]{1,8}  [0-9A-F ][0-9A-F]  ([0-9A-F]{2} ){1,8} [0-9][0-9]* ms  [0-9][0-9]* ms'
#
# valid hexadecimal-format CAN message with full date/time-stamp (long format)
HEX_PID='[0-9]{4}(-[0-9]{2}){2} ([0-9]{2}:){2}[0-9]{2}\.[0-9]{3} [0-9 ]{8}[0-9]  [12]  [0-9 ]*[0-9]  0x[0-9A-F]{1,8}  [0-9 ]*[0-9]  0x[0-9A-F]{1,8}  [0-9A-F ]{2}[0-9A-F]  ([0-9A-F]{2} ){1,8} [0-9][0-9]* ms  [0-9][0-9]* ms'
#
# valid decimal-format CAN message without date/time-stamp (short format)
DEC_CAN='[0-9]{4}(-[0-9]{2}){2} ([0-9]{2}:){2}[0-9]{2}\.[0-9]{3} [0-9 ]{8}[0-9]  [12]  0x[0-9A-F]{1,8}  [0-9 ]*[0-9]  [0-9 ]{2}[0-9]  ([0-9]{3} ){1,8} [0-9][0-9]* ms  [0-9][0-9]* ms'
#
# valid decimal-format CAN message with full date/time-stamp (long format)
DEC_PID='[0-9]{4}(-[0-9]{2}){2} ([0-9]{2}:){2}[0-9]{2}\.[0-9]{3} [0-9 ]{8}[0-9]  [12]  0x[0-9A-F]{1,8}  [0-9 ]*[0-9]  0x[0-9A-F]{1,8}  [0-9 ]*[0-9]   [0-9 ]{2}[0-9]  ([0-9]{3} ){1,8} [0-9][0-9]* ms  [0-9][0-9]* ms'
#
# valid time-sync record with ONLY full date/time-stamp plus upTime
TIME_SYNC='[0-9]{4}(-[0-9]{2}){2} ([0-9]{2}:){2}[0-9]{2}\.[0-9]{3} [0-9]{1,9}'
# ------------------------------------------------------------------------------

INCLUDE_BUS_NUM="0"

# quick 'n dirty options parsing
while true
do
	if test "$1" = '-h'
	then
		echo '
Synopsis: splitIntoIDfiles.sh [-h][-b] <log file pathname>
   where: -h : prints this help message, then exits
          -b : start all ID filenames with "Bus_<bus number>-"
          <log pathname>: provides a log file to be processed
Description:
This script will split a "-sorted" CAN or PID message file that was created by
processCANmsgLogs.sh into multiple files where each file contains ONLY the CAN
messages for a single CAN ID or PID.  This can (CAN?) be useful when you want to
assign formulas to CAN messages and compute values when attempting to reverse
engineer their usage/meaning.

The files that are created by this script are named either:
- PID-<PID decimal number>-<PID hex number>.txt
- CANid-<CAN ID decimal number>-<CAN ID hex number>.txt
... or, if the -b option was specified:
- Bus-<bus number>_PID-<PID decimal number>-<PID hex number>.txt
- Bus-<bus number>_CANid-<CAN ID decimal number>-<CAN ID hex number>.txt
'
		exit 1
	fi

	if test "$1" = '-b'
	then
		INCLUDE_BUS_NUM='1'
		shift
		continue
	fi

	break
done

# get the file pathname, it's base filename & suffix and containing directory
FILE_PATHNAME="$1"
FILE_NAME=`/usr/bin/basename "$FILE_PATHNAME" | \
														/usr/bin/sed -e 's/^\(.*\)\..*$/\1/'`
FILE_SUFFIX=`/usr/bin/basename "$FILE_PATHNAME" | /usr/bin/fgrep '.' | \
														/usr/bin/sed -e 's/^.*\(\..*\)$/\1/'`
DIR=`/usr/bin/dirname "$FILE_PATHNAME"`
#echo "SCRIPT_NAME = $SCRIPT_NAME"
#echo "SCRIPT_SUFFIX = $SCRIPT_SUFFIX"

# ensure the file exists
if test ! -f "$FILE_PATHNAME"
then
	echo '\nThe file:'
	echo "$FILE_PATHNAME"
	echo 'is not valid, quitting ...'
	exit 1
fi

# ensure the file is in the required pre-processed format
if test "`echo $FILE_NAME | \
								/usr/bin/grep -e '-CANidsSorted' -e '-PIDsSorted'`" = ''
then
	echo '\nThe file:'
	echo "$FILE_PATHNAME"
	echo 'is not a sorted CAN or PID message file ... quitting'
	exit 1
fi

echo "\nProcessing '${FILE_NAME}$FILE_SUFFIX' ..."

# determine the CAN-message format:
MSG_FORMAT=`
	/bin/cat "$FILE_PATHNAME" | /usr/bin/tr "\r" "\n" | \
	/usr/bin/sed -e '/^$/d' | \
	/usr/bin/egrep -e '^'"$HEX_CAN"'$' -e '^'"$HEX_PID"'$' \
						-e '^'"$DEC_CAN"'$' -e '^'"$DEC_PID"'$' | \
	/usr/bin/head -n 1 | \
	/usr/bin/awk '
	{ 
		# determine the format of the CAN message
		if (index($6, "0x") == 1) {  # hex format
			isHex = 1
			msgNumType = "HEX"

			if (index($8, "0x") == 1) { msgKind = "PID"; fOffset = 2 }
			else { msgKind = "CAN"; fOffset = 0 }
		}
		else { # decimal format
			isHex = 0
			msgNumType = "DEC"

			if (index($7, "0x") == 1) { msgKind = "PID"; fOffset = 2 }
			else { msgKind = "CAN"; fOffset = 0 }
		}

		# the number of fields should be:
		# field offset + 7 + the number of message-data bytes + 4
		if (isHex == 1) { numDataBytes = sprintf("%d", "0x"$(fOffset + 7)) }
		else { numDataBytes = $(fOffset + 7) }

		# ensure the number of fields is valid
		if (NF == (fOffset + 7 + numDataBytes + 4)) {  # valid message format
			print msgNumType"-"msgKind
		}
		else {  # invalid message format
			print "Invalid CAN-message format: "$0
		}
	}'`
#echo "MSG_FORMAT = $MSG_FORMAT"

# set the "valid message format" RE kind, the "is short format" and "is hex"
# indicators and the "field offset" for the current CAN-message format
case "$MSG_FORMAT" in
	'HEX-CAN')
		CURRENT_MSG_RE="$HEX_CAN"
		IS_PID_MSGS='0'
		#IS_HEX_FORMAT='1'
		#FO=0
	;;
	'HEX-PID')
		CURRENT_MSG_RE="$HEX_PID"
		IS_PID_MSGS='1'
		#IS_HEX_FORMAT='1'
		#FO=-2
	;;
	'DEC-CAN')
		CURRENT_MSG_RE="$DEC_CAN"
		IS_PID_MSGS='0'
		#IS_HEX_FORMAT='0'
		#FO=0
	;;
	'DEC-PID')
		CURRENT_MSG_RE="$DEC_PID"
		IS_PID_MSGS='1'
		#IS_HEX_FORMAT='0'
		#FO=-2
	;;
	'')
		echo "\nNo valid CAN messages were found ... quitting"
		exit 1
	;;
	*)
		echo "\n$MSG_FORMAT"
		echo 'The first CAN message was not valid ... quitting'
		exit 1
	;;
esac
#echo "IS_HEX_FORMAT = $IS_HEX_FORMAT"
#echo "IS_PID_MSGS = $IS_PID_MSGS"
#echo "FO = $FO"

# select only records that appear to have the correct fields
/usr/bin/egrep -e '^'"$CURRENT_MSG_RE"'$' "$FILE_PATHNAME" | \
/usr/bin/awk '
	BEGIN {
		directory = "'"$DIR"'"
		isPIDmsgs = "'"$IS_PID_MSGS"'"
		includeBusNum = '$INCLUDE_BUS_NUM'

		currID = ""
		prevID = ""
		prevBusNum = 0
		outPathname = ""
		processedIDlist = ""
	}
	{
		currBusNum = $4

		if (isPIDmsgs == "1") { currID = sprintf("%d", $7); typeName = "PID" }
		else { currID = sprintf("%d", $5); typeName = "CANid" }

		if ((currID != prevID) || \
			 ((includeBusNum == 1) && (currBusNum != prevBusNum))) {
			if (outPathname != "") {
				close(outPathname)

				# if required, keep track of IDs processed
				if (includeBusNum == 0) {
					processedIDlist = processedIDlist","prevID
				}

				# if files are not separated by bus, sort the output file by upTime
				if (includeBusNum == 0) {
					system("/usr/bin/sort -g -k 3,3 -o '\''"outPathname"'\'' '\''"outPathname"'\''")
				}
			}

			if (includeBusNum == 1) {
				fileName = sprintf("Bus-%d_%s-%d-0x%X.txt", \
										 currBusNum, typeName, currID, currID)
			}
			else { fileName = sprintf("%s-%d-0x%X.txt", typeName, currID, currID) }

			outPathname = sprintf("%s/%s", directory, fileName)

			# if applicable, allow for multiple-bus output to same file
			if ((includeBusNum == 1) || ((includeBusNum == 0) && \
				 (index(","processedIDlist",", currID) == 0))) {

				system("/bin/echo -n > '\''"outPathname"'\''")  # create empty file
			}

			printf("Processing [Bus %s] %s: ID %s ==> %s\n", \
					 currBusNum, typeName, currID, fileName)
			prevID = currID
			prevBusNum = currBusNum
		}

		print $0 >> outPathname
	}
	END {
		# if files are not separated by bus, sort the final output file by upTime
		if (includeBusNum == 0) {
			system("/usr/bin/sort -g -k 3,3 -o '\''"outPathname"'\'' '\''"outPathname"'\''")
		}
	}'
