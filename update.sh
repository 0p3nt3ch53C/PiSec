#!/bin/bash

sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y
sudo apt-get autoremove -y && sudo apt-get autoclean -y
sudo apt-get clean -y
