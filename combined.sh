#!/bin/sh

INPUT_DIR="input"
OUTPUT_DIR="output"
network_name="mainnet"
SYNC_URL="http:\\www.localhost.dev"


copy_file () {
    input_file=$INPUT_DIR/$1
    output_file=$OUTPUT_DIR/$1

    if [ -f $input_file ]; then
        if [ -e $output_file ]; then
            echo "File $output_file already exists!"
        else
            # Perform variable substitution and write to the new file
            sed "s|\${NETWORK_NAME}|$network_name|g; \
                s|\${USER_NAME}|$service_name|g; \
                s|\${CONF_FOLDER}|$CONF_FOLDER|g; \
                s|\${SYNC_URL}|$SYNC_URL|g; \
                s|\${SERVICE_NAME}|$service_name|g" \
                "$input_file" > "$output_file"
        fi
    else
        echo "File $input_file does not exist!"
    fi
}

service_name=$1
copy_file "$service_name.conf"
copy_file "$service_name.service"