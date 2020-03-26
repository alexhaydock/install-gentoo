#!/bin/bash

latest="{{ mirror }}/releases/amd64/autobuilds/latest-stage3-amd64-systemd.txt"

# currently using the systemd stage3 tarball
stage3_path=$(curl $latest 2>&1 | grep "stage3-amd64-systemd-" | awk '{print $1}')

# debug
echo $stage3_path

wget "{{ mirror }}/releases/amd64/autobuilds/$stage3_path" -O stage3.tar.bz2
