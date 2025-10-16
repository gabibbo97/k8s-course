# Reading etcd

1. Install `etcdctl`

```sh
apt-get update && apt-get install -y etcd-client
```

2. Write the environment variables to access etcd

```sh
export ETCDCTL_API=3
export ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt
export ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt
export ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key
export ETCDCTL_ENDPOINTS=https://127.0.0.1:2379
```

3. List all the keys in etcd

```sh
etcdctl get "" --prefix --keys-only
```

## Spying on a Secret

1. Create a Secret

```sh
kubectl create secret generic mysecret --from-literal=password='s3cr3t'
```

2. Find the key of the Secret in etcd

```sh
etcdctl get "" --prefix --keys-only | grep mysecret
```

3. Read the Secret from etcd

```sh
etcdctl get /registry/secrets/default/mysecret | hexdump -C
```
