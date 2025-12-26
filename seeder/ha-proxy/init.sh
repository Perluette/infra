#!/bin/bash

# https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2

rm -rf debian-13-genericcloud-*
cp ../debian-13-genericcloud-amd64.qcow2 ./debian-13-genericcloud-amd64.qcow2

virt-customize -a debian-13-genericcloud-amd64.qcow2 \
    --update \
    --install haproxy \
    --run-command 'systemctl enable haproxy'\
    --upload etc/haproxy/haproxy.cfg:/etc/haproxy/haproxy.cfg \
    --run-command "cloud-init clean" \
    --run-command "truncate -s 0 /etc/machine-id"

chmod 444 debian-13-genericcloud-amd64.qcow2
sha256sum debian-13-genericcloud-amd64.qcow2 > debian-13-genericcloud-amd64.qcow2.sha256
