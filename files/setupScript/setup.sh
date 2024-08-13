#!/bin/bash

# Exit on any error
set -e

# Create directories
mkdir -p containers/fika containers/server
cd containers/fika

# Create Dockerfile
cat << EOF > Dockerfile
FROM ubuntu:latest AS builder
ARG FIKA=HEAD^
ARG FIKA_TAG=[Insert Tag Here]
ARG SPT=HEAD^
ARG SPT_TAG=[Insert Tag Here]
ARG NODE=20.11.1

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
WORKDIR /opt

# Install git git-lfs curl
RUN apt update && apt install -yq git git-lfs curl
# Install Node Version Manager and NodeJS
RUN git clone https://github.com/nvm-sh/nvm.git \$HOME/.nvm || true
RUN \. \$HOME/.nvm/nvm.sh && nvm install \$NODE
## Clone the SPT repo or continue if it exist
RUN git clone https://dev.sp-tarkov.com/SPT/Server.git srv || true

## Check out and git-lfs (specific commit --build-arg SPT=xxxx)
WORKDIR /opt/srv/project

RUN git checkout tags/\$SPT_TAG
RUN git checkout \$SPT
RUN git-lfs pull

## remove the encoding from spt - todo: find a better workaround
RUN sed -i '/setEncoding/d' /opt/srv/project/src/Program.ts || true

## Install npm dependencies and run build
RUN \. \$HOME/.nvm/nvm.sh && npm install && npm run build:release -- --arch=\$([ "\$(uname -m)" = "aarch64" ] && echo arm64 || echo x64) --platform=linux
## Move the built server and clean up the source
RUN mv build/ /opt/server/
WORKDIR /opt
RUN rm -rf srv/
## Grab FIKA Server Mod or continue if it exist
RUN git clone https://github.com/project-fika/Fika-Server.git ./server/user/mods/fika-server
WORKDIR ./server/user/mods/fika-server
RUN git checkout tags/\$FIKA_TAG
RUN git checkout \$FIKA
RUN \. \$HOME/.nvm/nvm.sh && npm install
RUN rm -rf ../FIKA/.git

FROM ubuntu:latest
WORKDIR /opt/
RUN apt update && apt upgrade -yq && apt install -yq dos2unix
COPY --from=builder /opt/server /opt/srv
COPY fcpy.sh /opt/fcpy.sh
# Fix for Windows
RUN dos2unix /opt/fcpy.sh

# Set permissions
RUN chmod o+rwx /opt -R

# Exposing ports
EXPOSE 6969
EXPOSE 6970
EXPOSE 6971

# Specify the default command to run when the container starts
CMD bash ./fcpy.sh
EOF

# Create fcpy.sh
cat << EOF > fcpy.sh
#!/bin/bash
echo "FIKA Docker"

if [ -d "/opt/srv" ]; then
    start=\$(date +%s)
    echo "Started copying files to your volume/directory.. Please wait."
    cp -r /opt/srv/* /opt/server/
    rm -r /opt/srv
    end=\$(date +%s)
    
    echo "Files copied to your machine in \$((\$end-\$start)) seconds."
    echo "Starting the server to generate all the required files"
    cd /opt/server
    chown \$(id -u):\$(id -g) ./* -Rf
    if [ -f /opt/server/SPT_Data/Server/configs/http.json ]; then
    	sed -i 's/127.0.0.1/0.0.0.0/g' /opt/server/SPT_Data/Server/configs/http.json
	NODE_CHANNEL_FD= timeout --preserve-status 40s ./SPT.Server.exe </dev/null >/dev/null 2>&1
    else
	sed -i 's/127.0.0.1/0.0.0.0/g' /opt/server/Aki_Data/Server/configs/http.json
	NODE_CHANNEL_FD= timeout --preserve-status 40s ./Aki.Server.exe </dev/null >/dev/null 2>&1
    fi
    echo "Follow the instructions to proceed!"
fi

if [ -e "/opt/server/delete_me" ]; then
    echo "Error: Safety file found. Exiting."
    echo "Please follow the instructions."
     sleep 30
    exit 1
fi

cd /opt/server

if [ -f ./SPT.Server.exe ]; then
   ./SPT.Server.exe
else
   ./Aki.Server.exe
fi
echo "Exiting."
exit 0
EOF

echo "Setup complete. Make sure to configure the mod versions in the Dockerfile."
