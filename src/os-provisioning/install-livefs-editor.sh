#!/bin/bash

apt install xorriso squashfs-tools python3-debian gpg liblz4-tool python3-pip -y

# the installation of python3-pip can cause some issues. Try different ways to install it if it fails

git clone https://github.com/mwhudson/livefs-editor

cd livefs-editor/

python3 -m pip install .
