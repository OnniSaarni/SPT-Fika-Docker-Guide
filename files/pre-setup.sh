# pre-setup.sh

# This script is does serveral things depending on the user's choice:
## 1. Creates the necessary directories for the SPT-FIKA Docker container.
## 2. Clones the SPT-Fika-Docker-Guide repository.
## 3. Copies the required files to the container's "files" directory based on the choice.
## 4. Builds the Docker image using the docker-compose build command, or manually using Docker build.

# Using Docker Compose (pre-built image) option means waiting for the image to be updated before rebuilding the container for new versions but benefits from docker compose features.

# Using Docker build (build from Dockerfile) means building the image manually by editing the FIKA & SPT version tags in the Dockerfile and re-building the image.

#!/bin/bash

# Prompt the user for the setup method
echo "Choose your setup method:"
echo "1) Docker Compose (pre-built fika image)"
echo "2) Docker build (build from Dockerfile)"

read -p "Enter option [1 or 2]: " OPTION

# Get the current username dynamically
USER_NAME=$(whoami)

# Set up directories
echo "Creating container directories..."
mkdir -p /home/$USER_NAME/docker/containers/spt-fika/files
mkdir -p /home/$USER_NAME/docker/containers/spt-fika/server

# Define paths
FIKA_FILES=/home/$USER_NAME/docker/containers/spt-fika/files
FIKA_SERVER=/home/$USER_NAME/docker/containers/spt-fika/server
USER_HOME=$(eval echo ~$USER_NAME)              # Get the home directory dynamically
LOGFILE="$USER_HOME/docker/logs/spt-fika.log"   # Define the log file location

# Clone the repository if it doesn't exist
REPO_DIR="/home/$USER_NAME/github-repos/SPT-Fika-Docker-Guide"
if [ -d "$REPO_DIR" ]; then
    echo "Repository already exists. Continuing without cloning..."
else
    echo "Cloning the SPT-Fika-Docker-Guide repository..."
    mkdir -p /home/$USER_NAME/github-repos
    cd /home/$USER_NAME/github-repos
    git clone https://github.com/OnniSaarni/SPT-Fika-Docker-Guide
fi

# Option 1: Using Docker Compose (pre-built image)
if [ "$OPTION" == "1" ]; then
    echo "You have chosen Option 1: Docker Compose with pre-built image."

    # Copy the necessary files for Docker Compose
    echo "Copying the Docker Compose file..."
    cp /home/$USER_NAME/github-repos/SPT-Fika-Docker-Guide/files/docker-compose.yml $FIKA_FILES

    # Navigate to the container's files directory
    cd $FIKA_FILES

    # Pull the spt-fika image from Docker Hub
    echo "Pulling the pre-built SPT-FIKA image from Docker Hub..."
    docker compose pull

    # Start the container using Docker Compose
    echo "Starting the SPT-FIKA server using Docker Compose..."
    docker compose up -d
    echo "SPT-FIKA server has been started."
    echo "When the server is ready, you can exit the logs by pressing Ctrl+C."

    # Wait 5 seconds before tailing the logs
    echo "Waiting 5 seconds before tailing logs ..."
    sleep 5
    docker compose logs -f fika

# Option 2: Manual Docker build and run
elif [ "$OPTION" == "2" ]; then
    echo "You have chosen Option 2: Docker build using Dockerfile."
    
    # Create log directory
    mkdir -p $(dirname "$LOGFILE")

    # Copy necessary files for docker build
    echo "Copying Dockerfile & init-server.sh to the files directory..."
    cp /home/$USER_NAME/github-repos/SPT-Fika-Docker-Guide/files/Dockerfile $FIKA_FILES
    cp /home/$USER_NAME/github-repos/SPT-Fika-Docker-Guide/files/init-server.sh $FIKA_FILES

    # Navigate to the container's files directory
    cd $FIKA_FILES

    # Build the Docker image manually
    echo "Building the Docker image from the Dockerfile..."
    docker build --no-cache --label FIKA -t fika .

    # Navigate to the container's server directory
    cd $FIKA_SERVER

    # Run the Docker container with the specified server path
    echo "Running the Docker container..."
    docker run --pull=never -v "$FIKA_SERVER":/opt/server -p 6969:6969 -d --name fika fika > "$LOGFILE" 2>&1

    # Start the container and set restart policy
    echo "Starting the Docker container..."
    docker start fika
    docker update --restart unless-stopped fika
    echo "SPT-FIKA server has been started."
    echo "When the server is ready, you can exit the logs by pressing Ctrl+C."

    # Wait 5 seconds before tailing the logs
    echo "Waiting 5 seconds before tailing logs ..."
    sleep 5
    docker logs -f fika

else
    echo "Invalid option chosen. Please choose either 1 or 2."
    exit 1
fi

echo "Setup complete."
