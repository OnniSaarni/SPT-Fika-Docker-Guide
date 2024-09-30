# Setting up Fika SPT server with docker for Ubuntu/Debian/Raspberry Pi
Last updated: 30/09/24

**Make sure your computer is 64-bit! Arm64 works too!**

[For support you should join the Fika Discord server](https://discord.gg/project-fika)

## Table Of Contents

[Installation](https://github.com/OnniSaarni/SPT-Fika-Docker-Guide#installing-docker)

[Updating The Server](https://github.com/OnniSaarni/SPT-Fika-Docker-Guide#updating-to-newer-versions)

[Other Possibly Helpful Info](https://github.com/OnniSaarni/SPT-Fika-Docker-Guide#modding-and-other-possibly-helpful-info)

[Casual discussion and questions can go here](https://gist.github.com/OnniSaarni/a3f840cef63335212ae085a3c6c10d5c)

## Free VPS

[A good free VPS from Oracle. It offers 24gb ram, 4 cores and 200gb of storage. It's ARM but works with this setup.](https://www.oracle.com/cloud/free/)

## Recommended tools
SSH: [Putty](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html)

File Explorer: [WinSCP](https://winscp.net/eng/download.php)

All-in-one recommendation: [VSCode](https://code.visualstudio.com/download) with the Remote Explorer extension installed.

**DON'T LOOSE YOUR SSH KEY FILE!!!** Without this you won't be able to connect to your Oracle server - keep it somewhere **SAFE**

## Installing Docker

First of all you need Docker. [You can download it by following this guide here.](https://docs.docker.com/engine/install/ubuntu/)

This guide is for ubuntu but you can find guides for other operating systems/distributions on their website.

Here is a summary of the install commands from the guide:

Step 1: Update the Package Index and Install Prerequisites

```
sudo apt-get update
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
```

Step 2: Add Docker’s Official GPG Key

```
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```

Step 3: Set Up the Stable Repository

```
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

Step 4: Update the Package Index Again

```
sudo apt-get update
```

Step 5: Install latest Docker Engine

```
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose docker-compose-plugin
```

Step 6: Enable and Start Docker

```
sudo systemctl enable docker
```
```
sudo systemctl start docker
```

Step 7: Add user to the docker group & activate the changes

```
sudo usermod -aG docker $USER
```
```
newgrp docker
```

You can verify your Docker installation by running `docker --version`

## Creating a user for docker (Recommended)

For better security, it's recommended to set up a separate user for Docker containers.

```
sudo adduser dockercontainers
```

To be able to use docker with this user, add them to the docker group.

```
sudo groupadd docker
sudo usermod -aG docker dockercontainers
```

You can log into the new account by entering this command:

```
su - dockercontainers
```

## Setting up the server

After you've got docker installed you can start by downloading the pre-setup.sh script to the **root of your home folder** e.g: /home/YOURUSERNAME/

You can do this with:

```
cd ~
```
```
wget [download link for the pre-setup.sh file]
```

**BEFORE RUNNING PRE-SETUP**

This guide assumes that you would be starting on a "fresh" ARM VPS instance. If this is the case you can use either Option 1 or Option 2.

If you already have a VPS instance with existing folder structures for Docker & GitHub repositories, then **ONLY use Option 2 & edit the pre-setup.sh, Dockerfile & init-server.sh files to suit your environment**.

This script does several things depending on the user's choice:
- Option 1 will use a pre-built image and docker compose.
- Option 2 will use a Docker file & build/run commands.

When run, it will perform the following actions:
- Create the necessary directories for the SPT-FIKA Docker container.
- Clone the SPT-Fika-Docker-Guide repository.
- Copy the required files to the container's 'files' directory based on the choice.
- Create the FIKA server based on the choice.

How these methods affect updating the server:
- Using Docker Compose (option 1) means waiting for the image to be updated on DockerHub before rebuilding the container for new versions but benefits from docker compose features and is much faster to setup. [A Watchtower container](https://containrrr.dev/watchtower/) could be used to automate this process but requires testing.
- Using Docker build (option 2) means rebuilding the container by editing the FIKA & SPT version tags in the Dockerfile and build/run commands. This option is slower but allows for updating the container image without waiting for DockerHub updates.

[A good explainer of the differences between Docker build & Docker Compose can be found here.](https://cloudinfrastructureservices.co.uk/dockerfile-vs-docker-compose-whats-the-difference/)

# Running the setup script

Now we're going to make the script executable:

```
chmod +x pre-setup.sh
```

Now we're going to run pre-setup.sh:

```
./pre-setup.sh
```

Select setup option 1 or 2 depending on your needs 

Once the server is ready - you can exit the logs but pressing **Ctrl + C**

## Helpful Docker commands

To see the logs of the container:

```
docker logs -f fika
```

You can use **Ctrl + C** to exit the logs.

To stop the container:

```
docker stop fika
```

To restart the container:

```
docker restart fika
```

Taking ownership of FIKA related files (edit paths if needed):

```
sudo chown -R $(whoami):$(whoami) $HOME/docker/containers/spt-fika/server
sudo chown -R $(whoami):$(whoami) $HOME/docker/logs
```

## Updating to newer versions

First off you will have to stop the server with:

```
docker stop fika
```

It is recommended to backup profiles in your server/user/profiles directory. 

The server path is defined in the pre-setup script and if not edited - should be in ($HOME/docker/containers/spt-fika/server/user/profiles)

You can backup profiles with this command:

```
cp -r $HOME/docker/containers/spt-fika/server/user/profiles $HOME/docker/containers/backups/fika/profiles
```

If you have any mods installed - you can use the following commands to backup server & client mods:

```
cp -r $HOME/docker/containers/spt-fika/server/user/mods $HOME/docker/containers/backups/fika/mods
```
```
cp -r $HOME/docker/containers/spt-fika/server/BepInEx $HOME/docker/containers/backups/fika/BepInEx
```

Remove the old FIKA mod version from the backup:

```
rm -rf $HOME/docker/containers/backups/fika/mods/fika-server
```

Next we need to delete the container and the image. We can do that by running these commands:

If option 1 was used (Docker compose):

```
cd $HOME/docker/containers/spt-fika/files
```
```
docker compose down
```

Confirm the current image version:

```
docker images
```

Replace the current version for the dildz/spt-fika-X.X.X image in the next command:

```
docker rmi dildz/spt-fika-CURRENT_VERSION
```

Remove any old build files:

```
docker builder prune
```

Now we need the latest spt-fika image.

[Navigate to DockerHub & copy the latest spt-fika image pull command](https://hub.docker.com/u/dildz)

Pull the new spt-fika image by pasting the pull command:

```
docker pull dildz/spt-fika-NEW_VERSION
```

After that we can rebuild the container:

```
docker compose up -d && docker compose logs -f fika
```

Now your server is updated.

If option 2 was used (Docker build):

Stop the server with:

```
docker stop fika
```

Next we need to delete the container and the image. We can do that by running these commands:

```
docker rm fika
```
```
docker rmi FIKA
```
```
docker image prune
```

Now that the outdated FIKA container & image has been removed - edit the version tags to the latest FIKA & SPT versions in the Dockerfile and save.

```
# Define build arguments
ARG FIKA=HEAD^
ARG FIKA_TAG=v2.2.8     <<CHANGE TO NEW VERSION
ARG SPT=HEAD^
ARG SPT_TAG=3.9.8       <<CHANGE TO NEW VERSION
ARG NODE=20.11.1
```

After that we need to rebuild the container from within the fika 'files' directory (edit path if needed):

```
cd $HOME/docker/containers/spt-fika/files
```

```
docker build --no-cache --label FIKA -t fika .
```

Then we can start it back up with: [REMEMBER TO CHANGE PATHTOYOURSERVERFILE & PATHTOYOURLOGFILE](https://gist.github.com/OnniSaarni/a3f840cef63335212ae085a3c6c10d5c#setting-up-the-docker-container)

```
cd ..
```

```
cd server
```

```
docker run --pull=never -v PATHTOYOURSERVERFILE:/opt/server -p 6969:6969 -d --name fika fika > PATHTOYOURLOGFILE 2>&1
```

```
docker start fika
```

```
docker update --restart unless-stopped fika
```

Now your server is updated.

You can use **Ctrl + C** to exit the logs.

To restore any backed up profiles & mods we can run the following commands:

```
docker stop spt-fika
```

Edit the following paths if needed:

```
sudo chown -R $(whoami):$(whoami) $HOME/docker/containers/spt-fika/server
sudo chown -R $(whoami):$(whoami) $HOME/docker/logs
```

```
cp -r $HOME/docker/containers/backups/fika/profiles $HOME/docker/containers/spt-fika/server/user/
```

```
cp -r $HOME/docker/containers/backups/fika/mods $HOME/docker/containers/spt-fika/server/user/
```

```
cp -r $HOME/docker/containers/backups/fika/BepInEx $HOME/docker/containers/spt-fika/server/
```

With backups restored you can now start the fika container back up:

```
docker start fika && docker logs -f fika
```

You can use **Ctrl + C** to exit the logs.

[To update your client you can follow the instructions here.](https://dev.sp-tarkov.com/SPT/Stable-releases/releases) [You will also need to download the newest Fika plugin from here.](https://github.com/project-fika/Fika-Plugin/releases)

## Modding and other possibly helpful info

To play with your friends you first have to port forward or disable the firewall for port 6969 on the server.

To host Co-Op raids with your friends you either have to have UPnP enabled or have port 25565 forwarded to your PC. 
You should also disable the firewall for the EscapeFromTarkov.exe and allow ports in the firewall. [More info over here](https://github.com/project-fika/Fika-Documentation?tab=readme-ov-file#installation)

To add more mods to the game you have to add them to the "users" directory in the server directory.

http.json should be pre configured for port forwarding in this setup.

[You might also want to look into making automatic backups with cron.](https://unix.stackexchange.com/a/16954)

It's not necessary but it's a plus. I'm not going to go into it in depth but if someone wants they are free to make a simple guide for it.

[This is a maintained/modified fork of this guide with an included mod-pack, scripts for pre & post installation, automated restarts & daily launcher background changes.](https://github.com/Dildz/SPT-Fika-modded--Docker-Guide)

## Credits

Thanks to everyone who contributed for helping others in the comments and providing fixes.
Thanks to @Dildz for creating a more in-depth guide and improving this guide!

[Special thanks to k2rlxyz for making the original Dockerfile.](https://hub.docker.com/r/k2rlxyz/fika) It can also be found in the [Discord](https://discord.gg/project-fika).
