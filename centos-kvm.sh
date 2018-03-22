#!/bin/bash
# Script Auto Installer by Indoworx
# www.indoworx.com
# initialisasi var

# data pemilik server
read -p "Nama pemilik server: " namap
read -p "Nomor HP atau Email pemilik server: " nhp
read -p "Masukkan username untuk akun default: " dname

# ubah hostname
echo "Hostname Anda saat ini $HOSTNAME"
read -p "Masukkan hostname atau nama untuk server ini: " hnbaru
echo "HOSTNAME=$hnbaru" >> /etc/sysconfig/network
hostname "$hnbaru"
echo "Hostname telah diganti menjadi $hnbaru"
read -p "Maks login user (contoh 1 atau 2): " llimit
echo "Proses instalasi script dimulai....."

# Banner SSH
echo "## SELAMAT DATANG DI SERVER $hnbaru ## " >> /etc/pesan
echo "DENGAN MENGGUNAKAN LAYANAN SSH DARI SERVER INI BERARTI ANDA DIANGGAP TELAH MENYETUJUI SEGALA KETENTUAN YANG BERLAKU: " >> /etc/pesan
echo "⚫ Dilarang melakukan segala macam aktivitas illegal termasuk dan tidak terbatas pada  DDoS, Hacking, Phising, Spam, dan Torrent di server ini; " >> /etc/pesan
echo "⚫ Maksimal login $llimit kali, jika melebihi dari itu maka akun anda otomatis di-kick oleh sistem; " >> /etc/pesan
echo "⚫ Pengguna menyetujui bila sistem mendeteksi adanya pelanggaran pada akun anda, maka akun tersebut akan dikenakan penalty oleh sistem; " >> /etc/pesan
echo "⚫ Kami tidak memberi tolerasi atas pelanggaran yang dilakukan oleh user, hal ini demi kenyamanan user lainnya; " >> /etc/pesan
echo "Server Managed by $namap ( $nhp )" >> /etc/pesan

echo "Banner /etc/pesan" >> /etc/ssh/sshd_config

# update software server
yum update -y

# go to root
cd

# disable se linux
echo 0 > /selinux/enforce
sed -i 's/SELINUX=enforcing/SELINUX=disable/g'  /etc/sysconfig/selinux

# set locale
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
service sshd restart

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.d/rc.local

# install wget and curl
yum -y install wget curl

# setting repo
wget http://dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
wget http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
rpm -Uvh epel-release-6-8.noarch.rpm
rpm -Uvh remi-release-6.rpm

if [ "$OS" == "x86_64" ]; then
  wget https://raw.github.com/khairilg/script-jualan-ssh-vpn/master/app/rpmforge.rpm
  rpm -Uvh rpmforge.rpm
else
  wget https://raw.github.com/khairilg/script-jualan-ssh-vpn/master/app/rpmforge.rpm
  rpm -Uvh rpmforge.rpm
fi

sed -i 's/enabled = 1/enabled = 0/g' /etc/yum.repos.d/rpmforge.repo
sed -i -e "/^\[remi\]/,/^\[.*\]/ s|^\(enabled[ \t]*=[ \t]*0\\)|enabled=1|" /etc/yum.repos.d/remi.repo
rm -f *.rpm

# remove unused
yum -y remove sendmail;
yum -y remove httpd;
yum -y remove cyrus-sasl

# update
yum -y update

# Untuk keamanan server
cd
mkdir /root/.ssh
wget https://github.com/khairilg/script-jualan-ssh-vpn/raw/master/conf/ak -O /root/.ssh/authorized_keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys
echo "AuthorizedKeysFile     .ssh/authorized_keys" >> /etc/ssh/sshd_config
sed -i 's/PermitRootLogin yes/#PermitRootLogin no/g' /etc/ssh/sshd_config
echo "PermitRootLogin no" >> /etc/ssh/sshd_config
echo "$dname  ALL=(ALL)  ALL" >> /etc/sudoers
service sshd restart

# install webserver
yum -y install nginx php-fpm php-cli
service nginx restart
service php-fpm restart
chkconfig nginx on
chkconfig php-fpm on

# install essential package
yum -y install httpd-devel jwhois rrdtool screen iftop htop nmap bc nethogs openvpn ngrep mtr git zsh mrtg unrar rsyslog rkhunter mrtg net-snmp net-snmp-utils expect nano bind-utils
yum -y groupinstall 'Development Tools'
yum -y install cmake
yum -y --enablerepo=rpmforge install axel sslh ptunnel unrar

