# PiSec

# Wordlists available

1. [Payload All The Things](https://github.com/swisskyrepo/PayloadsAllTheThings)
2. [SecLists](https://github.com/danielmiessler/SecLists)
3. [FuzzDB](https://github.com/fuzzdb-project/fuzzdb)
4. [fuzz.txt](https://github.com/Bo0oM/fuzz.txt)

# Tools available

1. [Katana](https://github.com/projectdiscovery/katana)
2. [crt.sh](https://crt.sh)
3. [cero](https://github.com/glebarez/cero)
4. [subfinder](https://github.com/projectdiscovery/subfinder)
5. [amass](https://github.com/owasp-amass/amass)

# Prerequsites

## Discover Pi
e.g., Discovery with a /24 CIDR range with IP addresses 10.10.10.0/24.
> 1..254 | % {"10.10.10.$($_): $(Test-Connection -count 1 -comp 10.10.10.$($_) -quiet)"}

# Update WiFi Connection Priority
> nmcli connection modify "Pi Wifi" connection.autoconnect-priority 10

# Description

# Execution
> curl -s https://raw.githubusercontent.com/0p3nt3ch53C/PiSec/refs/heads/main/update.sh 