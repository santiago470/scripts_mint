#!/bin/bash
# 2>/dev/null joga fora as mensagens de "Permissão recusada"
du -hs ~/* 2>/dev/null | sort -rh | head -n 10
