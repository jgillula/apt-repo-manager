# apt-repo-manager
A set of scripts for managing apt repositories.

## What is this?

`apt-repo-manager` is a lightweight set of scripts for managing one or more apt repositories on a server, organized by distro. I use it to have a local mirror of apt packages for my various Ubuntu machines.

## Server Setup

### Create a directory where you want to host the repository:
```bash
sudo mkdir /srv/my_apt_repo
```

### Checkout the repository:
```bash
git clone https://github.com/jgillula/apt-repo-manager.git
cd apt-repo-manager
```

### Install the files
If you want to install it in your system (e.g. so it can run regularly via `cron`), copy the files to the right places:
```bash
sudo cp apt-repo-manager.conf /etc/apt-repo-manager.conf
sudo cp rsync-local-apt-archives.sh update-local-apt-repos.sh /usr/local/bin/.
```

> **Note:** If you don't want to install it, you'll have to set the environment variable `APT_REPO_MANAGER_CONF` to the location of your `apt-repo-manager.conf` file.

### Setup your `apt-repo-manager.conf` config
Then edit `/etc/apt-repo-manager.conf` (or your local version), setting `REPO_NAME` to some descriptive name of your repo (e.g. "My Awesome Repo") and `PACKAGE_ARCHIVE_DIR` to the directory you created in step zero (e.g. `/srv/my_apt_repo`).

### Create a repo signing key
In order to access your repo remotely, it needs to be signed with a gpg key. `apt-repo-manager` comes with a handy script for creating that key:
```bash
sudo ./get-repo-signing-key.sh --create
```
> **Note:** If you want to automate updating your repository, you'll need to leave the passphrase for this key blank.
This script will also save a copy of the public key, which you'll need if you want to access your repo remotely.

### Populate your repository
`apt-repo-manager` comes with a handy script for populating your repository from the local apt cache in `/var/cache/apt/archives`:
```bash
sudo ./rsync-local-apt-archives.sh
```

If you'd prefer to populate your repository manually, you'll need to put the `deb` files in the directory `$PACKAGE_ARCHIVE_DIR/dists/$DISTRO`, where `$PACKAGE_ARCHIVE_DIR` is the directory referred to in your `apt-repo-manager.conf` file (e.g. `/srv/my_apt_repo`), and `$DISTRO` is your distro (e.g. `bionic`, `focal`, `jammy`, etc.).

### Update your repository's metadata
Finally, update your repository's metadata by running:
```bash
sudo ./update-local-apt-repos.sh
```

### Bonus: do it automatially on a schedule
If you want to automate all this, `apt-repo-manager` has a useful `cron` file you can drop into `/etc/cron.d/`. First' edit `apt-repo-manager-cron` and uncomment one of the two lines (i.e. if you want to sync from the local apt cache *and* update your repo, or just update your repo). Then drop it in so the system finds it:
```bash
sudo cp apt-repo-manager-cron /etc/cron.d/apt-repo-manager-cron
```

### Host the repo
If you want the repo to be accessible over the network, you'll need to expose it somehow. You can use http or https, apache or nginx. Just make sure the root directory you're serving is the same as the `PACKAGE_ARCHIVE_DIR` in your `apt-repo-manager.conf` (e.g. `/srv/my_apt_repo`).

## Client setup

There are two ways to use your repo on a client

### Access your repo on the same machine on which its hosted
To access your repo on the same machine on which its hosted use a deb line like:
```
deb file:$PACKAGE_ARCHIVE_DIR $DISTRO main
```
and replace `$PACKAGE_ARCHIVE_DIR` with the value from your `apt-repo-manager.conf`, and `$DISTRO` with your distro (e.g. `jammy`). (E.g. you can add a file whose name ends in `.list` to `/etc/apt/sources.list.d/` with these contents.)

### Access your repo remotely
To access your repo from another machine, first copy the public key (i.e. the `.gpg` file) you created during setup from the server to the client. (If you don't have it, you can get it again by running `sudo ./get-repo-signing-key.sh` on the server.)

Then copy the public key to `/etc/apt/trusted.gpg.d/`.

Finally, add a deb line like:
```
deb http://$YOUR_MACHINES_URL $DISTRO main
```
where `$YOUR_MACHINES_URL` is the network url of your server (e.g. `my_apt_repo.local`) and `$DISTRO` is your distro.

### Don't forget to `apt update` after setting up the client!

## How It Works
