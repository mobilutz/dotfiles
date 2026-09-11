# Raspberry Pi specific shortcuts.
#
# Guarded on the device tree rather than on the OS alone, so these stay out of
# the way on any other Debian machine. Replaces the .zsh_aliases that used to
# live alongside my Pi scripts.
[[ -r /proc/device-tree/model ]] || return 0
grep -qi raspberry /proc/device-tree/model || return 0

# SoC temperature and the undervoltage/throttling bitmask
# https://www.raspberrypi.com/documentation/computers/os.html#get_throttled
alias temp='vcgencmd measure_temp'
alias throttled='vcgencmd get_throttled'

# Core clock and voltage, handy next to the two above
alias clocks='vcgencmd measure_clock arm; vcgencmd measure_volts core'

# SD card / filesystem fill level, the thing that kills these boxes
alias disk='df -h /'

# What the box has been doing
alias syslog='journalctl -f'
alias cronlog='journalctl -u cron -f'
alias bootlog='journalctl -b -p err'
