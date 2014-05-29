#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                           #
# Author: Rico Ullmann <git [<ät>] erinnerungsfragmente.de>                 #
# Website: erinnerungsfragmente.de                                          #
# Github: https://github.com/rullmann                                       #
#                                                                           #
# Version: 1.0 / Date: 23rd February 2014                                   #
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

echo -e "\nWelcome to the Atlassian Autoinstaller."

if [[ $EUID -ne 0 ]]; then
    echo "The Script hasn't been executed as root."
    echo "Please try again with sudo/as root user."
    exit 1
fi

echo -e "\nYou can install the following applications: \n
* Atlassian JIRA
* Atlassian Confluence
* Atlassian Bamboo
* Atlassian Stash
* Atlassian Fisheye & Crucible
* Atlassian Crowd \n"

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

# Let's generate passwords easily
function randpw { 
	(< /dev/urandom tr -dc '1234567890aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ!=-_#+' | head -c${1:-36};echo;)
}

# We must know which architecture to use
if [ `getconf LONG_BIT` = "64" ]
then
    arch="x64"
else
    arch="x32"
fi

# Some variables we need sooner or later
installjira='0'
installconfluence='0'
installbamboo='0'
installstash='0'
installfisheye='0'
installcrowd='0'
dbflush="flush privileges;"

# Get the ip address to print it later
ipaccess=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')

echo -e "The next steps will guide you through the setup of Atlassian products. If you're not going to enter 'Y' nothing will happen. \n
It's strongly recommended to read the README.md before proceeding! \n"
ask "Proceed?" N
if [ $? -ne 0 ] ; then
	echo "Goodbye!"
	exit 0
fi

# Check for the dependencies before we begin to install Atlassian products
echo ""
ask "MySQL server is going to be installed and configured. Are you fine with that?" N

if [ $? -ne 0 ] ; then
	echo "Without MySQL Server this script won't work. Goodbye!"
	exit 0
fi

echo ""
ask "Install Atlassian JIRA?" N

if [ $? -ne 1 ] ; then
	installjira='1'
	productjira="jira"
	choosejiraversion62="6.2.6, 6.2.5, 6.2.3, 6.2.1, 6.2,"
	choosejiraversion61="6.1.7, 6.1.6, 6.1.5, 6.1.4, 6.1.3, 6.1.2, 6.1.1, 6.1"
	choosejiraversion6="6.0.8, 6.0.7, 6.0.6, 6.0.5, 6.0.4, 6.0.3, 6.0.2, 6.0.1, 6.0"
	choosejiraversionold="5.2.11, 5.1.8, 5.0.7, 4.4.5"
	function askjiraversion {
    	while true; do
	       	if [ "${2:-}" = "Latest" ]; then
	           	prompt="Latest"
	           	default="Latest"
	       	fi
		        read -p "$1 [$prompt] " REPLYJIRA
	 
	        if [ -z "$REPLYJIRA" ]; then
	            REPLYJIRA=$default
	        fi
	 
	        case "$REPLYJIRA" in
				Latest) jiraversion="6.2.6" ; return 0 ;;
                6.2.6) jiraversion="6.2.6" ; return 0 ;;
                6.2.5) jiraversion="6.2.5" ; return 0 ;;
				6.2.3) jiraversion="6.2.3" ; return 0 ;;
				6.2.1) jiraversion="6.2.1" ; return 0 ;;
				6.2) jiraversion="6.2" ; return 0 ;;
				6.1.7) jiraversion="6.1.7" ; return 0 ;;
				6.1.6) jiraversion="6.1.6" ; return 0 ;;
				6.1.5) jiraversion="6.1.5" ; return 0 ;;
				6.1.4) jiraversion="6.1.4" ; return 0 ;;
				6.1.3) jiraversion="6.1.3" ; return 0 ;;
				6.1.2) jiraversion="6.1.2" ; return 0 ;;
				6.1.1) jiraversion="6.1.1" ; return 0 ;;
				6.1) jiraversion="6.1" ; return 0 ;;
				6.0.8) jiraversion="6.0.8" ; return 0 ;;
				6.0.7) jiraversion="6.0.7" ; return 0 ;;
				6.0.6) jiraversion="6.0.6" ; return 0 ;;
				6.0.5) jiraversion="6.0.5" ; return 0 ;;
				6.0.4) jiraversion="6.0.4" ; return 0 ;;
				6.0.3) jiraversion="6.0.3" ; return 0 ;;
				6.0.2) jiraversion="6.0.2" ; return 0 ;;
				6.0.1) jiraversion="6.0.1" ; return 0 ;;
				6.0) jiraversion="6.0" ; return 0 ;;
				5.2.11) jiraversion="5.2.11" ; return 0 ;;
				5.1.8) jiraversion="5.1.8" ; return 0 ;;
				5.0.7) jiraversion="5.0.7" ; return 0 ;;
				4.4.5) jiraversion="4.4.5" ; return 0 ;;
	        esac
    	done
	}
	echo -e "\nWhich version of JIRA would you like to install? \n\n    Available are: \n    $choosejiraversion62 \n    $choosejiraversion61 \n    $choosejiraversion6 \n    $choosejiraversionold \n"
	askjiraversion "Please choose now:" Latest
	dljira="https://downloads.atlassian.com/software/$productjira/downloads/atlassian-$productjira-$jiraversion-$arch.bin"
	echo -e "\nWe need to create a database for JIRA. Please enter one or copy this random generated password: \n"
	randpw
	read -s -p "Enter Password: " jiradbpw
	echo -e "\n\nWhich installation data path would you like to use?\n"
	read -p "Enter JIRA installation path: " -i /opt/jira -e jiralinkpath
	read -p "Enter JIRA data path: " -i /var/opt/jira -e jiradatapath
	echo ""
fi

ask "Install Atlassian Confluence?" N

