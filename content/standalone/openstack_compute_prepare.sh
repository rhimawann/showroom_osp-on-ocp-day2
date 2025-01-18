unset OS_CLOUD
export OS_AUTH_TYPE=none
export OS_ENDPOINT=http://127.0.0.1:8006/v1/admin

sudo egrep "oslo.*password" /etc/puppet/hieradata/service_configs.json \
| sed -e s/\"//g -e s/,//g >> $HOME/oslo.yaml

cp $HOME/tripleo-standalone-passwords.yaml $HOME/passwords.yaml