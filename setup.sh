#!/bin/bash

sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt-get autoclean && sudo apt-get autoremove -y

curl -sSL https://get.docker.com | sh
dockerd-rootless-setuptool.sh install

# Retrieve raw files for wordlists:
mkdir WL && cd WL

# Retrieve Payload All the Things
git clone --depth 1 https://github.com/swisskyrepo/PayloadsAllTheThings.git WL/PATT 

# Retrieve SecLists
git clone --depth 1 https://github.com/danielmiessler/SecLists.git WL/SL

# Add fuzz DB
git clone --depth 1 https://github.com/fuzzdb-project/fuzzdb.git WL/FDB

# Get fuzz.txt wordlist
git clone --depth 1 https://github.com/Bo0oM/fuzz.txt WL/

# Get LFI Wordlist
git clone --depth 1 https://github.com/hussein98d/LFI-files.git WL/LFILIST

# Get Assetnote wordlists
# mkdir ASW && cd ASW
# wget -r --no-parent -R "index.html*" https://wordlists-cdn.assetnote.io/data/ -nH -e robots=off

# Retrieve tools
# Retrieve XSS Hunter (docker)
git clone --depth 1 https://github.com/mandatoryprogrammer/xsshunter-express.git Tools/XSH 
cd Tools/XSSH
DOCKER_BUILDKIT=1 docker build -t xsshunter:latest .
cd ../..
docker compose up -d postgresdb
# Start up the service
docker compose up xsshunter


# Retrieve Katana (docker)
git clone --depth 1 https://github.com/projectdiscovery/katana.git Tools/KTA
cd Tools/KTA
DOCKER_BUILDKIT=1 docker build -t katana:latest .
cd ../..
# Builds: docker.io/library/katana:latest
# Example: docker run -rm katana:latest -u http://scanme.nmap.org/ -system-chrome -headless | tee results/20250428-scanme.nmap.org.txt
# Example: docker run --rm katana:latest -jc -d 25 -u https://rei.com/ -system-chrome -headless | tee results/20250428-rei-d25.txt &
# NOTE: first time run intalls chrome.
# NOTE: Creates residual containers.

# Below no longer effective:
: '
# Retrieve GoSpider (docker)
git clone --depth 1 https://github.com/jaeles-project/gospider.git Tools/GOS
cd Tools/GOS
DOCKER_BUILDKIT=1 docker build -t gospider:latest .
cd ../..
# Example: docker run --rm gospider:latest -s "https://rei.com/" -v -c 10 -t 50 -d 25 --other-source --include-subs | tee results/20250429-gsp-rei-d25.txt &
# Example: docker run --rm gospider:latest -s "https://rei.com/" -v -c 10 -t 50 -d 25 --other-source --include-subs -H "Referer: https://www.rei.com" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36" -H 'sec-ch-ua: "Google Chrome";v="135", "Not-A.Brand";v="8", "Chromium";v="135"' -H 'sec-ch-ua-mobile: ?0' -H 'sec-ch-ua-platform: "Windows"' | tee results/20250429-gsp-rei-d25.txt &

# Retrieve ParamSpider (docker)
git clone --depth 1 https://github.com/devanshbatham/ParamSpider.git Tools/PSP
cd Tools/PSP
DOCKER_BUILDKIT=1 docker build -t paramspider:latest .
cd ../..
# Example: docker run --rm paramspider:latest -d "https://rei.com/" -s  | tee results/20250429-psp-rei-d25.txt &
'

# Asset Discovery Tools:
# Using CRT.sh (requires jq)
mkdir Tools/CRT && cd Tools/CRT
echo '#!/bin/bash ' > crt.sh
echo """echo "\$1"
curl 'https://crt.sh/?q=%.'\$1'&output=json' | jq -r '.[].name_value' | grep -v '*' | sort | uniq
""" >> crt.sh

# Create dockerfile
echo '''
FROM alpine:3.21.3
RUN apk --update add jq curl bash
COPY crt.sh /usr/local/bin/crt.sh
RUN chmod +x /usr/local/bin/crt.sh

ENTRYPOINT ["/bin/bash", "/usr/local/bin/crt.sh"]
''' > Dockerfile
DOCKER_BUILDKIT=1 docker build -t crt:latest .
cd ../..
# Example: docker run --rm crt:latest rei.com | tee results/20250429-crt-rei.txt &


