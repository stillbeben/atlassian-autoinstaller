#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                           #
# Author: Rico Ullmann <git [<ät>] erinnerungsfragmente.de>                 #
# Website: erinnerungsfragmente.de                                          #
# Github: https://github.com/rullmann                                       #
#                                                                           #
# Version: 0.1 / Date: 14. February 2014                                    #
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

echo "Welcome to the Atlassian Autoinstaller.
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
install_deps () {
	DEPS=(mysql-server mysql-client apache2)
	export DEBIAN_FRONTEND=noninteractive
    aptitude install -q -y ${DEPS[*]}
}

# execute the check_deps function
install_deps

# Maybe Later we would like to make this more generic. So let's define this outside of the subshell:
jiralatest=6.1.7
jiraversion=$jiralatest
jiradl="http://downloads.atlassian.com/software/jira/downloads/atlassian-jira-$jiraversion-$arch.bin"

dbflush="flush privileges;"

# The mysql-connector-java is required. Currently this script download and install mysql-connector-java-5.1.29.tar.gz
echo "Now we download and unpack the mysql-connector-java for later use.
Without it we can't connect the Applications to mysql
"
ask "Proceed?" N
if [ $? -ne 0 ] ; then
	echo "Goodbye!"
	exit 0
fi

mysqlcversion="mysql-connector-java-5.1.29"
mysqlcdl="https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.29.tar.gz"
mysqlctar="/tmp/mysqlc.tar.gz"
mysqlcjar="/tmp/$mysqlcversion/$mysqlcversion-bin.jar"

wget -O /tmp/mysqlc.tar.gz $mysqlcdl
tar xzf $mysqlctar

# Install Jira
{
	ask "Install Atlassian Jira Latest?" N
	if [ $? -ne 1 ] ; then
		jirainstallpath="/opt/atlassian/jira/"
		echo "We need to create a database for Jira. Please enter one or copy this one?"
		randpw
		read -s -p "Enter Password: " jiradbpw
		echo "Creating database for Jira... Please wait"
		jiradbcreate="CREATE DATABASE jira CHARACTER SET utf8 COLLATE utf8_bin;"
		jiradbgrant="GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER,INDEX on jira.* TO 'jira'@'localhost' IDENTIFIED BY '$jiradbpw';"
		jirasql="$jiradbcreate $jiradbgrant $dbflush"
		mysql --defaults-file=/etc/mysql/debian.cnf -e "$jirasql"
		echo "Downloading and installing Jira. This will take a while."
		wget -O /tmp/jira_$jiraversion-$arch.bin $jiradl
		chmod +x /tmp/jira_$jiraversion-$arch.bin
		/tmp/jira_$jiraversion-$arch.bin
		cp $mysqlcjar $jirainstallpath/lib/
		echo "Now we must restart Jira. Please wait..."
		/etc/init.d/jira stop
		sleep 10
		/etc/init.d/jira start
		echo "Installation of Jira finished."
		echo "If you don't proceed with further installations please go to http://localhost:8080 and setup Jira."
		echo "For the database setup you can use the database and user name 'jira' and the password $jiradbpw"
		ask "Install another Atlassian product?" N
		if [ $? -ne 0 ] ; then
			echo "Thanks for using this script. Goodbye!"
		exit 0
		fi
	fi
}

echo "hello world"
