#!/bin/bash

# Input file name
INPUT_FILE="docker-images.txt"

# Check if the input file exists
if [[ ! -f "$INPUT_FILE" ]]; then
  echo "Error: File '$INPUT_FILE' not found!"
  exit 1
fi

# Retrieve Docker Hub authentication token
DOCKER_TOKEN=$(curl -s -H 'Content-Type: application/json' \
  -X POST -d "{\"username\": \"${DOCKER_USERNAME}\", \"password\": \"${DOCKER_PASSWORD}\"}" \
  https://hub.docker.com/v2/users/login/ | jq -r .token)

# Check if the token retrieval was successful
if [[ -z "$DOCKER_TOKEN" || "$DOCKER_TOKEN" == "null" ]]; then
  echo "Error: Failed to retrieve Docker Hub token. Please check your credentials."
  exit 1
fi
echo -e "\n"
echo "Successfully authenticated with Docker Hub."
echo -e "\n"
# Function to check if a Docker image exists in the repository
check_docker_image() {
  local image_name=$1
  local repo_name
  local tag

  # Extract repository name and tag
  if [[ "$image_name" == *:* ]]; then
    repo_name=${image_name%%:*}
    tag=${image_name##*:}
  else
    repo_name="$image_name"
    tag="latest"
  fi

  # Query Docker Hub API for the image
  response=$(curl -s -H "Authorization: JWT $DOCKER_TOKEN" \
    "https://hub.docker.com/v2/repositories/${repo_name}/tags/${tag}/")

  # Return 0 if the image exists, 1 otherwise
  if echo "$response" | jq -e '.name' > /dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# Read all lines and filter out empty lines and comments
mapfile -t all_images < <(grep -v -e '^\s*$' -e '^\s*#' "$INPUT_FILE")

total_images=${#all_images[@]}
if [[ "$total_images" -eq 0 ]]; then
  echo "No valid Docker images found in '$INPUT_FILE'."
  exit 0
fi

# Progress bar function
update_progress() {
  local current=$1
  local total=$2
  local bar_length=40

  local percent=$((current * 100 / total))
  local filled=$((bar_length * percent / 100))
  local bar=$(printf "%0.s#" $(seq 1 $filled))
  bar+=$(printf "%0.s-" $(seq $((filled + 1)) $bar_length))

  printf "\rProgress : [%-${bar_length}s] %3d%%" "$bar" "$percent"
}

# Categorize images
present_images=()
not_present_images=()

current_image=0
for image_name in "${all_images[@]}"; do
  check_docker_image "$image_name"
  if [[ $? -eq 0 ]]; then
    present_images+=("$image_name")
  else
    not_present_images+=("$image_name")
  fi
  current_image=$((current_image + 1))
  update_progress "$current_image" "$total_images"
done

# Ensure progress bar reaches 100%
update_progress "$total_images" "$total_images"
echo -e "\n"

# Display the results
echo -e "\n-------------------"
echo "Images present in Docker Hub:"
echo "-------------------"
for image in "${present_images[@]}"; do
  echo "$image"
done

echo -e "\n-------------------"
echo "Images not present in Docker Hub:"
echo -e "-------------------\n"
for image in "${not_present_images[@]}"; do
  echo "$image"
  echo -e "\n"
done

