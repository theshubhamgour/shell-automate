#!/bin/bash

# Input file name
INPUT_FILE="docker-images.txt"

# Check if the input file exists
if [[ ! -f "$INPUT_FILE" ]]; then
  echo "Error: File '$INPUT_FILE' not found!"
  exit 1
fi

# Retrieve Docker Hub authentication token
DOCKER_TOKEN=$(curl -s -H 'Content-Type: application/json' -X POST -d "{\"username\": \"${DOCKER_USERNAME}\", \"password\": \"${DOCKER_PASSWORD}\"}" https://hub.docker.com/v2/users/login/ | jq -r .token)

# Check if the token retrieval was successful
if [[ -z "$DOCKER_TOKEN" || "$DOCKER_TOKEN" == "null" ]]; then
  echo "Error: Failed to retrieve Docker Hub token. Please check your credentials."
  exit 1
fi

echo -e "\nSuccessfully authenticated with Docker Hub.\n"


# Arrays to store results
present_images=()
missing_images=()

# Function to check if a Docker image exists in the repository
check_docker_image() {
  local image_name=$1
  local repo_name=${image_name%%:*} # Extract repository name (before colon)
  local tag=${image_name##*:}      # Extract tag (after colon)

  # If no tag is specified, default to 'latest'
  if [[ "$repo_name" == "$tag" ]]; then
    tag="latest"
  fi

  # Query Docker Hub API for the image
  response=$(curl -s -H "Authorization: JWT $DOCKER_TOKEN" "https://hub.docker.com/v2/repositories/${repo_name}/tags/${tag}/")

  # Check if the response contains the image details
  if echo "$response" | jq -e '.name' > /dev/null 2>&1; then
    present_images+=("$image_name")
  else
    missing_images+=("$image_name")
  fi
}

# Iterate through each line in the file
while IFS= read -r image_name; do
  # Skip empty lines or lines starting with #
  if [[ -z "$image_name" || "$image_name" =~ ^# ]]; then
    continue
  fi

  # Check if the image exists
  check_docker_image "$image_name"
done < "$INPUT_FILE"

# Print grouped results
echo "-------------------"
echo "Images present in Docker Hub:"
echo "-------------------"
echo -e "\n"
if [[ ${#present_images[@]} -eq 0 ]]; then
  echo "None"
else
  for image in "${present_images[@]}"; do
    echo "$image"
  done
fi

echo -e "\n"
echo "-------------------"
echo -e "Images not present in Docker Hub:"
echo "-------------------"
echo -e "\n"
if [[ ${#missing_images[@]} -eq 0 ]]; then
  echo "None"
else
  for image in "${missing_images[@]}"; do
    echo "$image"
  done
fi

