#!/bin/bash

TRUSTED_STORE=../
TRUSTED_BASE_IMAGE=debian-13-genericcloud-amd64.qcow2
BUILT_IMAGE_NAME=debian-13-genericcloud-amd64-hproxy.qcow2

rm -rf debian-13-genericcloud-*
cp $TRUSTED_STORE$TRUSTED_BASE_IMAGE ./$BUILT_IMAGE_NAME

virt-customize -a $BUILT_IMAGE_NAME \
    --update \
    --install haproxy \
    --run-command 'systemctl enable haproxy'\
    --upload etc/haproxy/haproxy.cfg:/etc/haproxy/haproxy.cfg \
    --run-command "cloud-init clean" \
    --run-command "truncate -s 0 /etc/machine-id"

chmod 444 $BUILT_IMAGE_NAME
sha256sum $BUILT_IMAGE_NAME > $BUILT_IMAGE_NAME.sha256
