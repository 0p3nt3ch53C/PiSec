#!/bin/bash
# Arguments: $1 = domain
# Example: ./run.sh rei.com
set -x

if [ "$#" -ne 1 ]; then
  echo "Error: Please provide exactly one argument (either a domain or a Hacker One CSV file path formatted file)."
  exit 1
fi

argument="$1"

case "$argument" in
  "")
    echo "Error: Please provide exactly one argument (either a domain or a Hacker One CSV file path formatted file)."
    exit 1
    ;;
  -*)
    echo "Error: Argument cannot start with a dash."
    exit 1
    ;;
  *)
    # Check if the argument is a file
    if [ -f "$argument" ]; then
      echo "Argument is a file: $argument"
      # Add file processing logic here
      cat "$argument"
    else
      echo "Argument is a string: $argument"
      # Add string processing logic here
      echo "String length: ${#argument}"
    fi
    ;;
esac

echo "Attempting to retrieve domains for $1."

if [ -z "$1" ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi
if [ ! -d "results" ]; then
    mkdir results
fi
if [ -d "results/$1/" ]; then
    mv results/$1/ results/$1-$(date +%Y%m%d-%H%M%S)/
fi
mkdir -p results/$1/

# Retrieve domains
echo "Running subfinder..."
docker run --rm subfinder:latest -d $1 -all | tee results/$1/$(date +%Y%m%d)-SBF.txt

echo "Running crt..."
docker run --rm crt:latest $1 | tee results/$1/$(date +%Y%m%d)-CRT.txt

echo "Running cero..."
docker run --rm cero:latest $1 | tee results/$1/$(date +%Y%m%d)-CER.txt

# WIP - Requires filtering:
# echo "Running amass..."
# docker run --rm amass:latest enum -active -d $1 -v | tee results/$1/$(date +%Y%m%d)-AMA.txt

sort -u results/$1/$(date +%Y%m%d)-*.txt > results/$1/$(date +%Y%m%d)-DOMAINS.all
sed -i -e 's/^/https:\/\//' results/$1/$(date +%Y%m%d)-DOMAINS.all
tr '\n' ',' < results/$1/$(date +%Y%m%d)-DOMAINS.all > results/$1/$(date +%Y%m%d)-OLDOMAINS.all
echo "Found $(wc -l results/$1/$(date +%Y%m%d)-DOMAINS.all | awk '{print $1}') domains."

docker run -v $(pwd)/results/$1/:/app/paramspider/ --rm paramspider:latest -l /app/paramspider/$(date +%Y%m%d)-DOMAINS.all -s | tee results/$1/$(date +%Y%m%d)-PSP.txt

echo "Formatting paramspider results..."
cat results/$1/$(date +%Y%m%d)-PSP.txt | grep -i "http" > results/$1/$(date +%Y%m%d)-PSP-FUZZ.txt

echo "Attempting to spider domains found from $1..."

# Spider based on all domains
echo "Runing Katana..."
docker run --rm katana:latest -jc -d 25 -u $(cat results/$1/$(date +%Y%m%d)-OLDOMAINS.all) -system-chrome -headless | tee results/$1/$(date +%Y%m%d)-KTA.txt

echo "Final results from $1 include $(wc -l results/$1/$(date +%Y%m%d)-PSP-FUZZ.txt | awk '{print $1}') FUZZable URLs."
echo "Final results from $1 include $(wc -l results/$1/$(date +%Y%m%d)-KTA.txt | awk '{print $1}') URLs."

# Run Gobuster:
# REF: https://github.com/OJ/gobuster

# Run Recurse Buster:
# REF: https://github.com/C-Sto/recursebuster

# Run Waymore
# REF: https://github.com/xnl-h4ck3r/waymore

# Run Arjun
# REF: https://github.com/s0md3v/Arjun

# Run x8
# REF: https://github.com/Sh1Yo/x8


# To look into converting:

# Run Param Miner
# REF: https://github.com/PortSwigger/param-miner

set +x