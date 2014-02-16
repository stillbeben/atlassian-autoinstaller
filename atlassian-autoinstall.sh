#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                           #
# Author: Rico Ullmann <git [<ät>] erinnerungsfragmente.de>                 #
# Website: erinnerungsfragmente.de                                          #
# Github: https://github.com/rullmann                                       #
#                                                                           #
# Version: 0.3 / Date: 16th February 2014                                    #
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

It can install the following applications:
* Atlassian JIRA
* Atlassian Confluence
* Atlassian Bamboo
* Atlassian Stash
* Atlassian Fisheye & Crucible
* Atlassian Crowd
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
	(< /dev/urandom tr -dc '1234567890aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ!?=-_#+' | head -c${1:-24};echo;)
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
	DEPS=(mysql-server mysql-client unzip)
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
		jiralinkpath="/opt/atlassian/jira"
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
		echo ""
		echo "Creating database for JIRA... Please wait"
		echo ""
		jiradbcreate="CREATE DATABASE $product CHARACTER SET utf8 COLLATE utf8_bin;"
		jiradbgrant="GRANT ALL on $product.* TO '$product'@'localhost' IDENTIFIED BY '$jiradbpw';"
		jirasql="$jiradbcreate $jiradbgrant $dbflush"
		mysql --defaults-file=/etc/mysql/debian.cnf -e "$jirasql"
		echo "Downloading and installing JIRA. This will take a while."
		echo "After the download finished you can go through the setup by pressing enter."
		echo "The standard settings are fine.
		"
		wget -O /tmp/$product-$productversion-$arch.bin $dl
		chmod +x /tmp/$product-$productversion-$arch.bin
		/tmp/$product-$productversion-$arch.bin
		cp $mysqlcjar $jiralinkpath/lib/
		echo "Now we must restart JIRA. Please wait...
		"
		/etc/init.d/$product stop
		sleep 10
		/etc/init.d/$product start
		echo ""
		echo "Installation of JIRA finished."
		echo "If you don't proceed with further installations please go to http://${ipaccess[0]}:8080 now and setup JIRA."
		echo "For the database setup you can use the database and user name '$product' and the password $jiradbpw"
		echo ""
		ask "Install another Atlassian product?" N
		if [ $? -ne 0 ] ; then
			echo "To secure your MySQL Server installation we'll start a script provided by MySQL Server package. Please read everything carefully and set a password for the MySQL root user!"
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
		confluencelinkpath="/opt/atlassian/confluence"
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
		echo ""
		echo "Creating database for Confluence... Please wait"
		echo ""
		confluencedbbcreate="CREATE DATABASE $product CHARACTER SET utf8 COLLATE utf8_bin;"
		confluencedbgrant="GRANT ALL on $product.* TO '$product'@'localhost' IDENTIFIED BY '$confluencedbpw';"
		confluencesql="$confluencedbcreate $confluencedbgrant $dbflush"
		mysql --defaults-file=/etc/mysql/debian.cnf -e "$confluencesql"
		echo "Downloading and installing Confluence. This will take a while."
		echo "After the download finished you can go through the setup by pressing enter."
		echo "The standard settings are fine.
		"
		wget -O /tmp/$product-$productversion-$arch.bin $dl
		chmod +x /tmp/$product-$productversion-$arch.bin
		/tmp/$product-$productversion-$arch.bin
		cp $mysqlcjar $confluencelinkpath/lib/
		echo "Now we must restart Confluence. Please wait...
		"
		/etc/init.d/$product stop
		sleep 10
		/etc/init.d/$product start
		echo ""
		echo "Installation of Confluence finished."
		echo "If you don't proceed with further installations please go to http://${ipaccess[0]}:8090 now and setup Confluence."
		echo "For the database setup you can use the database and user name '$product' and the password $confluencedbpw"
		echo ""
		ask "Install another Atlassian product?" N
		if [ $? -ne 0 ] ; then
			echo "To secure your MySQL Server installation we'll start a script provided by MySQL Server package. Please read everything carefully and set a password for the MySQL root user!"
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
		echo ""
		echo "Creating database for Bamboo... Please wait"
		echo ""
		bamboodbbcreate="CREATE DATABASE $product CHARACTER SET utf8 COLLATE utf8_bin;"
		bamboodbgrant="GRANT ALL on $product.* TO '$product'@'localhost' IDENTIFIED BY '$bamboodbpw';"
		bamboosql="$bamboodbcreate $bamboodbgrant $dbflush"
		mysql --defaults-file=/etc/mysql/debian.cnf -e "$bamboosql"
		echo "Downloading and installing Bamboo. This will take a while."
		echo "As no setup is currently provided we'll do some magic to get it running."
		echo "Let's get Bamboo:"
		wget -O /tmp/$product-$productversion.tar.gz $dl
		echo "Unpack it..."
		tar xzf /tmp/$product-$productversion.tar.gz
		echo "Move it to /opt/atlassian/"
		mkdir /opt/atlassian
		mv /tmp/atlassian-$product-$productversion /opt/atlassian/
		echo "Link it to $bambooinstallpath ..."
		if [ -d $bamboolinkpath ]; then
			rm  $bamboolinkpath
		fi
		ln -s /opt/atlassian/atlassian-$product-$productversion $bamboolinkpath
		cp $mysqlcjar $bamboolinkpath/lib/
		echo "Create a home directory, set up rights and tell Bamboo where to find it..."
		bamboohome="/var/atlassian/application-data/bamboo-home"
		echo bamboo.home=$bamboohome >> $bamboolinkpath/atlassian-bamboo/WEB-INF/classes/bamboo-init.properties
		mkdir /var/atlassian
		mkdir /var/atlassian/application-data
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
		echo "And in the end add Bamboo as service which should start with the system..."
		update-rc.d $product defaults
		echo "Let's start Bamboo!"
		/etc/init.d/$product start
		echo ""
		echo "Installation of Bamboo finished."
		echo "If you don't proceed with further installations please go to http://${ipaccess[0]}:8085 now and setup Bamboo."
		echo "For the database setup you can use the database and user name '$product' and the password $bamboodbpw"
		echo ""
		ask "Install another Atlassian product?" N
		if [ $? -ne 0 ] ; then
			echo "To secure your MySQL Server installation we'll start a script provided by MySQL Server package. Please read everything carefully and set a password for the MySQL root user!"
			wait 10
			mysql_secure_installation
		exit 0
		fi
		echo ""
	fi
}

