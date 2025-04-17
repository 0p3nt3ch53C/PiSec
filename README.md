# PiSec

# Prerequsites

## Discover Pi
e.g., Discovery with a /24 CIDR range with IP addresses 10.10.10.0/24.
> 1..254 | % {"10.10.10.$($_): $(Test-Connection -count 1 -comp 10.10.10.$($_) -quiet)"}

# Update WiFi Connection Priority
> nmcli connection modify "Pi Wifi" connection.autoconnect-priority 10

# Description

# Execution
> curl -s https://raw.githubusercontent.com/0p3nt3ch53C/PiSec/refs/heads/main/update.sh 