if [ $? -ne 1 ] ; then
	installconfluence='1'
	productconfluence="confluence"
	chooseconfluenceversion55="5.5.1, 5.5.2, 5.5"	
	chooseconfluenceversion54="5.4.4, 5.4.3, 5.4.2, 5.4.1, 5.4"
	chooseconfluenceversion53="5.3.4, 5.3.1, 5.3"
	chooseconfluenceversion52="5.2.5, 5.2.3"
	chooseconfluenceversion51="5.1.5, 5.1.4, 5.1.3, 5.1.2, 5.1.1, 5.1"
	chooseconfluenceversion5="5.0.3, 5.0.2, 5.0.1, 5.0"
	chooseconfluenceversionold="4.3.7, 4.2.13, 4.1.9, 4.0.5"
	function askconfluenceversion {
    	while true; do
	       	if [ "${2:-}" = "Latest" ]; then
	           	prompt="Latest"
	           	default="Latest"
	       	fi
		        read -p "$1 [$prompt] " REPLYCONFLUENCE
	 
	        if [ -z "$REPLYCONFLUENCE" ]; then
	            REPLYCONFLUENCE=$default
	        fi
	 
	        case "$REPLYCONFLUENCE" in
				Latest) confluenceversion="5.5.2" ; return 0 ;;
                5.5.2) confluenceversion="5.5.2" ; return 0 ;;
                5.5.1) confluenceversion="5.5.1" ; return 0 ;;
				5.5) confluenceversion="5.5" ; return 0 ;;
				5.4.4) confluenceversion="5.4.4" ; return 0 ;;
				5.4.3) confluenceversion="5.4.3" ; return 0 ;;
				5.4.2) confluenceversion="5.4.2" ; return 0 ;;
				5.4.1) confluenceversion="5.4.1" ; return 0 ;;
				5.4) confluenceversion="5.4" ; return 0 ;;
				5.3.4) confluenceversion="5.3.4" ; return 0 ;;
				5.3.1) confluenceversion="5.3.1" ; return 0 ;;
				5.3) confluenceversion="5.3" ; return 0 ;;
				5.2.5) confluenceversion="5.2.5" ; return 0 ;;
				5.2.3) confluenceversion="5.2.3" ; return 0 ;;
				5.1.5) confluenceversion="5.1.5" ; return 0 ;;
				5.1.4) confluenceversion="5.1.4" ; return 0 ;;
				5.1.3) confluenceversion="5.1.3" ; return 0 ;;
				5.1.2) confluenceversion="5.1.2" ; return 0 ;;
				5.1.1) confluenceversion="5.1.1" ; return 0 ;;
				5.1) confluenceversion="5.1" ; return 0 ;;
				5.0.3) confluenceversion="5.0.3" ; return 0 ;;
				5.0.2) confluenceversion="5.0.2" ; return 0 ;;
				5.0.1) confluenceversion="5.0.1" ; return 0 ;;
				5.0) confluenceversion="5.0" ; return 0 ;;
				4.3.7) confluenceversion="4.3.7" ; return 0 ;;
	        esac
    	done
	}
	echo -e "\nWhich version of Confluence would you like to install? \n \n    Available are: \n    $chooseconfluenceversion55 \n    $chooseconfluenceversion54 \n    $chooseconfluenceversion53 \n    $chooseconfluenceversion52 \n    $chooseconfluenceversion51 \n    $chooseconfluenceversion5 \n    $chooseconfluenceversionold \n"
	askconfluenceversion "Please choose now:" Latest
	dlconfluence="https://downloads.atlassian.com/software/$productconfluence/downloads/atlassian-$productconfluence-$confluenceversion-$arch.bin"
	echo -e "\nWe need to create a database for Confluence. Please enter one or copy this random generated password: \n"
	randpw
	read -s -p "Enter Password: " confluencedbpw
	echo -e "\n\nWhich installation data path would you like to use?\n"
	read -p "Enter Confluence installation path: " -i /opt/confluence -e confluencelinkpath
	read -p "Enter Confluence data path: " -i /var/opt/confluence -e confluencedatapath
	echo ""
fi

echo -e "\nBefore selecting other Atlassian products for installation, please note that these require downloading and installing Oracle Java.
\nWhy? JIRA and Confluence are shipping with Java. The other applications are currently not. \n"

ask "Proceed selecting other Atlassian products for download and therefore install Oracle Java too?" N

