#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                           #
# Author: Rico Ullmann <git [<ät>] erinnerungsfragmente.de>                 #
# Website: erinnerungsfragmente.de                                          #
# Github: https://github.com/rullmann                                       #
#                                                                           #
# Version: 0.2 / Date: 15th February 2014                                    #
#                                                                           #
# Permission to use, copy, modify, and/or distribute this software for any  #
# purpose with or without fee is hereby granted, provided that the above    #
# copyright notice and this permission notice appear in all copies.         #
#                                                                           #
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES  #
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF          #
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR   #
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES    #
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN     #
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF   #
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.            #
#                                                                           #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

echo "
Welcome to the Atlassian Autoinstaller.
"

if [[ $EUID -ne 0 ]]; then
    echo "This Script hasn't been executed as root."
    echo "Please try again with sudo."
    exit 1
fi

# Let's use a function to ask the YN questions
# https://gist.github.com/davejamesmiller/1965569
function ask {
    while true; do
        if [ "${2:-}" = "Y" ]; then
            prompt="Y/n"
            default=Y
        elif [ "${2:-}" = "N" ]; then
            prompt="y/N"
            default=N
        else
            prompt="y/n"
            default=
        fi
 
        # Ask the question
        read -p "$1 [$prompt] " REPLY
 
        # Default?
        if [ -z "$REPLY" ]; then
            REPLY=$default
        fi
 
        # Check if the reply is valid
        case "$REPLY" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac
    done
}

echo "The next steps will guide you through the setup of Atlassian products. If you're not going to enter 'Y' nothing will happen.

It's strongly recommended to read the README.md before proceeding!
"
ask "Proceed?" N
if [ $? -ne 0 ] ; then
	echo "Goodbye!"
	exit 0
fi

# Let's generate passwords easily
function randpw { 
	(< /dev/urandom tr -dc '1234567890aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ!$?=-_#+' | head -c${1:-24};echo;)
}

# We must know which architecture to use
if [ `getconf LONG_BIT` = "64" ]
then
    arch="x64"
else
    arch="x32"
fi

# Get the ip address to print it later
ipaccess=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')

# Check for the dependencies before wee begin to install Atlassian products
echo ""
ask "First step is to install the mysql-server. Do you want to proceed?" N

if [ $? -ne 0 ] ; then
	echo "Goodbye!"
	exit 0
fi

installdeps () {
	DEPS=(mysql-server mysql-client)
	export DEBIAN_FRONTEND=noninteractive
    aptitude update && aptitude install -q -y ${DEPS[*]}
}

installdeps

dbflush="flush privileges;"

# The mysql-connector-java is required. Currently this script download and install mysql-connector-java-5.1.29.tar.gz
echo "
Now we need to download and unpack the mysql-connector-java for later use.
Without it we will not be able to connect the applications to out MySQL Server.
"
ask "Proceed?" N
if [ $? -ne 0 ] ; then
	echo "Goodbye!"
	exit 0
fi

mysqlcversion="mysql-connector-java-5.1.29"
mysqlcdl="https://dev.mysql.com/get/Downloads/Connector-J/$mysqlcversion.tar.gz"
mysqlctar="/tmp/mysqlc.tar.gz"
mysqlcjar="/tmp/$mysqlcversion/$mysqlcversion-bin.jar"

wget -O /tmp/mysqlc.tar.gz $mysqlcdl
tar xzf $mysqlctar

