#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#


# test setup: prepare test folder for download test file
testFolder=../sample-media/test
FILENAME_DOWNLOAD=test/test.mp4
DEFAULT_FILE_PATH_NAME=../sample-media/test/test-3840-15-bench.mp4
FILE_URL_TO_DOWNLOAD=https://storage.openvinotoolkit.org/data/test_data/videos/smartlab/v3/stream_1_left.mp4
mkdir $testFolder

cleanupTestFolder() {
  echo 
  echo "remove test folder..."
  rm -rf "$testFolder"
  echo "done."
}

cleanupTestFolderContent() {
    echo "remove all files under test folder..."
    # remove downloaded files so it's re-testable
    rm -f "$testFolder/*"
}

# test case 1: test without image
echo
echo "# test case 1: test without image"
docker image tag dlstreamer:2.0 test-dlstreamer:2.0
docker rmi dlstreamer:2.0

FIND_IMAGE_SCO=$(docker images --format "{{.Repository}}" | grep "sco-")

output=$(./format_avc_mp4.sh $FILENAME_DOWNLOAD $FILE_URL_TO_DOWNLOAD) 
statusCode=$?
if [ -z "$FIND_IMAGE_SCO" ]
then
    if [ $statusCode == 1 ]
    then
        echo "test PASSED: test without image and got expected status code of 1"
    else
        echo "test FAILED: expecting status code 1, but got something else"
    fi
else
    echo "test FAILED: Image found"
fi
# rename back the images
docker image tag test-dlstreamer:2.0 dlstreamer:2.0
docker rmi test-dlstreamer:2.0
cleanupTestFolderContent

# test case 2: test with image, got statusCode 0 and test media file downloaded (happy path)
echo
echo "# test case 2: test with image, got statusCode 0 and test media file downloaded (happy path)"
output=$(./format_avc_mp4.sh $FILENAME_DOWNLOAD $FILE_URL_TO_DOWNLOAD)  
statusCode=$?
echo "$statusCode"
if [ $statusCode == 0 ]
then
    if [ -f "$DEFAULT_FILE_PATH_NAME" ]
    then
        echo "test PASSED: $DEFAULT_FILE_PATH_NAME has been downloaded for $FILENAME_DOWNLOAD with $FILE_URL_TO_DOWNLOAD."
    else
        echo "test FAILED: $DEFAULT_FILE_PATH_NAME has NOT been downloaded for $FILENAME_DOWNLOAD with $FILE_URL_TO_DOWNLOAD."
    fi
else
    echo "test FAILED: expecting status code 0 but found $statusCode for $FILENAME_DOWNLOAD with $FILE_URL_TO_DOWNLOAD."
fi
cleanupTestFolderContent

# test case 3: download 2nd time, expect message "Skipping..."
SUB="Skipping..."
echo
echo "# test case 3: download 2nd time, expect message \"$SUB\""
output=$(./format_avc_mp4.sh $FILENAME_DOWNLOAD $FILE_URL_TO_DOWNLOAD)  
statusCode=$?
if [ $statusCode == 0 ]
then
    if test -f "$DEFAULT_FILE_PATH_NAME"; then
        #download again
        output=$(./format_avc_mp4.sh $FILENAME_DOWNLOAD $FILE_URL_TO_DOWNLOAD)  
        statusCode=$?
        if [ $statusCode == 0 ]
        then
            if [[ "$output" == "$SUB"* ]]
            then
                echo "test PASSED: Second time download was skipped!"
            else
                echo "test FAILED: Second time download was missing skipped message!"
            fi
        else
            echo "test FAILED: Second time download ERROR: $output: expecting status code 0 but found $statusCode."
        fi
    else
        echo "test FAILED: download $FILENAME_DOWNLOAD first time failed"
    fi
else
    echo "test FAILED: download $FILENAME_DOWNLOAD first time failed: $output: expecting status code 0 but found $statusCode."
fi
cleanupTestFolderContent


# test case 4: input resize, expect file name with resize in the file name (happy path)
echo
echo "# test case 4: input resize, expect file name with resize in the file name (happy path)"
WIDTH=1080
HEIGHT=720
FPS=10
output=$(./format_avc_mp4.sh $FILENAME_DOWNLOAD $FILE_URL_TO_DOWNLOAD $WIDTH $HEIGHT $FPS)  
statusCode=$?
FILE_PATH_NAME=../sample-media/test/test-$WIDTH-$FPS-bench.mp4
if [ $statusCode == 0 ]
then
    if test -f "$FILE_PATH_NAME"; then
        echo "test PASSED: with input width $WIDTH, height $HEIGHT, FPS $FPS."
    else
        echo "test FAILED: with input width $WIDTH, height $HEIGHT, FPS $FPS: couldn't find downloaded file $FILE_PATH_NAME."
    fi
else
    echo "test FAILED: with input width $WIDTH, height $HEIGHT, FPS $FPS: expecting status code 0 but found $statusCode."
fi
cleanupTestFolderContent

# test case 5: input Width should be integer type
echo
echo "# test case 5: input Width should be integer type"
WIDTH=8abv
HEIGHT=720
FPS=10
EXPECTED_MESSAGE="ERROR: width should be integer."
output=$(./format_avc_mp4.sh $FILENAME_DOWNLOAD $FILE_URL_TO_DOWNLOAD, $WIDTH $HEIGHT $FPS)
statusCode=$?
if [ $statusCode == 1 ]
then
    if [[ "$output" == "$EXPECTED_MESSAGE" ]]
    then
        echo "test PASSED: check for invalid width input"
    else
        echo "test FAILED: check for invalid width input"
    fi
else
    echo "test FAILED: check for invalid width input, it should return status code of 1"
fi
cleanupTestFolderContent

# test case 6: input Height should be integer type
echo
echo "# test case 6: input Height should be integer type"
WIDTH=1035
HEIGHT=8.0fd
FPS=10
EXPECTED_MESSAGE="ERROR: height should be integer."
output=$(./format_avc_mp4.sh $FILENAME_DOWNLOAD $FILE_URL_TO_DOWNLOAD, $WIDTH $HEIGHT $FPS)
statusCode=$?
if [ $statusCode == 1 ]
then
    if [[ "$output" == "$EXPECTED_MESSAGE" ]]
    then
        echo "test PASSED: check for invalid height input"
    else
        echo "test FAILED: check for invalid height input"
    fi
else
    echo "test FAILED: check for invalid height input, it should return status code of 1"
fi
cleanupTestFolderContent

# test case 7: input FPS should be float or integer type
echo
echo "# test case 7: input FPS should be float or integer type"
WIDTH=1035
HEIGHT=335
FPS=a.09
EXPECTED_MESSAGE="ERROR: FPS should be number."
output=$(./format_avc_mp4.sh $FILENAME_DOWNLOAD $FILE_URL_TO_DOWNLOAD, $WIDTH $HEIGHT $FPS)
statusCode=$?
if [ $statusCode == 1 ]
then
    if [[ "$output" == "$EXPECTED_MESSAGE" ]]
    then
        echo "test PASSED: check for invalid FPS input"
    else
        echo "test FAILED: check for invalid FPS input"
    fi
else
    echo "test FAILED: check for invalid FPS input, it should return status code of 1"
fi
cleanupTestFolderContent

# clean up: remove the test folder
cleanupTestFolder