if [ $? -ne 1 ] ; then
	installjava='1'
	if [ $arch == x32 ] ; then
		jdkarch="i586"
	else
		jdkarch="x64"
	fi
	echo ""
	ask "Install Atlassian Bamboo?" N

	if [ $? -ne 1 ] ; then
		installbamboo='1'
		productbamboo="bamboo"
		choosebambooversion55="5.5"
		choosebambooversion54="5.4.2, 5.4.1, 5.4"
		choosebambooversion53="5.3"
		choosebambooversion52="5.2.2, 5.2.1, 5.2"
		choosebambooversion51="5.1.1, 5.1.0"
		choosebambooversion5="5.0.1, 5.0"
		choosebambooversionold="4.4.8, 4.3.4, 4.2.2, 4.1.2, 4.0.1, 3.4.5, 3.3.4"
		function askbambooversion {
    		while true; do
	        	if [ "${2:-}" = "Latest" ]; then
	            	prompt="Latest"
	            	default="Latest"
	        	fi

		        read -p "$1 [$prompt] " REPLYBAMBOO
		 
		        if [ -z "$REPLYBAMBOO" ]; then
		            REPLYBAMBOO=$default
		        fi
		 
		        case "$REPLYBAMBOO" in
					Latest) bambooversion="5.5" ; return 0 ;;
					5.5) bambooversion="5.5" ; return 0 ;;
					5.4.2) bambooversion="5.4.2" ; return 0 ;;
					5.4.1) bambooversion="5.4.1" ; return 0 ;;
					5.4) bambooversion="5.4" ; return 0 ;;
					5.3) bambooversion="5.3" ; return 0 ;;
					5.2.2) bambooversion="5.2.2" ; return 0 ;;
					5.2) bambooversion="5.2" ; return 0 ;;
					5.1.1) bambooversion="5.1.1" ; return 0 ;;
					5.1.0) bambooversion="5.1.0" ; return 0 ;;
					5.0.1) bambooversion="5.0.1" ; return 0 ;;
					5.0) bambooversion="5.0" ; return 0 ;;
					4.4.8) bambooversion="4.4.8" ; return 0 ;;
					4.3.4) bambooversion="4.3.4" ; return 0 ;;
					4.2.2) bambooversion="4.2.2" ; return 0 ;;
					4.1.2) bambooversion="4.1.2" ; return 0 ;;
					4.0.1) bambooversion="4.0.1" ; return 0 ;;
					3.4.5) bambooversion="3.4.5" ; return 0 ;;
					3.3.4) bambooversion="3.3.4" ; return 0 ;;
		        esac
	    	done
		}
		echo -e "\nWhich version of Bamboo would you like to install? \n \n    Available are: \n    $choosebambooversion55 \n    $choosebambooversion54 \n    $choosebambooversion53 \n    $choosebambooversion52 \n    $choosebambooversion51 \n    $choosebambooversion5 \n    $choosebambooversionold \n"
		askbambooversion "Please choose now:" Latest
		dlbamboo="https://downloads.atlassian.com/software/$productbamboo/downloads/atlassian-$productbamboo-$bambooversion.tar.gz"
		echo -e "\nWe need to create a database for Bamboo. Please enter one or copy this random generated password: \n"
		randpw
		read -s -p "Enter Password: " bamboodbpw
		echo -e "\n\nWhich installation data path would you like to use?\nPlease note that a 'bamboo' folder will be created in there."
		read -p "Enter Bamboo base path: " -i /opt -e bamboobasepath
		bamboolinkpath="$bamboobasepath/$productbamboo"
		read -p "Enter Bamboo base data path: " -i /var/opt -e bamboodatapath
		bamboohome="$bamboodatapath/bamboo-home"
		echo ""
	fi

	ask "Install Atlassian Stash?" N

	if [ $? -ne 1 ] ; then
	installstash='1'
	ask "Stash requires perl and git. We must install both. Do you want to proceed?" N
		if [ $? -ne 1 ] ; then
			installdepsstash () {
				DEPS=(git perl)
				export DEBIAN_FRONTEND=noninteractive
			    aptitude install -q -y ${DEPS[*]}
			}
			productstash="stash"
			choosestashversion212="2.12.2"
			choosestashversion211="2.11.5, 2.11.4, 2.11.3"
			choosestashversion210="2.10.3, 2.10.2, 2.10.9, 2.10.0"
			choosestashversion29="2.9.5, 2.9.4, 2.9.3, 2.9.2, 2.9.1"
			choosestashversionold="2.8.4, 2.7.6, 2.6.5, 2.5.4, 2.4.2, 2.3.1, 2.2.0, 2.1.2"
			function askstashversion {
	    		while true; do
		        	if [ "${2:-}" = "Latest" ]; then
		            	prompt="Latest"
		            	default="Latest"
		        	fi

			        read -p "$1 [$prompt] " REPLYSTASH
			 
			        if [ -z "$REPLYSTASH" ]; then
			            REPLYSTASH=$default
			        fi
			 
			        case "$REPLYSTASH" in
						Latest) stashversion="2.12.2" ; return 0 ;;
						2.12.2) stashversion="2.12.2" ; return 0 ;;
						2.11.5) stashversion="2.11.5" ; return 0 ;;
						2.11.4) stashversion="2.11.4" ; return 0 ;;
						2.11.3) stashversion="2.11.3" ; return 0 ;;
						2.10.3) stashversion="2.10.3" ; return 0 ;;
						2.10.2) stashversion="2.10.2" ; return 0 ;;
						2.9.5) stashversion="2.9.5" ; return 0 ;;
						2.9.4) stashversion="2.9.4" ; return 0 ;;
						2.9.3) stashversion="2.9.3" ; return 0 ;;
						2.9.2) stashversion="2.9.2" ; return 0 ;;
						2.9.1) stashversion="2.9.1" ; return 0 ;;
						2.8.4) stashversion="2.8.4" ; return 0 ;;
						2.7.6) stashversion="2.7.6" ; return 0 ;;
						2.6.5) stashversion="2.6.5" ; return 0 ;;
						2.5.4) stashversion="2.5.4" ; return 0 ;;
						2.4.2) stashversion="2.4.2" ; return 0 ;;
						2.3.1) stashversion="2.3.1" ; return 0 ;;
						2.2.0) stashversion="2.2.0" ; return 0 ;;
						2.1.2) stashversion="2.1.2" ; return 0 ;;
			        esac
		    	done
			}
			echo -e "\nWhich version of Stash would you like to install? \n \n    Available are: \n    $choosestashversion212 \n    $choosestashversion211 \n    $choosestashversion210 \n    $choosestashversion29 \n    $choosestashversionold \n"
			askstashversion "Please choose now:" Latest
			dlstash="https://downloads.atlassian.com/software/$productstash/downloads/atlassian-$productstash-$stashversion.tar.gz"
			echo -e "\nWe need to create a database for Stash. Please enter one or copy this random generated password: \n"
			randpw
			read -s -p "Enter Password: " stashdbpw
			echo -e "\n\nWhich installation data path would you like to use?\nPlease note that a 'stash' folder will be created in there."
			read -p "Enter Stash base path: " -i /opt -e stashbasepath
			stashlinkpath="$stashbasepath/$productstash"
			read -p "Enter Stash base data path: " -i /var/opt -e stashdatapath
			stashhome="$stashdatapath/stash-home"
			echo ""
		else
			installstash=0
			echo -e "Stash is not going to be installed as it won't work without git and perl! \n"
		fi
	fi

	ask "Install Atlassian Fisheye & Crucible?" N

	if [ $? -ne 1 ] ; then
		installfisheye='1'
		productfisheye="fisheye"
		choosefisheyeversion3="3.4, 3.3.2, 3.3.1, 3.3.0, 3.2.4, 3.1.6, 3.0.3"
		choosefisheyeversionold="2.10.8, 2.9.2, 2.8.2, 2.7.15, 2.6.9, 2.5.9"
		function askfisheyeversion {
    		while true; do
	        	if [ "${2:-}" = "Latest" ]; then
	            	prompt="Latest"
	            	default="Latest"
	        	fi

		        read -p "$1 [$prompt] " REPLYFISHEYE
		 
		        if [ -z "$REPLYFISHEYE" ]; then
		            REPLYFISHEYE=$default
		        fi
		 
		        case "$REPLYFISHEYE" in
					Latest) fisheyeversion="3.4" ; return 0 ;;
					3.4) fisheyeversion="3.4" ; return 0 ;;
					3.3.1) fisheyeversion="3.3.2" ; return 0 ;;
					3.3.1) fisheyeversion="3.3.1" ; return 0 ;;
					3.3.0) fisheyeversion="3.3.0" ; return 0 ;;
					3.2.4) fisheyeversion="3.2.4" ; return 0 ;;
					3.1.6) fisheyeversion="3.1.6" ; return 0 ;;
					3.0.3) fisheyeversion="3.0.3" ; return 0 ;;
					2.10.8) fisheyeversion="2.10.8" ; return 0 ;;
					2.9.2) fisheyeversion="2.9.2" ; return 0 ;;
					2.8.2) fisheyeversion="2.8.2" ; return 0 ;;
					2.7.15) fisheyeversion="2.7.15" ; return 0 ;;
					2.6.9) fisheyeversion="2.6.9" ; return 0 ;;
					2.5.9) fisheyeversion="2.5.9" ; return 0 ;;
		        esac
	    	done
		}
		echo -e "\nWhich version of Fisheye would you like to install? \n \n    Available are: \n    $choosefisheyeversion3 \n    $choosefisheyeversionold \n"
		askfisheyeversion "Please choose now:" Latest
		dlfisheye="https://downloads.atlassian.com/software/$productfisheye/downloads/$productfisheye-$fisheyeversion.zip"
		echo -e "\nWe need to create a database for Fisheye. Please enter one or copy this random generated password: \n"
		randpw
		read -s -p "Enter Password: " fisheyedbpw
		echo -e "\n\nWhich installation data path would you like to use?\nPlease note that a 'fisheye' folder will be created in there."
		read -p "Enter Fisheye base path: " -i /opt -e fisheyebasepath
		fisheyelinkpath="$fisheyebasepath/$productfisheye"
		read -p "Enter Fisheye base data path: " -i /var/opt -e fisheyedatapath
		fisheyehome="$fisheyedatapath/fisheye-home"
		echo ""
	fi

	ask "Install Atlassian Crowd?" N

	if [ $? -ne 1 ] ; then
		installcrowd='1'
		productcrowd="crowd"
		choosecrowdversion27="2.7.1, 2.7.0"
		choosecrowdversionold="2.6.5, 2.6.4, 2.5.5, 2.4.10, 2.3.9, 2.2.9, 2.0.9"
		function askcrowdversion {
    		while true; do
	        	if [ "${2:-}" = "Latest" ]; then
	            	prompt="Latest"
	            	default="Latest"
	        	fi

		        read -p "$1 [$prompt] " REPLYCROWD
		 
		        if [ -z "$REPLYCROWD" ]; then
		            REPLYCROWD=$default
		        fi
		 
		        case "$REPLYCROWD" in
					Latest) crowdversion="2.7.1" ; return 0 ;;
					2.7.1) crowdversion="2.7.1" ; return 0 ;;
					2.7.0) crowdversion="2.7.0" ; return 0 ;;
					2.6.5) crowdversion="2.6.5" ; return 0 ;;
					2.6.4) crowdversion="2.6.4" ; return 0 ;;
					2.5.5) crowdversion="2.5.5" ; return 0 ;;
					2.4.10) crowdversion="2.4.10" ; return 0 ;;
					2.3.9) crowdversion="2.3.9" ; return 0 ;;
					2.2.9) crowdversion="2.2.9" ; return 0 ;;
					2.0.9) crowdversion="2.0.9" ; return 0 ;;
		        esac
	    	done
		}
		echo -e "\nWhich version of Crowd would you like to install? \n \n    Available are: \n    $choosecrowdversion27 \n    $choosecrowdversionold \n"
		askcrowdversion "Please choose now:" Latest
		dlcrowd="https://downloads.atlassian.com/software/$productcrowd/downloads/atlassian-$productcrowd-$crowdversion.tar.gz"
		echo -e "\nWe need to create a database for Crowd. Please enter one or copy this random generated password: \n"
		randpw
		read -s -p "Enter Password: " crowddbpw
		echo -e "\n\nWhich installation data path would you like to use?\nPlease note that a 'crowd' folder will be created in there."
		read -p "Enter Crowd base path: " -i /opt -e crowdbasepath
		crowdlinkpath="$crowdbasepath/$productcrowd"
		read -p "Enter Crowd base data path: " -i /var/opt -e crowddatapath
		crowdhome="$crowddatapath/crowd-home"
		echo ""
	fi
