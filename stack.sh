#!/bin/bash -xe

sudo mkdir -p /opt/stack
sudo chown -R ${USER}. /opt/stack

# Clone repository if not present, otherwise update
if [ ! -f /opt/stack/stack.sh ]; then
    git clone https://git.openstack.org/openstack-dev/devstack /opt/stack
else
    pushd /opt/stack
    git pull
    popd
fi

# Create DevStack configuration file
cat <<EOF > /opt/stack/local.conf
[[local|localrc]]
# General
GIT_BASE=https://github.com

# Secrets
DATABASE_PASSWORD=root
RABBIT_PASSWORD=secrete123
SERVICE_PASSWORD=secrete123
ADMIN_PASSWORD=secrete123

# Keystone
KEYSTONE_ADMIN_ENDPOINT=true

# Glance
GLANCE_LIMIT_IMAGE_SIZE_TOTAL=10000

# Cinder
VOLUME_BACKING_FILE_SIZE=50G

# Nova
LIBVIRT_TYPE=kvm

# Neutron
enable_plugin neutron https://opendev.org/openstack/neutron
FIXED_RANGE=10.1.0.0/20

# Barbican
enable_plugin barbican https://opendev.org/openstack/barbican

# Octavia
enable_plugin octavia https://opendev.org/openstack/octavia
enable_plugin ovn-octavia-provider https://opendev.org/openstack/ovn-octavia-provider
enable_service octavia o-api o-cw o-hm o-hk o-da

# Magnum
enable_plugin magnum https://github.com/stefan-chivu/magnum.git management-cluster-driver
enable_plugin magnum-ui https://opendev.org/openstack/magnum-ui

# Manila
LIBS_FROM_GIT=python-manilaclient
enable_plugin manila https://opendev.org/openstack/manila
enable_plugin manila-ui https://opendev.org/openstack/manila-ui
enable_plugin manila-tempest-plugin https://opendev.org/openstack/manila-tempest-plugin

SHARE_DRIVER=manila.share.drivers.generic.GenericShareDriver
MANILA_ENABLED_BACKENDS=generic
MANILA_OPTGROUP_generic_driver_handles_share_servers=True
MANILA_OPTGROUP_generic_connect_share_server_to_tenant_network=True
MANILA_DEFAULT_SHARE_TYPE_EXTRA_SPECS='snapshot_support=True create_share_from_snapshot_support=True'
MANILA_CONFIGURE_DEFAULT_TYPES=True

MANILA_SERVICE_IMAGE_ENABLED=True
MANILA_USE_SERVICE_INSTANCE_PASSWORD=True

[[post-config|/etc/magnum/magnum.conf]]
[cluster_template]
kubernetes_allowed_network_drivers = calico
kubernetes_default_network_driver = calico
EOF

# Start DevStack deployment
/opt/stack/stack.sh

# Install `kubectl` CLI
curl -Lo /tmp/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl

echo 'source <(kubectl completion bash)' >>~/.bashrc
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -o default -F __start_kubectl k' >>~/.bashrc
source ~/.bashrc
