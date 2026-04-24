#!/bin/bash
export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin

##### MAIN VARIABLES #####
ALERT='\033[0;31m'      # RED
SUCCESS='\033[0;32m'    # GREEN
WARNING='\033[0;33m'    # YELLOW
ECM='\033[0m'           # END COLOR MESSAGE

read -r -p "You are about to uninstall completly Boxtea daemon, your configurations and data would be deleted. Continue? [y/N] " response < /dev/tty

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo -e "\n${WARNING}> 1/3 Stoping Boxtea daemon and processus...${ECM}"
    sudo systemctl stop boxtea > /dev/null 2>&1 || true
    sudo systemctl disable boxtea > /dev/null 2>&1 || true
    sudo rm -f /etc/systemd/system/boxtea.service
    sudo systemctl daemon-reload

    echo -e "${WARNING}> 2/3 Deleting Boxtea data...${ECM}"
    sudo rm -rf /opt/boxtea

    echo -e "${WARNING}> 3/3 Removing permissions...${ECM}"
    sudo rm -f /etc/sudoers.d/boxtea

    echo ""
    echo -e "${SUCCESS}========================================================================${ECM}"
    echo -e "${SUCCESS}  [SUCCESS] Boxtea has been completely uninstalled!${ECM}"
    echo -e "${SUCCESS}========================================================================${ECM}"
else
    echo -e "\n${SUCCESS}> Cancelled process.${ECM}"
    exit 0
fi