fi

echo -e "\n# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                           #
# Now that you've choosen the Atlassian products you would like to install  #
# it's time for a deep breath, checking the selections you've made and      #
# then choosing to proceed with the installation of MySQL Server,           #
# (in case you've choosen other products than JIRA and Confluence) and      #
# the products.                                                             #
#                                                                           #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #\n
The followings products will be installed: \n"

if [ $installjira -ne 0 ] ; then
	echo -e "* JIRA $jiraversion\n    Installation path: $jiralinkpath\n    Data path: $jiradatapath\n"
fi
if [ $installconfluence -ne 0 ] ; then
	echo -e "* Confluence $confluenceversion\n    Installation path: $confluencelinkpath\n    Data path: $confluencedatapath\n"
fi
if [ $installbamboo -ne 0 ] ; then
	echo -e "* Bamboo $bambooversion\n    Installation path: $bamboolinkpath\n    Data path: $bamboohome\n"
fi
if [ $installstash -ne 0 ] ; then
	echo -e "* Stash $stashversion\n    Installation path: $stashlinkpath\n    Data path: $stashhome\n"
fi
if [ $installfisheye -ne 0 ] ; then
	echo -e "* Fisheye & Crucible $fisheyeversion\n    Installation path: $fisheyelinkpath\n    Data path: $fisheyehome\n"
