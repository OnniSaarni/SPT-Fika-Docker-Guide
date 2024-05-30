# fcpy.sh

#!/bin/bash
echo "FIKA Docker"

if [ -d "/opt/srv" ]; then
    start=$(date +%s)
    echo "Started copying files to your volume/directory.. Please wait."
    cp -r /opt/srv/* /opt/server/
    rm -r /opt/srv
    end=$(date +%s)
    
    echo "Files copied to your machine in $(($end-$start)) seconds."
    echo "Starting the server to generate all the required files"
    cd /opt/server
    chown $(id -u):$(id -g) ./* -Rf
    sed -i 's/127.0.0.1/0.0.0.0/g' /opt/server/Aki_Data/Server/configs/http.json
    NODE_CHANNEL_FD= timeout --preserve-status 40s ./Aki.Server.exe </dev/null >/dev/null 2>&1 
    echo "Follow the instructions to proceed!"
    exit 0
fi

if [ -e "/opt/server/delete_me" ]; then
    echo "Error: Safety file found. Exiting."
    echo "Please follow the instructions."
     sleep 30
    exit 1
fi

cd /opt/server && ./Aki.Server.exe

echo "Exiting."
exit 0