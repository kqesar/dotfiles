#!bin/bash

sudo dpkg --add-architecture i386
sudo add-apt-repository ppa:lutris-team/lutris
sudo apt-get update
sudo apt-get install lutris
sudo apt install libvulkan1 libvulkan1:i386 
