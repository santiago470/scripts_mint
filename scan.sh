#!/bin/bash

# Verificar se nmap está instalado
if ! command -v nmap &> /dev/null; then
    echo "nmap nao esta instalado. A instalar..."
    sudo apt install nmap -y
fi

# Detetar rede local a partir do gateway
GATEWAY=$(ip route | grep default | awk '{print $3}')
REDE=$(ip route | grep default | awk '{print $3}' | sed 's/\.[0-9]*$/.0\/24/')

echo "Gateway: $GATEWAY"
echo "Rede: $REDE"
echo ""
echo "1) Listar todos os dispositivos na rede"
echo "2) Ver sistema operativo de um dispositivo especifico"
echo "3) Ambos"
read -p "Escolha [1-3]: " OPCAO

case $OPCAO in
    1)
        echo ""
        echo "A escanear a rede $REDE ..."
        sudo nmap -sn "$REDE"
        ;;
    2)
        read -p "IP do dispositivo: " IP
        echo ""
        echo "A escanear $IP ..."
        sudo nmap -O "$IP"
        ;;
    3)
        echo ""
        echo "A escanear a rede $REDE ..."
        sudo nmap -sn "$REDE"
        echo ""
        read -p "IP do dispositivo para ver SO: " IP
        echo ""
        echo "A escanear $IP ..."
        sudo nmap -O "$IP"
        ;;
    *)
        echo "Opcao invalida."
        exit 1
        ;;
esac
