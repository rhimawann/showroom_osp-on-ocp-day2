#!/bin/bash
#
# Copyright 2023 Red Hat Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
set -ex

EDPM_COMPUTE_SRIOV_ENABLED=${EDPM_COMPUTE_SRIOV_ENABLED:-false}
EDPM_COMPUTE_DHCP_AGENT_ENABLED=${EDPM_COMPUTE_DHCP_AGENT_ENABLED:-false}
COMPUTE_DRIVER=${COMPUTE_DRIVER:-"libvirt"}
INTERFACE_MTU=${INTERFACE_MTU:-1500}
BARBICAN_ENABLED=${BARBICAN_ENABLED:-false}
MANILA_ENABLED=${MANILA_ENABLED:-false}
SWIFT_REPLICATED=${SWIFT_REPLICATED:-false}
TLSE_ENABLED=${TLSE_ENABLED:-false}
CLOUD_DOMAIN=${CLOUD_DOMAIN:-localdomain}
TELEMETRY_ENABLED=${TELEMETRY_ENABLED:-true}
HEAT_ENABLED=${HEAT_ENABLED:-true}
OCTAVIA_ENABLED=${OCTAVIA_ENABLED:-false}
IPA_IMAGE=${IPA_IMAGE:-"quay.io/freeipa/freeipa-server:fedora-41"}
NTP_SERVER=pool.ntp.org

# Use the files created in the previous steps including the network_data.yaml file and thw deployed_network.yaml file.
# The deployed_network.yaml file hard codes the IPs and VIPs configured from the network.sh

export NEUTRON_INTERFACE=eth1
export CTLPLANE_IP=${IP:-172.22.0.15}
export CTLPLANE_VIP=${CTLPLANE_VIP:-172.22.0.16}
export CIDR=24
export GATEWAY=${GATEWAY:-10.0.2.1}
export BRIDGE="br-ex"
BRIDGE_MAPPINGS=${BRIDGE_MAPPINGS:-"datacentre:${BRIDGE}"}
NEUTRON_FLAT_NETWORKS=${NEUTRON_FLAT_NETWORKS:-"datacentre"}

CMD="openstack tripleo deploy --keep-running"

CMD_ARGS+=" --templates /usr/share/openstack-tripleo-heat-templates"
CMD_ARGS+=" --local-ip=$CTLPLANE_IP/$CIDR"
CMD_ARGS+=" --control-virtual-ip=$CTLPLANE_VIP"
CMD_ARGS+=" --output-dir $HOME"
CMD_ARGS+=" --standalone-role Standalone"
CMD_ARGS+=" -r $HOME/Standalone.yaml"
CMD_ARGS+=" -n $HOME/network_data.yaml"

ENV_ARGS+=" -e /usr/share/openstack-tripleo-heat-templates/environments/standalone/standalone-tripleo.yaml"
ENV_ARGS+=" -e /usr/share/openstack-tripleo-heat-templates/environments/low-memory-usage.yaml"
ENV_ARGS+=" -e /usr/share/openstack-tripleo-heat-templates/environments/deployed-network-environment.yaml"
ENV_ARGS+=" -e /usr/share/openstack-tripleo-heat-templates/environments/cinder-backup.yaml"
if [ "$COMPUTE_DRIVER" = "ironic" ]; then
    ENV_ARGS+=" -e /usr/share/openstack-tripleo-heat-templates/environments/services/ironic-overcloud.yaml"
    ENV_ARGS+=" -e /usr/share/openstack-tripleo-heat-templates/environments/services/ironic-inspector.yaml"
fi
if [ "$HEAT_ENABLED" = "true" ]; then
    cat <<EOF > enable_heat.yaml
resource_registry:
  OS::TripleO::Services::HeatApi: /usr/share/openstack-tripleo-heat-templates/deployment/heat/heat-api-container-puppet.yaml
  OS::TripleO::Services::HeatApiCfn: /usr/share/openstack-tripleo-heat-templates/deployment/heat/heat-api-cfn-container-puppet.yaml
  OS::TripleO::Services::HeatEngine: /usr/share/openstack-tripleo-heat-templates/deployment/heat/heat-engine-container-puppet.yaml
EOF
    ENV_ARGS+=" -e $HOME/enable_heat.yaml"
fi
if [ "$BARBICAN_ENABLED" = "true" ]; then
    ENV_ARGS+=" -e /usr/share/openstack-tripleo-heat-templates/environments/services/barbican.yaml"
    ENV_ARGS+=" -e /usr/share/openstack-tripleo-heat-templates/environments/barbican-backend-simple-crypto.yaml"
fi
if [ "$MANILA_ENABLED" = "true" ]; then
    ENV_ARGS+=" -e /usr/share/openstack-tripleo-heat-templates/environments/manila-cephfsnative-config.yaml"
fi

if [ "$OCTAVIA_ENABLED" = "true" ]; then
    ENV_ARGS+=" -e /usr/share/openstack-tripleo-heat-templates/environments/services/octavia.yaml"
fi
if [ "$TELEMETRY_ENABLED" = "true" ]; then
    ENV_ARGS+=" -e /usr/share/openstack-tripleo-heat-templates/environments/enable-legacy-telemetry.yaml"
fi
ENV_ARGS+=" -e $HOME/standalone_parameters.yaml"
ENV_ARGS+=" -e $HOME/containers-prepare-parameters.yaml"
ENV_ARGS+=" -e $HOME/deployed_network.yaml"
ENV_ARGS+=" -e $HOME/disable-validations.yaml"
ENV_ARGS+=" -e $HOME/service-reassignments.yaml"
ENV_ARGS+=" -e $HOME/nfs-storage.yaml"
ENV_ARGS+=" -e $HOME/oslo.yaml"

sudo ${CMD} ${CMD_ARGS} ${ENV_ARGS}
