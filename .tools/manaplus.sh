#!/bin/bash

client_repo="https://git.themanaworld.org/$1"
client_branch="$2"
client_job_name="$3"
logfile="$4"
# One cache directory per client, branch and job, e.g. mana_verse_master_pkg_deb
dl_dir="${1//\//_}_${client_branch}_${client_job_name}"
clientdata_path="$PWD"

set -e

export HOME="$PWD/logs/home"
rm -rf "$PWD/logs/"
mkdir -p "$PWD/logs/"

source ./.tools/init.sh


# Stop tzdata from asking to pick a location, hanging the pipeline
export DEBIAN_FRONTEND=noninteractive

aptget_update
aptget_install ca-certificates curl unzip

cd ..
pwd
mkdir -p "$dl_dir"
pushd "$dl_dir"
ls -lah

# GitLab sends neither Last-Modified nor ETag for artifacts, so downloads
# can't be skipped based on timestamps. The artifact URL does redirect to
# the job that produced it though, so cache the zip under that job id.
artifact_url="$client_repo/-/jobs/artifacts/$client_branch/download?job=$client_job_name"
printf "Checking for latest artifact at %s...\n" "$artifact_url"
job_url=$(curl --silent --show-error --fail --output /dev/null \
    --retry 10 --retry-connrefused \
    --write-out '%{redirect_url}' "$artifact_url")
job_id="${job_url##*/jobs/}"
job_id="${job_id%%/*}"
if [[ ! $job_id =~ ^[0-9]+$ ]]; then
    printf 'Unable to determine job id from %s, aborting!\n' "$job_url"
    exit 1
fi
zip_path="$job_id.zip"

if [[ -f $zip_path ]]; then
    printf 'Using cached %s\n' "$zip_path"
else
    printf 'Downloading artifacts of job %s\n' "$job_id"
    # Only the latest job is of any use, so drop older downloads.
    rm -f ./*.zip ./*.zip.part
    curl --silent --show-error --fail --location \
        --retry 10 --retry-connrefused \
        --output "$zip_path.part" "$job_url"
    mv "$zip_path.part" "$zip_path"
fi

rm -rf packages
unzip -o "$zip_path" -d packages
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
