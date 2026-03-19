#!/bin/bash

# Configurações
CONEXAO="Ligação com fios 1"
DNS_ADGUARD="192.168.1.87"

echo "O que pretendes fazer?"
echo "1 - Ligar AdGuard (DNS: $DNS_ADGUARD)"
echo "2 - Desligar AdGuard (DNS Automático do Router)"
read -p "Escolha [1 ou 2]: " opcao

if [ "$opcao" == "1" ]; then
    sudo nmcli connection modify "$CONEXAO" ipv4.dns "$DNS_ADGUARD"
    sudo nmcli connection modify "$CONEXAO" ipv4.ignore-auto-dns yes
    sudo nmcli connection up "$CONEXAO"
    echo "Sucesso: AdGuard Ativado!"
elif [ "$opcao" == "2" ]; then
    sudo nmcli connection modify "$CONEXAO" ipv4.dns ""
    sudo nmcli connection modify "$CONEXAO" ipv4.ignore-auto-dns no
    sudo nmcli connection up "$CONEXAO"
    echo "Sucesso: DNS Automático Ativado!"
else
    echo "Opção inválida."
fi
