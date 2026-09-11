#!/usr/bin/env bash
#
# apt counterpart of `brew bundle`: installs what linux/packages.txt lists.
#
# Only packages that are missing AND available in the configured apt sources
# are installed, so a Debian 12 machine simply ends up without eza rather than
# failing the whole run.

set -e

DOTFILES_LINUX="$(cd "$(dirname "$0")" && pwd -P)"
PACKAGES_FILE="$DOTFILES_LINUX/packages.txt"

if ! command -v apt-get >/dev/null
then
  echo "  [WARN] no apt-get, skipping $PACKAGES_FILE"
  exit 0
fi

sudo=""
if [ "$(id -u)" != "0" ]
then
  sudo="sudo"
fi

wanted=()
while read -r line
do
  line="${line%%#*}"
  line="$(echo "$line" | tr -d '[:space:]')"
  [ -n "$line" ] && wanted+=("$line")
done < "$PACKAGES_FILE"

missing=()
unavailable=()
for package in "${wanted[@]}"
do
  if dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "ok installed"
  then
    continue
  fi

  if apt-cache show "$package" >/dev/null 2>&1
  then
    missing+=("$package")
  else
    unavailable+=("$package")
  fi
done

if [ ${#unavailable[@]} -gt 0 ]
then
  echo "  [WARN] not in this release's apt sources: ${unavailable[*]}"
fi

if [ ${#missing[@]} -eq 0 ]
then
  echo "  [ OK ] all packages from packages.txt are installed"
  exit 0
fi

echo "  [ .. ] apt-get install ${missing[*]}"
DEBIAN_FRONTEND=noninteractive $sudo apt-get install -y "${missing[@]}"
echo "  [ OK ] installed ${missing[*]}"