echo ""

{
	ask "Install Atlassian Stash?" N
	if [ $? -ne 1 ] ; then
		stashinstallpath="/opt/atlassian/stash/"
		stashlinkpath="/opt/atlassian/stash"
		product="stash"
		chooseversion210="2.10.2, 2.10.9, 2.10.0"
		chooseversion29="2.9.5, 2.9.4, 2.9.3, 2.9.2, 2.9.1"
		chooseversionold="2.8.4, 2.7.6, 2.6.5, 2.5.4, 2.4.2, 2.3.1, 2.2.0, 2.1.2"
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
					Latest) productversion="2.10.2" ; return 0 ;;
					2.10.2) productversion="2.10.2" ; return 0 ;;
					2.9.5) productversion="2.9.5" ; return 0 ;;
					2.9.4) productversion="2.9.4" ; return 0 ;;
					2.9.3) productversion="2.9.3" ; return 0 ;;
					2.9.2) productversion="2.9.2" ; return 0 ;;
					2.9.1) productversion="2.9.1" ; return 0 ;;
					2.8.4) productversion="2.8.4" ; return 0 ;;
					2.7.6) productversion="2.7.6" ; return 0 ;;
					2.6.5) productversion="2.6.5" ; return 0 ;;
					2.5.4) productversion="2.5.4" ; return 0 ;;
					2.4.2) productversion="2.4.2" ; return 0 ;;
					2.3.1) productversion="2.3.1" ; return 0 ;;
					2.2.0) productversion="2.2.0" ; return 0 ;;
					2.1.2) productversion="2.1.2" ; return 0 ;;
		        esac
	    	done
		}
		echo "Which version of Stash would you like to install?"
		echo ""
		echo "Available are:"
		echo $chooseversion210
		echo $chooseversion29
		echo $chooseversionold
		echo ""
		askversion "Please choose now:" Latest
		dl="https://downloads.atlassian.com/software/$product/downloads/atlassian-$product-$productversion.tar.gz"
		echo "We need to create a database for Stash. Please enter one or copy this random generated password:
		"
		randpw
		read -s -p "Enter Password: " stashdbpw
		echo ""
		echo "Creating database for Stash... Please wait"
		echo ""
		stashdbbcreate="CREATE DATABASE $product CHARACTER SET utf8 COLLATE utf8_bin;"
		stashdbgrant="GRANT ALL on $product.* TO '$product'@'localhost' IDENTIFIED BY '$stashdbpw';"
		bstashsql="$stashdbcreate $stashdbgrant $dbflush"
		mysql --defaults-file=/etc/mysql/debian.cnf -e "$stashsql"
		ask "Stash requires perl and git. We must install both. Do you want to proceed?" N

		if [ $? -ne 0 ] ; then
			echo "Without perl and git Stash won't work. Goodbye!"
			exit 0
		fi

		installdepsstash () {
			DEPS=(git perl)
			export DEBIAN_FRONTEND=noninteractive
		    aptitude install -q -y ${DEPS[*]}
		}

		installdepsstash
		echo ""
		echo "Downloading and installing Stash. This will take a while."
		echo "As no setup is currently provided we'll do some magic to get it running."
		echo "Let's get Stash:"
		echo ""
		wget -O /tmp/$product-$productversion.tar.gz $dl
		echo "Unpack it..."
		tar xzf /tmp/$product-$productversion.tar.gz
		echo "Move it to /opt/atlassian/"
		mkdir /opt/atlassian
		mv /tmp/atlassian-$product-$productversion /opt/atlassian/
		echo "Link it to $stashinstallpath ..."
		if [ -d $stashlinkpath ]; then
			rm  $stashlinkpath
		fi
		ln -s /opt/atlassian/atlassian-$product-$productversion $stashlinkpath
		cp $mysqlcjar $stashlinkpath/lib/
		echo "Create a home directory, set up rights and tell Stash where to find it..."
		stashhome="/var/atlassian/application-data/stash-home"
		echo STASH_HOME="$stashhome" >> $stashlinkpath/bin/setenv.sh
		mkdir /var/atlassian
		mkdir /var/atlassian/application-data
		mkdir $stashhome
		useradd --create-home -c "Stash role account" stash
		chown -R stash: $stashlinkpath
		chown -R stash: /opt/atlassian/atlassian-$product-$productversion
		chown -R stash: $stashhome
		cat <<'EOF' > /etc/init.d/$product
