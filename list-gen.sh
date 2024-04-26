#!/bin/bash

root_dir="." # Set the root directory

# Function to compute SHA-256 and update list.json
update_list_json() {
    local dir=$1
    local file_path=$2
    local binary_name=$(basename "$file_path")
    local version=$(echo "$binary_name" | grep -o 'v[0-9]*\.[0-9]*\.[0-9]*')
    local sha256

    if command -v sha256sum >/dev/null; then
        sha256=$(sha256sum "$file_path" | awk '{print $1}')
    elif command -v shasum >/dev/null; then
        sha256=$(shasum -a 256 "$file_path" | awk '{print $1}')
    else
        echo "Error: No suitable command for computing SHA-256 checksums."
        exit 1
    fi

    local list_path="${dir}/list.json"
    if [ ! -f "$list_path" ]; then
        echo '{"builds": [], "releases": {}}' > "$list_path"
    fi

    # Update or append new data
    jq --arg version "$version" --arg sha256 "$sha256" --arg binary "$binary_name" \
       'del(.builds[] | select(.version == $version)) | .builds += [{"version": $version, "sha256": $sha256}] | .releases[$version] = $binary' \
       "$list_path" > "${list_path}.tmp" && mv "${list_path}.tmp" "$list_path"
}

export -f update_list_json

# Find and process each binary file
find $root_dir -type f -name 'zksolc-*' -exec bash -c 'update_list_json "$(dirname "{}")" "{}"' \;

echo "Updated list.json files for all binaries."