{
	ask "Install Atlassian JIRA?" N
	if [ $? -ne 1 ] ; then
		jirainstallpath="/opt/atlassian/jira/"
		product="jira"
		chooseversion61="6.1.7, 6.1.6, 6.1.5, 6.1.4, 6.1.3, 6.1.2, 6.1.1, 6.1"
		chooseversion6="6.0.8, 6.0.7, 6.0.6, 6.0.5, 6.0.4, 6.0.3, 6.0.2, 6.0.1, 6.0"
		chooseversionold="5.2.11, 5.1.8, 5.0.7, 4.4.5"
		function askversion {
    		while true; do
	        	if [ "${2:-}" = "Latest" ]; then
	            	prompt="Latest"
	            	default="Latest"
	        	fi

		        read -p "$1 [$prompt] " REPLY
		 
		        if [ -z "$REPLY" ]; then
		            REPLY=$default
		        fi
		 
		        case "$REPLY" in
					Latest) productversion="6.1.7" ; return 0 ;;
					6.1.7) productversion="6.1.7" ; return 0 ;;
					6.1.6) productversion="6.1.6" ; return 0 ;;
					6.1.5) productversion="6.1.5" ; return 0 ;;
					6.1.4) productversion="6.1.4" ; return 0 ;;
					6.1.3) productversion="6.1.3" ; return 0 ;;
					6.1.2) productversion="6.1.2" ; return 0 ;;
					6.1.1) productversion="6.1.1" ; return 0 ;;
					6.1) productversion="6.1" ; return 0 ;;
					6.0.8) productversion="6.0.8" ; return 0 ;;
					6.0.7) productversion="6.0.7" ; return 0 ;;
					6.0.6) productversion="6.0.6" ; return 0 ;;
					6.0.5) productversion="6.0.5" ; return 0 ;;
					6.0.4) productversion="6.0.4" ; return 0 ;;
					6.0.3) productversion="6.0.3" ; return 0 ;;
					6.0.2) productversion="6.0.2" ; return 0 ;;
					6.0.1) productversion="6.0.1" ; return 0 ;;
					6.0) productversion="6.0" ; return 0 ;;
					5.2.11) productversion="5.2.11" ; return 0 ;;
					5.1.8) productversion="5.1.8" ; return 0 ;;
					5.0.7) productversion="5.0.7" ; return 0 ;;
					4.4.5) productversion="4.4.5" ; return 0 ;;
		        esac
	    	done
		}
		echo "Which version of JIRA would you like to install?"
		echo ""
		echo "Available are:"
		echo $chooseversion61
		echo $chooseversion6
		echo $chooseversionold
		echo ""
		askversion "Please choose now:" Latest
		dl="https://downloads.atlassian.com/software/$product/downloads/atlassian-$product-$productversion-$arch.bin"
		echo "We need to create a database for JIRA. Please enter one or copy this random generated password:
		"
		randpw
		read -s -p "Enter Password: " jiradbpw
		echo "
		Creating database for JIRA... Please wait
		"
		jiradbcreate="CREATE DATABASE $product CHARACTER SET utf8 COLLATE utf8_bin;"
		jiradbgrant="GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER,INDEX on $product.* TO '$product'@'localhost' IDENTIFIED BY '$jiradbpw';"
		jirasql="$jiradbcreate $jiradbgrant $dbflush"
		mysql --defaults-file=/etc/mysql/debian.cnf -e "$jirasql"
		echo "Downloading and installing JIRA. This will take a while."
		echo "After the download finished you can go through the setup by pressing enter."
		echo "The standard settings are fine.
		"
		wget -O /tmp/$product-$productversion-$arch.bin $dl
		chmod +x /tmp/$product-$productversion-$arch.bin
		/tmp/$product-$productversion-$arch.bin
		cp $mysqlcjar $jirainstallpath/lib/
		echo "Now we must restart JIRA. Please wait...
		"
		/etc/init.d/$product stop
		sleep 10
		/etc/init.d/$product start
		echo ""
		echo "Installation of JIRA finished."
		echo "If you don't proceed with further installations please go to http://${ipaccess[0]}:8080 now and setup JIRA."
		echo "For the database setup you can use the database and user name '$product' and the password $jiradbpw"
		ask "Install another Atlassian product?" N
		if [ $? -ne 0 ] ; then
			echo" To secure your MySQL Server istallation we'll start a script provided by MySQL Server package. Please read everything carefully and set a password for the MySQL root user!"
			wait 10
			mysql_secure_installation
		exit 0
		fi
	fi
}

echo ""

