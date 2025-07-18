#!/bin/bash


git_executable=$(which git)
webkit_repo_url="https://github.com/WebKit/WebKit.git"
webkit_container_sdk_repo_url="https://github.com/Igalia/webkit-container-sdk.git"

# Function to check command execution status
check_exit_status() {
    if [ $? -ne 0 ]; then
        echo "Error: Command failed. Please check the output above."
        exit 1
    fi
}

# Check if git is installed and webkit-container-sdk directory doesn't exist
if [ -x "${git_executable}" ] && [ ! -d "webkit-container-sdk" ]; then
    # Configure git buffer size
    "${git_executable}" config --global http.postBuffer 2737418240
    check_exit_status

    # Clone repositories
    "${git_executable}" clone --depth 1 "${webkit_repo_url}" 2>&1
    check_exit_status

    "${git_executable}" clone "${webkit_container_sdk_repo_url}" 2>&1
    check_exit_status
else
    if [ ! -x "${git_executable}" ]; then
        echo "Error: Git is not installed or not executable."
        exit 1
    fi
    if [ -d "webkit-container-sdk" ]; then
        echo "Warning: webkit-container-sdk directory already exists. Skipping clone."
    fi
fi


if ! command -v podman &> /dev/null; then sudo apt-get -y install podman; fi
if ! command -v lsmod &> /dev/null; then  sudo apt-get update &&  sudo apt-get install kmod;  fi

cd webkit-container-sdk || {
    echo "Error: Failed to change to webkit-container-sdk directory."
    exit 1
}




# Source the SDK registration script
source ./register-sdk-on-host.sh 2>&1
check_exit_status

# Execute wkdev commands
wkdev-create --create-home 2>&1
check_exit_status

wkdev-enter 2>&1
check_exit_status