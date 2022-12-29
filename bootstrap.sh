#!/usr/bin/env sh

set -e

get_escalation_method() {
  if [ "$(whoami)" != "root" ]; then
    if [ -x "$(command -v sudo)" ]; then echo "sudo -S -E"
    elif [ -x "$(command -v su)" ]; then echo "su - -c"; fi
  fi
}

get_package_management_method () {
  if [ -x "$(command -v apt-get)" ];    then  echo "_facts_manager=\"apt\";       _facts_install=\"DEBIAN_FRONTEND=noninteractive apt-get install -y\";     _facts_update=\"apt-get update\" "
  elif [ -x "$(command -v yum)" ];      then  echo "_facts_manager=\"yum\";       _facts_install=\"yum install -y\";         _facts_update=\"yum check-update\" "
  elif [ -x "$(command -v dnf)" ];      then  echo "_facts_manager=\"dnf\";       _facts_install=\"dnf install -y\";         _facts_update=\"dnf check-update\" "
  elif [ -x "$(command -v microdnf)" ]; then  echo "_facts_manager=\"microdnf\";  _facts_install=\"microdnf install -y\";    _facts_update=\"microdnf update\" "
  elif [ -x "$(command -v zypper)" ];   then  echo "_facts_manager=\"zypper\"     _facts_install=\"zypper install -y\";      _facts_update=\"zypper refresh\" "
  elif [ -x "$(command -v apk)" ];      then  echo "_facts_manager=\"apk\";       _facts_install=\"apk add --no-cache\";     _facts_update=\"apk update\" "
  else return 1
  fi
}

echo "[bootstrap start]"
echo "prerequisite package instal start"

# install packages for chezmoi
eval $(get_package_management_method)
eval $(get_escalation_method) $_facts_update 1>/dev/null
eval $(get_escalation_method) $_facts_install git curl tar bash 1>/dev/null

echo "prerequisite package instal finished."
echo "init scripts start"

# apply dotfiles using chezmoi
sh -c "$(curl -fsLSk https://chezmoi.io/get)" -- init --apply --destination / --source /etc/chezmoi/data https://github.com/Torimune29/dotfiles-admin.git

echo "init script finished"
echo "[bootstrap finished]"
