#!/bin/bash

openssl genrsa -out /etc/etcd/pki/ca.key 4096
openssl req -x509 -new -nodes -key /etc/etcd/pki/ca.key -sha256 -days 3650 -out /etc/etcd/pki/ca.crt -subj "/CN=etcd-builder-CA"
openssl genrsa -out /etc/etcd/pki/server.key 2048
openssl req -new -key /etc/etcd/pki/server.key -out /etc/etcd/pki/server.csr -subj "/CN=etcd-bootstrap" -addext "subjectAltName=DNS:$HOSTNAME,IP:$(ip -4 addr show dev eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')"
openssl x509 -req -in /etc/etcd/pki/server.csr -CA /etc/etcd/pki/ca.crt -CAkey /etc/etcd/pki/ca.key -CAcreateserial -out /etc/etcd/pki/server.crt -days 3650 -sha256