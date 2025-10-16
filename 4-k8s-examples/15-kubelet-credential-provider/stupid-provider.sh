#!/bin/sh
image=$(jq -r '.image' < /dev/stdin)
cat <<EOF
{
  "apiVersion": "credentialprovider.kubelet.k8s.io/v1",
  "kind": "CredentialProviderResponse",
  "cacheKeyType": "Image",
  "auth": {
    "${image}": {
      "username": "aaa",
      "password": "bbb"
    }
  }
}
EOF
