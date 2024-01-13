#!/bin/sh

arg0=$(basename "$0" .sh)
blnk=$(echo "$arg0" | sed 's/./ /g')
CONF_FOLDER=/etc/ethereum/
SERVICE_FOLDER=/usr/lib/systemd/system/
MAX_ARGS=2

usage_info()
{
    echo "Usage: $arg0 [{-i|--install} username] \\"
    echo "       $blnk [{-d|--delete} username] \\"
    echo "       $blnk [-h|--help]"
}

usage()
{
    exec 1>2   # Send standard output to standard error
    usage_info
    exit 1
}

error()
{
    echo "$arg0: $*" >&2
    exit 1
}

help()
{
    usage_info
    echo
    echo "  {-i|--install} username         -- Install username and directory"
    echo "  {-d|--delete} username          -- Delete username and directory"
    echo "  {-h|--help}                     -- Print this help message and exit"
#   echo "  {-V|--version}                  -- Print version information and exit"
    exit 0
}

if [ $# -gt $MAX_ARGS ]; then
    echo "Error: Too many arguments."
    usage_info
    exit 1
fi

flags()
{
    OPTCOUNT=0
    while test $# -gt 0
    do
        case "$1" in
        (-i|--install)
            shift
            [ $# = 0 ] && error "No install username specified"
            export INSTALL=true
            export USERNAME=$1
            shift
            OPTCOUNT=$(($OPTCOUNT + 2));;
        (-d|--delete)
            shift
            [ $# = 0 ] && error "No delete username specified"
            export DELETE=true
            export USERNAME=$1
            shift
            OPTCOUNT=$(($OPTCOUNT + 2));;
        (-h|--help)
            help;;
#       (-V|--version)
#           version_info;;
        (--)
            shift
            OPTCOUNT=$(($OPTCOUNT + 1))
            break;;
        (*) usage;;
        esac
    done
#    echo "DEBUG-1: [$*]" >&2
#    echo "OPTCOUNT=$OPTCOUNT" >&2
}

flags "$@"
#echo "DEBUG-2: [$*]" >&2
shift $OPTCOUNT
#echo "DEBUG-3: [$*]" >&2



if [ $INSTALL ]; then
    # create sandbox user
    echo "installing $USERNAME"
    sudo useradd -r -s /sbin/nologin $USERNAME
    sudo mkdir -p /home/$USERNAME/.ethereum
    sudo chown -R $USERNAME:$USERNAME /home/$USERNAME/

    # create user config
    if [ -e $USERNAME.conf ]; then
        echo "File $USERNAME.conf already exists!"
    else
        cat << EOF >> $USERNAME.conf
ARGS="--datadir /home/$USERNAME/.ethereum \\
  --mainnet \\
  --metrics \\
  --metrics.expensive \\
  --pprof \\
  --http \\
  --authrpc.jwtsecret=/etc/ethereum/jwtsecret"
EOF

    sudo mv $USERNAME.conf $CONF_FOLDER
    fi

    # create user service
    if [ -e $USERNAME.service ]; then
	    echo "File $USERNAME.service already exists!"
    else
        cat << EOF >> $USERNAME.service
 [Unit]
 Description=Ethereum geth client daemon by The Ethereum Foundation
 After=network.target

 [Service]
 EnvironmentFile=${CONF_FOLDER}${USERNAME}.conf
 ExecStart=/usr/bin/geth \$ARGS
 Restart=always
 User=${USERNAME}
 KillSignal=SIGTERM
 TimeoutStopSec=600

 [Install]
 WantedBy=multi-user.target
EOF

    sudo mv $USERNAME.service $SERVICE_FOLDER
    fi
elif [ $DELETE ]; then
    # del sandbox user
    echo "deleting $USERNAME"
    sudo userdel $USERNAME
    sudo rm -rf /home/$USERNAME/ ${CONF_FOLDER}${USERNAME}.conf ${SERVICE_FOLDER}${USERNAME}.service
fi


sudo systemctl daemon-reload

