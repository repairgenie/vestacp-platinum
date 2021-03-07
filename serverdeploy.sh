#!/bin/bash

#VESTACP for Development and Web Hosting Purposes Installation
#Debian 9 Edition
#Created for Peoria IT by George Morris 3/5/2021
#Telegram: @TheOneSpanky
#Twitter: @pekinwebguy
#Email: pekinwebguy@gmail.com
##########################################################
clear
echo "VestaCP for Development and Web Hosting Professional Installation"
echo "Debian 9 Edition - Only run this on Debian 9"
echo "Created by George Morris 3/5/2021"
echo "Updated 3/6/2021"
echo "Contact me at pekinwebguy@gmail.com for any questions or issues"
echo .
echo "Please make sure this is a blank system with nothing else installed on it. Press Enter to continue..."
read startpoint

#First, we update the system
echo "Phase 1, Updating OS and installing prerequisites"
apt-get update
apt-get upgrade -y

#Debian doesn't have curl from the get go, plus it's lacking a few other things I like
apt-get install curl dialog mlocate htop build-essential -y

#We are now installing maldet
curl -O http://www.rfxn.com/downloads/maldetect-current.tar.gz
tar -zxvf maldetect-current.tar.gz
cd maldetect-*/
bash install.sh
maldet -u


#Now we grab Vesta CP
curl -O http://vestacp.com/pub/vst-install.sh

#Fantastic! Now we must decide if this server is going to be for Development or Production
echo "Phase 2, Installing VestaCP"
echo "IF YOU GOT ANY ERRORS HERE, YOU ARE AN IDIOT THAT DIDN'T CALL WITH BASH"
echo "***"
echo "Please select if server is going to be dev or prod. Dev is webserver only, and prod is full stack"
STAT='Is this server going to be for Development or production? '
choice1=("Development" "Production")
select life in "${choice1[@]}"; do
	case $life in
	"Development")
	echo "You have selected Development. These options will now install."
	bash vst-install.sh --nginx no --apache yes --phpfpm no --named no --remi yes --vsftpd yes --proftpd no --iptables yes --fail2ban yes --quota no --exim yes --dovecot no --spamassassin no --clamav no --softaculous no --mysql yes --postgresql yes
	#We will now pause input so we can grab the default logins for the server.
	echo "***********************************"
	echo "SCREEN HAS BEEN PAUSED SO YOU CAN COPY THE LOGIN INFO BEFORE PROCEEDING!!"
	echo "PLEASE DO SO NOW BEFORE PROCEEDING WITH THE REST OF THE INSTALL PROCESS"
	echo "What's to come next is more PHP versions as the default is not an up-to-date version."
	echo "***********************************"
	echo "Press any key to continue..."
	read getinfo
	;;
	"Production")
	echo "You have selected Production. These options will now install."
	bash vst-install.sh --nginx no --apache yes --phpfpm no --named yes --remi yes --vsftpd yes --proftpd no --iptables yes --fail2ban yes --quota yes --exim yes --dovecot yes --spamassassin yes --clamav yes --softaculous no --mysql yes --postgresql yes
	
	#We will now pause input so we can grab the default logins for the server.
	echo "***********************************"
	echo "SCREEN HAS BEEN PAUSED SO YOU CAN COPY THE LOGIN INFO BEFORE PROCEEDING!!"
	echo "PLEASE DO SO NOW BEFORE PROCEEDING WITH THE REST OF THE INSTALL PROCESS"
	echo "What's to come next is more PHP versions as the default is not an up-to-date version."
	echo "***********************************"
	echo "Press any key to continue..."
	read getinfo
	#We need to force clamav and spamassassin installation
	apt-get install clamav-daemon clamav clamdscan -y
	wget http://c.vestacp.com/0.9.8/ubuntu/clamd.conf -O /etc/clamav/clamd.conf
	gpasswd -a clamav mail
	gpasswd -a clamav Debian-exim
	freshclam
	update-rc.d clamav-daemon defaults
	service clamav-daemon restart
	apt-get install spamassassin -y
	update-rc.d spamassassin defaults
	sed -i "s/ENABLED=0/ENABLED=1/" /etc/default/spamassassin
	service spamassassin restart
	
	#Exim Configuration for SA and CLAM
	sed -i "s/^#SPAMASSASSIN/SPAMASSASSIN/g" /etc/exim4/exim4.conf.template
	sed -i "s/^#CLAMD/CLAMD/g" /etc/exim4/exim4.conf.template
	sed -i "s/^#SPAM_SCORE/SPAM_SCORE/g" /etc/exim4/exim4.conf.template
	service exim4 restart
	
	#Vesta Configuration for SA and CLAM
	sed -i "s/ANTIVIRUS.*/ANTIVIRUS_SYSTEM='clamav-daemon'/" /usr/local/vesta/conf/vesta.conf
	sed -i "s/ANTISPAM.*/ANTISPAM_SYSTEM='spamassassin'/" /usr/local/vesta/conf/vesta.conf
	
	;;
	
	*) echo "invalid option $REPLY"
		echo "Press ctrl+c if you have already installed the server"
		;;
