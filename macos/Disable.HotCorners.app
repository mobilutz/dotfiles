use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions

tell application "System Preferences"
    activate
    set current pane to pane id "com.apple.preference.expose"
    tell application "System Events"
        tell window "Mission Control" of process "System Preferences"
            click button "Hot Corners…"
            tell sheet 1
                tell group 1
                    set theCurrentValues to value of pop up buttons
                    if theCurrentValues is {"-", "-", "-", "-"} then
                        quit
                    else
                        repeat with i from 1 to 4
                            tell pop up button i
                                click
                                click last menu item of menu 1
                            end tell
                        end repeat
                    end if
                end tell
                click button "OK"
            end tell
        end tell
    end tell
    quit
end tell
