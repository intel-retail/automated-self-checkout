#!/usr/bin/env bash
# USAGE LOG_DIRECTORY
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

fix_igt_json() {
   echo "Fix IGT JSON called"
    sed -i -e s/^}$/},/ $1
    sed -i '$ s/.$//' $1
    tmp_file=/tmp/tmp.json
    echo '[' > $tmp_file
    cat $1 >> $tmp_file
    echo ']' >> $tmp_file
    mv $tmp_file $1
}

if [ -z "$1" ]
then
	echo "Missing log_directory"
	exit 1
fi

LOG_DIRECTORY=$1

echo "fixing igt and xpum for files in $LOG_DIRECTORY"
if [ -e ${LOG_DIRECTORY}/igt0.json ]; then
    echo "fixing igt0.json"
    fix_igt_json ${LOG_DIRECTORY}/igt0.json
    #./fix_json.sh ${LOG_DIRECTORY}
fi
if [ -e ${LOG_DIRECTORY}/igt1.json ]; then
    echo "fixing igt1.json"
    fix_igt_json ${LOG_DIRECTORY}/igt1.json
fi

#move the xpumanager dump files
devices=(0 1 2)
for device in ${devices[@]}; do
    xpum_file=${LOG_DIRECTORY}/device${device}*.csv
    if [ -e $xpum_file ]; then
    echo "==== Stopping xpumanager collection (device ${device}) ===="
    cat $xpum_file | \
    python3 -c 'import csv, json, sys; print(json.dumps([dict(r) for r in csv.DictReader(sys.stdin)]))' > xpum${device}.json
    mv xpum${device}.json ${LOG_DIRECTORY}/xpum${device}.json
    fi
done
