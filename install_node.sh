#!/bin/sh

arg0=$(basename "$0" .sh)
blnk=$(echo "$arg0" | sed 's/./ /g')
CONF_FOLDER=/etc/ethereum
SERVICE_FOLDER=/usr/lib/systemd/system/
network_name="mainnet"
INPUT_DIR="input"
OUTPUT_DIR="output"
MIN_ARGS=1
MAX_ARGS=6

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
    echo "  {-c|--client} clientname        -- Use given client config/exe"
    echo "  {-h|--help}                     -- Print this help message and exit"
#   echo "  {-V|--version}                  -- Print version information and exit"
    exit 0
}

if [ $# -gt $MAX_ARGS ]; then
    echo "Error: Too many arguments."
    usage_info
    exit 1
elif [ $# -lt $MIN_ARGS ]; then
    echo "Error: Too few arguments."
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
            export service_name=$1
            shift
            OPTCOUNT=$(($OPTCOUNT + 2));;
        (-d|--delete)
            shift
            [ $# = 0 ] && error "No delete servicename specified"
            export DELETE=true
            export service_name=$1
            shift
            OPTCOUNT=$(($OPTCOUNT + 2));;
        (-n|--network)
            shift
            [ $# = 0 ] && error "No network specified"
            export network_name=$1
            shift
            OPTCOUNT=$(($OPTCOUNT + 2));;
        (-c|--client)
            shift
            [ $# = 0 ] && error "No client specified [geth|lighthouse-beacon]"
            export client_name=$1
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

add_user () {
    user_name=$1
    # create sandboxed service user
    echo "installing service as $user_name"
    sudo useradd -r -s /sbin/nologin $user_name
    sudo mkdir -p /home/$user_name/.ethereum
    sudo chown -R $user_name:$user_name /home/$user_name/
}

copy_file () {
    input_file=$INPUT_DIR/$1
    output_file=$OUTPUT_DIR/$2

    if [ -f $input_file ]; then
        if [ -e $output_file ]; then
            echo "File $output_file already exists!"
            exit 1
        else
            sed "s|\${NETWORK_NAME}|$network_name|g; \
                s|\${USER_NAME}|$service_name|g; \
                s|\${CONF_FOLDER}|$CONF_FOLDER|g; \
                s|\${SYNC_URL}|$SYNC_URL|g; \
                s|\${SERVICE_NAME}|$service_name|g" \
                "$input_file" > "$output_file"
        fi
    else
        echo "File $input_file does not exist!"
        exit 1
    fi
}

flags "$@"
#echo "DEBUG-2: [$*]" >&2
shift $OPTCOUNT
#echo "DEBUG-3: [$*]" >&2



if [ $INSTALL ]; then
    # if user does not exist create them
    if ! [ -e "/home/$service_name" ]; then
        add_user $service_name
    fi

    if [[ $network_name == "holesky" ]]; then
        export SYNC_URL=https://holesky.beaconstate.ethstaker.cc
    else
        export SYNC_URL=https://beaconstate.ethstaker.cc
    fi
    # create config file
    copy_file $client_name.conf $service_name.conf

    # create service file
    copy_file $client_name.service $service_name.service

elif [ $DELETE ]; then
    # del sandbox user
    echo "deleting $service_name"
    sudo userdel $service_name
    sudo rm -rf /home/$service_name/ ${CONF_FOLDER}/${service_name}.conf ${SERVICE_FOLDER}${service_name}.service
fi

sudo systemctl daemon-reload