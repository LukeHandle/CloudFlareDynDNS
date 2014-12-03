#!/bin/bash

DEBUG=false
# Set debuging
if [ $DEBUG == "true" ]; then set -x; fi

domain="example.com"
subdomain="subdomain"
fqdn="$subdomain.$domain"
# Get IP of the FQDN
fqdn_ip=$(dig A $fqdn @ns.cloudflare.com +short 2> /dev/null || { echo "FAILURE"; exit 1; })
# Get IP of the WAN
wan_ip=$(dig A myip.opendns.com @resolver1.opendns.com +short 2> /dev/null || { echo "FAILURE"; exit 1; })

cloudflare_key="##KEY##"
cloudflare_email="##EMAIL##"
cloudflare_id="##CF_ID##"

error=0

if [[ "$fqdn_ip" == *FAILURE* ]]; then
    logger -t "CloudFlare DNS Updater" "Error getting FQDN IP"
    echo "FQDN IP Failed"
    error=1
fi

if [[ "$wan_ip" == *FAILURE* ]]; then
    logger -t "CloudFlare DNS Updater" "Error getting WAN IP"
    echo "WAN IP Failed"
    error=1
fi

if [[ "$error" = "1" ]]; then
    echo "Error(s) found, update failed!"
    exit 1
fi

if [[ "$wan_ip" != "$fqdn_ip" ]]; then
    logger -t "CloudFlare DNS Updater" "Attempting to update to $wan_ip"
    curl https://www.cloudflare.com/api_json.html \
      -d "a=rec_edit" \
      -d "tkn=$cloudflare_key" \
      -d "id=$cloudflare_id" \
      -d "email=$cloudflare_email" \
      -d "z=$domain" \
      -d "type=A" \
      -d "name=$subdomain" \
      -d "content=$wan_ip" \
      -d "service_mode=0" \
      -d "ttl=300"
    echo
    exit 0
else
    #logger -t "CloudFlare DNS Updater" "No update required: $wan_ip"
    exit 0
fi