#! /bin/sh
### BEGIN INIT INFO
# Provides:          stash
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Initscript for Atlassian Stash
# Description:  Automatically start Atlassian Stash when the system starts up.
#               Provide commands for manually starting and stopping Stash.
### END INIT INFO
# Adapt the following lines to your configuration
# RUNUSER: The user to run Stash as.
RUNUSER=stash
# STASH_INSTALLDIR: The path to the Stash installation directory
STASH_INSTALLDIR="/opt/atlassian/stash"
# STASH_HOME: Path to the Stash home directory
STASH_HOME="/var/atlassian/application-data/stash-home"
# ==================================================================================
# ==================================================================================
# ==================================================================================
# PATH should only include /usr/* if it runs after the mountnfs.sh script
PATH=/sbin:/usr/sbin:/bin:/usr/bin
DESC="Atlassian Stash"
NAME=stash
PIDFILE=$STASH_INSTALLDIR/work/catalina.pid
SCRIPTNAME=/etc/init.d/$NAME
# Read configuration variable file if it is present
[ -r /etc/default/$NAME ] && . /etc/default/$NAME
# Define LSB log_* functions.
# To be replaced by LSB functions
# Defined here for distributions that don't define
# log_daemon_msg
log_daemon_msg () {
    echo $@
}
# To be replaced by LSB functions
# Defined here for distributions that don't define
# log_end_msg
log_end_msg () {
    retval=$1
    if [ $retval -eq 0 ]; then
        echo "."
    else
        echo " failed!"
    fi
    return $retval
}
# Depend on lsb-base (>= 3.0-6) to ensure that this file is present.
. /lib/lsb/init-functions
 
run_with_home() {
    if [ "$RUNUSER" != "$USER" ]; then
        su - "$RUNUSER" -c "export STASH_HOME=${STASH_HOME};${STASH_INSTALLDIR}/bin/$1"
    else
        export STASH_HOME=${STASH_HOME};${STASH_INSTALLDIR}/bin/$1
    fi
}
#
# Function that starts the daemon/service
#
do_start()
{
    run_with_home start-stash.sh
}
#
# Function that stops the daemon/service
#
do_stop()
{
    if [ -e $PIDFILE ]; then
      run_with_home stop-stash.sh
    else
      log_failure_msg "$NAME is not running."
    fi
}
 
