#!/usr/bin/env bash

ssh-keygen -t rsa -b 4096 -C "malcomgilbert@gmail.com" -N "" -f "$HOME/.ssh/id_rsa"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa

echo ""
echo "printing ssh-key:"
cat ~/.ssh/id_rsa.pub
