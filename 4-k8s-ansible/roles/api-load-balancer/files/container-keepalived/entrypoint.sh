#!/bin/sh

# check parameters
STATE=${STATE:-BACKUP}
INTERFACE=${INTERFACE:-eth0}
ROUTER_ID=${ROUTER_ID:-51}
PRIORITY=${PRIORITY:-100}
AUTH_PASS=${AUTH_PASS:-secret}
APISERVER_VIP=${APISERVER_VIP:-192.168.1.100}
APISERVER_PORT=${APISERVER_PORT:-6443}

# write check_apiserver.sh
cat > /etc/keepalived/check_apiserver.sh <<-EOF
#!/bin/sh
if ! curl --silent --insecure https://localhost:${APISERVER_PORT}/healthz >/dev/null; then
  exit 1
fi
exit 0
EOF
chmod +x /etc/keepalived/check_apiserver.sh

# write config file
tee /etc/keepalived/keepalived.conf <<-EOF
! /etc/keepalived/keepalived.conf
! Configuration File for keepalived
global_defs {
    router_id LVS_DEVEL
}

vrrp_script check_apiserver {
  script "/etc/keepalived/check_apiserver.sh"
  interval 3
  weight -2
  fall 10
  rise 2
}

vrrp_instance VI_1 {
    state ${STATE}
    interface ${INTERFACE}
    virtual_router_id ${ROUTER_ID}
    priority ${PRIORITY}
    authentication {
        auth_type PASS
        auth_pass ${AUTH_PASS}
    }
    virtual_ipaddress {
        ${APISERVER_VIP}
    }
    track_script {
        check_apiserver
    }
}
EOF
exec "$(command -v keepalived)" --dont-fork --log-console -f /etc/keepalived/keepalived.conf