fi
if [ $installcrowd -ne 0 ] ; then
	echo -e "* Crowd $crowdversion\n    Installation path: $crowdlinkpath\n    Data path: $crowdhome\n"
fi
echo""

ask "Proceed with installation?" Y

if [ $? -ne 0 ] ; then
	echo "Goodbye!"
	exit 0
fi

# install mysql-server with configuration file and download mysql-java-connector
echo ""
installdeps () {
	DEPS=(mysql-server mysql-client unzip)
	export DEBIAN_FRONTEND=noninteractive
    aptitude update && aptitude install -q -y ${DEPS[*]}
}

installdeps

if [ -f /etc/mysql/conf.d/atlassian.cnf ] ; then
	echo "Atlassian optimized MySQL config is already installed. Nothing to do."
else
	cat <<'EOF' > /etc/mysql/conf.d/atlassian.cnf
[mysqld]
#################
# General settings
#################

# Number of concurrent connections to MySQL
max_connections = 400
# The number of open tables for all threads. Increasing this value increases the number of file descriptors that mysqld requires.
# You can check whether you need to increase the table cache by checking the Opened_tables status variable (SHOW GLOBAL STATUS LIKE 'Opened_tables';). 
# If it's very large, your table_cache or rather table_open_cache is to small
#table_open_cache = 1024
# Allow large packages, e.g. if your application stores some binary data as BLOBs
max_allowed_packet = 64M
# Isolation Level, as of Confluence 3.5
# READ-COMMITTED is mandatory
transaction-isolation = READ-COMMITTED
# Row based binary logging
# Enable this for MariaDB
# binlog_format = row 

# All tables shall be lower case
lower_case_table_names = 1

#################
# Character Encoding
#################

character-set-server = utf8
collation-server = utf8_bin
#################
# InnoDB settings
#################
# One file for each table
# You want this setting because cannot shrink already grown innodb files
# That is, if you delete a database or table, you can also simply delete the corresponding
# ibdata-files to regain disk space
innodb_file_per_table = 1
# Memory pool InnoDB uses to store data dictionary information and other internal structures
innodb_additional_mem_pool_size = 8M
# Set this value to a minimum of 25 % of your available RAM, and a maximum of roughly 80% if your
# machine hosts only MySQL
# In general, to not set this value so high that the OS starts swapping/paging
innodb_buffer_pool_size = 256M
# This value should be half of the innodb_buffer_pool_size
# Please delete all innodb logfiles (iblogfile*), otherwise MySQL will fail to start
innodb_log_file_size = 128M
# Cache size for transaction logging
innodb_log_buffer_size = 8M
# If you can afford data loss in a crash and want more speed, set to 0, otherwise leave as is
innodb_flush_log_at_trx_commit = 1
innodb_support_xa = 1
# ONLY FOR UNIX/Linux
#
# fdatasync is the default, but can only be 'set' by leaving this parameter unset as of version 5.1.24
#
# Most Unix/Linux systems are fastest with the default, however some systems perform better with O_DIRECT
# or O_DSYNC.
#
# Do NOT use O_DIRECT if you innodb files are located on a SAN
#
# Take your time and benchmark your MySQL with O_DSYNC and O_DIRECT
#innodb_flush_method = O_DIRECT
# ONLY FOR WINDOWS
# Increase the number of threads for IO operations
#innodb_file_io_threads = 6
[mysqldump]
max_allowed_packet = 64M
[mysqlclient]
max_allowed_packet = 64M
EOF
fi

/etc/init.d/mysql stop
rm /var/lib/mysql/ib_logfile*
/etc/init.d/mysql start

mysqlcversion="mysql-connector-java-5.1.29"
mysqlcdl="https://dev.mysql.com/get/Downloads/Connector-J/$mysqlcversion.tar.gz"
mysqlctar="/tmp/mysqlc.tar.gz"
mysqlcjar="/tmp/$mysqlcversion/$mysqlcversion-bin.jar"

wget -O /tmp/mysqlc.tar.gz $mysqlcdl
tar xzf $mysqlctar

if [ $installjira -ne 0 ] ; then
	# Create the response.varfile for unattended installation
	cat <<EOF > /tmp/$productjira-$jiraversion-$arch.unattended
#install4j response file for JIRA $jiraversion
#Sat Feb 22 11:34:12 CET 2014
rmiPort$Long=8005
app.jiraHome=$jiradatapath
app.install.service$Boolean=true
existingInstallationDir=/usr/local/JIRA
sys.confirmedUpdateInstallationString=false
sys.languageId=en
sys.installationDir=$jiralinkpath
httpPort$Long=8080
portChoice=default
EOF
	echo -e "Creating database for JIRA... \n"
	jiradbcreate="CREATE DATABASE $productjira CHARACTER SET utf8 COLLATE utf8_bin;"
	jiradbgrant="GRANT ALL on $productjira.* TO '$productjira'@'localhost' IDENTIFIED BY '$jiradbpw';"
	jirasql="$jiradbcreate $jiradbgrant $dbflush"
	mysql --defaults-file=/etc/mysql/debian.cnf -e "$jirasql"
	echo -e "Downloading and installing JIRA. This will take a while. \nAfter the download finished you can go through the setup by pressing enter. \nThe standard settings are fine."
	wget -O /tmp/$productjira-$jiraversion-$arch.bin $dljira
	chmod +x /tmp/$productjira-$jiraversion-$arch.bin
	/tmp/$productjira-$jiraversion-$arch.bin -q -varfile /tmp/$productjira-$jiraversion-$arch.unattended
	cp $mysqlcjar $jiralinkpath/lib/
	if [ -f /etc/init.d/$productjira ] ; then
		echo "JIRA init Script already installed. Nothing to do."
	else
		cat <<EOF > /etc/init.d/$productjira
