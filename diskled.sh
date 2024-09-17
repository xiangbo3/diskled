#!/usr/bin/env bash
#####################################################################################
##
## Hard disk activity monitor in console
##
##         Copyright (c) 2024, xiangbo@foxmail.com
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
## Update log:
## - v0.3
##    FreeBSD support added
##

### version
ver="v0.3"
ver_name="Hard Disk LED ${ver} / by xiangbo"
ver_line="-------------------------------"

## READ color / green
r_color='\033[0;32m'
## WRITE color / red
w_color='\033[0;31m'
## clear colors
no_color='\033[0m'

### OS Version
OS="Linux"
uname -a|grep ^FreeBSD > /dev/null
ret=$?
if [ "$ret" -eq 0 ]; then
	OS="FreeBSD"
fi

## set variables
if [ "$OS" = "FreeBSD" ]; then
	disks=$(sysctl kern.disks|awk -F ': ' '{print $2}')
else 
	disks=$(lsblk -d | tail -n+2 | grep -v '^ ' | awk '{print $1}')
fi

for d in $disks; do
	eval "${d}_r0=0"
	eval "${d}_w0=0"
done

### show title
show_title() {
  clear
  echo 
  echo -e "\t $ver_name"
  echo -e "\t $ver_line"
}

show_title

## loop
while [ 1 ]; do

    ## clear every 10 seconds
    now=$(date "+%s")
    if [ $(($now % 10)) -eq 0 ]; then
	    show_title
    fi

    ##move cursor
    echo -ne '\033[4;1H'

    for d in $disks; do

	if [ "$OS" = "FreeBSD" ]; then
		dsk="${d}"
		stats=$(iostat -dxI $dsk|grep $d)
		r1=$(echo $stats | awk '{print $2}')
		w1=$(echo $stats | awk '{print $3}')
		r1=${r1%.*}
		w1=${w1%.*}
	else
		dsk="/sys/block/${d}/stat"
		stats=$(cat $dsk) stat=($stats)
		r1="${stat[0]}"
		w1="${stat[4]}"
	fi

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

    sleep 1

done
