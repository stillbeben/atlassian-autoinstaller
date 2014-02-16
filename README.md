atlassian-autoinstaller
=======================

Automatic installation of Atlassian products and requirements

Legal note
----------

This script automates the process of setting up Atlassian (https://www.atlassian.com) products for testing purposes. E.g. trying out a new version of a product before upgrading.
This script hasn't been developed by Atlassian nor is it the intention to break any copyright or trademark by Atlassian.

Additionally the MySQL Connector/J is being downloaded. Please read the license on the Connector/J website:
https://dev.mysql.com/downloads/connector/j/

Supported products
------------------

* Atlassian JIRA
* Atlassian Confluence
* Atlassian Bamboo
* Atlassian Stash
* Atlassian Fisheye & Crucible
* Atlassian Crowd

How to use
----------

Simply download this script to an Ubuntu 12.04 (http://releases.ubuntu.com/12.04/) and run it as root.
As the script uses aptitude to install packages it should be possible to use it on any Debian-based system.
Give it a try and report the result to me:
<git [<ät>] erinnerungsfragmente.de>

Please note the printed access urls and MySQL passwords for the installed applications.

What to expect
--------------

This script automates the process of installing Atlassian products for testing purposes.
It may break your system. Especially when there are already running Atlassian products on the machine.
The JIRA and Confluence installers are not manipulated by this script in any way.
You can press Enter for all questions by the Installers. This is what's expected (specially the installation folder).
After you've finished the installation you are able to access the applications via http on the standard ports.
Nothing more is planned. But sure it's possible to run everything behind a webserver and access it via https.

Use in production environment
-----------------------------

Please note that you shouln't (really, don't do it!) use any product installed with this script in a production environment.
If you want to do so please consider reading the Atlassian Documentation (https://confluence.atlassian.com/display/ALLDOC/Atlassian+Documentation) or get help by a professional consulting team.

Anything else?
--------------

Nothing at this time.