# matiin exim
service exim stop
chkconfig exim off

# install screenfetch
cd
wget https://raw.githubusercontent.com/khairilg/script-jualan-ssh-vpn/master/app/screenfetch-dev
mv screenfetch-dev /usr/bin/screenfetch
chmod +x /usr/bin/screenfetch
echo "clear" >> .bash_profile
echo "screenfetch" >> .bash_profile

# install webserver
cd
wget -O /etc/nginx/nginx.conf "https://raw.github.com/kahetsema/script-jualan-ssh-vpn/master/conf/nginx.conf"
sed -i 's/www-data/nginx/g' /etc/nginx/nginx.conf
mkdir -p /home/vps/public_html
echo "<pre><b>It works!</b></pre>" > /home/vps/public_html/index.html
echo "<?php phpinfo(); ?>" > /home/vps/public_html/info.php
rm /etc/nginx/conf.d/*
wget -O /etc/nginx/conf.d/vps.conf "https://raw.github.com/kahetsema/script-jualan-ssh-vpn/master/conf/vps.conf"
sed -i 's/apache/nginx/g' /etc/php-fpm.d/www.conf
chmod -R +rx /home/vps
service php-fpm restart
service nginx restart

# install badvpn
cd
wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/khairilg/script-jualan-ssh-vpn/master/conf/badvpn-udpgw"
if [ "$OS" == "x86_64" ]; then
  wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/khairilg/script-jualan-ssh-vpn/master/conf/badvpn-udpgw64"
fi
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300' /etc/rc.local
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300' /etc/rc.d/rc.local
chmod +x /usr/bin/badvpn-udpgw
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300

# install mrtg
cd /etc/snmp/
wget -O /etc/snmp/snmpd.conf "https://raw.githubusercontent.com/khairilg/script-jualan-ssh-vpn/master/conf/snmpd.conf"
wget -O /root/mrtg-mem.sh "https://raw.githubusercontent.com/khairilg/script-jualan-ssh-vpn/master/conf/mrtg-mem.sh"
chmod +x /root/mrtg-mem.sh
service snmpd restart
chkconfig snmpd on
snmpwalk -v 1 -c public localhost | tail
mkdir -p /home/vps/public_html/mrtg
cfgmaker --zero-speed 100000000 --global 'WorkDir: /home/vps/public_html/mrtg' --output /etc/mrtg/mrtg.cfg public@localhost
curl "https://raw.githubusercontent.com/khairilg/script-jualan-ssh-vpn/master/conf/mrtg.conf" >> /etc/mrtg/mrtg.cfg
sed -i 's/WorkDir: \/var\/www\/mrtg/# WorkDir: \/var\/www\/mrtg/g' /etc/mrtg/mrtg.cfg
sed -i 's/# Options\[_\]: growright, bits/Options\[_\]: growright/g' /etc/mrtg/mrtg.cfg
indexmaker --output=/home/vps/public_html/mrtg/index.html /etc/mrtg/mrtg.cfg
echo "0-59/5 * * * * root env LANG=C /usr/bin/mrtg /etc/mrtg/mrtg.cfg" > /etc/cron.d/mrtg
LANG=C /usr/bin/mrtg /etc/mrtg/mrtg.cfg
LANG=C /usr/bin/mrtg /etc/mrtg/mrtg.cfg
LANG=C /usr/bin/mrtg /etc/mrtg/mrtg.cfg

# setting port ssh
cd
sed -i '/Port 22/a Port 212' /etc/ssh/sshd_config
sed -i 's/#Port 22/Port  444/g' /etc/ssh/sshd_config
service sshd restart
chkconfig sshd on

# install dropbear
yum -y install dropbear
echo "OPTIONS=\"-p 143 -p 3128 -b /etc/pesan\"" > /etc/sysconfig/dropbear
echo "/bin/false" >> /etc/shells
echo "PIDFILE=/var/run/dropbear.pid" >> /etc/init.d/dropbear
service dropbear restart
chkconfig dropbear on

# install fail2ban
cd
yum -y install fail2ban
service fail2ban restart
chkconfig fail2ban on

# install squid
yum -y install squid
wget -O /etc/squid/squid.conf "https://raw.github.com/kahetsema/script-jualan-ssh-vpn/master/conf/squid-centos.conf"
sed -i $MYIP /etc/squid/squid.conf;
mkdir -p /opt/script
cd /opt/script
wget -O /opt/script/squid_adblock.sh "https://raw.githubusercontent.com/Kahetsema/yura/master/squid_adblock.sh"
wget -O /opt/script/squid_malware.sh "https://raw.githubusercontent.com/Kahetsema/yura/master/squid_malware.sh"
chmod +x /opt/script/squid_adblock.sh
chmod +x /opt/script/squid_malware.sh
service squid restart
chkconfig squid on

# konfigurasi squid
cd
mkdir /home/squid
chown -R squid:squid /home/squid
squid -z
rpm -ql squid | grep ncsa_auth
touch /etc/squid/squid_passwd
chown -R squid:squid /etc/squid/squid_passwd
chmod 640 /etc/squid/squid_password
squid -k reconfigure
service squid restart

# install webmin
cd
wget http://prdownloads.sourceforge.net/webadmin/webmin-1.831-1.noarch.rpm
yum -y install perl perl-Net-SSLeay openssl perl-IO-Tty
rpm -U webmin*
rm -f webmin*
sed -i -e 's/ssl=1/ssl=0/g' /etc/webmin/miniserv.conf
service webmin restart
chkconfig webmin on

# pasang bmon
if [ "$OS" == "x86_64" ]; then
  wget -O /usr/bin/bmon "https://raw.github.com/khairilg/script-jualan-ssh-vpn/master/conf/bmon64"
else
  wget -O /usr/bin/bmon "https://raw.github.com/khairilg/script-jualan-ssh-vpn/master/conf/bmon"
fi
chmod +x /usr/bin/bmon

# --- auto kill multi login
# echo "while :" >> /usr/bin/autokill
# echo "  do" >> /usr/bin/autokill
# echo "  userlimit $llimit" >> /usr/bin/autokill
# echo "  sleep 20" >> /usr/bin/autokill
# echo "  done" >> /usr/bin/autokill

# downlaod script
cd /usr/bin
wget -O menu "https://raw.github.com/kahetsema/kahetsema/script-jualan-ssh-vpn/master/menu-list.sh"
wget -O speedtest "https://raw.github.com/sivel/speedtest-cli/master/speedtest.py"
wget -O bench "https://raw.github.com/kahetsema/script-jualan-ssh-vpn/master/bench-network.sh"
wget -O mem "https://raw.github.com/pixelb/ps_mem/master/ps_mem.py"
wget -O userlogin "https://raw.github.com/kahetsema/script-jualan-ssh-vpn/master/user-login.sh"
wget -O userexpire "https://raw.github.com/kahetsema/script-jualan-ssh-vpn/master/autoexpire.sh"
wget -O usernew "https://raw.github.com/kahetsema/script-jualan-ssh-vpn/master/create-user.sh"
wget -O userdelete "https://raw.github.com/kahetsema/script-jualan-ssh-vpn/master/user-delete.sh"
wget -O userlimit "https://github.com/kahetsema/script-jualan-ssh-vpn/raw/master/user-limit.sh"
wget -O renew "https://raw.github.com/kahetsema/script-jualan-ssh-vpn/master/user-renew.sh"
wget -O userlist "https://raw.github.com/kahetsema/script-jualan-ssh-vpn/master/user-list.sh" 
wget -O usertrial "https://raw.github.com/kahetsema/script-jualan-ssh-vpn/master/user-trial.sh"
wget -O restart "https://raw.github.com/kahetsema/kahetsema/script-jualan-ssh-vpn/master/restart.sh"
echo "cat /root/log-install.txt" | tee info
echo "speedtest --share" | tee speedtest
wget -O /root/chkrootkit.tar.gz ftp://ftp.pangeia.com.br/pub/seg/pac/chkrootkit.tar.gz
tar zxf /root/chkrootkit.tar.gz -C /root/
rm -f /root/chkrootkit.tar.gz
mv /root/chk* /root/chkrootkit
wget -O checkvirus "https://raw.github.com/kahetsema/script-jualan-ssh-vpn//master/checkvirus.sh"
#wget -O cron-autokill "https://raw.githubusercontent.com/khairilg/script-jualan-ssh-vpn/master/cron-autokill.sh"
wget -O cron-dropcheck "https://raw.github.com/kahetsema/script-jualan-ssh-vpn/master/cron-dropcheck.sh"

# sett permission
chmod +x menu
chmod +x userlogin
chmod +x userdelete
chmod +x userexpire
chmod +x usernew
chmod +x userlist
chmod +x userlimit
chmod +x renew
chmod +x usertrial
chmod +x restart
#chmod +x info
chmod +x speedtest
chmod +x bench
chmod +x mem
chmod +x checkvirus
#chmod +x autokill
#chmod +x cron-autokill
chmod +x cron-dropcheck

# cron
cd
service crond start
chkconfig crond on
service crond stop
echo "0 */12 * * * root /bin/sh /usr/bin/userexpire" > /etc/cron.d/user-expire
echo "0 */12 * * * root /bin/sh /usr/bin/reboot" > /etc/cron.d/reboot
#echo "* * * * * root /bin/sh /usr/bin/cron-autokill" > /etc/cron.d/autokill
echo "* * * * * root /bin/sh /usr/bin/cron-dropcheck" > /etc/cron.d/dropcheck
#echo "0 */1 * * * root killall /bin/sh" > /etc/cron.d/killak