case "$1" in
  start)
    [ "$VERBOSE" != no ] && log_daemon_msg "Starting $DESC" "$NAME"
    do_start
    case "$?" in
        0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
        2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
    esac
    ;;
  stop)
    [ "$VERBOSE" != no ] && log_daemon_msg "Stopping $DESC" "$NAME"
    do_stop
    case "$?" in
        0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
        2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
    esac
    ;;
  status)
       if [ ! -e $PIDFILE ]; then
         log_failure_msg "$NAME is not running."
         return 1
       fi
       status_of_proc -p $PIDFILE "" $NAME && exit 0 || exit $?
       ;;
  restart|force-reload)
    #
    # If the "reload" option is implemented then remove the
    # 'force-reload' alias
    #
    log_daemon_msg "Restarting $DESC" "$NAME"
    do_stop
    case "$?" in
      0|1)
        do_start
        case "$?" in
            0) log_end_msg 0 ;;
            1) log_end_msg 1 ;; # Old process is still running
            *) log_end_msg 1 ;; # Failed to start
        esac
        ;;
      *)
        # Failed to stop
        log_end_msg 1
        ;;
    esac
    ;;
  *)
    echo "Usage: $SCRIPTNAME {start|stop|status|restart|force-reload}" >&2
    exit 3
    ;;
esac
EOF
		chmod +x /etc/init.d/$product
		echo "And in the end add Stash as service which should start with the system..."
		update-rc.d $product defaults
		echo "Let's start Stash!"
		/etc/init.d/$product start
		echo ""
		echo "Installation of Stash finished."
		echo "If you don't proceed with further installations please go to http://${ipaccess[0]}:7990 now and setup Stash."
		echo "For the database setup you can use the database and user name '$product' and the password $stashdbpw"
		echo ""
		ask "Install another Atlassian product?" N
		if [ $? -ne 0 ] ; then
			echo "To secure your MySQL Server installation we'll start a script provided by MySQL Server package. Please read everything carefully and set a password for the MySQL root user!"
			wait 10
			mysql_secure_installation
		exit 0
		fi
		echo ""
	fi
}

echo ""

{
	ask "Install Atlassian FishEye?" N
	if [ $? -ne 1 ] ; then
		fisheyeinstallpath="/opt/atlassian/fisheye/"
		fisheyelinkpath="/opt/atlassian/fisheye"
		product="fisheye"
		chooseversion3="3.3.0, 3.2.4, 3.1.6, 3.0.3"
		chooseversionold="2.10.8, 2.9.2, 2.8.2, 2.7.15, 2.6.9, 2.5.9"
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
					Latest) productversion="3.3.0" ; return 0 ;;
					3.3.0) productversion="3.3.0" ; return 0 ;;
					3.2.4) productversion="3.2.4" ; return 0 ;;
					3.1.6) productversion="3.1.6" ; return 0 ;;
					3.0.3) productversion="3.0.3" ; return 0 ;;
					2.10.8) productversion="2.10.8" ; return 0 ;;
					2.9.2) productversion="2.9.2" ; return 0 ;;
					2.8.2) productversion="2.8.2" ; return 0 ;;
					2.7.15) productversion="2.7.15" ; return 0 ;;
					2.6.9) productversion="2.6.9" ; return 0 ;;
					2.5.9) productversion="2.5.9" ; return 0 ;;
		        esac
	    	done
		}
		echo "Which version of Fisheye would you like to install?"
		echo ""
		echo "Available are:"
		echo $chooseversion3
		echo $chooseversionold
		echo ""
		askversion "Please choose now:" Latest
		dl="https://downloads.atlassian.com/software/$product/downloads/$product-$productversion.zip"
		echo "We need to create a database for Fisheye. Please enter one or copy this random generated password:
		"
		randpw
		read -s -p "Enter Password: " fisheyedbpw
		echo ""
		echo "Creating database for Fisheye... Please wait"
		echo ""
		fisheyedbbcreate="CREATE DATABASE $product CHARACTER SET utf8 COLLATE utf8_bin;"
		fisheyedbgrant="GRANT ALL on $product.* TO '$product'@'localhost' IDENTIFIED BY '$fisheyedbpw';"
		fisheyesql="$fisheyedbcreate $fisheyedbgrant $dbflush"
		mysql --defaults-file=/etc/mysql/debian.cnf -e "$fisheyesql"
		echo "Downloading and installing Fisheye. This will take a while."
		echo "As no setup is currently provided we'll do some magic to get it running."
		echo "Let's get Fisheye:"
		wget -O /tmp/$product-$productversion.zip $dl
		echo "Unpack it..."
		unzip /tmp/$product-$productversion.zip -d /tmp/
		echo "Move it to /opt/atlassian/"
		mkdir /opt/atlassian
		mv /tmp/fecru-$productversion /opt/atlassian/
		echo "Link it to $fisheyeinstallpath ..."
		if [ -d $fisheyelinkpath ]; then
			rm  $fisheyelinkpath
		fi
		ln -s /opt/atlassian/fecru-$productversion $fisheyelinkpath
		cp $mysqlcjar $fisheyelinkpath/lib/
		echo "Create a home directory, set up rights and tell Fisheye where to find it..."
		fisheyehome="/var/atlassian/application-data/fisheye-home"
		grep FISHEYE_INST="$fisheyehome" /etc/environment
		if [ $? -eq 1 ]; then
			echo FISHEYE_INST="$fisheyehome" >> /etc/environment
		fi
		mkdir /var/atlassian
		mkdir /var/atlassian/application-data
		mkdir $fisheyehome
		cp $fisheyelinkpath/config.xml $fisheyehome
		useradd --create-home -c "Fisheye role account" fisheye
		chown -R fisheye: $fisheyelinkpath
		chown -R fisheye: /opt/atlassian/fecru-$productversion
		chown -R fisheye: $fisheyehome
		cat <<'EOF' > /etc/init.d/$product
