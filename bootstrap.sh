#!/usr/bin/env sh

set -e

# see: https://stackoverflow.com/questions/16843382/colored-shell-script-output-library

## Enable our easy to read Colour Flags as long as --no-colors hasn't been passed or the NO_COLOR Env Variable is set.
## NOTE: the NO_COLOR env variable is from: https://no-color.org/
if [ -z "${NO_COLOR}" ]; then
  ESeq="\x1b["
  # Set up our Colour Holders.
  ResetColor="$ESeq"'0m'    # Text Reset
  Bold="$ESeq"'1m';    Underline="$ESeq"'4m'
  # Regular              Bold                        Underline                       High Intensity
  Black="$ESeq"'0;30m';  BoldBlack="$ESeq"'1;30m';   UnderlineBlack="$ESeq"'4;30m';  IntenseBlack="$ESeq"'0;90m';
  Red="$ESeq"'0;31m';    BoldRed="$ESeq"'1;31m';     UnderlineRed="$ESeq"'4;31m';    IntenseRed="$ESeq"'0;91m';
  Green="$ESeq"'0;32m';  BoldGreen="$ESeq"'1;32m';   UnderlineGreen="$ESeq"'4;32m';  IntenseGreen="$ESeq"'0;92m';
  Yellow="$ESeq"'0;33m'; BoldYelllow="$ESeq"'1;33m'; UnderlineYellow="$ESeq"'4;33m'; IntenseYellow="$ESeq"'0;93m';
  Blue="$ESeq"'0;34m';   BoldBlue="$ESeq"'1;34m';    UnderlineBlue="$ESeq"'4;34m';   IntenseBlue="$ESeq"'0;94m';
  Purple="$ESeq"'0;35m'; BoldPurple="$ESeq"'1;35m';  UnderlinePurple="$ESeq"'4;35m'; IntensePurple="$ESeq"'0;95m';
  Cyan="$ESeq"'0;36m';   BoldCyan="$ESeq"'1;36m';    UnderlineCyan="$ESeq"'4;36m';   IntenseCyan="$ESeq"'0;96m';
  White="$ESeq"'0;37m';  BoldWhite="$ESeq"'1;37m';   UnderlineWhite="$ESeq"'4;37m';  IntenseWhite="$ESeq"'0;97m';
  #Bold High Intensity                Background              High Intensity Backgrounds
  BoldIntenseBlack="$ESeq"'1;90m';    OnBlack="$ESeq"'40m';   OnIntenseBlack="$ESeq"'0;100m';
  BoldIntenseRed="$ESeq"'1;91m';      OnRed="$ESeq"'41m';     OnIntenseRed="$ESeq"'0;101m';
  BoldIntenseGreen="$ESeq"'1;92m';    OnGreen="$ESeq"'42m';  OnIntenseGreen="$ESeq"'0;102m';
  BoldIntenseYellow="$ESeq"'1;93m';   OnYellow="$ESeq"'43m';  OnIntenseYellow="$ESeq"'0;103m';
  BoldIntenseBlue="$ESeq"'1;94m';     OnBlue="$ESeq"'44m';    OnIntenseBlue="$ESeq"'0;104m';
  BoldIntensePurple="$ESeq"'1;95m';   OnPurple="$ESeq"'45m';  OnIntensePurple="$ESeq"'0;105m';
  BoldIntenseCyan="$ESeq"'1;96m';     OnCyan="$ESeq"'46m';    OnIntenseCyan="$ESeq"'0;106m';
  BoldIntenseWhite="$ESeq"'1;97m';    OnWhite="$ESeq"'47m';   OnIntenseWhite="$ESeq"'0;107m';
fi

#
# color log.
# log_(success|error|warning|note) uses stdout(color) only
# logger_(success|error|warning|note) uses stdout(color) and syslog(no-color)
_log() {
   __template="$1"
   shift
   echo "$(printf "$__template" "$@")" >&2
   unset __template
}

log_success() {  _log "$Green✔ %s$ResetColor\n" "$@"; }
log_error() {    _log "$Red✖ %s$ResetColor\n" "$@"; }
log_warning() {  _log "$Yellow➜ %s$ResetColor\n" "$@"; }
log_note() {     _log "$Blue%s$ResetColor\n" "$@"; }

logger_success() {  _log "$Green✔ %s$ResetColor\n" "$@";  logger -p user.info "$@"; }
logger_error() {    _log "$Red✖ %s$ResetColor\n" "$@";    logger -p user.err "$@"; }
logger_warning() {  _log "$Yellow➜ %s$ResetColor\n" "$@"; logger -p user.warning "$@"; }
logger_note() {     _log "$Blue%s$ResetColor\n" "$@";      logger -p user.notice "$@"; }


#######################################
# get escalation method(sudo, or su) if needed
# Arguments:
#   None
# Returns:
#   0
# Outputs:
#   Write method("sudo~", "su~", or "") to stdout
# Details:
#   If root, write empty("").
#   If non root, delegate environments (sudo -E).
#######################################
get_escalation_method() {
  if [ "$(whoami)" != "root" ]; then
    if [ -x "$(command -v sudo)" ]; then echo "sudo -S -E"
    elif [ -x "$(command -v su)" ]; then echo "su - -c"; fi
  fi
}


#######################################
# get package management method information
# Arguments:
#   None
# Returns:
#   0 is ok
#   1 is error. can't parse package manager.
# Outputs:
#   Write space-separated variable-like string("A=a; B=b;") to stdout
#     _facts_manager=(apt|yum|dnf|zypper|apk)
#     _facts_install=(apt-get install|yum install|dnf~|zypper~|apk~)
#     _facts_update=(apt-get update|yum check-update|dnf~|zypper~|apk~)
# Details:
#   use stdout with eval.
#   e.g. eval $(get_package_manager); eval $_facts_install git
#   see: https://stackoverflow.com/questions/2488715/idioms-for-returning-multiple-values-in-shell-scripting
#######################################
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

log_note "[bootstrap start]"
log_note "prerequisite package instal start"

# install packages for chezmoi
set +e
eval $(get_package_management_method)
eval $(get_escalation_method) $_facts_update 1>/dev/null
eval $(get_escalation_method) $_facts_install git curl tar bash 1>/dev/null
set -e

log_success "prerequisite package instal finished."
log_note "init scripts start"

# apply dotfiles using chezmoi
sh -c "$(curl -fsLSk https://chezmoi.io/get)" -- init --apply Torimune29 --destination / --source /etc/chezmoi/data --working-tree /etc/chezmoi/data --config /etc/chezmoi/chezmoi.toml --purge-binary https://github.com/Torimune29/dotfiles-admin

log_success "init script finished"
log_success "[bootstrap finished]"
