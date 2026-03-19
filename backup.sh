#!/bin/bash
cd ~/scripts
git add .
git commit -m "backup $(date '+%Y-%m-%d %H:%M')"
git push
echo "Scripts sincronizados com o GitHub!"
