#!/bin/bash

git_executable=$(which git)
webkit_repo_url="https://github.com/WebKit/WebKit.git"
webkit_container_sdk_repo_url="https://github.com/Igalia/webkit-container-sdk.git"

check_exit_status() {
    if [ $? -ne 0 ]; then
        echo "Error: Command failed. Please check the output above."
        exit 1
    fi
}

# Check if git is installed and webkit-container-sdk directory doesn't exist
if [ -x "${git_executable}" ] && [ ! -d "webkit-container-sdk" ]; then
    "${git_executable}" config --global http.postBuffer 2737418240
    check_exit_status

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

if ! command -v podman &> /dev/null; then 
    sudo apt-get -y install podman
    check_exit_status
fi
if ! command -v lsmod &> /dev/null; then 
    sudo apt-get update && sudo apt-get install -y kmod
    check_exit_status
fi

cd webkit-container-sdk || { echo "Error: Failed to change to webkit-container-sdk directory."; exit 1}


source ./register-sdk-on-host.sh 2>&1
check_exit_status

wkdev-create --create-home 2>&1
check_exit_status

wkdev-enter 2>&1
check_exit_status

cd /host/home/$USER/WebKit || { echo "Error: Failed to change to WebKit directory.";exit 1}
Tools/Scripts/build-webkit --gtk --release 2>&1
check_exit_status

echo "Importing W3C WebDriver BiDi Test Suite..."
Tools/Scripts/import-webdriver-tests --w3c 2>&1
check_exit_status

importer_json="WebDriverTests/imported/w3c/importer.json"
if [ -f "$importer_json" ]; then
    echo "Checking paths_to_import in $importer_json..."
    grep '"paths_to_import"' "$importer_json" | grep -q 'webdriver' || {
        echo "Warning: 'webdriver' not found in paths_to_import. Please update $importer_json and rerun import-webdriver-tests."
    }
else
    echo "Warning: $importer_json not found. Ensure import-webdriver-tests completed successfully."
fi

echo "Running BiDi Test..."
pip install mozdebug mozlog mozterm mozprocess --quiet 2>&1
check_exit_status

Tools/Scripts/run-webdriver-tests --gtk --release --verbose --display-server=xvfb \
  imported/w3c/webdriver/tests/bidi/session/subscribe/user_contexts.py::test_subscribe_multiple_user_contexts 2>&1
check_exit_status

echo "Script completed successfully."