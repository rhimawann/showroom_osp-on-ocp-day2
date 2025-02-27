export COMPUTE_IP=${IP:-172.22.0.110}
export CIDR=24

CMD="openstack tripleo deploy"

CMD_ARGS+=" --templates /usr/share/openstack-tripleo-heat-templates"
CMD_ARGS+=" --deployment-user cloud-user"
CMD_ARGS+=" --local-ip=$COMPUTE_IP/$CIDR"
CMD_ARGS+=" -r $HOME/compute_role_standalone.yaml"
CMD_ARGS+=" -n $HOME/network_data.yaml"
CMD_ARGS+=" --output-dir $HOME"

ENV_ARGS+=" -e /usr/share/openstack-tripleo-heat-templates/environments/standalone/standalone-tripleo.yaml"
ENV_ARGS+=" -e /usr/share/openstack-tripleo-heat-templates/environments/deployed-network-environment.yaml"
ENV_ARGS+=" -e $HOME/deployed_network_compute_02.yaml"
ENV_ARGS+=" -e $HOME/containers-prepare-parameters.yaml"
ENV_ARGS+=" -e $HOME/standalone_parameters_compute_02.yaml"
ENV_ARGS+=" -e $HOME/disable-validations.yaml"
ENV_ARGS+=" -e $HOME/standalone_compute.yaml"
ENV_ARGS+=" -e $HOME/passwords.yaml"
ENV_ARGS+=" -e $HOME/endpoint-map.json"
ENV_ARGS+=" -e $HOME/all-nodes-extra-map-data.json"
ENV_ARGS+=" -e $HOME/extra-host-file-entries.json"
ENV_ARGS+=" -e $HOME/oslo.yaml"

sudo ${CMD} ${CMD_ARGS} ${ENV_ARGS}
sudo systemctl restart tripleo_ovn*