# Retrieve Cero (docker)
# NO NEED FOR HAVING FILES: git clone --depth 1 https://github.com/glebarez/cero.git Tools/CER
cd Tools/CER
mv cero.go main.go
echo '''
FROM golang:1.23-alpine AS build-env
COPY . /app
WORKDIR /app
RUN go mod download
RUN go build -o /app .

FROM alpine:3.21.3
COPY --from=build-env /app /usr/local/bin/
ENTRYPOINT ["cero"]
''' > Dockerfile
DOCKER_BUILDKIT=1 docker build -t cero:latest .
cd ../..
# Example: docker run --rm cero:latest www.rei.com -v  | tee results/20250429-cer-rei.txt &


# Retrieve subfinder (docker)
git clone --depth 1 https://github.com/projectdiscovery/subfinder.git Tools/SBF
cd Tools/SBF
ls -a | grep -iv -e "Dockerfile" -e "v2" | xargs rm -rf
DOCKER_BUILDKIT=1 docker build -t subfinder:latest .
cd ../..
# Example: docker run --rm subfinder:latest -d rei.com -all  | tee results/20250429-sbf-rei.txt &


# Retrieve amass (docker)
git clone --depth 1 https://github.com/owasp-amass/amass.git Tools/AMA
cd Tools/AMA
DOCKER_BUILDKIT=1 docker build -t amass:latest .
cd ../..
# Example: docker run --rm amass:latest enum -active -d rei.com -v | tee results/20250429-ama-rei.txt &


# Retrieve nuclei (docker)
git clone --depth 1 https://github.com/projectdiscovery/nuclei.git Tools/NUC
cd Tools/NUC
sed -i 's/FROM\ golang\:1.22-alpine\ AS\ builder/FROM\ golang\:1.23-alpine\ AS\ builder/g' Dockerfile
sed -i 's/RUN\ make\ verify//g' Dockerfile
sed -i 's/FROM\ alpine:latest/FROM\ alpine:latest\nRUN\ apk\ add\ --no-cache\ git\nRUN\ git\ clone\ --depth\ 1\ https:\/\/github.com\/projectdiscovery\/nuclei-templates\ \/tmp\/nuclei-templates/g' Dockerfile
DOCKER_BUILDKIT=1 docker build -t nuclei:latest .
cd ../..
# Example: docker run --rm nuclei:latest -u https://www.rei.com | tee results/20250429-nuc-rei.txt &


# Retrieve waymore (docker)
git clone --depth 1 https://github.com/xnl-h4ck3r/waymore.git Tools/WAY
cd Tools/WAY
DOCKER_BUILDKIT=1 docker build -t waymore:latest .
cd ../..
# Example: docker run --rm waymore:latest waymore -i rei.com -mode B -v | tee results/20250429-ama-rei.txt &

# Retrieve shuffledns (docker)
git clone --depth 1 https://github.com/projectdiscovery/shuffledns.git Tools/SDNS
cd Tools/SDNS
ls -a | grep -iv "Dockerfile" | xargs rm -rf
DOCKER_BUILDKIT=1 docker build -t shuffledns:latest .
cd ../..
# Example: docker run --rm shuffledns:latest shuffledns -d rei.com

# Retrieve gobuster (docker)
git clone --depth 1 https://github.com/OJ/gobuster.git Tools/GBU
cd Tools/GBU
DOCKER_BUILDKIT=1 docker build -t gobuster:latest .
cd ../..
# Example: docker run --rm gobuster:latest dir -u rei.com

# Retrieve x8 (docker)
git clone --depth 1 https://github.com/Sh1Yo/x8.git Tools/X8
cd Tools/X8
ls -a | grep -iv -e "Dockerfile" -e "Cargo" -e "src" | xargs rm -rf
DOCKER_BUILDKIT=1 docker build -t x8:latest .
cd ../..
# Example: docker run --rm x8:latest -u "https://rei.com"

# Retrieve httpx (docker)
git clone --depth 1 https://github.com/projectdiscovery/httpx.git Tools/HTX
cd Tools/HTX
sed -i 's/apk\ add\ --no-cache\ git\ build-base\ gcc\ musl-dev//g' Dockerfile
DOCKER_BUILDKIT=1 docker build -t httpx:latest .
cd ../..
# Example: docker run --rm httpx:latest rei.com 

# remove all dangling data:
docker system prune --volumes -f

# Work in progress (WIP):
# https://github.com/d3mondev/puredns (to dockerize)
# https://github.com/C-Sto/recursebuster (to dockerize)
# https://github.com/s0md3v/Arjun (to dockerize)
# https://github.com/projectdiscovery/wappalyzergo (to dockerize)
# https://github.com/projectdiscovery/notify (docker)
# https://github.com/projectdiscovery/urlfinder (docker)
# Domain Listing: https://raw.githubusercontent.com/projectdiscovery/public-bugbounty-programs/refs/heads/main/chaos-bugbounty-list.json

# To look into converting:
# REF: https://github.com/PortSwigger/param-miner