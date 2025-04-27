#!/bin/bash

sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y
sudo apt-get autoremove -y && sudo apt-get autoclean -y
sudo apt-get clean -y

# Retrieve Payload All the Things
git clone --depth 1 https://github.com/swisskyrepo/PayloadsAllTheThings.git PATT 

# Retrieve SecLists
git clone --depth 1 https://github.com/danielmiessler/SecLists.git SL
