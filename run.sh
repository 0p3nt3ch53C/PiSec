#!/bin/bash
# Arguments: $1 = domain / hackeronecsv
# Example: ./run.sh <domain>
# Example: ./run.sh <hackerone csv file>
set -x

if [[ "$#" -gt 2 ]]; then
  echo "Error: Please provide exactly one argument (either a domain or a Hacker One CSV file path formatted file)."
  exit 1
fi

domain_only=false
domain_list_file=false
hackerone_csv_file=false

while getopts "d:dl:h1csv:" opt; do
  case "$opt" in
    d)
     target="${OPTARG}"
     domain_only=true;;
    dlf)
      target="${OPTARG}"
      domain_list_file=true;;
    h1csvf)
      target="${OPTARG}"
      hackerone_csv_file=true;;
    *)
      echo "Usage: $0 [-d domain] [-dl domain list] [-h1csv hackerone_csv_file]"
      echo "Example - Domain: $0 -d target-domain.com"
      echo "Example - Domain List: $0 -dlf 'target-domain1.com,target-domain2.com'"
      echo "Example - Hacker One CSV: $0 -h1csvf '/path/to/h1.csv'"
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
    mv results/"$target"/ results/"$target"-$(date +%Y%m%d-%H%M%S)-archived/
fi
results_directory="results/$target/"
mkdir -p $results_directory

echo "Continuing with: $target".
# Create logic for if file used for domains.
# WIP - If a file, strip out and check if hackerone csv file, or raw domains, or something else.

# Retrieve domains
echo "Running subfinder..."
docker run --rm subfinder:latest -d "$target" -all | tee "$results_directory$(date +%Y%m%d)-SBF.txt"

echo "Running crt..."
docker run --rm crt:latest "$target" | tee "$results_directory$(date +%Y%m%d)-CRT.txt"

echo "Running cero..."
docker run --rm cero:latest "$target" | tee "$results_directory$(date +%Y%m%d)-CER.txt"

# WIP - Requires filtering:
# echo "Running amass..."
# Capture OSINT:
# docker run --rm amass:latest intel -active -whois -d "$target" -v | tee "$results_directory$(date +%Y%m%d)-OSINT-AMA.txt"
# Capture ENUM:
# docker run --rm amass:latest enum -active -d "$target" -v | tee "$results_directory$(date +%Y%m%d)-ENUM-AMA.txt"

sort -u "$results_directory"$(date +%Y%m%d)-*.txt > "$results_directory$(date +%Y%m%d)-DOMAINS.all"
sed -i -e 's/^/https:\/\//' "$results_directory$(date +%Y%m%d)-DOMAINS.all"
tr '\n' ',' < "$results_directory$(date +%Y%m%d)-DOMAINS.all" > "$results_directory$(date +%Y%m%d)-OLDOMAINS.all"
echo "Found $(wc -l results/$target/$(date +%Y%m%d)-DOMAINS.all | awk '{print $1}') domains."

docker run -v $(pwd)"/$results_directory":/app/paramspider/ --rm paramspider:latest -l /app/paramspider/$(date +%Y%m%d)-DOMAINS.all -s | tee "$results_directory$(date +%Y%m%d)-PSP.txt"

echo "Formatting paramspider results..."
cat "$results_directory$(date +%Y%m%d)-PSP.txt" | grep -i "http" > "$results_directory$(date +%Y%m%d)-PSP-FUZZ.txt"

echo "Attempting to spider domains found from $target..."

# Check status with HTTPX based on all domains:
echo "Running HTTPX..."
docker run -v $(pwd)"/$results_directory":/app/ --rm httpx:latest -l /app/$(date +%Y%m%d)-DOMAINS.all -sc -cl -ct -title -server -td -cdn -location -csv | tee "$results_directory$(date +%Y%m%d)-HTTPX.csv"

# Fuzzing:

# Sort fuzzing lists:
# grep -v "*" results/cocacola.com/20250528-DOMAINS.all > results/cocacola.com/20250528-BASE-DOMAINS.all

# DNS:
docker run -v $(pwd)/WL/SL/Discovery/DNS/:/app/ --rm ffuf:latest -w /app/subdomains-top1million-5000.txt -u "https://FUZZ.$target/" | tee "$results_directory$(date +%Y%m%d)-FFUF.txt"

# Directory:
docker run -v $(pwd)/WL/SL/Discovery/Web-Content/:/app/ --rm ffuf:latest -w /app/common.txt -u "https://$target/FUZZ" | tee "$results_directory$(date +%Y%m%d)-FFUF.txt"
docker run -v $(pwd)/WL/SL/Discovery/Web-Content/:/app/ --rm ffuf:latest -w /app/combined_directories.txt -u "https://$target/FUZZ" | tee "$results_directory$(date +%Y%m%d)-FFUF.txt"
docker run -v $(pwd)/WL/SL/Discovery/Web-Content/:/app/ --rm ffuf:latest -w /app/directory-list-2.3-big.txt -u "https://$target/FUZZ" | tee "$results_directory$(date +%Y%m%d)-FFUF.txt"
docker run -v $(pwd)/WL/SL/Discovery/Web-Content/:/app/ --rm ffuf:latest -w /app/quickhits.txt -u "https://$target/FUZZ" | tee "$results_directory$(date +%Y%m%d)-FFUF.txt"
docker run -v $(pwd)/WL/SL/Discovery/Web-Content/:/app/ --rm ffuf:latest -w /app/raft-small-directories.txt -u "https://$target/FUZZ" | tee "$results_directory$(date +%Y%m%d)-FFUF.txt"
docker run -v $(pwd)/WL/SL/Discovery/Web-Content/:/app/ --rm ffuf:latest -w /app/raft-medium-directories.txt -u "https://$target/FUZZ" | tee "$results_directory$(date +%Y%m%d)-FFUF.txt"
docker run -v $(pwd)/WL/SL/Discovery/Web-Content/:/app/ --rm ffuf:latest -w /app/raft-large-directories.txt -u "https://$target/FUZZ" | tee "$results_directory$(date +%Y%m%d)-FFUF.txt"

# Fuzzing from all urls in Paraminer: 
# docker run -v $(pwd)/WL/SL/Fuzzing/:/app/ --rm ffuf:latest -w /app/Unicode.txt -u <''> | tee "$results_directory$(date +%Y%m%d)-FFUF.txt"


# Spider based on all domains
echo "Runing Katana..."
docker run --rm katana:latest -jc -d 15 -u $(cat "$results_directory$(date +%Y%m%d)-OLDOMAINS.all") -system-chrome -headless | tee "$results_directory$(date +%Y%m%d)-KTA.txt"

# Print final results:
echo "Final results from "$target" include $(wc -l "$results_directory$(date +%Y%m%d)-PSP-FUZZ.txt" | awk '{print $1}') FUZZable URLs."
echo "Final results from "$target" include $(wc -l "$results_directory$(date +%Y%m%d)-KTA.txt" | awk '{print $1}') URLs."
echo "Confirmed final results from "$target" include $(wc -l "$results_directory$(date +%Y%m%d)-HTTPX.csv" | awk '{print $1}') resolvable URLs."

set +x