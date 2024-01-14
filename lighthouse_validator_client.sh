#!/bin/sh

arg0=$(basename "$0" .sh)
blnk=$(echo "$arg0" | sed 's/./ /g')
CONF_FOLDER=/etc/ethereum/
SERVICE_FOLDER=/usr/lib/systemd/system/
DATA_FOLDER=/home/rocketpool/data/validators/lighthouse
MAX_ARGS=2

usage_info()
{
    echo "Usage: $arg0 [{-i|--install} servicename] \\"
    echo "       $blnk [{-d|--delete} servicename] \\"
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

    # create user config
    if [ -e $SERVICE_NAME.conf ]; then
        echo "File $SERVICE_NAME.conf already exists!"
    else
        cat << EOF >> $SERVICE_NAME.conf
ARGS="validator \\
  --network mainnet \\
  --datadir ${DATA_FOLDER} \\
  --graffiti \"Hello World!\" \\
  --init-slashing-protection \\
  --enable-doppelganger-protection"
EOF

    sudo mv $SERVICE_NAME.conf $CONF_FOLDER
    fi

    # create user service
    if [ -e $SERVICE_NAME.service ]; then
	    echo "File $SERVICE_NAME.service already exists!"
    else
        cat << EOF >> $SERVICE_NAME.service
[Unit]
Description=Lighthouse Validator %I
After=network.target

[Service]
EnvironmentFile=/etc/ethereum/${SERVICE_NAME}@%i
EnvironmentFile=/home/%i/data/validators/rp-fee-recipient-env.txt
EnvironmentFile=${CONF_FOLDER}${SERVICE_NAME}.conf
ExecStart=/usr/bin/lighthouse \$ARGS --suggested-fee-recipient \${FEE_RECIPIENT}
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