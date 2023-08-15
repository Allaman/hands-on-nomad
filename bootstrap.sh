#!/bin/bash
apt-get update -y

set -e

# install docker-ce
apt-get install -y ca-certificates curl gpg
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg
echo "deb [arch="$(dpkg --print-architecture)" signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/debian "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# install java
apt-get install -y openjdk-17-jdk

# install nomad
apt-get install -y wget gpg coreutils
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt-get update && apt-get install -y nomad

# Download CNI plugins
curl -L -o cni-plugins.tgz "https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-$([ $(uname -m) = aarch64 ] && echo arm64 || echo amd64)"-v1.3.0.tgz
mkdir -p /opt/cni/bin
tar -C /opt/cni/bin -xzf cni-plugins.tgz

cat <<EOT >/etc/nomad.d/config.hcl
log_level = "DEBUG"
acl {
  enabled = true
}
client {
  enabled = true
}
server {
  enabled = true
  bootstrap_expect = 1
}
datacenter = "dc1"
data_dir = "/opt/nomad"
name =  "example.com"
EOT

cat <<EOT >/etc/systemd/system/nomad.service
[Unit]

Description=Nomad
Documentation=https://nomadproject.io/docs/
Wants=network-online.target
After=network-online.target

[Service]
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/bin/nomad agent -config /etc/nomad.d
KillMode=process
KillSignal=SIGINT
LimitNOFILE=infinity
LimitNPROC=infinity
Restart=on-failure
RestartSec=2
StartLimitBurst=3
TasksMax=infinity

[Install]
WantedBy=multi-user.target
EOT

systemctl daemon-reload
systemctl enable nomad.service
systemctl start nomad.service

nomad -autocomplete-install
TOKEN=$(nomad acl bootstrap | grep "Secret ID" | awk '{print $4}')
echo "$TOKEN" >bootstrap.token
export NOMAD_TOKEN=$(cat bootstrap.token)
echo "Use this token for setting up"
echo "$NOMAD_TOKEN"
