#!/bin/bash

# Set the project ID
PROJECT_ID="unique-provider-362520"

# Set the instance name
INSTANCE_NAME="instance-1"

# Set the machine type
MACHINE_TYPE="n1-highmem-4"

# Set the disk size in GB
DISK_SIZE_GB="20"

# Set the image family and project
IMAGE_FAMILY="ubuntu-2204-lts"
IMAGE_PROJECT="ubuntu-os-cloud"

# Set the accelerator type and count
ACCELERATOR_TYPE="nvidia-tesla-t4"
ACCELERATOR_COUNT="1"

# Set the list of zones with GPU support
ZONES=("asia-northeast3-b" "asia-northeast3-c" "asia-south1-a" "asia-south1-b" "asia-southeast1-a" "asia-southeast1-b" "asia-southeast1-c" "asia-southeast2-b" "australia-southeast1-a" "australia-southeast1-c" "europe-central2-c" "europe-west1-b" "europe-west1-c" "europe-west1-d" "europe-west2-b" "europe-west3-b" "europe-west4-a" "europe-west4-b" "europe-west4-c" "me-west1-b" "me-west1-c" "northamerica-northeast1-c" "southamerica-east1-b" "southamerica-east1-c" "us-central1-a" "us-central1-b" "us-central1-c" "us-central1-f" "us-east1-c" "us-east1-d" "us-east4-a" "us-east4-b" "us-east4-c" "us-west1-a" "us-west1-b" "us-west2-c" "us-west3-b" "us-west4-a" "us-west4-b")

# Function to create the instance
create_instance() {

  local current_zone="$1"

  # Create the instance
  gcloud compute instances create $INSTANCE_NAME \
    --custom-cpu=4 \
    --custom-memory=20GB \
    --image-family=$IMAGE_FAMILY \
    --image-project=$IMAGE_PROJECT \
    --accelerator=type=$ACCELERATOR_TYPE,count=$ACCELERATOR_COUNT \
    --boot-disk-size=$DISK_SIZE_GB \
    --boot-disk-type=pd-balanced \
    --zone=$current_zone \
    --project=$PROJECT_ID \
    --maintenance-policy TERMINATE --restart-on-failure
}

# Display progress message
echo "Creating the instance..."

# Variable to track the failed zones
failed_zones=()

# Loop through the zones
for zone in "${ZONES[@]}"; do
  create_instance $zone

  # Check if the instance creation was successful
  if [ $? -eq 0 ]; then
    echo "Instance created successfully in zone $zone!"
    exit 0
  else
    echo "Failed to create instance in zone $zone. Retrying with a different zone..."
    failed_zones+=($zone)
  fi
done

echo "Failed to create instance in all available zones:"
echo "${failed_zones[@]}"
exit 1

