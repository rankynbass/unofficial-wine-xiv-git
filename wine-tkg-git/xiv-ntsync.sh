#!/bin/bash

sed -i 's/_use_ntsync="false"/_use_ntsync="true"/' customization.cfg
sed -i 's/_use_esync="true"/_use_esync="false"/' customization.cfg
sed -i 's/_use_fsync="true"/_use_fsync="false"/' customization.cfg