{
	ask "Install Atlassian Confluence?" N
	if [ $? -ne 1 ] ; then
		confluenceinstallpath="/opt/atlassian/confluence/"
		product="confluence"
		chooseversion54="5.4.2, 5.4.1, 5.4"
		chooseversion53="5.3.4, 5.3.1, 5.3"
		chooseversion52="5.2.5, 5.2.3"
		chooseversion51="5.1.5, 5.1.4, 5.1.3, 5.1.2, 5.1.1, 5.1"
		chooseversion5="5.0.3, 5.0.2, 5.0.1, 5.0"
		chooseversionold="4.3.7, 4.2.13, 4.1.9, 4.0.5"
		function askversion {
    		while true; do
	        	if [ "${2:-}" = "Latest" ]; then
	            	prompt="Latest"
	            	default="Latest"
	        	fi

		        read -p "$1 [$prompt] " REPLY
		 
		        if [ -z "$REPLY" ]; then
		            REPLY=$default
		        fi
		 
		        case "$REPLY" in
					Latest) productversion="5.4.2" ; return 0 ;;
					5.4.2) productversion="5.4.2" ; return 0 ;;
					5.4.1) productversion="5.4.1" ; return 0 ;;
					5.4) productversion="5.4" ; return 0 ;;
					5.3.4) productversion="5.3.4" ; return 0 ;;
					5.3.1) productversion="5.3.1" ; return 0 ;;
					5.3) productversion="5.3" ; return 0 ;;
					5.2.5) productversion="5.2.5" ; return 0 ;;
					5.2.3) productversion="5.2.3" ; return 0 ;;
					5.1.5) productversion="5.1.5" ; return 0 ;;
					5.1.4) productversion="5.1.4" ; return 0 ;;
					5.1.3) productversion="5.1.3" ; return 0 ;;
					5.1.2) productversion="5.1.2" ; return 0 ;;
					5.1.1) productversion="5.1.1" ; return 0 ;;
					5.1) productversion="5.1" ; return 0 ;;
					5.0.3) productversion="5.0.3" ; return 0 ;;
					5.0.2) productversion="5.0.2" ; return 0 ;;
					5.0.1) productversion="5.0.1" ; return 0 ;;
					5.0) productversion="5.0" ; return 0 ;;
		        esac
	    	done
		}
		echo "Which version of Confluence would you like to install?"
		echo ""
		echo "Available are:"
		echo $chooseversion54
		echo $chooseversion53
		echo $chooseversion52
		echo $chooseversion51
		echo $chooseversion5
		echo $chooseversionold
		echo ""
		askversion "Please choose now:" Latest
		dl="https://downloads.atlassian.com/software/$product/downloads/atlassian-$product-$productversion-$arch.bin"
		echo "We need to create a database for Confluence. Please enter one or copy this random generated password:
		"
		randpw
		read -s -p "Enter Password: " confluencedbpw
		echo "
		Creating database for Confluence... Please wait
		"
		confluencedbbcreate="CREATE DATABASE $product CHARACTER SET utf8 COLLATE utf8_bin;"
		confluencedbgrant="GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER,INDEX on $product.* TO '$product'@'localhost' IDENTIFIED BY '$jiradbpw';"
		confluencesql="$confluencedbcreate $confluencedbgrant $dbflush"
		mysql --defaults-file=/etc/mysql/debian.cnf -e "$confluencesql"
		echo "Downloading and installing Confluence. This will take a while."
		echo "After the download finished you can go through the setup by pressing enter."
		echo "The standard settings are fine.
		"
		wget -O /tmp/$product-$productversion-$arch.bin $dl
		chmod +x /tmp/$product-$productversion-$arch.bin
		/tmp/$product-$productversion-$arch.bin
		cp $mysqlcjar $confluenceinstallpath/lib/
		echo "Now we must restart Confluence. Please wait...
		"
		/etc/init.d/$product stop
		sleep 10
		/etc/init.d/$product start
		echo ""
		echo "Installation of Confluence finished."
		echo "If you don't proceed with further installations please go to http://${ipaccess[0]}:8090 now and setup Confluence."
		echo "For the database setup you can use the database and user name '$product' and the password $confluencedbpw"
		ask "Install another Atlassian product?" N
		if [ $? -ne 0 ] ; then
			echo" To secure your MySQL Server istallation we'll start a script provided by MySQL Server package. Please read everything carefully and set a password for the MySQL root user!"
			wait 10
			mysql_secure_installation
		exit 0
		fi
	fi
}

