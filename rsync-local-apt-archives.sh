#!/bin/bash
# VERSION 1.0.0

CONFIG_FILE=${APT_REPO_MANAGER_CONF:-/etc/apt-repo-manager.conf}
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Config file \"$CONFIG_FILE\" not found"
    exit 1
fi
source "${CONFIG_FILE}"

if [[ -z "$PACKAGE_ARCHIVE_DIR" || ! -d "$PACKAGE_ARCHIVE_DIR" ]]; then
    echo "PACKAGE_ARCHIVE_DIR \"$PACKAGE_ARCHIVE_DIR\" not found"
    exit 1
fi

DISTRO=$( lsb_release -c | sed -e "s/Codename:[[:space:]]*//" )

rsync -a /var/cache/apt/archives/*.deb "${PACKAGE_ARCHIVE_DIR}/dists/${DISTRO}/"
