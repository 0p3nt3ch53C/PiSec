#!/bin/bash
set -x

if [[ "$#" -gt 2 ]]; then
  echo "Error: Please provide exactly one argument (either a domain or a Hacker One CSV file path formatted file)."
  exit 1
fi

domain_only=false
domain_list=false
hackerone_csv=false

while getopts "d:dl:h1csv:" opt; do
  case "$opt" in
    d)
     target="${OPTARG}"
     domain_only=true;;
    dl)
      target="${OPTARG}"
      domain_list=true;;
    h1csv)
      target="${OPTARG}"
      hackerone_csv=true;;
    *)
      echo "Usage: $0 [-d domain] [-dl domain list] [-h1csv hackerone_csv_file]"
      echo "Example - Domain: $0 -d target-domain.com"
      echo "Example - Domain List: $0 -dl 'target-domain1.com,target-domain2.com'"
      echo "Example - Hacker One CSV: $0 -h1csv '/path/to/h1.csv'"
      exit 1;;
  esac
done

echo "Attempting to retrieve domains for $target."

if [ -z "$1" ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi
if [ ! -d "results" ]; then
    mkdir results
fi
if [ -d "results/$target/" ]; then
    mv results/"$target"/ results/"$target"-$(date +%Y%m%d-%H%M%S)/
fi
mkdir -p results/"$target"/

echo "Continuing with: $target".

exit
# Create logic for if file used for domains.
# WIP - If a file, strip out and check if hackerone csv file, or raw domains, or something else.

# Retrieve domains
echo "Running subfinder..."
docker run --rm subfinder:latest -d $1 -all | tee results/$1/$(date +%Y%m%d)-SBF.txt

echo "Running crt..."
docker run --rm crt:latest $1 | tee results/$1/$(date +%Y%m%d)-CRT.txt

echo "Running cero..."
docker run --rm cero:latest $1 | tee results/$1/$(date +%Y%m%d)-CER.txt

# WIP - Requires filtering:
# echo "Running amass..."
# Capture OSINT:
# docker run --rm amass:latest intel -active -whois -d $1 -v | tee results/$1/$(date +%Y%m%d)-OSINT-AMA.txt
# Capture ENUM:
# docker run --rm amass:latest enum -active -d $1 -v | tee results/$1/$(date +%Y%m%d)-ENUM-AMA.txt

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

# Print final results:
echo "Final results from $1 include $(wc -l results/$1/$(date +%Y%m%d)-PSP-FUZZ.txt | awk '{print $1}') FUZZable URLs."
echo "Final results from $1 include $(wc -l results/$1/$(date +%Y%m%d)-KTA.txt | awk '{print $1}') URLs."

set +x