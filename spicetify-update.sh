#!/bin/bash
# Tenta aplicar o backup e as modificações
spicetify backup apply

# Se falhar, restaura e tenta de novo
if [ $? -ne 0 ]; then
    echo "A tentativa inicial falhou. A tentar restaurar e reconfigurar..."
    spicetify restore
    spicetify backup apply
fi

spicetify apply

