# pre-setup.sh

## This script is does serveral things:
## 1. Creates the necessary directories for the SPT-FIKA Docker container.
## 2. Clones the SPT-Fika-Docker-Guide repository.
## 3. Copies the required files to the container's "files" directory.
## 5. Builds the Docker image using the docker-compose build command.

#!/bin/bash

echo "Running pre-setup.sh ..."

# Set up directories (modify paths if you have an existing docker folder structure)
echo "Creating container directories..."
mkdir -p /home/ubuntu/docker/containers/spt-fika/files
mkdir -p /home/ubuntu/docker/containers/spt-fika/server

# Define the container's file path
export FIKA_FILES=/home/ubuntu/docker/containers/spt-fika/files

# Create a github-repos directory if it doesn't exist
echo "Creating GitHub repository directory..."
mkdir -p /home/ubuntu/github-repos

# Define the repository path
REPO_DIR="/home/ubuntu/github-repos/SPT-Fika-Docker-Guide"

# Check if the repository already exists
if [ -d "$REPO_DIR" ]; then
    echo "Repository already exists. Continuing without cloning..."
else
    # Clone the SPT-Fika-Docker-Guide repository
    echo "Cloning the SPT-Fika-Docker-Guide repository..."
    cd /home/ubuntu/github-repos
    git clone https://github.com/OnniSaarni/SPT-Fika-Docker-Guide
fi

# Copy the Docker compose file to the "files" directory
echo "Copying docker-compose.yml to the files directory..."
cp /home/ubuntu/github-repos/SPT-Fika-Docker-Guide/files/docker-compose.yml $FIKA_FILES

# Navigate to the container's files directory
cd $FIKA_FILES

# Pull the spt-fika image from Docker Hub
echo "Pulling the SPT-FIKA image from Docker Hub..."
docker pull dildz/spt-fika-3.9.8

# Bring up the SPT-FIKA server
echo "Building the SPT-FIKA server..."
docker compose up -d
echo "SPT-FIKA server has been started."
echo "When the server is ready, you can exit the logs by pressing Ctrl+C and follow the next step to run post-setup.sh."

# Wait 5sec before tailing the logs
echo "Waiting 5 seconds before tailing logs ..."
sleep 5

docker compose logs -f fika
