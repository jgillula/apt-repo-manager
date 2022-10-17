#!/bin/bash

CONFIG_FILE=${APT_REPO_MANAGER_CONF:-/etc/apt-repo-manager.conf}
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Config file \"$CONFIG_FILE\" not found"
    exit 1
fi
source "${CONFIG_FILE}"

if [[ -z "$REPO_NAME" ]]; then
    echo "REPO_NAME not found in \"$CONFIG_FILE\""
    exit 1
fi

PUBLIC_KEY_FILENAME="${REPO_NAME}.gpg"
PUBLIC_KEY_FILENAME=${PUBLIC_KEY_FILENAME// /_}
CREATE_KEY=false

columns=$(stty size | awk '{print $2}')
while [ "$1" != "" ]; do
    case "$1" in
        --create | -c)
            CREATE_KEY=true
            shift
            ;;
        -h | --help)
            echo "Usage: ${0##*/} [-c] [KEY_FILE]"  | fold -s -w $columns -
            echo "Write the public key of the repo to KEY_FILE (defaults to \"$PUBLIC_KEY_FILENAME\")." | fold -s -w $columns -
            echo "  -c, --create|Create the private key before saving the public key" | column -t -s '|' -c $columns
            exit 0
            ;;
        *)
            PUBLIC_KEY_FILENAME="$1"
            shift
            ;;
    esac    
done

if [[ "$CREATE_KEY" == true ]]; then
    gpg --batch --quick-gen-key "${REPO_NAME}"
fi

gpg --export -a "${REPO_NAME}" > "${PUBLIC_KEY_FILENAME}"
echo "Public key saved in \"${PUBLIC_KEY_FILENAME}\""
echo "Copy it to /etc/apt/trusted.gpg.d/ on your client"
