#!/bin/sh

arg0=$(basename "$0" .sh)
blnk=$(echo "$arg0" | sed 's/./ /g')
CONF_FOLDER=/etc/ethereum
SERVICE_FOLDER=/usr/lib/systemd/system/
INPUT_DIR="input"
OUTPUT_DIR="output"
MIN_ARGS=1
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

copy_file () {
    input_file=$INPUT_DIR/$1
    output_file=$OUTPUT_DIR/$1

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
    # create sandboxed service user
    # echo "installing service $service_name"
    # sudo useradd -r -s /sbin/nologin $service_name
    # sudo mkdir -p /home/$service_name/.ethereum
    # sudo chown -R $service_name:$service_name /home/$service_name/

    if [[ $NETWORK_NAME == "holesky" ]]; then
        export SYNC_URL=https://holesky.beaconstate.ethstaker.cc
    else
        export SYNC_URL=https://beaconstate.ethstaker.cc
    fi
    # create config file
    copy_file "$service_name.conf"

    # create service file
    copy_file "$service_name.service"

elif [ $DELETE ]; then
    # del sandbox user
    echo "deleting $service_name"
    sudo userdel $service_name
    sudo rm -rf /home/$service_name/ ${CONF_FOLDER}/${service_name}.conf ${SERVICE_FOLDER}${service_name}.service
fi

#sudo systemctl daemon-reload