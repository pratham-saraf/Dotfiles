#!/bin/bash

# Define the path to the build_info.json file
json_file="/opt/discord/resources/build_info.json"

# Check if the json file exists
if [ -f "$json_file" ]; then
    # Get the existing version number
    version=$(jq -r '.version' $json_file)

    # Split into array and increment revision
    version_parts=(${version//./ })
    ((version_parts[3]++))

    # Compose new version
    new_version="${version_parts[0]}.${version_parts[1]}.${version_parts[2]}.${version_parts[3]}"

    # Write new version to json file
    jq --arg new_version "$new_version" '.version = $new_version' $json_file > "tmp.json" && sudo mv "tmp.json" $json_file
else
    echo "build_info.json file not found"
fi

