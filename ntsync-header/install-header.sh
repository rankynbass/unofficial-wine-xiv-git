#!/usr/bin/env bash
if [ ! -e "/usr/include/linux/ntsync.h" ]; then
    echo "NTSync header is missing from /usr/include/linux. Installing..."
    mkdir -p /usr/include/linux
    cp ntsync-header/ntsync.h /usr/include/linux/ntsync.h
fi
echo "NTSync header is installed at /usr/include/linux/ntsync.h"
