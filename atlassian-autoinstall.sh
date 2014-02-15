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

# Install Jira
{
	ask "Install Atlassian JIRA?" N
	if [ $? -ne 1 ] ; then
		jirainstallpath="/opt/atlassian/jira/"
		product="jira"
		chooseversion61="6.1.6 6.1.5 6.1.4 6.1.3 6.1.2 6.1.1 6.1"
		chooseversion60="6.0.8 6.0.7 6.0.6 6.0.5 6.0.4 6.0.3 6.0.2 6.0.1 6.0"
		chooseversionold="5.2.11 5.1.8 5.0.7 4.4.5"
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
		echo "Which version of JIRA would you like to install?

		Available are:"
		echo $chooseversion61
		echo $chooseversion60
		echo $chooseversionold
		echo ""
		askversion "Please choose now:" Latest
		dl="http://downloads.atlassian.com/software/$product/downloads/atlassian-$product-$productversion-$arch.bin"
		echo "We need to create a database for JIRA. Please enter one or copy this random generated password:
		"
		randpw
		read -s -p "Enter Password: " jiradbpw
		echo "
		Creating database for Jira... Please wait
		"
		jiradbcreate="CREATE DATABASE jira CHARACTER SET utf8 COLLATE utf8_bin;"
		jiradbgrant="GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER,INDEX on jira.* TO 'jira'@'localhost' IDENTIFIED BY '$jiradbpw';"
		jirasql="$jiradbcreate $jiradbgrant $dbflush"
		mysql --defaults-file=/etc/mysql/debian.cnf -e "$jirasql"
		echo "Downloading and installing JIRA. This will take a while.
		"
		wget -O /tmp/jira_$productversion-$arch.bin $dl
		chmod +x /tmp/jira_$productversion-$arch.bin
		/tmp/jira_$productversion-$arch.bin
		cp $mysqlcjar $jirainstallpath/lib/
		echo "Now we must restart JIRA. Please wait...
		"
		/etc/init.d/jira stop
		sleep 10
		/etc/init.d/jira start
		echo ""
		echo "Installation of JIRA finished."
		echo "If you don't proceed with further installations please go to http://localhost:8080 now and setup JIRA."
		echo "For the database setup you can use the database and user name 'jira' and the password $jiradbpw"
		ask "Install another Atlassian product?" N
		if [ $? -ne 0 ] ; then
			echo "Thanks for using this script. Goodbye!"
		exit 0
		fi
	fi
}

echo "hello world"
