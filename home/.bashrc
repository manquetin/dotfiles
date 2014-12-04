# ============================================================================ #
# ${HOME}/.bashrc
#
# Based on Emmanuel Rouat's work
# http://tldp.org/LDP/abs/html/sample-bashrc.html
#
# This file is read by interactive shells only. Here is the place to define
# personal aliases, function or other interactive features like the prompt.
# ============================================================================ #

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# ---------------------------------------------------------------------------- #
# Source global definitions (if any)
# ---------------------------------------------------------------------------- #
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
elif [ -f /etc/bash.bashrc ]; then
    . /etc/bash.bashrc
fi

# ---------------------------------------------------------------------------- #
# DISPLAY
# ---------------------------------------------------------------------------- #
function get_xserver ()
{
    XSERVER=$(who -m | awk '{print $NF}' | tr -d ')''(' )
    XSERVER=${XSERVER%%:*}
}

if [ -z ${DISPLAY:=""} ]; then
    get_xserver
    if [[ -z ${XSERVER} || ${XSERVER} == $(hostname) || ${XSERVER} == "unix" ]];
    then
        DISPLAY=":0.0"          # Display on local host.
    else
        DISPLAY=${XSERVER}:0.0     # Display on remote host.
    fi
fi

export DISPLAY

# ---------------------------------------------------------------------------- #
# Settings
# ---------------------------------------------------------------------------- #
alias debug="set -o nounset; set -o xtrace"

ulimit -S -c 0 # Disable core dumps
set -o notify
set -o noclobber
set -o ignoreeof

shopt -s autocd
shopt -s cdspell dirspell
shopt -s cdable_vars
shopt -s checkhash
shopt -s checkjobs
shopt -s checkwinsize
shopt -s cmdhist
shopt -s histappend histreedit histverify
shopt -s globstar
shopt -s extglob

shopt -u mailwarn
unset MAILCHECK

# ---------------------------------------------------------------------------- #
# Dotfiles management
# ---------------------------------------------------------------------------- #
if [[ -e "${HOME}/.homesick/repos/homeshick" ]]; then
    source "${HOME}/.homesick/repos/homeshick/homeshick.sh"
    source "${HOME}/.homesick/repos/homeshick/completions/homeshick-completion.bash"
fi

# ---------------------------------------------------------------------------- #
# Colors
# ---------------------------------------------------------------------------- #

# Normal Colors
Black='\e[0;30m'
Red='\e[0;31m'
Green='\e[0;32m'
Yellow='\e[0;33m'
Blue='\e[0;34m'
Purple='\e[0;35m'
Cyan='\e[0;36m'
White='\e[0;37m'

# Bold
BBlack='\e[1;30m'
BRed='\e[1;31m'
BGreen='\e[1;32m'
BYellow='\e[1;33m'
BBlue='\e[1;34m'
BPurple='\e[1;35m'
BCyan='\e[1;36m'
BWhite='\e[1;37m'

# Background
On_Black='\e[40m'
On_Red='\e[41m'
On_Green='\e[42m'
On_Yellow='\e[43m'
On_Blue='\e[44m'
On_Purple='\e[45m'
On_Cyan='\e[46m'
On_White='\e[47m'

# Color Reset
NC='\e[0m'

# Alert
ALERT=${BWhite}${On_Red} # Bold White on red background

# ---------------------------------------------------------------------------- #
# Shell prompt
# ---------------------------------------------------------------------------- #
# [TIME] - [USER @ HOST] - [PWD NR_FILES SIZE/SIZE_FS]
# [JOBSr/JOBSs/LOAD_AVG] - [$?] > 

# Test connection type
if [ -n "${SSH_CONNECTION}" ]; then
    CNX=${BGreen}
elif [[ "${DISPLAY%%:0*}" != "" ]]; then
    CNX=${ALERT}
else
    CNX=${BCyan}
fi

# Test user type
if [[ ${USER} == "root" ]]; then
    SU=${BRed}
elif [[ ${USER} != $(logname) ]]; then
    SU=${BYellow}
else
    SU=${BGreen}
fi

