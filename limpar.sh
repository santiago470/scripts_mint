#!/bin/bash
sudo apt autoremove -y
sudo apt autoclean
sudo apt clean
rm -rf ~/.cache/thumbnails/*
journalctl --vacuum-time=3d

