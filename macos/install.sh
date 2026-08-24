#!/bin/bash
#
# macOS default applications
#
# Assigns default apps to file types via duti. Run by script/install and
# bin/dot, so it must stay idempotent and must never prompt.
#
# Note: set-defaults.sh and set-hostname.sh are deliberately NOT called from
# here. They need sudo and change system wide behaviour, so they stay manual.

if ! command -v duti > /dev/null; then
  echo "  ✗ duti is missing, skipping default app assignment (brew bundle installs it)"
  exit 0
fi

# One line per handler: bundle id followed by the extensions and UTIs it should
# own. Comment a line out instead of deleting it to keep the history readable.
DEFAULT_HANDLERS=(
  "com.zettlr.app .md .markdown .mdown net.daringfireball.markdown"
  # Shell scripts open in an editor on purpose: with a terminal as the handler
  # a double click in Finder runs the script instead of showing it.
  "com.microsoft.VSCode .sh .zsh .bash .command public.shell-script"
  "com.microsoft.VSCode .py .rb .css .txt .log .conf .tf .ini"
  "com.microsoft.VSCode .plist com.apple.property-list"
  "org.videolan.vlc .webm"
  # .rar resolves through its UTI, an extension only binding loses to VLC.
  "com.jinghaoshe.ezip .rar com.rarlab.rar-archive"
)

for handler in "${DEFAULT_HANDLERS[@]}"; do
  read -r bundle_id types <<< "$handler"

  # duti silently accepts unknown bundle ids, so check the app exists first.
  if [ "$(mdfind -count "kMDItemCFBundleIdentifier == '$bundle_id'")" = "0" ]; then
    echo "  ✗ $bundle_id is not installed, skipping its file types"
    continue
  fi

  for type in $types; do
    duti -s "$bundle_id" "$type" all 2> /dev/null
  done

  echo "  ✓ $bundle_id owns: $types"
done
