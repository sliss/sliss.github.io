#!/bin/bash

# Loop through all files in current directory
for file in *; do
    # Skip if it's not a file
    [ -f "$file" ] || continue
    
    # Skip the script itself
    [ "$file" = "rename-to-kebab.sh" ] && continue
    
    # Create new filename:
    # 1. Convert to lowercase
    # 2. Replace spaces and underscores with hyphens
    # 3. Remove special characters except hyphens and dots
    # 4. Replace multiple hyphens with single hyphen
    newname=$(echo "$file" | \
        tr '[:upper:]' '[:lower:]' | \
        tr ' _' '-' | \
        sed 's/[^a-z0-9.-]/-/g' | \
        sed 's/-\+/-/g')
    
    # Rename only if the filename is different
    if [ "$file" != "$newname" ]; then
        mv "$file" "$newname"
        echo "Renamed: $file → $newname"
    fi
done
