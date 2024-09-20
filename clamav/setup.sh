#!/usr/bin/env bash

SUDO=/usr/bin/sudo
BREW_PREFIX=$(brew --prefix)

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

CLAMAV_ETC_DIR=${BREW_PREFIX}/etc/clamav

# create your configuration files
FRESHCLAM_CONF=${CLAMAV_ETC_DIR}/freshclam.conf
cp ${CLAMAV_ETC_DIR}/freshclam.conf.sample ${FRESHCLAM_CONF}
sed -ie 's/^Example/#Example/g' ${FRESHCLAM_CONF}
sed -ie 's/^#LogTime yes/LogTime yes/g' ${FRESHCLAM_CONF}
sed -ie "s|^#NotifyClamd /path/to/clamd.conf|NotifyClamd ${CLAMAV_ETC_DIR}/clamd.conf|g" ${FRESHCLAM_CONF}

CLAMD_CONF=${CLAMAV_ETC_DIR}/clamd.conf
cp ${CLAMAV_ETC_DIR}/clamd.conf.sample ${CLAMD_CONF}
sed -ie 's/^Example/#Example/g' ${CLAMD_CONF}
sed -ie 's/^#LogTime yes/LogTime yes/g' ${CLAMD_CONF}

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