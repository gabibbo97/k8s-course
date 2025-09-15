#!/bin/sh
N_NODES=${N_NODES:-3}

#
# number of servers
#

if [ $N_NODES -lt 3 ]; then
  N_SERVERS=1
else
  N_SERVERS=3
fi

#
# ansible
#

echo '# automatically generated' > ansible.inventory

#
# ssh key
#

if ! [ -f ssh.key ]; then
  echo 'Generating ssh key'
  ssh-keygen -f ssh.key -q -N '' -t ed25519
fi

#
# ssh script
#

(
  echo '#!/bin/sh'
  # shellcheck disable=SC2016
  echo 'case $1 in'
  echo '  all)'
  echo '    shift'
  for i in $(seq 1 "${N_NODES}"); do
    echo "    echo '=== node${i} ===' && sh \"\$0\" node${i} \"\$@\"; echo ''"
  done
  echo '    ;;'
  echo ''
  for i in $(seq 1 "${N_NODES}"); do
    echo "  # node${i}"
    echo "  ${i}|node${i})"
    echo "    shift"
    echo "    exec sh '$(pwd)/ssh-node${i}.sh' \"\$@\""
    echo "    ;;"
    echo ""
  done
  echo "  *)"
  echo "    echo 'Unknown node, available nodes are:'"
  for i in $(seq 1 "${N_NODES}"); do
    echo "    echo '  - node$i'"
  done
  echo "    exit 1"
  echo "    ;;"
  echo 'esac'
) > ssh.sh

#
# create nodes
#

for node_i in $(seq 1 "${N_NODES}"); do
  # start VM
  sudo systemd-run \
    "--unit=testbed-node${node_i}.service" \
    --description="Testbed Node ${node_i} VM" \
    --remain-after-exit \
    --same-dir \
    "--property=Environment=NODE_N=${node_i}" \
    sh ./lib-start-vm.sh &

  # ansible
  echo "node${node_i}.k8scourse.serics.eu ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' ansible_user=user ansible_host=172.16.42.${node_i}0 ansible_ssh_private_key_file=${PWD}/ssh.key" >> ansible.inventory

done
wait

# ansible inventory

echo '' >> ansible.inventory
echo '[all:vars]' >> ansible.inventory
echo 'k8s_api_loadbalancer_dns=api-lb.k8scourse.serics.eu' >> ansible.inventory
echo 'k8s_api_loadbalancer_dns_srv=_k8s-server._tcp.k8scourse.serics.eu' >> ansible.inventory
echo 'k8s_api_loadbalancer_port=8443' >> ansible.inventory
echo 'k8s_api_loadbalancer_ip=172.16.42.5' >> ansible.inventory

echo '' >> ansible.inventory
echo '[k8s-servers]' >> ansible.inventory
for server_i in $(seq 1 "${N_SERVERS}"); do
  echo "node${server_i}.k8scourse.serics.eu" >> ansible.inventory
done

echo '' >> ansible.inventory
echo '[k8s-workers]' >> ansible.inventory
for server_i in $(seq "$((N_SERVERS + 1))" "${N_NODES}"); do
  echo "node${server_i}.k8scourse.serics.eu" >> ansible.inventory
done