#!/bin/bash
# Fisheye startup script
# chkconfig: 345 90 90
# description: Atlassian FishEye
# original found at: http://jarrod.spiga.id.au/?p=35

FISHEYE_USER=fisheye
FISHEYE_HOME=/opt/atlassian/fisheye/bin
start() {
        echo "Starting FishEye: "
        if [ "x$USER" != "x$FISHEYE_USER" ]; then
          su - $FISHEYE_USER -c "$FISHEYE_HOME/fisheyectl.sh start"
        else
          $FISHEYE_HOME/fisheyectl.sh start
        fi
        echo "done."
}
stop() {
        echo "Shutting down FishEye: "
        if [ "x$USER" != "x$FISHEYE_USER" ]; then
          su - $FISHEYE_USER -c "$FISHEYE_HOME/fisheyectl.sh stop"
        else
          $FISHEYE_HOME/fisheyectl.sh stop
        fi
        echo "done."
}

case "$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  restart)
        stop
        sleep 10
        start
        ;;
  *)
        echo "Usage: $0 {start|stop|restart}"
esac

exit 0
EOF
		chmod +x /etc/init.d/$product
		echo "And in the end add Fisheye as service which should start with the system..."
		update-rc.d $product defaults
		echo "Let's start Fisheye!"
		/etc/init.d/$product start
		echo ""
		echo "Installation of Fisheye finished."
		echo "If you don't proceed with further installations please go to http://${ipaccess[0]}:8060 now and setup Fisheye."
		echo "For the database setup you can use the database and user name '$product' and the password $fisheyedbpw"
		echo ""
		ask "Install another Atlassian product?" N
		if [ $? -ne 0 ] ; then
			echo "To secure your MySQL Server installation we'll start a script provided by MySQL Server package. Please read everything carefully and set a password for the MySQL root user!"
			wait 10
			mysql_secure_installation
		exit 0
		fi
		echo ""
	fi
}

echo ""

