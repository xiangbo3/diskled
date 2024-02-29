#!/bin/bash
###############################################
## Hard disk activity monitor in console
##
##                      by xiangbo@foxmail.com
##
##      Copyright 2024, all rights reserved.
##############################################
##
##
### version
ver_name="Hard Disk LED v0.1 / by xiangbo"
ver_line="-------------------------------"

## READ color
r_color='\033[0;32m'
## WRITE color
w_color='\033[0;31m'
## clear color
no_color='\033[0m'

## set variables
disks=$(lsblk -d | tail -n+2 | awk '{print $1}')
for d in $disks; do
	eval "${d}_r0=0"
	eval "${d}_w0=0"
done

### show title
clear
echo 
echo -e "\t $ver_name"
echo -e "\t $ver_line"

## loop
while [ 1 = 1 ]; do

    ##move cursor
    echo -ne '\033[4;1H'

    for d in $disks; do

	dsk="/sys/block/${d}/stat"

	stats=$(cat $dsk) stat=($stats)

	r1="${stat[0]}"
	w1="${stat[4]}"

	eval 'r0=$'${d}_r0
	eval 'w0=$'${d}_w0

	rout="    "
	wout="     "

	if [ $r0 != $r1 ] && [ $r0 != 0 ]; then
		rout="READ"
	fi
	if [ $w0 != $w1 ] && [ $w0 != 0 ]; then
		wout="WRITE"
	fi

	eval "${d}_r0=${r1}"
	eval "${d}_w0=${w1}"

	### output led status
	echo -ne "\t $d | $r_color $rout \t $w_color $wout $no_color \n"

    done
    
    ## show time
    echo -e "\t $ver_line"
    now=$(date "+%Y-%m-%d %H:%M:%S")
    echo -ne "\t $now \n\n"

    sleep 0.5

done