echo ""
echo "Before proceeding with the installation of other Atlassian products we must download and install Oracle Java.
Why? JIRA and Confluence are shipping with Java. The other applications are currently not.
"
ask "Proceed with the Java Installation?" Y
if [ $? -ne 0 ] ; then
	echo "Can't proceed without Java. Goodbye!"
	exit 0
fi

if [ $arch == x32 ] ; then
	jdkarch="i586"
else
	jdkarch="x64"
fi

# Please note that the download link is not as generic as you wish it would be!
jdkversion="jdk-7u51-linux"
jdkunpack="jdk1.7.0_51"
wget -O /tmp/java_jdk.tar.gz --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com" "http://download.oracle.com/otn-pub/java/jdk/7u51-b13/$jdkversion-$jdkarch.tar.gz"
echo "Unpacking Java and moving to /opt/"
tar xzf /tmp/java_jdk.tar.gz
mv /tmp/$jdkunpack /opt
chown -R root: /opt/$jdkunpack
echo "Linking new Java to /opt/java_current"
if [ -d /opt/java_current ]; then
	rm  /opt/java_current
fi
ln -s /opt/$jdkunpack /opt/java_current
echo "Setting up JAVA_HOME in /etc/environment if it doesn't exist. Hold on!"
grep JAVA_HOME="/opt/java_current" /etc/environment
if [ $? -eq 1 ]; then
	echo JAVA_HOME="/opt/java_current" >> /etc/environment
fi
echo ""

{
	ask "Install Atlassian Bamboo?" N
	if [ $? -ne 1 ] ; then
		bambooinstallpath="/opt/atlassian/bamboo/"
		bamboolinkpath="/opt/atlassian/bamboo"
		product="bamboo"
		chooseversion54="5.4.1, 5.4"
		chooseversion53="5.3"
		chooseversion52="5.2.2, 5.2.1, 5.2"
		chooseversion51="5.1.1, 5.1.0"
		chooseversion5="5.0.1, 5.0"
		chooseversionold="4.4.8, 4.3.4, 4.2.2, 4.1.2, 4.0.1, 3.4.5, 3.3.4"
		function askversion {
    		while true; do
	        	if [ "${2:-}" = "Latest" ]; then
	            	prompt="Latest"
	            	default="Latest"
	        	fi

		        read -p "$1 [$prompt] " REPLY
		 
		        if [ -z "$REPLY" ]; then
		            REPLY=$default
		        fi
		 
		        case "$REPLY" in
					Latest) productversion="5.4.1" ; return 0 ;;
					5.4.1) productversion="5.4.1" ; return 0 ;;
					5.4.1) productversion="5.4.1" ; return 0 ;;
					5.4) productversion="5.4" ; return 0 ;;
					5.3) productversion="5.3" ; return 0 ;;
					5.2.2) productversion="5.2.2" ; return 0 ;;
					5.2) productversion="5.2" ; return 0 ;;
					5.1.1) productversion="5.1.1" ; return 0 ;;
					5.1.0) productversion="5.1.0" ; return 0 ;;
					5.0.1) productversion="5.0.1" ; return 0 ;;
					5.0) productversion="5.0" ; return 0 ;;
					4.4.8) productversion="4.4.8" ; return 0 ;;
					4.3.4) productversion="4.3.4" ; return 0 ;;
					4.2.2) productversion="4.2.2" ; return 0 ;;
					4.1.2) productversion="4.1.2" ; return 0 ;;
					4.0.1) productversion="4.0.1" ; return 0 ;;
					3.4.5) productversion="3.4.5" ; return 0 ;;
					3.3.4) productversion="3.3.4" ; return 0 ;;
		        esac
	    	done
		}
		echo "Which version of Bamboo would you like to install?"
		echo ""
		echo "Available are:"
		echo $chooseversion54
		echo $chooseversion53
		echo $chooseversion52
		echo $chooseversion51
		echo $chooseversion5
		echo $chooseversionold
		echo ""
		askversion "Please choose now:" Latest
		dl="https://downloads.atlassian.com/software/$product/downloads/atlassian-$product-$productversion.tar.gz"
		echo "We need to create a database for Bamboo. Please enter one or copy this random generated password:
		"
		randpw
		read -s -p "Enter Password: " bamboodbpw
		echo "
		Creating database for Bamboo... Please wait
		"
		bamboodbbcreate="CREATE DATABASE $product CHARACTER SET utf8 COLLATE utf8_bin;"
		bamboodbgrant="GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER,INDEX on $product.* TO '$product'@'localhost' IDENTIFIED BY '$jiradbpw';"
		bamboosql="$bamboodbcreate $bamboodbgrant $dbflush"
		mysql --defaults-file=/etc/mysql/debian.cnf -e "$bamboosql"
		echo "Downloading and installing Bamboo. This will take a while."
		echo "As no setup is currently provided we'll do some magic to get it running."
		echo "Let's get bamboo:"
		wget -O /tmp/$product-$productversion.tar.gz $dl
		echo "Unpack it..."
		tar xzf /tmp/$product-$productversion.tar.gz
		echo "Move it to /opt/atlassian/"
		mkdir /opt/atlassian
		mv /tmp/atlassian-$product-$productversion /opt/atlassian/
		echo "Link it to $bambooinstallpath..."
		if [ -d $bamboolinkpath ]; then
			rm  $bamboolinkpath
		fi
		ln -s /opt/atlassian/atlassian-$product-$productversion $bamboolinkpath
		cp $mysqlcjar $bamboolinkpath/lib/
		echo "Create a home directory, set up rights and tell bamboo where to find it..."
		bamboohome="/var/atlassian/bamboo-home"
		echo bamboo.home=$bamboohome >> $bamboolinkpath/atlassian-bamboo/WEB-INF/classes/bamboo-init.properties
		mkdir /var/atlassian
		mkdir $bamboohome
		useradd --create-home -c "Bamboo role account" bamboo
		chown -R bamboo: $bamboolinkpath
		chown -R bamboo: /opt/atlassian/atlassian-$product-$productversion
		chown -R bamboo: $bamboohome
		cat <<'EOF' > /etc/init.d/$product
