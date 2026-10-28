#!/bin/zsh
# Unmounts an SMB share, launched by the Marta plugin.
# Marta's own "Unmount Volume" refuses network shares because macOS does not
# flag them as ejectable, so this uses diskutil instead.
#
# Usage:  smb-disconnect.sh <path> …   (first path on or inside an SMB mount wins)

emulate -L zsh
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
TITLE="Disconnect SMB Share"
source "${0:A:h}/dialogs.zsh"

mount_points=("${(@f)$(mount -t smbfs | sed -nE 's/^.* on (.*) \(smbfs.*$/\1/p')}")
mount_points=(${mount_points:#})

MP=""
for p in "$@"; do
  for m in "${mount_points[@]}"; do
    if [[ $p == "$m" || $p == "$m"/* ]]; then
      MP=$m
      break 2
    fi
  done
done
[[ -n $MP ]] || die "No SMB share selected." "Select a share in /Volumes, or open a folder inside one.

Paths from Marta:
${(F)@:-none}

SMB mounts:
${(F)mount_points:-none}"

name=${MP:t}
if out=$(diskutil unmount "$MP" 2>&1); then
  notify "Disconnected “$name”."
  exit 0
fi

confirm "Could not disconnect “$name”." "$out

Force it? Unsaved changes in open files on this share may be lost." "Force Disconnect" || exit 0
out=$(diskutil unmount force "$MP" 2>&1) || die "Could not disconnect “$name”." "$out"
notify "Disconnected “$name”."
