#!/usr/bin/env bash

SUDO=/usr/bin/sudo
BREW_DIR=$(brew --prefix)

# prerequisites
# install macos command line tools
CLT_DIR=$(xcode-select -p)
RV=$?
if ! [ $RV -eq '0' ]
then
    $SUDO -E /usr/bin/xcode-select --install
    $SUDO -E /usr/bin/xcodebuild -license
fi


# simply brew with the install verb and clamav as the recipe to be brewed:
brew install clamav

# check and fix freshclam and clamd symlinks
CLAMAV_PREFIX=$(clamav-config --prefix)
test -f ${BREW_DIR}/bin/freshclam || ln -s "${CLAMAV_PREFIX}"/bin/freshclam ${BREW_DIR}/bin/freshclam
test -f ${BREW_DIR}/bin/clamd || ln -s "${CLAMAV_PREFIX}"/sbin/clamd ${BREW_DIR}/bin/clamd

# create your configuration files
#cp ${BREW_DIR}/etc/clamav/freshclam.conf.sample ${BREW_DIR}/etc/clamav/freshclam.conf && \
#sed -ie 's/^Example/#Example/g' ${BREW_DIR}/etc/clamav/freshclam.conf
#sed -ie 's/^LocalSocket /tmp/clamd.socket/#LocalSocket /tmp/clamd.socket/g' ${BREW_DIR}/etc/clamav/freshclam.conf
#cp ${BREW_DIR}/etc/clamav/clamd.conf.sample ${BREW_DIR}/etc/clamav/clamd.conf && \
#sed -ie 's/^Example/#Example/g' ${BREW_DIR}/etc/clamav/clamd.conf
cp ./freshclam.conf ${BREW_DIR}/etc/clamav/freshclam.conf
cp ./clamd.conf ${BREW_DIR}/etc/clamav/clamd.conf

# update the virus definitions for clamav
freshclam -v

# setup to a quarantine location
sudo mkdir -p /Users/Shared/Quarantine
#sudo clamscan -r — scan-pdf=yes -l /Users/Shared/Quarantine/Quarantine.txt — move=/Users/Shared/Quarantine/ /

# use an Extension Attribute to read the Quarantine.txt file
#Read Quarantine
#result=$(cat /Users/Shared/Quarantine/Quarantine.txt)
#Echo Quarantine into EA
#echo "<result>$result</result>"

# create a plist that automatically runs on-demand clamdscan on a schedule
#sudo install -m 644 ./net.clamav.clamdscan.plist /Library/LaunchDaemons
#sudo launchctl load -w /Library/LaunchDaemons/net.clamav.clamdscan.plist

### Related sources
# https://github.com/essandess/macOS-clamAV
# https://trac.macports.org/ticket/50570
# https://krypted.com/mac-os-x/managing-virus-scans-clamav/
# http://redgreenrepeat.com/2019/08/09/setting-up-clamav-on-macos/
# https://github.com/Cisco-Talos/clamav-faq/blob/master/manual/UserManual/Installation-Unix/Steps-macOS.md