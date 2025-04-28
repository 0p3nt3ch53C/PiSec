#!/bin/bash

curl -sSL https://get.docker.com | sh
dockerd-rootless-setuptool.sh install

# Retrieve raw files for wordlists:
# Retrieve Payload All the Things
git clone --depth 1 https://github.com/swisskyrepo/PayloadsAllTheThings.git PATT 

# Retrieve SecLists
git clone --depth 1 https://github.com/danielmiessler/SecLists.git SL

# Add fuzz DB
git clone --depth 1 https://github.com/fuzzdb-project/fuzzdb FDB

# Get fuzz.txt wordlist
git clone --depth 1 https://github.com/Bo0oM/fuzz.txt

# Get Assetnote wordlists
# mkdir ASW && cd ASW
# wget -r --no-parent -R "index.html*" https://wordlists-cdn.assetnote.io/data/ -nH -e robots=off

# Retrieve tools
# Retrieve XSS Hunter (docker)
git clone --depth 1 https://github.com/mandatoryprogrammer/xsshunter-express.git Tools/XSSH 

# Retrieve Katana (docker)
git clone --depth 1 https://github.com/projecstdiscovery/katana.git Tools/KTA
cd Tools/KTA
DOCKER_BUILDKIT=1 docker build -t katana:latest .
# Builds: docker.io/library/katana:latest
# Example: docker run katana:latest -u http://scanme.nmap.org/ -system-chrome -headless > results/20250428-scanme.nmap.org.txt
# NOTE: first time run intalls chrome.
# NOTE: Creates residual containers.

# Retrieve GoSpider (docker)
git clone --depth 1 https://github.com/jaeles-project/gospider.git Tools/GOS

# Retrieve ParamSpider (docker)
git clone --depth 1 https://github.com/devanshbatham/ParamSpider.git Tools/PSP

mkdir results && cd results

