# Docker Image Existence Checker

This script checks whether the specified Docker images exist in a private Docker Hub repository. It uses the Docker Hub API to verify image presence without actually pulling the images. A progress bar is displayed while the script is running, and results are formatted for clarity.

## Prerequisites

Before using the script, ensure the following:

1. **Dependencies**:
   - `jq`: This JSON parsing tool is required for processing Docker Hub API responses.
   - `curl`: Used for making HTTP requests to the Docker Hub API.
2. **Docker Hub Credentials**:
   - Set the `DOCKER_USERNAME` and `DOCKER_PASSWORD` environment variables with your Docker Hub username and password.

## Input File

The script expects a file named `docker-images.txt` in the same directory. This file should contain a list of Docker images (one per line) in the format:

```
repo_name/image_name:tag
```

- Lines starting with `#` or empty lines are ignored.
- If a tag is not specified, the script defaults to `latest`.

## Script Overview

### 1. **Authentication**
The script first authenticates with Docker Hub using the provided credentials. It retrieves a token via the Docker Hub API to authenticate subsequent requests.

### 2. **Image Check**
For each image listed in the `docker-images.txt` file:
- The script queries the Docker Hub API for the image tag.
- If the image exists, it is added to the "present" list; otherwise, it is added to the "not present" list.

### 3. **Progress Bar**
A dynamic progress bar runs while the script processes the images. The bar updates in real time to reflect the progress percentage.

### 4. **Formatted Output**
After completing the checks, the script displays:
- A list of images present in Docker Hub.
- A list of images not found in Docker Hub.

## Usage

### Step 1: Set Up the Environment
Ensure the required environment variables are set:

```bash
export DOCKER_USERNAME="your_username"
export DOCKER_PASSWORD="your_password"
```

### Step 2: Prepare the Input File
Create a `docker-images.txt` file containing the list of images to check.

Example:
```text
repo_name/image_name:tag
repo_name/another_image:latest
# This is a comment
```

### Step 3: Run the Script
Make the script executable and run it:

```bash
chmod +x check_docker_images.sh
./check_docker_images.sh
```

### Example Output
During Execution:
```plaintext
Progress : [##############################--------------] 75%
```

After Completion:
```plaintext
Successfully authenticated with Docker Hub.

-------------------
Images present in Docker Hub:
-------------------
repo_name/image_name:tag
repo_name/another_image:latest

-------------------
Images not present in Docker Hub:
-------------------
repo_name/missing_image:tag
```

## Error Handling

1. **File Not Found**:
   If the `docker-images.txt` file is missing, the script exits with an error message:
   ```
   Error: File 'docker-images.txt' not found!
   ```

2. **Authentication Failure**:
   If authentication fails, the script exits with:
   ```
   Error: Failed to retrieve Docker Hub token. Please check your credentials.
   ```

3. **Empty Input File**:
   If the input file contains no valid entries, the script exits with:
   ```
   No valid Docker images found in 'docker-images.txt'.
   ```

## Customization

- **Progress Bar Duration**:
   The progress bar dynamically updates based on the number of images, ensuring it runs till 100%.
- **File Name**:
   To use a different input file, modify the `INPUT_FILE` variable in the script:
   ```bash
   INPUT_FILE="your_custom_file.txt"
   ```

## License

This script is open-source and available for modification under the MIT License.

