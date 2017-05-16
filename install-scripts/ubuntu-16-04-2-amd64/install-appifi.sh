#!/bin/bash

set -e

DASH="------------------------------------------------------------"

function banner {
	echo ""
	echo $DASH
	echo "$1"
	echo $DASH
	echo ""
}


bash -c "systemctl stop appifi-bootstrap.service"
bash -c "systemctl stop appifi-bootstrap-update.service"

stopAppifi

banner "install nodejs"
curl -sL https://deb.nodesource.com/setup_6.x | bash -
apt -y install nodejs

banner "install docker"
apt -y install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt update
apt -y install docker-ce

banner "install dependencies"
apt -y install avahi-daemon avahi-utils build-essential python-minimal btrfs-tools imagemagick ffmpeg samba udisks2

banner "stop and disable samba service"
systemctl stop smbd nmbd
systemctl disable smbd nmbd

banner "pull bootstrap files"
mkdir -p /wisnuc/bootstrap
wget -O /wisnuc/bootstrap/appifi-bootstrap-update.packed.js  https://raw.githubusercontent.com/wisnuc/appifi-bootstrap-update/release/appifi-bootstrap-update.packed.js
wget -O /wisnuc/bootstrap/appifi-bootstrap.js.sha1 https://raw.githubusercontent.com/wisnuc/appifi-bootstrap/release/appifi-bootstrap.js.sha1

banner "install and start appifi-bootstrap and appifi-bootstrap-update service"
cat > /lib/systemd/system/appifi-bootstrap.service <<EOF
[Unit]
Description=Appifi Bootstrap Server
After=network.target

[Service]
Type=idle
ExecStartPre=/bin/cp /wisnuc/bootstrap/appifi-bootstrap.js.sha1 /wisnuc/bootstrap/appifi-bootstrap.js
ExecStart=/usr/bin/node /wisnuc/bootstrap/appifi-bootstrap.js
TimeoutStartSec=3
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat > /lib/systemd/system/appifi-bootstrap-update.service <<EOF
[Unit]
Description=Appifi Bootstrap Update

[Service]
Type=simple
ExecStart=/usr/bin/node /wisnuc/bootstrap/appifi-bootstrap-update.packed.js
EOF

cat > /lib/systemd/system/appifi-bootstrap-update.timer <<EOF
[Unit]
Description=Runs Appifi Bootstrap Update every 4 hour

[Timer]
OnBootSec=5min
OnUnitActiveSec=4h
Unit=appifi-bootstrap-update.service

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable appifi-bootstrap
systemctl enable appifi-bootstrap-update.timer
systemctl start appifi-bootstrap
systemctl start appifi-bootstrap-update.timer

echo "WISNUC system successfully installed."

for (( i=30; i>0; i--)); do
    printf "\rJump to login in $i seconds, or hit any key to continue."
    read -s -n 1 -t 1 key
    if [ $? -eq 0 ]
    then
        break
    fi
done

