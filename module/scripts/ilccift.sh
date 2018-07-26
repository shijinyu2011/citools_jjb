#!/bin/bash
# retry checkout ILCCI script 3 times
retry=0
while [ $retry -lt 3 ]; do
	svn co --non-interactive https://svne1.access.nokiasiemensnetworks.com/isource/svnroot/citools/scripts/branches/ILCCI_B2/ ILCCI
	if [ $? -eq 0 ]; then
		break;
	fi
        rm -fr ILCCI
	retry=$(($retry+1))
done

if [ $retry -eq 3 ]; then
 exit 1
fi
