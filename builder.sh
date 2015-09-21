#!/bin/sh

TOP_DIR=$(dirname `readlink -f "$0"` 2> /dev/null || pwd)
. $TOP_DIR/variables.sh
. $TOP_DIR/secure_variables.sh

main () {
  for param in "$@" ; do
    case "$param" in
      0|prep)
        prep
        ;;
      1|build)
        build
        ;;
      2|install)
        install
        ;;
      3|postinstall)
        postinstall
        ;;
      hot|hot_install)
        hot_install
        ;;
      quick|quick_install)
        quick_install
        ;;
      update|update_ports)
        update_all
        ;;
      resume|resume_portmaster)
        resume_portmaster
        ;;
      bootstrap)
        bootstrap
        ;;
      bootstrap_rc)
        bootstrap_rc
        ;;
      link|bootstrap_kernel_config)
        bootstrap_kernel_config
        ;;
      reboot|multi|multi_user_reboot)
        multi_user_reboot
        ;;
      single|single_user_reboot)
        single_user_reboot
        ;;
      repair|repair_filesystem)
        repair_filesystem
        ;;
      sub|single_user_bootstrap)
        single_user_bootstrap
        ;;
      clock|adjust_clock)
        adjust_clock
        ;;
      ath0|ath0_wifi_reset)
        single_user_bootstrap
        ;;
      clear)
        clear
        ;;
      -v=*|--value=*)
        VALUE="${i#*=}"
        ;;
      -f|--flag)
        FLAG=1
        ;;
      --)
        break
        ;;
      *)
        usage
        ;;
    esac
  done
}

usage () {
  echo "Usage: ..."
}

bootstrap () {
  bootstrap_ports
  bootstrap_doc
  bootstrap_freebsd_src
  bootstrap_kernel_config
  bootstrap_tools
  update_all
}

prep () {
  update_all
  single_user_reboot
}

build () {
  single_user_bootstrap
  build_freebsd_all
  install_freebsd_kernel
  single_user_reboot
}

install () {
  single_user_bootstrap
  install_freebsd_world
  delete_obsolete_files
  multi_user_reboot
}

postinstall () {
  rebuild_all_ports
  delete_obsolete_libraries
}

hot_install () {
  adjust_clock
  update_all
  build_freebsd_all
  install_freebsd_kernel
  install_freebsd_world
  delete_obsolete_files
  rebuild_all_ports
  delete_obsolete_libraries
}

quick_install () {
  adjust_clock
  update_freebsd_source
  clean_build_environment
  build_freebsd_world
  backup_freebsd_kernel
  build_freebsd_kernel
  install_freebsd_kernel
  install_freebsd_world
  delete_obsolete_files
  delete_obsolete_libraries
}

bootstrap_ports () {
  echo "Boostrapping ports..."
  # Bootstrap Ports
  rm -rf $PORTS_SRC_DIR
  $SVN co $PORTS_SRC_SERVER/$PORTS_SRC_PROJECT $PORTS_SRC_DIR
  $SVN up $PORTS_SRC_DIR
  cd $PORTS_SRC_DIR/ports-mgmt/portmaster && make config-recursive && make config-recursive && make install clean
  portmaster $PORTMASTER_FLAGS ports-mgmt/portupgrade
  #portmaster $PORTMASTER_FLAGS devel/subversion
  echo "Boostrapping ports... Done."
}

bootstrap_doc () {
  echo "Boostrapping doc..."
  # Install Documentation
  rm -rf $DOC_SRC_DIR
  $SVN co $DOC_SRC_SERVER/$DOC_SRC_PROJECT $DOC_SRC_DIR
  $SVN up $DOC_SRC_DIR
  portmaster $PORTMASTER_FLAGS textproc/docproj
  (cd $DOC_SRC_DIR; make install clean)
  echo "Boostrapping doc... Done."
}

bootstrap_freebsd_src () {
  echo "Tracking FreeBSD $FREEBSD_SRC_PROJECT..."
  # Install Source
  rm -rf $FREEBSD_SRC_DIR
  $SVN co $FREEBSD_SRC_SERVER/$FREEBSD_SRC_PROJECT $FREEBSD_SRC_DIR
  $SVN up $FREEBSD_SRC_DIR
  echo "Tracking FreeBSD $FREEBSD_SRC_PROJECT... Done."
}

