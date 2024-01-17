#!/bin/sh

arg0=$(basename "$0" .sh)
blnk=$(echo "$arg0" | sed 's/./ /g')
CONF_FOLDER=/etc/ethereum/
SERVICE_FOLDER=/usr/lib/systemd/system/
MAX_ARGS=4

usage_info()
{
    echo "Usage: $arg0 [{-i|--install} servicename] \\"
    echo "       $blnk [{-d|--delete} servicename] \\"
    echo "       $blnk [{-n|--network} networkname] \\"
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
    echo "  {-i|--install} servicename      -- Install servicename and directory"
    echo "  {-d|--delete} servicename       -- Delete servicename and directory"
    echo "  {-n|--network} networkname      -- Use specific network given"
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
            [ $# = 0 ] && error "No install servicename specified"
            export INSTALL=true
            export SERVICE_NAME=$1
            shift
            OPTCOUNT=$(($OPTCOUNT + 2));;
        (-d|--delete)
            shift
            [ $# = 0 ] && error "No delete servicename specified"
            export DELETE=true
            export SERVICE_NAME=$1
            shift
            OPTCOUNT=$(($OPTCOUNT + 2));;
        (-n|--network)
            shift
            [ $# = 0 ] && error "No network specified"
            export NETWORK_NAME=$1
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
    echo "installing $SERVICE_NAME"
    sudo useradd -r -s /sbin/nologin $SERVICE_NAME
    sudo mkdir -p /home/$SERVICE_NAME/.ethereum
    sudo chown -R $SERVICE_NAME:$SERVICE_NAME /home/$SERVICE_NAME/

    if [[ $NETWORK_NAME == "holesky" ]]; then
        export SYNC_URL=https://holesky.beaconstate.ethstaker.cc
    else
        export SYNC_URL=https://beaconstate.ethstaker.cc
    fi
    # create user config
    if [ -e $SERVICE_NAME.conf ]; then
        echo "File $SERVICE_NAME.conf already exists!"
    else
        cat << EOF >> $SERVICE_NAME.conf
ARGS="beacon \\
  --network ${NETWORK_NAME} \\
  --datadir /home/${SERVICE_NAME}/.ethereum \\
  --eth1 \\
  --http \\
  --metrics \\
  --execution-endpoint http://127.0.0.1:8551 \\
  --execution-jwt /etc/ethereum/jwtsecret \\
  --builder http://127.0.0.1:18550 \\
  --checkpoint-sync-url ${SYNC_URL} \\
  --prune-payloads false"
EOF

    sudo mv $SERVICE_NAME.conf $CONF_FOLDER
    fi

    # create user service
    if [ -e $SERVICE_NAME.service ]; then
	    echo "File $SERVICE_NAME.service already exists!"
    else
        cat << EOF >> $SERVICE_NAME.service
[Unit]
Description=Lighthouse Beacon chain daemon
After=network.target

[Service]
EnvironmentFile=${CONF_FOLDER}${SERVICE_NAME}.conf
ExecStart=/usr/bin/lighthouse \$ARGS
Restart=always
User=${SERVICE_NAME}
KillSignal=SIGTERM
TimeoutStopSec=600

[Install]
WantedBy=multi-user.target
EOF

    sudo mv $SERVICE_NAME.service $SERVICE_FOLDER
    fi
elif [ $DELETE ]; then
    # del sandbox user
    echo "deleting $SERVICE_NAME"
    sudo userdel $SERVICE_NAME
    sudo rm -rf /home/$SERVICE_NAME/ ${CONF_FOLDER}${SERVICE_NAME}.conf ${SERVICE_FOLDER}${SERVICE_NAME}.service
fi

sudo systemctl daemon-reload