#!/bin/sh

cat > /target/lib/systemd/system/wisnuc-installer.service <<'EOF'
[Unit]
Description=Wisnuc Installer
Before=getty@tty1.service
After=multi-user.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/wisnuc-installer
StandardInput=tty
StandardOutput=inherit
StandardError=inherit

[Install]
WantedBy=multi-user.target
EOF

cat > /target/usr/bin/wisnuc-installer <<'EOF'
#!/bin/bash

URL=https://raw.githubusercontent.com/wisnuc/appifi-system/master/install-scripts/ubuntu-16-04-02-amd64/install-appifi.sh
SHA1=/wisnuc/bootstrap/appifi-bootstrap.js.sha1
UPDATE=/wisnuc/bootstrap/appifi-bootstrap-update.packed.js

if [ -f $SHA1 ] || [ -f $UPDATE ]; then exit 0; fi

systemctl is-active appifi-bootstrap.service
if [ $? -eq 0 ]; then systemctl stop appifi-bootstrap.service; fi

systemctl is-active appifi-bootstrap-update.service
if [ $? -eq 0 ]; then systemctl stop appifi-bootstrap-update.service; fi

mkdir -p /wisnuc
curl -s $URL | bash - 2>&1 | tee /wisnuc/install.log

if [ $? -ne 0 ]; then
  echo "----------------------------------"
  echo "wisnuc installation failed"
  echo "see /wisnuc/install.log for detail"
  echo "----------------------------------"
  sleep 10
else
  systemctl disable wisnuc-installer.service
  echo "----------------------------------"
  echo "wisnuc system successfully installed"
  echo "----------------------------------"
  sleep 10
fi
EOF

in-target systemctl enable wisnuc-installer.service
