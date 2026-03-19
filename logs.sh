#!/bin/bash

echo "A limpar logs antigos..."

# Limpar logs com mais de 7 dias
sudo find /var/log -type f -name "*.log" -mtime +7 -delete
sudo find /var/log -type f -name "*.gz" -mtime +7 -delete
sudo find /var/log -type f -name "*.old" -mtime +7 -delete

# Limpar journal do systemd (manter apenas os últimos 7 dias)
sudo journalctl --vacuum-time=7d

echo "Logs antigos limpos com sucesso!"
