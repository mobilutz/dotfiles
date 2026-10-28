-- Marta plugin: "Connect to SMB Server…"
-- Adds an action to the Actions panel (⌘⇧P) that discovers SMB servers on
-- the local network, lets you pick a share, mounts it and opens it in Marta.

marta.expose()

plugin {
    id = "net.lengemann.smbconnect",
    name = "SMB Connect",
    apiVersion = "2.2",
    author = "Lutz Lengemann"
}

local PLUGIN_DIR = martax.getHomeDirectory()
    .. "/Library/Application Support/org.yanex.marta/Plugins/smb-connect"

action {
    id = "connect",
    name = "Connect to SMB Server…",
    apply = function(context)
        -- Runs asynchronously; the script shows its own macOS dialogs
        -- and opens the mounted share in Marta when done.
        martax.execute("/bin/zsh", { PLUGIN_DIR .. "/smb-connect.sh" })
    end
}

action {
    id = "disconnect",
    name = "Disconnect SMB Share",
    apply = function(context)
        -- The script unmounts the first path that is on an SMB share:
        -- the item under the cursor (e.g. /Volumes/web), else the current folder.
        local model = context.activePane.model
        local args = { PLUGIN_DIR .. "/smb-disconnect.sh" }
        -- tostring(File) yields its path
        for _, file in ipairs(model.activeFiles) do
            table.insert(args, tostring(file))
        end
        if model.folder then
            table.insert(args, tostring(model.folder))
        end
        martax.execute("/bin/zsh", args)
    end
}