bootstrap_kernel_config () {
  echo "Bootstrapping kernel configuration..."
  (cd $FREEBSD_SRC_DIR/sys/amd64/conf/; rm -f $KERNEL_CONFIG; ln -s $TOP_DIR/$KERNEL_CONFIG; ln -s $TOP_DIR/VIRTUALBOX)
  echo "Bootstrapping kernel configuration... Done."
}

bootstrap_tools () {
  echo "Boostrapping tools..."
  # Install Development Tools
  portmaster $PORTMASTER_FLAGS devel/git
  portmaster $PORTMASTER_FLAGS shells/bash editors/vim ftp/curl ftp/wget sysutils/screen
  #portmaster $PORTMASTER_FLAGS devel/py-setuptools33 devel/py-pip devel/py-virtualenv devel/py-virtualenvwrapper
  #portmaster $PORTMASTER_FLAGS www/nginx www/lynx security/tor
  echo "Boostrapping tools... Done."
}

bootstrap_rc () {
  echo "Boostrapping /etc/rc.conf..."
  echo "hostname=\"$HOSTNAME\"" >> /etc/rc.conf
  echo "keymap=\"$KEYMAP\"" >> /etc/rc.conf
  echo 'ifconfig_em0="DHCP"' >> /etc/rc.conf
  echo 'ifconfig_em0_ipv6="inet6 accept_rtadv"' >> /etc/rc.conf
  echo 'sshd_enable="YES"' >> /etc/rc.conf
  echo 'ntpd_enable="YES"' >> /etc/rc.conf
  echo 'powerd_enable="YES"' >> /etc/rc.conf
  #echo 'moused_enable="YES"' >> /etc/rc.conf
  echo "Boostrapping /etc/rc.conf... Done."
}

update_all () {
  update_freebsd_source
  update_doc_source
  update_ports
}

update_freebsd_source () {
  echo 'Updating FreeBSD source code...'
  $SVN up $FREEBSD_SRC_DIR
  echo 'Updating FreeBSD source code... Done.'
}

update_doc_source () {
  echo 'Updating documentation source...'
  $SVN up $DOC_SRC_DIR
  echo 'Updating documentation source... Done.'
}

update_ports () {
  echo 'Updating ports...'
  $SVN up $PORTS_SRC_DIR
  portmaster --no-confirm -m BATCH=yes -aD
  #portmaster --no-confirm -m BATCH=yes -m DISABLE_VULNERABILITIES=yes -aD
  portsclean -CD
  echo 'Updating ports... Done.'
}

rebuild_all_ports () {
  echo 'Rebuilding ports...'
  $SVN up $PORTS_SRC_DIR
  portmaster --no-confirm -m BATCH=yes -afD
  portsclean -CD
  echo 'Rebuilding ports... Done.'
}

resume_portmaster () {
  echo 'Resuming portmaster...'
  $SVN up $PORTS_SRC_DIR
  #portmaster --no-confirm -m BATCH=yes -m DISABLE_VULNERABILITIES=yes -D $PORTS_TO_INSTALL
  portmaster --no-confirm -m BATCH=yes -D $PORTS_TO_INSTALL 
  # update outdated ports
  #portmaster --no-confirm -m BATCH=yes -aD
  echo 'Resuming portmaster... Done.'
}

multi_user_reboot() {
  echo 'Rebooting system...'
  shutdown -r +1
  echo 'Rebooting system... Done.'
}

single_user_reboot () {
  echo 'Rebooting into single user mode...'
  nextboot -D
  nextboot -o "-s" -k kernel
  shutdown -r +1
  echo 'Rebooting into single user mode... Done.'
}

single_user_bootstrap () {
  #repair_filesystem
  mount_rw_filesystem
  mount_fdescfs_and_proc
  initialize_devices
  adjust_clock
}

repair_filesystem () {
  echo 'Filesystem check...'
  fsck -p
  echo 'Filesystem check... Done.'
}

