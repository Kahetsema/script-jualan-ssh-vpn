#!/bin/bash
# Script auto create trial user SSH
# akan expired setelah 1 hari

Login=xlon-`</dev/urandom tr -dc X-Z0-9 | head -c4`
masaaktif="1"
Pass=`</dev/urandom tr -dc a-f0-9 | head -c9`
IP=`dig +short myip.opendns.com @resolver1.opendns.com`
useradd -e `date -d "$masaaktif days" +"%Y-%m-%d"` -s /bin/false -M $Login
echo -e "$Pass\n$Pass\n"|passwd $Login &> /dev/null
echo -e "Host      : $IP" 
echo -e "OpenSSH   : 212, 444"
echo -e "Dropbear  : 143, 3128"
echo -e "Username  : $Login "
echo -e "Password  : $Pass\n"
echo -e ""
echo -e "Akun ini hanya aktif untuk 1 hari"
echo -e "============================"
