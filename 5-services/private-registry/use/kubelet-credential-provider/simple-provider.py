#!/usr/bin/env python3
import json
import os
import sys

from datetime import datetime

# settings
USERNAME = 'registry-user'
PASSWORD = 'registry-password'

# make logging fifo
FIFO_PATH = '/run/kubelet-credential-provider-log.sock'
if not os.path.exists(FIFO_PATH):
    try:
        os.mkfifo(FIFO_PATH, mode = 0o600)
    except FileExistsError:
        pass

# parse input json
input_json = json.load(sys.stdin)

# return credentials
output_json = {
    'apiVersion': 'credentialprovider.kubelet.k8s.io/v1',
    'kind': 'CredentialProviderResponse',
    'cacheKeyType': 'Image',
    'auth': {
        input_json['image']: {
            'username': USERNAME,
            'password': PASSWORD,
        }
    }
}
print(json.dumps(output_json))

# log to fifo
fifo_fd = os.open(FIFO_PATH, os.O_RDWR | os.O_NONBLOCK)
os.write(fifo_fd, json.dumps({
    'timestamp': datetime.now().isoformat(sep = 'T'),
    'input': input_json,
    'output': output_json,
}).encode() + b'\n')
