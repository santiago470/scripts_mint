#!/bin/bash
# Limpa a memória da sessão atual
history -c
# Esvazia o ficheiro de registo
truncate -s 0 ~/.bash_history
# Aplica as mudanças
history -w
