#!/bin/bash

CONFIG_FILE=${APT_REPO_MANAGER_CONF:-/etc/apt-repo-manager.conf}
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Config file \"$CONFIG_FILE\" not found"
    exit 1
fi
source "${CONFIG_FILE}"

if [[ -z "$REPO_NAME" ]]; then
    echo "REPO_NAME not found in \"$CONFIG_FILE\""
    echo "$REPO_NAME"
    exit 1
fi

if [[ -z "$PACKAGE_ARCHIVE_DIR" || ! -d "$PACKAGE_ARCHIVE_DIR" ]]; then
    echo "PACKAGE_ARCHIVE_DIR \"$PACKAGE_ARCHIVE_DIR\" not found"
    exit 1
fi

mkdir -p "${PACKAGE_ARCHIVE_DIR}/dists"

DISTROS=$( find "${PACKAGE_ARCHIVE_DIR}/dists/" -maxdepth 1 -mindepth 1 -type d -printf "%f " )
if [[ -z "$DISTROS" ]]; then
    echo "No distros found in PACKAGE_ARCHIVE_DIR \"$PACKAGE_ARCHIVE_DIR"\"
    exit 2
fi

for DISTRO in ${DISTROS}; do
    cd "${PACKAGE_ARCHIVE_DIR}/dists/${DISTRO}"

    echo -e "Origin:     ${REPO_NAME}" > Release
    echo -e "Label:      ${REPO_NAME}" >> Release
    echo -e "Components: main" >> Release
    echo -e "Date:       `LANG=C date -Ru`" >> Release
    echo -e "Codename:   ${DISTRO}" >> Release
    
    ARCHITECTURES=$( ls -1 | grep -Eo "_(?\w+?)\.deb" | sed -n -e "s/_\([[:alnum:]]\+\)\.deb/\1/p" | sort | uniq | grep -v "all" )
    if [ -n "$ARCHITECTURES" ]; then
        echo "Architectures: "${ARCHITECTURES} >> Release

        for ARCH in ${ARCHITECTURES}; do
            #echo ${ARCH}
            ARCH_DIR="main/binary-${ARCH}"
            mkdir -p "${ARCH_DIR}"
            dpkg-scanpackages --arch "${ARCH}" --multiversion . /dev/null 2>/dev/null 1> "${ARCH_DIR}/Packages"
            gzip --keep --force -9 "${ARCH_DIR}/Packages"
        done
        echo -e 'MD5Sum:' >> Release
        for FILENAME in main/binary-*/Packages* ; do
            printf ' '$(md5sum "${FILENAME}" | cut --delimiter=' ' --fields=1)" %16d ${FILENAME}\n" $(wc --bytes "${FILENAME}" | cut --delimiter=' ' --fields=1) >> Release
        done
        echo -e 'SHA256:' >> Release
        for FILENAME in main/binary-*/Packages* ; do
            printf ' '$(sha256sum "${FILENAME}" | cut --delimiter=' ' --fields=1)" %16d ${FILENAME}\n" $(wc --bytes "${FILENAME}" | cut --delimiter=' ' --fields=1) >> Release
        done

        rm -f InRelease
        gpg --clearsign --digest-algo SHA512 --local-user "${REPO_NAME}" -o InRelease Release
    fi

    echo "Updated repo ${PACKAGE_ARCHIVE_DIR}/dists/${DISTRO}"
done
