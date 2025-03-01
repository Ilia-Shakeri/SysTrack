#!/bin/bash

#Welcome message
echo "Welcome to my System Resource Monitoring script."

#Email validation loop
while true; do
	read -p "Please enter your email: " Email
	if [[ "$Email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
		break
	else
		printf "\U274C Error: Invalid email format! Please try again.\n"
	fi
done

clear

#Check if log file exists, create it if it doesn't
Log_file="$HOME/SysTrack.log"

if [ ! -f "$Log_file" ]; then
	touch "$Log_file"
	if [ $? -ne 0 ]; then
        	echo "Error: Failed to create log file."
        	exit 1
	fi
fi 

# Rotate log file if it exceeds 10MB
Log_file_size=$(stat -c%s "$Log_file")
Max_size=$((10 * 1024 * 1024))

if [ "$Log_file_size" -ge "$Max_size" ]; then
	mv "$Log_file" "${Log_file}_$(date '+%Y%m%d%H%M%S').bak"
	if [ $? -ne 0 ]; then
        	echo "Error: Failed to rotate log file."
        	exit 1
	fi
	touch "$Log_file"
	if [ $? -ne 0 ]; then
        	echo "Error: Failed to create new log file after rotation."
        	exit 1
	fi
fi

# Function to log messages
log() {
    local message="$1"
    echo -e "$message" >&3
}

# Open log file for appending
exec 3>>"$Log_file"
if [ $? -ne 0 ]; then
        echo "Error: Failed to create new log file after rotation."
        exit 1
fi

#log the current date and time
log "\U1F4C5 Today is: $(date '+%H:%M:%S %A, %d %B %Y')"

log "=============================="

#define resource usage limits
CPU_limit=80
RAM_limit=80
DISK_limit=80

#calculate CPU usage
CPU_idle=$(top -bn1 | grep "Cpu(s)" | tr -s ' ' | cut -d ' ' -f 8 )
CPU_usage=$(echo "100 - $CPU_idle" | bc)
log "CPU Usage: $CPU_usage%"
log "=============================="

#calculate RAM usage
MEM_total=$(free -m | grep Mem | tr -s ' ' | cut -d ' ' -f 2)
MEM_used=$(free -m | grep Mem | tr -s ' ' | cut -d ' ' -f 3)
MEM_usage=$(echo "scale=2; ($MEM_used/$MEM_total)*100" | bc)
log "RAM Usage: $MEM_usage%"
log "=============================="

#show Disk usage
log "Disk Usage: Total  Used  Usage"
df -h | grep '^/dev/' | tr -s ' ' | cut -d ' ' -f 1,2,3,5 | while read -r partition total used usage; do
	usage_percent=$(echo $usage | tr -d '%')
	log "$partition   $total   $used   $usage"
done
log "=============================="

#calculate Network usage
Interface=$(ip route | grep default | tr -s ' ' | cut -d ' ' -f 5)
Download_MB=$(($(cat /sys/class/net/$Interface/statistics/rx_bytes) / 1024 / 1024))
Upload_MB=$(($(cat /sys/class/net/$Interface/statistics/tx_bytes) / 1024 / 1024))
log "Network Usage ($Interface):"
log "\U2B07 Download:   $Download_MB MB"
log "\U2B06 Upload:     $Upload_MB MB"
log "============================="

#show Uptime stats
log "Uptime:"
log "$(uptime -p)"
log "============================="

#check if any limits are exceeded and send an email if they are
Email_content=""

#check cpu usage limit
if (( $(echo "$CPU_usage > $CPU_limit" | bc -l ) )); then
	Email_content+="CPU usage is at $CPU_usage%, which is above the limit of $CPU_limit%.\n"
fi

#check ram usage limit
if (( $(echo "$MEM_usage > $RAM_limit" | bc -l ) )); then                                                  
	Email_content+="RAM usage is at $MEM_usage%, which is above the limit of $RAM_limit%.\n"
fi

#check disk usage limit
df -h | grep '^/dev/' | tr -s ' ' | cut -d ' ' -f 1,5 | while read -r partition usage; do
    usage_percent=$(echo $usage | tr -d '%')
    if (( usage_percent > DISK_limit )); then
        Email_content+="Disk usage for $partition is at $usage, which is above the limit of $DISK_limit%.\n"
    fi
done

#send an alert email is any limits are exceeded
if [ -n "$Email_content" ]; then
    echo -e "Resource Usage Alert:\n\n$Email_content" | mail -s "System Resource Alert" "$Email"
    log "Alert email sent to $Email."
else
    log "\U2705 All resource usage levels are within limits."
fi

log "============================="

#close the log file
exec 3>&-

# Show only new lines in the log file
echo "New entries in log file:"
tail -n 22 "$Log_file"

# Write a cron job to run this script every 12 hours
(crontab -l 2>/dev/null; echo "0 */12 * * * $HOME/SysTrack.sh") | crontab -
echo "Cron job added to run this script every 12 hours."