esac




# Time to install the PHP selections!
# Inspiration came from https://forum.vestacp.com/viewtopic.php?t=17129
echo "Entering Phase 3, PHP Versions"
apt-get update
apt-get -y install apt-transport-https ca-certificates
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
sh -c 'echo "deb https://packages.sury.org/php/ stretch main" > /etc/apt/sources.list.d/php.list'
apt-get update
a2enmod proxy_fcgi setenvif

#PHP 5.6
apt-get -y install php5.6-apcu php5.6-mbstring php5.6-bcmath php5.6-cli php5.6-curl php5.6-fpm php5.6-gd php5.6-intl php5.6-mcrypt php5.6-mysql php5.6-soap php5.6-xml php5.6-zip php5.6-memcache php5.6-memcached php5.6-zip
update-rc.d php5.6-fpm defaults
a2enconf php5.6-fpm
systemctl restart apache2
cp -r /etc/php/5.6/ /root/vst_install_backups/php5.6/
rm -f /etc/php/5.6/fpm/pool.d/*
wget http://dl.mycity.tech/vesta/php-fpm-tpl/PHP-FPM-56.stpl -O /usr/local/vesta/data/templates/web/apache2/PHP-FPM-56.stpl
wget http://dl.mycity.tech/vesta/php-fpm-tpl/PHP-FPM-56.tpl -O /usr/local/vesta/data/templates/web/apache2/PHP-FPM-56.tpl
wget http://dl.mycity.tech/vesta/php-fpm-tpl/PHP-FPM-56.sh -O /usr/local/vesta/data/templates/web/apache2/PHP-FPM-56.sh
chmod a+x /usr/local/vesta/data/templates/web/apache2/PHP-FPM-56.sh

#PHP 7.0
apt-get -y install php7.0-apcu php7.0-mbstring php7.0-bcmath php7.0-cli php7.0-curl php7.0-fpm php7.0-gd php7.0-intl php7.0-mcrypt php7.0-mysql php7.0-soap php7.0-xml php7.0-zip php7.0-memcache php7.0-memcached php7.0-zip
update-rc.d php7.0-fpm defaults
a2enconf php7.0-fpm
systemctl restart apache2
cp -r /etc/php/7.0/ /root/vst_install_backups/php7.0/
rm -f /etc/php/7.0/fpm/pool.d/*
wget http://dl.mycity.tech/vesta/php-fpm-tpl/PHP-FPM-70.stpl -O /usr/local/vesta/data/templates/web/apache2/PHP-FPM-70.stpl
wget http://dl.mycity.tech/vesta/php-fpm-tpl/PHP-FPM-70.tpl -O /usr/local/vesta/data/templates/web/apache2/PHP-FPM-70.tpl
wget http://dl.mycity.tech/vesta/php-fpm-tpl/PHP-FPM-70.sh -O /usr/local/vesta/data/templates/web/apache2/PHP-FPM-70.sh
chmod a+x /usr/local/vesta/data/templates/web/apache2/PHP-FPM-70.sh

#PHP 7.1
apt-get -y install php7.1-apcu php7.1-mbstring php7.1-bcmath php7.1-cli php7.1-curl php7.1-fpm php7.1-gd php7.1-intl php7.1-mcrypt php7.1-mysql php7.1-soap php7.1-xml php7.1-zip php7.1-memcache php7.1-memcached php7.1-zip
update-rc.d php7.1-fpm defaults
a2enconf php7.1-fpm
systemctl restart apache2
cp -r /etc/php/7.1/ /root/vst_install_backups/php7.1/
rm -f /etc/php/7.1/fpm/pool.d/*
wget http://dl.mycity.tech/vesta/php-fpm-tpl/PHP-FPM-71.stpl -O /usr/local/vesta/data/templates/web/apache2/PHP-FPM-71.stpl
wget http://dl.mycity.tech/vesta/php-fpm-tpl/PHP-FPM-71.tpl -O /usr/local/vesta/data/templates/web/apache2/PHP-FPM-71.tpl
wget http://dl.mycity.tech/vesta/php-fpm-tpl/PHP-FPM-71.sh -O /usr/local/vesta/data/templates/web/apache2/PHP-FPM-71.sh
chmod a+x /usr/local/vesta/data/templates/web/apache2/PHP-FPM-71.sh

#PHP 7.2
apt-get -y install php7.2-apcu php7.2-mbstring php7.2-bcmath php7.2-cli php7.2-curl php7.2-fpm php7.2-gd php7.2-intl php7.2-mysql php7.2-soap php7.2-xml php7.2-zip php7.2-memcache php7.2-memcached php7.2-zip
update-rc.d php7.2-fpm defaults
a2enconf php7.2-fpm
systemctl restart apache2
cp -r /etc/php/7.2/ /root/vst_install_backups/php7.2/
rm -f /etc/php/7.2/fpm/pool.d/*
wget http://dl.mycity.tech/vesta/php-fpm-tpl/PHP-FPM-72.stpl -O /usr/local/vesta/data/templates/web/apache2/PHP-FPM-72.stpl
wget http://dl.mycity.tech/vesta/php-fpm-tpl/PHP-FPM-72.tpl -O /usr/local/vesta/data/templates/web/apache2/PHP-FPM-72.tpl
wget http://dl.mycity.tech/vesta/php-fpm-tpl/PHP-FPM-72.sh -O /usr/local/vesta/data/templates/web/apache2/PHP-FPM-72.sh
chmod a+x /usr/local/vesta/data/templates/web/apache2/PHP-FPM-72.sh

#PHP7.3
apt-get -y install php7.3-apcu php7.3-mbstring php7.3-bcmath php7.3-cli php7.3-curl php7.3-fpm php7.3-gd php7.3-intl php7.3-mysql php7.3-soap php7.3-xml php7.3-zip php7.3-memcache php7.3-memcached php7.3-zip
update-rc.d php7.3-fpm defaults
a2enconf php7.3-fpm
systemctl restart apache2
cp -r /etc/php/7.3/ /root/vst_install_backups/php7.3/
rm -f /etc/php/7.3/fpm/pool.d/*
wget http://dl.mycity.tech/vesta/php-fpm-tpl/PHP-FPM-73.stpl -O /usr/local/vesta/data/templates/web/apache2/PHP-FPM-73.stpl
wget http://dl.mycity.tech/vesta/php-fpm-tpl/PHP-FPM-73.tpl -O /usr/local/vesta/data/templates/web/apache2/PHP-FPM-73.tpl
wget http://dl.mycity.tech/vesta/php-fpm-tpl/PHP-FPM-73.sh -O /usr/local/vesta/data/templates/web/apache2/PHP-FPM-73.sh
chmod a+x /usr/local/vesta/data/templates/web/apache2/PHP-FPM-73.sh

#PHP7.4
apt-get -y install php7.4-apcu php7.4-mbstring php7.4-bcmath php7.4-cli php7.4-curl php7.4-fpm php7.4-gd php7.4-intl php7.4-mysql php7.4-soap php7.4-xml php7.4-zip php7.4-memcache php7.4-memcached php7.4-zip
update-rc.d php7.4-fpm defaults
a2enconf php7.4-fpm
systemctl restart apache2
cp -r /etc/php/7.4/ /root/vst_install_backups/php7.4/
rm -f /etc/php/7.4/fpm/pool.d/*
wget http://dl.mycity.tech/vesta/php-fpm-tpl/PHP-FPM-74.stpl -O /usr/local/vesta/data/templates/web/apache2/PHP-FPM-74.stpl
wget http://dl.mycity.tech/vesta/php-fpm-tpl/PHP-FPM-74.tpl -O /usr/local/vesta/data/templates/web/apache2/PHP-FPM-74.tpl
wget http://dl.mycity.tech/vesta/php-fpm-tpl/PHP-FPM-74.sh -O /usr/local/vesta/data/templates/web/apache2/PHP-FPM-74.sh
chmod a+x /usr/local/vesta/data/templates/web/apache2/PHP-FPM-74.sh

echo "Completed PHP Installations!"



#Finishing up
echo "Server Installation Completed!"
echo "Hostname: " $HOSTNAME
echo "Installation completed at: " `date`
echo "Please record your MySQL Root password below:"
cat /root/.my.cnf

exit
done