#!/bin/bash

client_repo="https://git.themanaworld.org/$1"
client_branch="$2"
client_job_name="$3"
dl_dir="${1//\//_}_$client_job_name" #mana_verse_pkg_deb or the like
clientdata_path="$PWD"
logfile="$4"

set -e

export HOME="$PWD/logs/home"
rm -rf "$PWD/logs/"
mkdir -p "$PWD/logs/"
wget_log="$PWD/logs/wget.log"

source ./.tools/init.sh


# Stop tzdata from asking to pick a location, hanging the pipeline
export DEBIAN_FRONTEND=noninteractive

aptget_update
aptget_install wget unzip

cd ..
pwd
ls -lah # timestamps for rough idea of version..
mkdir -p "$dl_dir"
pushd "$dl_dir"
ls -lah

# --no-if-modified-since to make only-newer downloads work.
wget --retry-connrefused --tries=10 --waitretry=5 \
    --timestamping --no-if-modified-since \
    --retry-on-host-error \
    --progress=dot:mega \
    "$client_repo/-/jobs/artifacts/$client_branch/download?job=$client_job_name" \
    2>&1 | tee "$wget_log"

zip_path=""
while read -r line; do
    if [[ $line =~ ^"Saving to: '"(.*)"'"$ || \
          $line =~ ^"File '"(.*)"' not modified on server. Omitting download."$ ]]; then
        if [[ -z $zip_path ]]; then
            zip_path="${BASH_REMATCH[1]}"
        else
            printf 'Multiple matches, aborting!\n'
            exit 1
        fi
    fi
done <"$wget_log"

if [[ -z $zip_path ]]; then
    printf 'Unable to determine zip path, aborting!\n'
    exit 1
fi
printf 'Zip path: %s\n' "$zip_path"

# Docker will cache the unpacked files, so make unzip only extract
# if the archive contains newer ones. The same filesystem will
# most likely contain extracted MV/M+ from both CI jobs.
# Unfortunately there's no way to tell unzip to delete files not in
# archive, which will become a problem when version is included.
rm -rf packages
unzip -o -u "$zip_path" -d packages
# Print package sums to troubleshoot docker caching
printf "Using debian packages with the following checksums:\n"
cat packages/deb-sha256checksum.txt
ls -lah packages # timestamps for rough idea of version..
# apt-get takes care of dependencies for us.
aptget_install ./packages/*.deb
rm -rf packages # And we'll delete them anyways, so there's no point caching.
popd

PATH="$PATH:/usr/games"
export SDL_VIDEODRIVER=dummy
manaplus --version || exit 1
manaplus --validate -u -d "$clientdata_path" || exit 1

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
