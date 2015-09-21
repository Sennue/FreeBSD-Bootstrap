#!/bin/sh

# kernel configuration to use
HOSTNAME=`hostname 2> /dev/null || echo "hostname"`
KERNEL_CONFIG=`echo $HOSTNAME | tr '[:lower:]' '[:upper:]'`_KERNEL
KEYMAP=us

# svnlite is part of FreeBSD 10.1+ base. Change this value to "svn" and install the devel/subversion port if building on an older version of FreeBSD.
SVN=svnlite

# change the version of freebsd to install here
# FreeBSD 11 release schedule: https://www.freebsd.org/releases/11.0R/schedule.html
FREEBSD_SRC_PROJECT=head
FREEBSD_SRC_SERVER=svn://svn.freebsd.org/base
FREEBSD_SRC_DIR=/usr/src

# ports tree settings
# pull ports subversion repository and update with "svn up /usr/ports"
PORTS_SRC_PROJECT=head
PORTS_SRC_SERVER=svn://svn.freebsd.org/ports
PORTS_SRC_DIR=/usr/ports

# ports tree settings
# pull ports subversion repository and update with "svn up /usr/ports"
DOC_SRC_PROJECT=head
DOC_SRC_SERVER=svn://svn.freebsd.org/doc
DOC_SRC_DIR=/usr/doc

# portmaster
PORTMASTER_FLAGS=-Gd