mount_rw_filesystem () {
  echo 'Mounting RW filesystem...'
  #fsck -p
  mount -u /
  #mount -a -t ufs 
  mount -a
  swapon -a
  echo 'Mounting RW filesystem... Done.'
}

mount_fdescfs_and_proc () {
  echo "Mounting fdescfs and proc ..."
  mount -t fdescfs fdesc /dev/fd
  mount -t procfs proc /proc
  echo "Mounting fdescfs and proc ... Done."
}

initialize_devices () {
  echo "Initializing devices..."
  service devd start
  service syscons start
  echo "Initializing devices..."
}

adjust_clock () {
  echo 'Adjusting clock...'
  adjkerntz -i
  ntpdate -v -b in.pool.ntp.org
  echo 'Adjusting clock... Done.'
}

build_freebsd_all () {
  build_freebsd_doc
  clean_build_environment
  build_freebsd_world
  backup_freebsd_kernel
  build_freebsd_kernel
}

clean_build_environment () {
  echo 'Cleaning FreeBSD build environment...'
  chflags -R noschg /usr/obj/*
  rm -rf /usr/obj/*
  (cd $FREEBSD_SRC_DIR; make cleandir && make cleandir)
  echo 'Cleaning FreeBSD build environment... Done.'
}

backup_freebsd_kernel () {
  echo 'Backing up kernel...'
  (cd /boot/; cp -Rp kernel kernel.good)
  echo 'Backing up kernel... Done.'
}

build_freebsd_doc () {
  echo 'Building FreeBSD documentation...'
  #(cd /usr/doc; make install clean)
  (cd $DOC_SRC_DIR/en_US.ISO8859-1; make install clean)
  (cd $DOC_SRC_DIR/ja_JP.eucJP; make install clean)
  echo 'Building FreeBSD documentation... Done.'
}

build_freebsd_world () {
  echo 'Building FreeBSD world...'
  (cd $FREEBSD_SRC_DIR; make buildworld)
  echo 'Building FreeBSD world... Done.'
}

build_freebsd_kernel () {
  echo 'Building FreeBSD kernel...'
  (cd $FREEBSD_SRC_DIR; make buildkernel KERNCONF=$KERNEL_CONFIG)
  echo 'Building FreeBSD kernel... Done.'
}

install_freebsd_kernel () {
  echo 'Installing FreeBSD kernel...'
  (cd $FREEBSD_SRC_DIR; make installkernel KERNCONF=$KERNEL_CONFIG)
  echo 'Installing FreeBSD kernel... Done.'
}

install_freebsd_world () {
  mergemaster_preinstall
  echo 'Installing FreeBSD world...'
  (cd $FREEBSD_SRC_DIR; make installworld)
  echo 'Installing FreeBSD world... Done.'
  mergemaster_postinstall
}

mergemaster_preinstall () {
  echo 'Running preinstall mergemaster...'
  mergemaster -p
  echo 'Running preinstall mergemaster... Done.'
}

mergemaster_postinstall () {
  echo 'Running postinstall mergemaster...'
  mergemaster
  echo 'Running postinstall mergemaster... Done.'
}

delete_obsolete_files () {
  echo 'Deleting obsolete files and directories...'
  (cd $FREEBSD_SRC_DIR; make check-old)
  (cd $FREEBSD_SRC_DIR; make -DBATCH_DELETE_OLD_FILES delete-old)
  (cd $FREEBSD_SRC_DIR; make -DWITH_ATF delete-old)
  echo 'Deleting obsolete files and directories... Done.'
}

delete_obsolete_libraries () {
  echo 'Deleting obsolete libraries...'
  (cd $FREEBSD_SRC_DIR; make delete-old-libs)
  (cd $FREEBSD_SRC_DIR; make -DWITH_ATF delete-old-libs)
  echo 'Deleting obsolete libraries... Done.'
}

ath0_wifi_reset () {
  echo "Resetting ath0 WiFi..."
  ifconfig wlan0 destroy
  pkill -9 wpa_supplicant
  ifconfig wlan0 create wlandev ath0
  wpa_supplicant -i wlan0 -c /etc/wpa_supplicant.conf &
  echo "Resetting ath0 WiFi... Done."
}

main $@