{
	ask "Install Atlassian Crowd?" N
	if [ $? -ne 1 ] ; then
		crowdinstallpath="/opt/atlassian/crowd/"
		crowdlinkpath="/opt/atlassian/crowd"
		product="crowd"
		chooseversion27="2.7.1, 2.7.0"
		chooseversionold="2.6.5, 2.6.4, 2.5.5, 2.4.10, 2.3.9, 2.2.9, 2.0.9"
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
					Latest) productversion="2.7.1" ; return 0 ;;
					2.7.1) productversion="2.7.1" ; return 0 ;;
					2.7.0) productversion="2.7.0" ; return 0 ;;
					2.6.5) productversion="2.6.5" ; return 0 ;;
					2.6.4) productversion="2.6.4" ; return 0 ;;
					2.5.5) productversion="2.5.5" ; return 0 ;;
					2.4.10) productversion="2.4.10" ; return 0 ;;
					2.3.9) productversion="2.3.9" ; return 0 ;;
					2.2.9) productversion="2.2.9" ; return 0 ;;
					2.0.9) productversion="2.0.9" ; return 0 ;;
		        esac
	    	done
		}
		echo "Which version of Crowd would you like to install?"
		echo ""
		echo "Available are:"
		echo $chooseversion27
		echo $chooseversionold
		echo ""
		askversion "Please choose now:" Latest
		dl="https://downloads.atlassian.com/software/$product/downloads/atlassian-$product-$productversion.tar.gz"
		echo "We need to create a database for Crowd. Please enter one or copy this random generated password:
		"
		randpw
		read -s -p "Enter Password: " crowddbpw
		echo ""
		echo "Creating database for Crowd... Please wait"
		echo ""
		crowddbbcreate="CREATE DATABASE $product CHARACTER SET utf8 COLLATE utf8_bin;"
		crowddbgrant="GRANT ALL on $product.* TO '$product'@'localhost' IDENTIFIED BY '$crowddbpw';"
		crowdsql="$crowddbcreate $crowddbgrant $dbflush"
		mysql --defaults-file=/etc/mysql/debian.cnf -e "$crowdsql"
		echo ""
		echo "Downloading and installing Crowd. This will take a while."
		echo "As no setup is currently provided we'll do some magic to get it running."
		echo "Let's get Crowd:"
		echo ""
		wget -O /tmp/$product-$productversion.tar.gz $dl
		echo "Unpack it..."
		tar xzf /tmp/$product-$productversion.tar.gz
		echo "Move it to /opt/atlassian/"
		mkdir /opt/atlassian
		mv /tmp/atlassian-$product-$productversion /opt/atlassian/
		echo "Link it to $crowdinstallpath ..."
		if [ -d $crowdlinkpath ]; then
			rm  $crowdlinkpath
		fi
		ln -s /opt/atlassian/atlassian-$product-$productversion $crowdlinkpath
		cp $mysqlcjar $crowdlinkpath/apache-tomcat/lib/
		echo "Create a home directory, set up rights and tell Crowd where to find it..."
		crowdhome="/var/atlassian/application-data/crowd-home"
		echo crowd.home=$crowdhome >> $crowdlinkpath/crowd-webapp/WEB-INF/classes/crowd-init.properties
		mkdir /var/atlassian
		mkdir /var/atlassian/application-data
		mkdir $crowdhome
		useradd --create-home -c "Crowd role account" crowd
		chown -R crowd: $crowdlinkpath
		chown -R crowd: /opt/atlassian/atlassian-$product-$productversion
		chown -R crowd: $crowdhome
		cat <<'EOF' > /etc/init.d/$product
#!/bin/bash
# Crowd startup script
#chkconfig: 2345 80 05
#description: Crowd
 
 
# Based on script at http://www.bifrost.org/problems.html
 
RUN_AS_USER=crowd
CATALINA_HOME=/opt/atlassian/crowd/apache-tomcat
 
start() {
        echo "Starting Crowd: "
        if [ "x$USER" != "x$RUN_AS_USER" ]; then
          su - $RUN_AS_USER -c "$CATALINA_HOME/bin/startup.sh"
        else
          $CATALINA_HOME/bin/startup.sh
        fi
        echo "done."
}
stop() {
        echo "Shutting down Crowd: "
        if [ "x$USER" != "x$RUN_AS_USER" ]; then
          su - $RUN_AS_USER -c "$CATALINA_HOME/bin/shutdown.sh"
        else
          $CATALINA_HOME/bin/shutdown.sh
        fi
        echo "done."
}
 
case "$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  restart)
        stop
        sleep 10
        #echo "Hard killing any remaining threads.."
        #kill -9 `cat $CATALINA_HOME/work/catalina.pid`
        start
        ;;
  *)
        echo "Usage: $0 {start|stop|restart}"
esac
 
exit 0
EOF
		chmod +x /etc/init.d/$product
		echo "And in the end add Crowd as service which should start with the system..."
		update-rc.d $product defaults
		echo "Let's start bamboo!"
		/etc/init.d/$product start
		echo ""
		echo "Installation of Crowd finished."
		echo "If you don't proceed with further installations please go to http://${ipaccess[0]}:8095/crowd now and setup Crowd."
		echo "For the database setup you can use the database and user name '$product' and the password $stashdbpw"
		echo ""
	fi
}

echo "To secure your MySQL Server installation we'll start a script provided by MySQL Server package. Please read everything carefully and set a password for the MySQL root user!"
wait 10
mysql_secure_installation

exit 0