# SMB Connect (Marta plugin)

SMB actions for the [Marta](https://marta.sh) file manager:

- **Connect to SMB Server…** – finds SMB servers via Bonjour, lists their shares,
  mounts the chosen one and opens it in Marta.
- **Disconnect SMB Share** – unmounts the share under the cursor (e.g. `/Volumes/web`)
  or the one the current folder is on. Marta's own "Unmount Volume" refuses network
  shares because macOS does not flag them as ejectable.

## Layout

- `init.lua` – plugin (id `net.lengemann.smbconnect`, actions `connect`, `disconnect`)
- `smb-connect.sh`, `smb-disconnect.sh` – GUI flows, started by the plugin
- `lib.zsh` – shared helpers (discovery, cache, mounts), `dialogs.zsh` – AppleScript dialogs
- `~/.dotfiles/bin/smb-connect` – terminal version with `select` menus (`smb-connect [host]`)
- `marta/install.darwin.sh` links this folder to `~/Library/Application Support/org.yanex.marta/Plugins/smb-connect`

## Install

```sh
marta/install.darwin.sh   # also run by `dot`
```

Restart Marta, then run the actions from ⌘⇧P, or with the hotkeys set in
`marta/conf.marco`: ⌘⇧K connect, ⌘⇧D disconnect.

## Cache

`~/Library/Caches/net.lengemann.smbconnect/` holds:

- `servers.tsv` – servers found by Bonjour. The list is shown from here and rescanned in the
  background; servers missing from the last scan are flagged, after 30 days they are dropped.
- `users.tsv` – last username that worked per host.

Delete the folder to start fresh.
