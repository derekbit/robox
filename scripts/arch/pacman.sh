#!/bin/bash -eux

retry() {
  local COUNT=1
  local RESULT=0
  while [[ "${COUNT}" -le 10 ]]; do
    [[ "${RESULT}" -ne 0 ]] && {
      [ "`which tput 2> /dev/null`" != "" ] && tput setaf 1
      echo -e "\\n${*} failed... retrying ${COUNT} of 10.\\n" >&2
      [ "`which tput 2> /dev/null`" != "" ] && tput sgr0
    }
    "${@}" && { RESULT=0 && break; } || RESULT="${?}"
    COUNT="$((COUNT + 1))"

    # Increase the delay with each iteration.
    DELAY="$((DELAY + 10))"
    sleep $DELAY
  done

  [[ "${COUNT}" -gt 10 ]] && {
    [ "`which tput 2> /dev/null`" != "" ] && tput setaf 1
    echo -e "\\nThe command failed 10 times.\\n" >&2
    [ "`which tput 2> /dev/null`" != "" ] && tput sgr0
  }

  return "${RESULT}"
}

# Force the pacman keyring to reinitialize.
rm -rf /etc/pacman.d/gnupg/

# Setup the pacman keyring.
pacman-key --init
retry pacman-key --populate archlinux

# Update the package database.
retry pacman --sync --noconfirm --refresh

# Update the system packages.
retry pacman --sync --noconfirm --refresh --sysupgrade

# Useful tools.
retry pacman --sync --noconfirm --refresh vim curl wget sysstat lsof psmisc man-db mlocate net-tools haveged lm_sensors vim-runtime bash-completion

# Start the services we just added so the system will track its own performance.
systemctl enable sysstat.service && systemctl start sysstat.service

# Enable the entropy daemon.
systemctl enable haveged

# Ensure the daily update timers are enabled.
systemctl enable man-db.timer
systemctl enable updatedb.timer

# Initialize the databases.
updatedb
mandb

# Setup vim as the default editor.
printf "alias vi=vim\n" >> /etc/profile.d/vim.sh

# Reboot onto the new kernel (if applicable).
reboot