#!/bin/sh -e
# bamboo startup script
#chkconfig: 2345 80 05
#description: bamboo
 
# Define some variables
# Name of app ( bamboo, Confluence, etc )
APP=bamboo
# Name of the user to run as
USER=bamboo
# Location of application's bin directory
BASE=/opt/atlassian/bamboo
# Location of Java JDK
export JAVA_HOME=/opt/java_current
 
case "$1" in
  # Start command
  start)
    echo "Starting $APP"
    /bin/su -m $USER -c "cd $BASE/logs && $BASE/bin/startup.sh &> /dev/null"
    ;;
  # Stop command
  stop)
    echo "Stopping $APP"
    /bin/su -m $USER -c "$BASE/bin/shutdown.sh &> /dev/null"
    echo "$APP stopped successfully"
    ;;
   # Restart command
   restart)
        $0 stop
        sleep 5
        $0 start
        ;;
  *)
    echo "Usage: /etc/init.d/$APP {start|restart|stop}"
    exit 1
    ;;
esac
 
exit 0
EOF
		chmod +x /etc/init.d/$product
		echo "And in the end add bamboo as service which should start with the system..."
		update-rc.d $product defaults
		echo "Let's start bamboo!"
		/etc/init.d/$product start
		echo ""
		echo "Installation of Bamboo finished."
		echo "If you don't proceed with further installations please go to http://${ipaccess[0]}:8085 now and setup Bamboo."
		echo "For the database setup you can use the database and user name '$product' and the password $bamboodbpw"
		ask "Install another Atlassian product?" N
		if [ $? -ne 0 ] ; then
			echo" To secure your MySQL Server istallation we'll start a script provided by MySQL Server package. Please read everything carefully and set a password for the MySQL root user!"
			wait 10
			mysql_secure_installation
		exit 0
		fi
		echo ""
	fi
}

echo "hello world"
