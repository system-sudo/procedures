### Python script to deletes all images from Docker Hub repo except last 5 images and latest in all repo of Docker Hub.

## ✅ How to Use

### Install dependencies:
```sh
pip install requests
```

### Save the script to a file:
```sh
sudo nano docker_cleanup.py
```

copy and paste the below script
```sh
import requests

# Deletes all images from repo except last 5 and latest in all repo of Docker Hub.
# Replace with your Docker Hub username and personal access token
USERNAME = "your_dockerhub_username"
TOKEN = "your_personal_access_token"

BASE_URL = "https://hub.docker.com/v2"
HEADERS = {"Authorization": f"Bearer {TOKEN}"}

def get_repositories(username):
    repos = []
    page = 1
    while True:
        url = f"{BASE_URL}/repositories/{username}/?page={page}&page_size=100"
        response = requests.get(url, headers=HEADERS)
        data = response.json()
        repos.extend([repo['name'] for repo in data['results']])
        if not data.get('next'):
            break
        page += 1
    return repos

def get_tags(username, repo):
    tags = []
    page = 1
    while True:
        url = f"{BASE_URL}/repositories/{username}/{repo}/tags/?page={page}&page_size=100"
        response = requests.get(url, headers=HEADERS)
        data = response.json()
        tags.extend([tag['name'] for tag in data['results']])
        if not data.get('next'):
            break
        page += 1
    return tags

def delete_tag(username, repo, tag):
    url = f"{BASE_URL}/repositories/{username}/{repo}/tags/{tag}/"
    response = requests.delete(url, headers=HEADERS)
    if response.status_code == 204:
        print(f"Deleted tag '{tag}' from repository '{repo}'")
    else:
        print(f"Failed to delete tag '{tag}' from repository '{repo}': {response.status_code}")

def cleanup_repository(username, repo):
    tags = get_tags(username, repo)
    numeric_tags = sorted([int(tag) for tag in tags if tag.isdigit()], reverse=True)
    keep_tags = set(map(str, numeric_tags[:5])) | {"latest"}
    for tag in tags:
        if tag not in keep_tags:
            delete_tag(username, repo, tag)

def main():
    repositories = get_repositories(USERNAME)
    for repo in repositories:
        print(f"Cleaning up repository: {repo}")
        cleanup_repository(USERNAME, repo)

if __name__ == "__main__":
    main()
```


The script is also in https://github.com/system-sudo/procedures/blob/main/python_scripts/docker_cleanup.py

### Replace with your actual credentials in the script.  
your_dockerhub_username  
your_personal_access_token

### Run the script:
```sh
python3 docker_cleanup.py
```