#!/bin/bash

# JIRA Linux service controller script
cd "$jiralinkpath/bin"
EOF
		cat <<'EOF' >> /etc/init.d/$productjira

case "$1" in
    start)
        ./start-jira.sh
        ;;
    stop)
        ./stop-jira.sh
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac
EOF
	chmod +x /etc/init.d/$productjira
	fi
	echo -e "Now we must restart JIRA. Please wait...\n"
	sleep 10
	/etc/init.d/$productjira stop
	sleep 5
	/etc/init.d/$productjira start
	echo -e "\nInstallation of JIRA finished.\n"
fi

if [ $installconfluence -ne 0 ] ; then
	# Create the response.varfile for unattended installation
	cat <<EOF > /tmp/$productconfluence-$confluenceversion-$arch.unattended
#install4j response file for Confluence $confluenceversion
#Sat Feb 22 11:52:10 CET 2014
rmiPort$Long=8000
app.install.service$Boolean=true
existingInstallationDir=/opt/Confluence
sys.confirmedUpdateInstallationString=false
sys.languageId=en
sys.installationDir=$confluencelinkpath
app.confHome=$confluencedatapath
httpPort$Long=8090
portChoice=default
EOF
	confluencedbbcreate="CREATE DATABASE $productconfluence CHARACTER SET utf8 COLLATE utf8_bin;"
	confluencedbgrant="GRANT ALL on $productconfluence.* TO '$productconfluence'@'localhost' IDENTIFIED BY '$confluencedbpw';"
	confluencesql="$confluencedbbcreate $confluencedbgrant $dbflush"
	mysql --defaults-file=/etc/mysql/debian.cnf -e "$confluencesql"
	echo -e "Downloading and installing Confluence. This will take a while. \nAfter the download finished you can go through the setup by pressing enter. \nThe standard settings are fine. \n"
	wget -O /tmp/$productconfluence-$confluenceversion-$arch.bin $dlconfluence
	chmod +x /tmp/$productconfluence-$confluenceversion-$arch.bin
	/tmp/$productconfluence-$confluenceversion-$arch.bin -q -varfile /tmp/$productconfluence-$confluenceversion-$arch.unattended
	cp $mysqlcjar $confluencelinkpath/lib/
	if [ -f /etc/init.d/$productconfluence ] ; then
		echo "Confluence init Script already installed. Nothing to do."
	else
		cat <<EOF > /etc/init.d/$productconfluence
#!/bin/bash

# Confluence Linux service controller script
cd "$confluencelinkpath/bin"
EOF
		cat <<'EOF' >> /etc/init.d/$productconfluence

case "$1" in
    start)
        ./start-confluence.sh
        ;;
    stop)
        ./stop-confluence.sh
        ;;
    restart)
        ./stop-confluence.sh
        ./start-confluence.sh
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
        ;;
esac
EOF
	chmod +x /etc/init.d/$productconfluence
	fi
	echo -e "Now we must restart Confluence. Please wait...\n"
	sleep 10
	/etc/init.d/$productconfluence stop
	sleep 5
	/etc/init.d/$productconfluence start
	echo -e "\nInstallation of Confluence finished. \n"
fi

if [ "$installbamboo" == "1" ] || [ "$installstash" == "1" ] || [ "$installfisheye" == "1" ] || [ "$installcrowd" == "1" ] ; then
	echo -e "Installing Java... \n"
	jdkversion="jdk-7u51-linux"
	jdkunpack="jdk1.7.0_51"
	wget -O /tmp/java_jdk.tar.gz --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com" "http://download.oracle.com/otn-pub/java/jdk/7u51-b13/$jdkversion-$jdkarch.tar.gz"
	echo "Unpacking Java and moving to /opt/"
	tar xzf /tmp/java_jdk.tar.gz
	mv /tmp/$jdkunpack /opt
	chown -R root: /opt/$jdkunpack
	echo "Linking new Java to /opt/java_current"
	if [ -d /opt/java_current ] ; then
		rm  /opt/java_current
	fi
	ln -s /opt/$jdkunpack /opt/java_current
	echo -e "Setting up JAVA_HOME in /etc/environment if it doesn't exist. Hold on!\n"
	grep JAVA_HOME="/opt/java_current" /etc/environment
	if [ $? -eq 1 ]; then
		echo JAVA_HOME="/opt/java_current" >> /etc/environment
	fi
fi

