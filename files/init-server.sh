# init-server.sh

## This script is responsible for setting up the SPT-FIKA server Docker container.

#!/bin/bash

echo "Running init-server.sh ..."
echo "SPT FIKA Docker (SPT 3.9.x)"

# Get the host user from the environment variable
USER_HOME="/home/$HOST_USER"

LOGFILE="$USER_HOME/docker/logs/spt-fika.log"

# Ensure the log directory exists and set permissions
mkdir -p "$USER_HOME/docker/logs"

# Clear the log file if it exists, or create it if it doesn't
> "$LOGFILE"
chmod 775 "$LOGFILE"
chown "$HOST_USER":"$HOST_USER" "$LOGFILE"

# Function to move the server files and start the server to generate the required files
if [ -d "/opt/srv" ]; then
    start=$(date +%s)
    echo "Started copying files to your volume/directory.. Please wait."
    cp -r /opt/srv/* /opt/server/
    rm -r /opt/srv
    end=$(date +%s)
    
    echo "Files copied to your machine in $(($end-$start)) seconds."
    echo "Starting the server to generate all the required files"
    cd /opt/server

    # Modify the http.json file
    sed -i 's/127.0.0.1/0.0.0.0/g' /opt/server/SPT_Data/Server/configs/http.json

    NODE_CHANNEL_FD= timeout --preserve-status 40s ./SPT.Server.exe </dev/null >/dev/null 2>&1
    exit 0
fi

# Check for the safety file
if [ -e "/opt/server/delete_me" ]; then
    echo "Error: Safety file found. Exiting."
    echo "Please follow the instructions."
    sleep 30
    exit 1
fi

cd /opt/server

# Capture the start time to filter logs accordingly
START_TIME=$(date +%s)
echo "Server starting at $(date)" | tee "$LOGFILE"

# Start the server and log output, ensuring only new logs are recorded
./SPT.Server.exe 2>&1 | tee -a "$LOGFILE"

echo "Please follow the instructions to proceed."
exit 0

