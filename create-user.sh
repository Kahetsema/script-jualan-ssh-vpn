#!/bin/bash
#Script auto create user SSH

read -p "Username : " Login
read -p "Password : " Pass
read -p "Expired (hari): " masaaktif

IP=`curl icanhazip.com`
useradd -e `date -d "$masaaktif days" +"%Y-%m-%d"` -s /bin/false -M $Login
exp="$(chage -l $Login | grep "Account expires" | awk -F": " '{print $2}')"
echo -e "$Pass\n$Pass\n"|passwd $Login &> /dev/null
echo -e ""
echo -e "Informasi SSH"
echo -e "=========-ACCOUNT-=========="
echo -e "Host      : $IP" 
echo -e "OpenSSH   : 212, 444"
echo -e "Dropbear  : 143, 3128"
echo -e "Username  : $Login"
echo -e "Password  : $Pass"
echo -e "-----------------------------"
echo -e "Aktif Sampai : $exp"
echo -e "==========================="
