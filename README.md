# Overview
This repository is a continuation of [rpi-home-lab ](https://github.com/Misterdeiff/rpi-home-lab), my original setup running on a `Raspberry Pi OS Lite 64-bit`. I decided to migrate everthing to a Beelink SEi12 MiniPC because the Raspberry gave me buffering problems while watching 4K movies on Plex. In addition, the Intel Graphic card helps with transcoding, which wasn't possible with the Raspberry.

This repository contains a variety of docker containers, with the majority of them oriented to have your own media solution using ARR servers, but also adding cool containers such as Pi-hole for DNS, Tailscale for remote private access, or Watchtower for automatic Docker updates. 

It has been built using Ansible to create every single requirement. So, in case your system goes totally down and you don't have a snapshot of your VM, you will only need to apply the playbook and restore your docker config. Ideally, you make a regular snapshots of the VM or create backups with Kopia in a different drive. It's also very helpful for those who just want the infrastructure to be finished quickly and just invest the time in the container configurations.

I included some interesting container notes to take into account when configuring them.

# Containers
Here a summary of what's in this repository

- [Plex](https://hub.docker.com/r/linuxserver/plex): Media organizer and player
- [Tautilli](https://docs.linuxserver.io/images/docker-tautulli/): Plex monitoring & analytics
- [qBittorrent](https://docs.linuxserver.io/images/docker-qbittorrent/): Torrent manager
- [Overseerr](https://docs.linuxserver.io/images/docker-overseerr/): Media request manager and discovery
- [Radarr](https://docs.linuxserver.io/images/docker-radarr/): Movies manager (Usenet and Bittorrent)
- [Sonarr](https://docs.linuxserver.io/images/docker-sonarr/): TV Shows manager (Usenet and Bittorrent)
- [Prowlarr](https://docs.linuxserver.io/images/docker-prowlarr/): Indexer manager
- [Flaresolverr](https://github.com/FlareSolverr/FlareSolverr): Bypass Cloudflare and DDoS-GUARD protection
- [Samba](https://hub.docker.com/r/dperson/samba): Share directories
- [PiHole](https://docs.pi-hole.net/docker/): DNS & Ad-Blocker
- [Watchtower](https://github.com/containrrr/watchtower): Automatic Docker upgrades
- [Kopia](https://kopia.io/): Backups
- [Tailscale](https://tailscale.com/): Client VPN
- [Netdata](https://www.netdata.cloud/): Monitoring & Alerting

# Notes
1. There are two methods to mount your drive/s destinated to store media for ARR containers: Mount it [directly in the Docker server](https://trash-guides.info/File-and-Folder-Structure/How-to-set-up/Docker/) or mount it using [TrueNAS and a NFS share](https://trash-guides.info/File-and-Folder-Structure/How-to-set-up/TrueNAS-Core/). I originally used the first method, but then I switched to TrueNAS to easyly handle ZFS and for better visualitation. If you choose the first method you can disregard all references to TrueNAS in this project.

# My setup
Hardware: [Beelink SEi12](https://www.bee-link.com/products/beelink-sei12-i5-12450h) (check the specs in the link). 
Virtualization software and VMs:
Proxmox VE
- Ubuntu 24.04 LTS - Running Docker

# Requirements
Before starting the `Setup procedure` you will need the next:

1. Server or PC to run Proxmox
2. External HDDs to use for media and backup
3. Telegram account - Notification system
4. Tailscale account - Remote connection

# Setup procedure
1. Install Ansible in your laptop
   ```shell
   brew install ansible
   ```
2. Install Proxmox VE in your server
   - 2.1. Filesystem: For my use case I chose `ext4` since I only have a primary SSD, but you should choose what fits better for you.
3. Create a VM for Ubuntu
   3.1. Download the latest Ubuntu ISO and add it to Proxmox ISO images storage.
   3.2. Create the VM with the config that works best for you.
4. Connect your drive/s to the hardware running Proxmox
5. In Proxmox UI, go to the Ubuntu VM > Hardware > Add > USB Device and add your drives. This will passthrough your drives directly to the VM.
6. (Optional) Add your public SSH key to Ubuntu and Proxmox.
7. SSH to the Ubuntu VM and run `lsblk -f` to confirm they are available and to find out the HDDs' UUIDs.
8. Create your own Telegram Bot for notifications from ARR apps, Watchtower and disk space.
9. Follow the steps under Tailscale container to get the `TAILSCALE_AUTHKEY`.
10. Modify variables inside `roles/common/vars/main.yml`.
11. Adjust `inventories/hosts` as needed.
12. Run all tasks in the playbook:
   ```shell
   ansible-playbook -i inventories/hosts playbook.yml
   ```

# Useful commands

## Get a List of Playbook Tasks
``` shell
ansible-playbook -i inventories/hosts playbook.yml --list-tasks
```

## Run all Tasks in Playbook
```shell
ansible-playbook -i inventories/hosts playbook.yml
```

## Test changes
Use --check for a dry run and, in addition, use --diff to have a detail differences

```shell
ansible-playbook -i inventories/hosts playbook.yml -t docker --check --diff
```

## Run task with a Specific Tag - Example: Docker installation
```shell
ansible-playbook -i inventories/hosts playbook.yml -t docker
```

## Copy compose.yml and restart only the specified container
```shell
ansible-playbook -i inventories/hosts playbook.yml -t container -e "container=samba"
```
# Tools
## Telegram
In order to create your own bot follow the next steps:
1. Create a Telegram bot with `@BotFather` (the verified one)
2. Paste your bot's token in the main.yml file and use it to create connections in the ARR apps (Overseerr, Radarr, Sonarr, Prowlarr)
3. Use `@get_id_bot` to find your bot's Channel ID. Use it to receive the notifications in that channel for the ARR apps and Watchtower (main.yml)
4. (Optional) Create a Telegram Channel to separate system notifications (Overseer approvals and container updates received in the bot directly) from the new Movies / TV Shows added (Telegram Channel for family and friends).
   4.1. Create your new channel
   4.2. Add your bot as Admin
   4.3. Use Telegram web and access your new Channel. Get the Channel ID from the URL. It usually starts with `-100`
   4.4. Use this Channel ID in the Connection configured in Radarr and Sonarr

Note: `telegram_notification_disk.sh` uses an optional variable `EXCLUDE_DISK` to exclude from the notifications the Time Machine disk. This is because Time Machine tends to use the whole disk space before removing old backups.

# Sever Notes
## TrueNAS
1. Once connected the USB to the virtual machine in Proxmox, create a Pool
2. Follow the steps [here](https://trash-guides.info/File-and-Folder-Structure/How-to-set-up/TrueNAS-Core/) to ensure Hardlinks and atomic moves work properly

## Plex
1. Go to http://YOUR_IP:32400/web/index.html
2. Configure your folders
3. Add server in your end device

## Pi-hole
More info at https://github.com/pi-hole/docker-pi-hole/ and https://docs.pi-hole.net/

If NOT using it for DHCP, remove:
- Port `67:67/udp`
- `cap_add: - NET_ADMIN`

## Watchtower
- List of arguments: https://containrrr.dev/watchtower/arguments/
- WATCHTOWER_SCHEDULE is set to execute every Sunday at 4AM

## Kopia
- Server start commands: https://kopia.io/docs/reference/command-line/common/server-start/

## Tailscale
VPN access to your home network

1. Create an account and download the app on your client devices: https://tailscale.com/
2. Access Controls - Ensure you have the next config.
   
   This config creates a group `admin` where you are included by email. It also adds a `container` tag to be used in the tailscale container. The ACL allows only your group to access your private network, adjust it to your needs. See more examples [here](https://tailscale.com/kb/1019/subnets#add-access-rules-for-the-advertised-subnet-routes):
   ```
   "groups": {
		"group:admin": ["YOUR_EMAIL"],
	},
	"tagOwners": {
		"tag:container": ["autogroup:admin"],
	},
   "acls": [
		{
			"action": "accept",
			"src":    ["group:admin", "*"],
			"dst":    ["192.168.0.0/24:*"],
		},
	],
   ```
3. Settings > oAuth Clients > Create oAuth Client
   3.1. Add a description to identify the client e.i. "home_server"
   3.2. Mark Devices Read and Write
   3.3. Add tags > tag:container
   3.4. Generate Client
4. Add the token to the main.yml environment variable list
5. Once the tailscale container is up, access the [Tailscale dashboard > Machines](https://login.tailscale.com/admin/machines) > Options (in Tailscale machine) > Edit route settings > Check the shared subnet > Save
6. DNS > Nameservers > Add nameserver > Enter the internal IP of your server (Pi-hole should be running)

## UniFi
Controller for Ubiquiti UniFi network devices. 

The regular inform port is 8080, but since I used that one already, I changed it to 8081, this means you must ensure the controller overrides the default config of your devices. To do so, follow the next steps once you are in the controller:

1. Go to Settings > System > Advanced
2. Check `Inform Host` Override checkbox
3. Add the local IP or DNS of the server running the Docker container

# Features
These are additional features that you can find in the `environment.yml` file.
- Custom aliases
- Run tasks without entering the `BECOME` password