if [ $installbamboo -ne 0 ] ; then
	echo -e "Creating database for Bamboo... \n"
	bamboodbcreate="CREATE DATABASE $productbamboo CHARACTER SET utf8 COLLATE utf8_bin;"
	bamboodbgrant="GRANT ALL on $productbamboo.* TO '$productbamboo'@'localhost' IDENTIFIED BY '$bamboodbpw';"
	bamboosql="$bamboodbcreate $bamboodbgrant $dbflush"
	mysql --defaults-file=/etc/mysql/debian.cnf -e "$bamboosql"
	echo -e "Downloading and installing Bamboo. This will take a while. \nAs no setup is currently provided we'll do some magic to get it running. \nLet's download Bamboo:"
	wget -O /tmp/$productbamboo-$bambooversion.tar.gz $dlbamboo
	echo "Unpack it..."
	tar xzf /tmp/$productbamboo-$bambooversion.tar.gz
	echo "Move it to $bamboobasepath"
	mkdir $bamboobasepath
	mv /tmp/atlassian-$productbamboo-$bambooversion $bamboobasepath
	echo "Link it to $bamboolinkpath ..."
	if [ -d $bamboolinkpath ]; then
		rm  $bamboolinkpath
	fi
	ln -s $bamboobasepath/atlassian-$productbamboo-$bambooversion $bamboolinkpath
	cp $mysqlcjar $bamboolinkpath/lib/
	echo "Create a home directory, set up rights and tell Bamboo where to find it..."
	echo bamboo.home=$bamboohome >> $bamboolinkpath/atlassian-bamboo/WEB-INF/classes/bamboo-init.properties
	mkdir $bamboodatapath
	mkdir $bamboohome
	useradd --create-home -c "Bamboo role account" bamboo
	chown -R bamboo: $bamboolinkpath
	chown -R bamboo: $bamboobasepath/atlassian-$productbamboo-$bambooversion
	chown -R bamboo: $bamboohome
	cat <<EOF > /etc/init.d/$productbamboo
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
BASE=$bamboolinkpath
# Location of Java JDK
export JAVA_HOME=/opt/java_current
EOF
	cat <<'EOF' >> /etc/init.d/$productbamboo
 
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
	chmod +x /etc/init.d/$productbamboo
	echo "And in the end add Bamboo as service which should start with the system..."
	update-rc.d $productbamboo defaults
	echo "Let's start Bamboo!"
	/etc/init.d/$productbamboo start
	echo -e "\nInstallation of Bamboo finished. \n"
fi

if [ $installstash -ne 0 ] ; then
		echo "Installing Stash dependencies..."
		installdepsstash
		echo -e "Creating database for Stash... \n"
		stashdbcreate="CREATE DATABASE $productstash CHARACTER SET utf8 COLLATE utf8_bin;"
		stashdbgrant="GRANT ALL on $productstash.* TO '$productstash'@'localhost' IDENTIFIED BY '$stashdbpw';"
		stashsql="$stashdbcreate $stashdbgrant $dbflush"
		mysql --defaults-file=/etc/mysql/debian.cnf -e "$stashsql"
		echo -e "\nDownloading and installing Stash. This will take a while. \nAs no setup is currently provided we'll do some magic to get it running. \nLet's download Stash: \n"
		wget -O /tmp/$productstash-$stashversion.tar.gz $dlstash
		echo "Unpack it..."
		tar xzf /tmp/$productstash-$stashversion.tar.gz
		echo "Move it to $stashbasepath"
		mkdir $stashbasepath
		mv /tmp/atlassian-$productstash-$stashversion $stashbasepath
		echo "Link it to $stashbasepath/stash ..."
		if [ -d $stashlinkpath ]; then
			rm  $stashlinkpath
		fi
		ln -s $stashbasepath/atlassian-$productstash-$stashversion $stashlinkpath
		cp $mysqlcjar $stashlinkpath/lib/
		echo "Create a home directory, set up rights and tell Stash where to find it..."
		echo STASH_HOME="$stashhome" >> $stashlinkpath/bin/setenv.sh
		mkdir $stashdatapath
		mkdir $stashhome
		useradd --create-home -c "Stash role account" stash
		chown -R stash: $stashlinkpath
		chown -R stash: $stashbasepath/atlassian-$productstash-$stashversion
		chown -R stash: $stashhome
		cat <<EOF > /etc/init.d/$productstash
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
STASH_INSTALLDIR="$stashlinkpath"
# STASH_HOME: Path to the Stash home directory
STASH_HOME="$stashhome"
EOF
		cat <<'EOF' >> /etc/init.d/$productstash
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
		chmod +x /etc/init.d/$productstash
		echo "And in the end add Stash as service which should start with the system..."
		update-rc.d $productstash defaults
		echo "Let's start Stash!"
		/etc/init.d/$productstash start
		echo -e "\nInstallation of Stash finished. \n"
fi

if [ $installfisheye -ne 0 ] ; then
		echo -e "Creating database for Fisheye... \n"
		fisheyedbcreate="CREATE DATABASE $productfisheye CHARACTER SET utf8 COLLATE utf8_bin;"
		fisheyedbgrant="GRANT ALL on $productfisheye.* TO '$productfisheye'@'localhost' IDENTIFIED BY '$fisheyedbpw';"
		fisheyesql="$fisheyedbcreate $fisheyedbgrant $dbflush"
		mysql --defaults-file=/etc/mysql/debian.cnf -e "$fisheyesql"
		echo -e "Downloading and installing Fisheye. This will take a while. \nAs no setup is currently provided we'll do some magic to get it running. \nLet's download Fisheye:"
		wget -O /tmp/$productfisheye-$fisheyeversion.zip $dlfisheye
		echo "Unpack it..."
		unzip /tmp/$productfisheye-$fisheyeversion.zip -d /tmp/
		echo "Move it to $fisheyelinkpath"
		mkdir $fisheyebasepath
		mv /tmp/fecru-$fisheyeversion $fisheyebasepath
		echo "Link it to $fisheyelinkpath ..."
		if [ -d $fisheyelinkpath ]; then
			rm  $fisheyelinkpath
		fi
		ln -s $fisheyebasepath/fecru-$fisheyeversion $fisheyelinkpath
		cp $mysqlcjar $fisheyelinkpath/lib/
		echo "Create a home directory, set up rights and tell Fisheye where to find it..."
		grep FISHEYE_INST="$fisheyehome" /etc/environment
		if [ $? -eq 1 ]; then
			echo FISHEYE_INST="$fisheyehome" >> /etc/environment
		fi
		mkdir $fisheyedatapath
		mkdir $fisheyehome
		cp $fisheyelinkpath/config.xml $fisheyehome
		useradd --create-home -c "Fisheye role account" fisheye
		chown -R fisheye: $fisheyelinkpath
		chown -R fisheye: $fisheyebasepath/fecru-$fisheyeversion
		chown -R fisheye: $fisheyehome
		cat <<EOF > /etc/init.d/$productfisheye
