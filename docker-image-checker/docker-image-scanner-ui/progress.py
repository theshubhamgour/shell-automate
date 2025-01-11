import tkinter as tk
from tkinter import messagebox
from tkinter import ttk
import requests
import json
from dotenv import load_dotenv
import os
import time

# Load environment variables from .env file
load_dotenv()
DOCKER_USERNAME = os.getenv("DOCKER_USERNAME")
DOCKER_PASSWORD = os.getenv("DOCKER_PASSWORD")

if not DOCKER_USERNAME or not DOCKER_PASSWORD:
    raise ValueError("DOCKER_USERNAME or DOCKER_PASSWORD is not set in the .env file.")

# Function to save Docker images to a file
def save_docker_images(image_text):
    try:
        with open("docker-images.txt", "w") as f:
            f.write(image_text.strip())
        return True
    except Exception as e:
        messagebox.showerror("Error", f"Failed to save file: {e}")
        return False

# Function to authenticate and get Docker Hub token
def get_docker_token():
    url = "https://hub.docker.com/v2/users/login/"
    headers = {"Content-Type": "application/json"}
    payload = json.dumps({"username": DOCKER_USERNAME, "password": DOCKER_PASSWORD})

    try:
        response = requests.post(url, headers=headers, data=payload)
        if response.status_code == 200:
            return response.json().get("token")
        else:
            messagebox.showerror("Error", "Authentication failed. Please check your credentials.")
            return None
    except Exception as e:
        messagebox.showerror("Error", f"Failed to authenticate: {e}")
        return None

# Function to check if Docker images exist
def scan_docker_images(token, images, progress):
    results = {"present": [], "not_present": []}

    total_images = len(images)
    for idx, image in enumerate(images):
        # Update the progress bar
        progress["value"] = (idx + 1) / total_images * 100
        app.update_idletasks()  # Refresh the UI to show the progress

        if ":" in image:
            repo_name, tag = image.split(":", 1)
        else:
            repo_name, tag = image, "latest"

        url = f"https://hub.docker.com/v2/repositories/{repo_name}/tags/{tag}/"
        headers = {"Authorization": f"JWT {token}"}

        try:
            response = requests.get(url, headers=headers)
            if response.status_code == 200:
                results["present"].append(image)
            else:
                results["not_present"].append(image)
        except Exception as e:
            results["not_present"].append(image)

    return results

# Function to handle scan button click
# Function to handle scan button click
def on_scan():
    image_text = image_textbox.get("1.0", tk.END).strip()

    if not image_text:
        messagebox.showerror("Error", "Please enter Docker image names.")
        return

    # Save Docker images to file
    if save_docker_images(image_text):
        token = get_docker_token()
        if token:
            # Filter out comments and empty lines
            images = [
                line.strip() 
                for line in image_text.splitlines() 
                if line.strip() and not line.strip().startswith("#")
            ]
            
            if not images:
                messagebox.showerror("Error", "No valid Docker images found. Please check your input.")
                return
            
            # Start the progress bar and scan images
            progress["value"] = 0
            app.update_idletasks()  # Refresh the UI to show the progress bar
            results = scan_docker_images(token, images, progress)

            # Display results in one line
            present = ", ".join(results["present"])  # Join with commas
            not_present = ", ".join(results["not_present"])  # Join with commas

            result_text = (
                f"Images Present in Docker Hub: {present}\n\n"
                f"Images Not Present in Docker Hub: {not_present}"
            )
            messagebox.showinfo("Scan Results", result_text)
            progress["value"] = 100  # Complete the progress bar



# Create the main application window
app = tk.Tk()
app.title("Docker Image Scanner")
app.geometry("600x400")

# Textbox for Docker images
image_label = tk.Label(app, text="Enter Docker Images (one per line):")
image_label.pack(pady=5)
image_textbox = tk.Text(app, height=10, width=50)
image_textbox.pack(pady=10)

# Progress bar
progress_label = tk.Label(app, text="Progress:")
progress_label.pack(pady=5)
progress = ttk.Progressbar(app, orient="horizontal", length=400, mode="determinate")
progress.pack(pady=10)

# Scan button
scan_button = tk.Button(app, text="Scan", command=on_scan, bg="green", fg="white")
scan_button.pack(pady=20)

# Run the application
app.mainloop()
