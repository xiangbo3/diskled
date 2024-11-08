#!/bin/sh

#####################################################################################
#####################################################################################
##
## Hard disk activity monitor in console
##
##         Copyright (c) 2024 Xiang Bo <xiangbo@foxmail.com>
##         All rights reserved.
##
## Redistribution and use in source and binary forms, with or without
## modification, are permitted provided that the following conditions are met:
## 1. Redistributions of source code must retain the above copyright notice, this
##    list of conditions and the following disclaimer.
## 2. Redistributions in binary form must reproduce the above copyright notice,
##    this list of conditions and the following disclaimer in the documentation
##    and/or other materials provided with the distribution.
##
## THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
## AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
## IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
## DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
## FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
## DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
## SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
## CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
## OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
## OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
##
#####################################################################################
#####################################################################################

## Update log:
## - v0.7
#    Remove bash dependencies, now script is run by sh.
## - v0.6
#    Add DragonFlyBSD support.
## - v0.5
#    Add NetBSD support.
## - v0.4
#    Add OpenBSD support.
## - v0.3
#    Add FreeBSD support.
## - v0.2
#    Modify to work with line update.
## - v0.1
#    Works in linux os.
##

### version
ver="v1.0"
ver_name="Disk LED ${ver} / by xiangbo"
ver_line="--------------------------"

## WRITE color / red
w_color='\033[0;31m'
## READ color / green
r_color='\033[0;32m'
## READ & WRITE color / yellow
rw_color='\033[0;33m'
## clear colors
no_color='\033[0m'

### title
show_title() {
  clear
  echo 
  echo " $ver_name"
  echo " $ver_line"
}

### OS Version
OS=$(uname)

### Echo -e function
## test if echo needs -e parameter
## freebsd netbsd dragonflybsd need -e
ECHO_E="no"
if [ "Yes\n" = $(echo "Yes\n") ]; then
  ECHO_E="yes"
fi

echo_e() {
  if [ "$ECHO_E" = "yes" ]; then
	echo -e "$@"
  else
	echo "$@"
  fi
}

### Name function
NAME_MAX=0
name_fit() {
  name="$1"
  while [ ${#name} -lt $NAME_MAX ]; do
    name="${name} "
  done
  echo "${name}"
}

## Set variables
if [ "$OS" = "FreeBSD" ]; then
	disks=$(sysctl -n kern.disks)
elif [ "$OS" = "OpenBSD" ]; then
	foo=$(sysctl -n hw.disknames)
	old_ifs="${IFS}"
	IFS=','
	disks=""
	for d in $foo; do
		if [ -z $disks ]; then
			disks="${d%:*}"
		else
			disks="$disks ${d%:*}"
		fi
	done
	IFS="${old_ifs}"
elif [ "$OS" = "NetBSD" ]; then
	disks=$(sysctl -n hw.disknames) 
elif [ "$OS" = "DragonFly" ]; then
	disks=$(sysctl -n kern.disks)
elif [ "$OS" = "Linux" ]; then
	disks=$(lsblk -d | tail -n+2 | grep -v '^ ' | awk '{print $1}')
else
	echo "OS not supported"
	exit
fi

### set NAME_MAX
for d in $disks; do
	if [ ${#d} -gt $NAME_MAX ]; then
	    NAME_MAX=${#d}
	fi
	eval "${d}_r0=0"
	eval "${d}_w0=0"
done

### Cleanup function
cleanup () {
    tput cnorm
    exit
}

## signal handle
trap cleanup EXIT INT ABRT KILL TERM SIGINT

## hiden cursor
clear
tput civis

## print title
show_title

## loop
while [ 1 ]; do

    ## clear every 15 seconds
    now=$(date "+%s")
    if [ $(($now % 15)) -eq 0 ]; then
	    show_title
    fi

    ## move cursor
    echo_e '\033[3;1H'

    for d in $disks; do

	if [ "$OS" = "FreeBSD" ]; then
		dsk="${d}"
		stats=$(iostat -dxI $dsk|grep $d)
		r1=$(echo $stats | awk '{print $2}')
		w1=$(echo $stats | awk '{print $3}')
		r1=${r1%.*}
		w1=${w1%.*}
	elif [ "$OS" = "OpenBSD" ]; then
		stats=$(iostat -dI $d|tail -n1)
		r1=$(echo $stats | awk '{print $2}')
		w1=0
		#w1=$(echo $stats | awk '{print $2}')
	elif [ "$OS" = "NetBSD" ]; then
		stats=$(iostat -dxI $dsk|grep $d)
		r1=$(echo $stats | awk '{print $3}')
		w1=$(echo $stats | awk '{print $7}')
	elif [ "$OS" = "DragonFly" ]; then
		## skip virtual disk
		if [ "${d#vn*}" != "${d}" ]; then
			continue
		fi
		stats=$(iostat -dI $d|tail -n1)
		r1=$(echo $stats | awk '{print $2}')
		w1=0
		#w1=$(echo $stats | awk '{print $2}')
	elif [ "$OS" = "Linux" ]; then
		dsk="/sys/block/${d}/stat"
		stats=$(cat $dsk)
		r1=$(echo $stats | awk '{print $1}')
		w1=$(echo $stats | awk '{print $5}')
		#r1="${stat[0]}"
		#w1="${stat[4]}"
	fi

	eval 'r0=$'${d}_r0
	eval 'w0=$'${d}_w0

	rout="    "
	wout="     "

	if [ $r0 != $r1 ] && [ $r0 != 0 ]; then
	    if [ "$OS" = "OpenBSD" ]; then
		rout="[//]"
		r_color=$rw_color
	    elif [ "$OS" = "DragonFly" ]; then
		rout="[//]"
		r_color=$rw_color
	    else
		rout="READ"
	    fi
	fi
	if [ $w0 != $w1 ] && [ $w0 != 0 ]; then
		wout="WRITE"
	fi

	eval "${d}_r0=${r1}"
	eval "${d}_w0=${w1}"

	### output led status
	echo_e " $(name_fit $d) | $r_color $rout \t $w_color $wout $no_color "

    done
    
    ## show time
    echo " $ver_line"
    now=$(date "+%Y-%m-%d %H:%M:%S")
    echo " $now "

    sleep 0.5

done
