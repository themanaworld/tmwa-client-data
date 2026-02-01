#!/bin/bash

client_branch="$1"
client_job_name="$2"
logfile="$3"

set -e

source ./.tools/init.sh

clientdata_init

# Stop tzdata from asking to pick a location, hanging the pipeline
export DEBIAN_FRONTEND=noninteractive

aptget_update
# Evidently libcurl3-gnutls ships libcurl4-gnutls.so.4
aptget_install \
    x11-utils xdg-utils xsel \
    ttf-dejavu-core fonts-liberation \
    libcurl3-gnutls \
    libsdl-gfx1.2 libsdl-image1.2 libsdl-mixer1.2 libsdl-net1.2 libsdl-ttf2.0 \
    wget unzip

pwd
ls

# --retry-on-host-error unknown option?
wget --retry-connrefused --tries=10 --waitretry=5 \
    --progress=dot:mega \
    -O "$client_job_name.zip" \
    "https://git.themanaworld.org/mana/appimg-builder/-/jobs/artifacts/$client_branch/download?job=$client_job_name"

# Docker will cache the unpacked files, so make unzip only extract
# if the archive contains newer ones. The same filesystem will
# most likely contain exctracted MV/M+ from both CI jobs.
unzip -o -u "$client_job_name.zip" -d "$client_job_name"
pushd "$client_job_name"
# Print package sums to troubleshoot docker caching
printf "Using debian packages with the following checksums:\n"
cat deb-sha256checksum.txt
dpkg -i "manaplus-data_latest_all.deb"
dpkg -i "manaplus_latest_amd64.deb"
dpkg -i "manaplus-dbg_latest_amd64.deb"
popd

PATH="$PATH:/usr/games"
export SDL_VIDEODRIVER=dummy
manaplus --version || exit 1
manaplus --validate -u -d clientdata || exit 1

log_path="$HOME/.local/share/mana/$logfile"
if [[ ! -f "$log_path" ]]; then
    printf "Error: logfile %s not found\n" "$log_path"
    exit 1
fi

# grep exits 0 (OK) if it found matches, this condition inverts it
if grep -A 10 "Assert:" "$log_path"; then
    echo "Error: Asserts found"
    exit 1
fi