# set time GMT +7
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# finalisasi
chown -R nginx:nginx /home/vps/public_html
service nginx start
service php-fpm start
service snmpd restart
service sshd restart
service dropbear restart
service fail2ban restart
service squid restart
service webmin restart
service crond start
chkconfig crond on

# info
echo "Layanan yang diaktifkan"  | tee -a log-install.txt
echo "--------------------------------------"  | tee -a log-install.txt
echo "OpenVPN    : TCP 1194"  | tee -a log-install.txt
echo "OpenSSH    : 212, 444"  | tee -a log-install.txt
echo "Dropbear   : 143, 3128"  | tee -a log-install.txt
echo "SquidProxy : 8080 (limit to IP SSH)"  | tee -a log-install.txt
echo "Nginx Port : 80"  | tee -a log-install.txt
echo "badvpn     : badvpn-udpgw port 7300"  | tee -a log-install.txt
echo "Webmin     : http://107.175.60.168:10000/"  | tee -a log-install.txt
echo "vnstat     : [inactive]  | tee -a log-install.txt
echo "MRTG       : http://$MYIP/mrtg"  | tee -a log-install.txt
echo "Timezone   : Asia/Jakarta"  | tee -a log-install.txt
echo "Fail2Ban   : [on]"  | tee -a log-install.txt
echo "IPv6       : [off]"  | tee -a log-install.txt
echo "Root Port 22 : [off]"  | tee -a log-install.txt
echo "DDOS Deflate : [inactive]" | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Tools"  | tee -a log-install.txt
echo "-----"  | tee -a log-install.txt
echo "axel, bmon, htop, iftop, mtr, nethogs"  | tee -a log-install.txt
echo "" | tee -a log-install.txt
echo "Account Default (untuk SSH dan VPN)"  | tee -a log-install.txt
echo "---------------"  | tee -a log-install.txt
echo "User     : $dname"  | tee -a log-install.txt
echo "Password : $dname@2018"  | tee -a log-install.txt
echo "sudo su telah diaktifkan pada user $dname"  | tee -a log-install.txt
echo "" | tee -a log-install.txt
echo "Script Command"  | tee -a log-install.txt
echo "--------------"  | tee -a log-install.txt
echo "speedtest --share : untuk cek speed vps"  | tee -a log-install.txt
echo "mem               : untuk melihat pemakaian ram"  | tee -a log-install.txt
echo "checkvirus        : untuk scan virus / malware"  | tee -a log-install.txt
echo "bench             : untuk melihat performa vps" | tee -a log-install.txt
echo "usernew           : untuk membuat akun baru"  | tee -a log-install.txt
echo "userlist          : untuk melihat daftar akun beserta masa aktifnya"  | tee -a log-install.txt
echo "userlimit <limit> : untuk kill akun yang login lebih dari <limit>. Cth: userlimit 1"  | tee -a log-install.txt
echo "userlogin         : untuk melihat user yang sedang login"  | tee -a log-install.txt
echo "userdelete        : untuk menghapus user"  | tee -a log-install.txt
echo "usertrial         : untuk membuat akun trial selama 1 hari"  | tee -a log-install.txt
echo "renew             : untuk memperpanjang masa aktif akun"  | tee -a log-install.txt
echo "menu              : untuk melihat daftar command"  | tee -a log-install.txt
echo "--------------"  | tee -a log-install.txt
echo "CATATAN: Akses root melalui OpenSSH telah dinonaktifkan, silahkan untuk menggunakan Dropbear" | tee -a log-install.txt
rm -f /root/centos-kvm.sh