# Test system load
NCPU=$(grep -c 'processor' /proc/cpuinfo)
SLOAD=$(( 100*${NCPU} ))
MLOAD=$(( 200*${NCPU} ))
XLOAD=$(( 400*${NCPU} ))

function load()
{
    local SYSLOAD=$(cut -d " " -f1 /proc/loadavg | tr -d '.')
    echo $((10#$SYSLOAD))
}

function load_color()
{
    local SYSLOAD=$(load)
    if [ ${SYSLOAD} -gt ${XLOAD} ]; then
        echo -en ${ALERT}
    elif [ ${SYSLOAD} -gt ${MLOAD} ]; then
        echo -en ${BRed}
    elif [ ${SYSLOAD} -gt ${SLOAD} ]; then
        echo -en ${BYellow}
    else
        echo -en ${BGreen}
    fi
}

function background_jobs()
{
    echo -en "$(jobs -r | wc -l)r"
    echo -en "/"
    echo -en "$(jobs -s | wc -l)s"
    echo -en "/"
}

# Test disk space and path permissions for $PWD
function path_color()
{
    if [ ! -w "${PWD}" ]; then
        echo -en ${BRed}
    else
        echo -en ${BBlue}
    fi
}

function path_files()
{
    echo -en "$(ls -lA | wc -l) files"
}

function path_size()
{
    local TotalBytes=0

    for Bytes in $(ls -lA | grep "^-" | awk '{ print $5 }')
    do
        let TotalBytes=$TotalBytes+$Bytes
    done

    # The if...fi's give a more specific output in byte, kilobyte, megabyte, 
    # and gigabyte
    if [ $TotalBytes -lt 1024 ]; then
        TotalSize=$(echo -e "scale=3 \n$TotalBytes \nquit" | bc)
        suffix="b"
    elif [ $TotalBytes -lt 1048576 ]; then
        TotalSize=$(echo -e "scale=3 \n$TotalBytes/1024 \nquit" | bc)
        suffix="kb"
    elif [ $TotalBytes -lt 1073741824 ]; then
        TotalSize=$(echo -e "scale=3 \n$TotalBytes/1048576 \nquit" | bc)
        suffix="Mb"
    else
        TotalSize=$(echo -e "scale=3 \n$TotalBytes/1073741824 \nquit" | bc)
        suffix="Gb"
    fi

    echo -en "${TotalSize}${suffix}"
}

function size_color()
{
    if [ -s "${PWD}" ] ; then
        local used=$(command df -P "$PWD" | awk 'END {print $5} {sub(/%/,"")}')
        if [ ${used} -gt 95 ]; then
            echo -en ${ALERT}
        elif [ ${used} -gt 90 ]; then
            echo -en ${BRed}
        else
            echo -en ${BGreen}
        fi
    else
        echo -en ${BCyan}
        # Current directory is size '0' (like /proc, /sys etc).
    fi
}

# Set the prompt
PROMPT_COMMAND=__prompt_command

function __prompt_command()
{
    local EXIT=$?

    history -a

    PS1="[\D{%d %b %Y} \A]"
    PS1+=" - ["
    PS1+="\[${SU}\]\u\[${NC}\]"
    PS1+="\[${BWhite}\] @ \[${NC}\]"
    PS1+="\[${CNX}\]\h\[${NC}\]"
    PS1+="] - ["
    PS1+="\[\$(path_color)\]\w\[${NC}\]"
    PS1+=" "
    PS1+="\[\$(size_color)\]\$(path_files) \$(path_size)\[${NC}\]"
    PS1+="]\n["
    PS1+="\$(background_jobs)"
    PS1+="\[\$(load_color)\]\$(cut -d ' ' -f1 /proc/loadavg)\[${NC}\]"
    
    if [[ ${EXIT} -ne 0 ]]; then
        PS1+="] - [\[${Red}\]${EXIT}\[${NC}\]] > "
    else
        PS1+="] - [\[${Green}\]${EXIT}\[${NC}\]] > "
    fi
}
 
case ${TERM} in
    xterm* | rxvt* | linux)
        PS1=${PS1}
        ;;
    *)
        PS1="(\u@\h \w) > "
        ;;
esac
