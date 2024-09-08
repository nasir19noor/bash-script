#!/bin/bash

echo "===== Laptop Hardware Information ====="

echo -e "\n--- CPU Information ---"
lscpu | grep "Model name"
lscpu | grep "CPU(s):"

echo -e "\n--- Memory Information ---"
free -h | grep "Mem:"

echo -e "\n--- Disk Information ---"
df -h | grep -E "Filesystem|/$"

echo -e "\n--- Graphics Card Information ---"
lspci | grep VGA

echo -e "\n--- Network Interface Information ---"
ip link show | grep -E "^[0-9]+" | awk -F: '{print $2}'

echo -e "\n--- Battery Information ---"
if [ -e /sys/class/power_supply/BAT0/capacity ]; then
    echo "Battery capacity: $(cat /sys/class/power_supply/BAT0/capacity)%"
else
    echo "Battery information not available"
fi

echo -e "\n--- System Information ---"
hostnamectl | grep -E "Operating System|Kernel|Architecture"