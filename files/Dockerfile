##
## Dockerfile
## SPT FIKA LINUX Container
##

# Define a build stage to handle dependencies and building
FROM ubuntu:latest AS builder

# Define build arguments to accept values from docker-compose.yml
ARG FIKA=HEAD^
ARG FIKA_TAG=v2.2.8
ARG SPT=HEAD^
ARG SPT_TAG=3.9.8
ARG NODE=20.11.1

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
WORKDIR /opt

# Install git, git-lfs, curl
RUN apt update && apt install -yq git git-lfs curl

# Increase Git's HTTP buffer size
RUN git config --global http.postBuffer 524288000

# Install Node Version Manager and NodeJS
RUN git clone https://github.com/nvm-sh/nvm.git $HOME/.nvm || true
RUN . $HOME/.nvm/nvm.sh && nvm install $NODE

# Clone the SPT repo or continue if it exists
RUN git clone --branch $SPT_TAG https://dev.sp-tarkov.com/SPT/Server.git srv || true

# Checkout specific commit and pull large files
WORKDIR /opt/srv/project
RUN git checkout $SPT
RUN git-lfs pull

# Remove the encoding from aki - todo: find a better workaround
RUN sed -i '/setEncoding/d' /opt/srv/project/src/Program.ts || true

# Install npm dependencies and run build
RUN . $HOME/.nvm/nvm.sh && npm install && npm run build:release -- --arch=$([ "$(uname -m)" = "aarch64" ] && echo arm64 || echo x64) --platform=linux

# Move the built server and clean up the source
RUN mv build/ /opt/server/
WORKDIR /opt
RUN rm -rf srv/

# Grab FIKA Server Mod or continue if it exists
RUN git clone --branch $FIKA_TAG https://github.com/project-fika/Fika-Server.git ./server/user/mods/fika-server
RUN . $HOME/.nvm/nvm.sh && cd ./server/user/mods/fika-server && git checkout $FIKA && npm install
RUN rm -rf ./server/user/mods/fika-server/.git

# Define the final stage with only necessary runtime dependencies
FROM ubuntu:latest
WORKDIR /opt/
RUN apt update && apt upgrade -yq && apt install -yq dos2unix

# Copy built server from the builder stage
COPY --from=builder /opt/server /opt/srv

# Copy initialization script and set executable permissions
COPY --chmod=755 init-server.sh /opt/init-server.sh

# Fix for Windows line endings
RUN dos2unix /opt/init-server.sh

# Expose necessary ports
EXPOSE 6969

# Specify the default command to run when the container starts
CMD ["bash", "/opt/init-server.sh"]
