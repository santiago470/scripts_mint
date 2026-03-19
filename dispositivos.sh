#!/bin/bash

# Descobre a rede local automaticamente
REDE=$(ip route | grep -oP '(\d+\.\d+\.\d+\.\d+/\d+)' | head -1)

echo "A procurar dispositivos em $REDE ..."
echo ""

# Usa nmap se disponível, senão faz ping sweep manual
if command -v nmap &>/dev/null; then
    nmap -sn "$REDE" | grep -E "Nmap scan report|MAC Address" | awk '
        /Nmap scan report/ { ip = $NF }
        /MAC Address/      { print ip, $0 }
        !/MAC Address/     { print ip }
    '
else
    echo "(nmap não encontrado, a usar ping sweep - mais lento)"
    echo ""
    BASE=$(echo "$REDE" | cut -d'.' -f1-3)
    for i in $(seq 1 254); do
        (ping -c1 -W1 "$BASE.$i" &>/dev/null && echo "$BASE.$i está online") &
    done
    wait
fi