#!/bin/bash
# Fisheye startup script
# chkconfig: 345 90 90
# description: Atlassian FishEye
# original found at: http://jarrod.spiga.id.au/?p=35

FISHEYE_USER=fisheye
FISHEYE_HOME=$fisheyebasepath/$productfisheye/bin
EOF
		cat <<'EOF' >> /etc/init.d/$productfisheye
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
		chmod +x /etc/init.d/$productfisheye
		echo "And in the end add Fisheye as service which should start with the system..."
		update-rc.d $productfisheye defaults
		echo "Let's start Fisheye!"
		/etc/init.d/$productfisheye start
		echo -e "\nInstallation of Fisheye finished."
fi

if [ $installcrowd -ne 0 ] ; then
		echo -e "Creating database for Crowd... \n"
		crowddbcreate="CREATE DATABASE $productcrowd CHARACTER SET utf8 COLLATE utf8_bin;"
		crowddbgrant="GRANT ALL on $productcrowd.* TO '$productcrowd'@'localhost' IDENTIFIED BY '$crowddbpw';"
		crowdsql="$crowddbcreate $crowddbgrant $dbflush"
		mysql --defaults-file=/etc/mysql/debian.cnf -e "$crowdsql"
		echo -e "\nDownloading and installing Crowd. This will take a while. \nAs no setup is currently provided we'll do some magic to get it running. \nLet's download Crowd: \n"
		wget -O /tmp/$productcrowd-$crowdversion.tar.gz $dlcrowd
		echo "Unpack it..."
		tar xzf /tmp/$productcrowd-$crowdversion.tar.gz
		echo "Move it to $crowdlinkpath"
		mkdir $crowdbasepath
		mv /tmp/atlassian-$productcrowd-$crowdversion $crowdbasepath
		echo "Link it to $crowdlinkpath ..."
		if [ -d $crowdlinkpath ]; then
			rm  $crowdlinkpath
		fi
		ln -s $crowdbasepath/atlassian-$productcrowd-$crowdversion $crowdlinkpath
		cp $mysqlcjar $crowdlinkpath/apache-tomcat/lib/
		echo "Create a home directory, set up rights and tell Crowd where to find it..."
		echo crowd.home=$crowdhome >> $crowdlinkpath/crowd-webapp/WEB-INF/classes/crowd-init.properties
		mkdir $crowddatapath
		mkdir $crowdhome
		useradd --create-home -c "Crowd role account" crowd
		chown -R crowd: $crowdlinkpath
		chown -R crowd: $crowdbasepath/atlassian-$productcrowd-$crowdversion
		chown -R crowd: $crowdhome
		cat <<EOF > /etc/init.d/$productcrowd
#!/bin/bash
# Crowd startup script
#chkconfig: 2345 80 05
#description: Crowd
 
 
# Based on script at http://www.bifrost.org/problems.html
 
RUN_AS_USER=crowd
CATALINA_HOME=$crowdbasepath/$productcrowd/apache-tomcat
EOF
		cat <<'EOF' >> /etc/init.d/$productcrowd
 
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
		chmod +x /etc/init.d/$productcrowd
		echo "And in the end add Crowd as service which should start with the system..."
		update-rc.d $productcrowd defaults
		echo "Let's start Crowd!"
		/etc/init.d/$productcrowd start
		echo -e "\nInstallation of Crowd finished. \n"
fi

echo "Install of all selected Atlassian products finished."

ask "Last step before printing the connection details is to secure your MySQL Server installation. Proceed?" Y

if [ $? -ne 0 ] ; then
	echo -e "Please secure your MySQL Server later by executing 'mysql_secure_installation'.\n"
else
	mysql_secure_installation	
fi

# Print all URLs, database settings and passwords

if [ $installjira -ne 0 ] ; then
echo -e "JIRA detailed information:
Access URL: http://${ipaccess[0]}:8080
Database Name: $productjira
Database Username: $productjira
Database Password: $jiradbpw
Install path: $jiralinkpath
Data path: $jiradatapath\n"
fi
if [ $installconfluence -ne 0 ] ; then
echo -e "Confluence detailed information:
Access URL: http://${ipaccess[0]}:8090
Database Name: $productconfluence
Database Username: $productconfluence
Database Password: $confluencedbpw
Install path: $confluencelinkpath
Data path: $confluencedatapath\n"
fi
if [ $installbamboo -ne 0 ] ; then
echo -e "Bamboo detailed information:
Access URL: http://${ipaccess[0]}:8085
Database Name: $productbamboo
Database Username: $productbamboo
Database Password: $bamboodbpw
Install path: $bamboolinkpath
Data path: $bamboohome\n"
fi
if [ $installstash -ne 0 ] ; then
echo -e "Stash detailed information:
Access URL: http://${ipaccess[0]}:7990
Database Name: $productstash
Database Username: $productstash
Database Password: $stashdbpw
Install path: $stashlinkpath
Data path: $stashhome\n"
fi
if [ $installfisheye -ne 0 ] ; then
echo -e "Fisheye & Crucible detailed information:
Access URL: http://${ipaccess[0]}:8060
Database Name: $productfisheye
Database Username: $productfisheye
Database Password: $fisheyedbpw
Install path: $fisheyelinkpath
Data path: $fisheyehome\n"
fi
if [ $installcrowd -ne 0 ] ; then
echo -e "Crowd detailed information:
Access URL: http://${ipaccess[0]}:8095
Database Name: $productcrowd
Database Username: $productcrowd
Database Password: $crowddbpw
Install path: $crowdlinkpath
Data path: $crowdhome\n"
fi

echo -e "\nThank you for using the Autoinstaller for Atlassian products. Goodbye!"
