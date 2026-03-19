#!/bin/bash
echo "IP Local (USB): $(hostname -I | awk '{print $1}')"
echo "IP Público:     $(curl -s https://ifconfig.me)"
echo "Gateway:        $(ip route | grep default | awk '{print $3}')"

