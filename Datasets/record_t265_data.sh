#!/bin/bash

DATASETS_DIR="$HOME/ORB_SLAM3/Datasets"
ARCHIVE_DIR="$DATASETS_DIR/archive"
BASE_FOLDER="realsense_t265"
CALIBRATION_DIR="$HOME/ORB_SLAM3/Examples/Calibration"
PROCESS_SCRIPT_DIR="$CALIBRATION_DIR/python_scripts"
RECORDER_EXEC="$CALIBRATION_DIR/recorder_realsense_T265_v2"

# Ensure necessary directories exist
mkdir -p "$DATASETS_DIR"
mkdir -p "$ARCHIVE_DIR"

# Find the next available folder name
FOLDER_NAME="$BASE_FOLDER"
COUNT=1
while [ -d "$DATASETS_DIR/$FOLDER_NAME" ]; do
    FOLDER_NAME="${BASE_FOLDER}_v$COUNT"
    COUNT=$((COUNT + 1))
done

DATASET_PATH="$DATASETS_DIR/$FOLDER_NAME"
ARCHIVE_PATH="$ARCHIVE_DIR/$FOLDER_NAME"

# Create dataset structure
mkdir -p "$DATASET_PATH/cam0" "$DATASET_PATH/cam1" "$DATASET_PATH/IMU"

# Run the recording executable and wait for user to stop it
sudo "$RECORDER_EXEC" "$DATASET_PATH"
echo "Recording stopped. Proceeding with data processing..."

# Process IMU data
cd "$PROCESS_SCRIPT_DIR" || exit
python3 process_imu.py "$DATASET_PATH"

# Organize recorded data
cd "$DATASET_PATH" || exit
mkdir mav0
mv cam0 cam1 IMU mav0/

# Organize cam0 and cam1 data
cd mav0/cam0 || exit
if [ -f times.txt ]; then
    mv times.txt "$DATASET_PATH/"
fi
mkdir -p data
mv *.png data/

cd ../cam1 || exit
mkdir -p data
mv *.png data/

# Rename IMU folder and ensure imu0.csv is correctly placed
cd ../
mv IMU imu0
cd imu0 || exit
if [ -f "$DATASET_PATH/imu0.csv" ]; then
    mv "$DATASET_PATH/imu0.csv" data.csv
elif [ -f imu0.csv ]; then
    mv imu0.csv data.csv
else
    echo "Warning: imu0.csv not found. Check if the recording process completed successfully."
fi

# Move acc.txt and gyro.txt to the archive directory
mkdir -p "$ARCHIVE_PATH"
if [ -f acc.txt ] || [ -f gyro.txt ]; then
    mv acc.txt gyro.txt "$ARCHIVE_PATH/"
    echo "IMU raw data moved to archive: $ARCHIVE_PATH"
else
    echo "Warning: acc.txt and gyro.txt not found. Check if the recording process completed successfully."
fi

# Final message
echo "Data recording and organization complete. Data stored in $DATASET_PATH"
