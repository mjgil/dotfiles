#!/usr/bin/env bash

ssh-keygen -t rsa -b 4096 -C "malcomgilbert@gmail.com" -N "" -f "$HOME/.ssh/id_rsa"
cat ~/.ssh/id_rsa.pub
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa

echo "printing ssh-key:"
cat ~/.ssh/id_rsa.pub
