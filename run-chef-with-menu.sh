#!/bin/bash

set -e


#-----------------------------------------------------------------------------------------------------------------------
# Vars

FLASHERROR=''
CURRENT_USER="${SUDO_USER}"
[ -z "${CURRENT_USER}" ] && CURRENT_USER="${USER}"


#-----------------------------------------------------------------------------------------------------------------------
# Functions : STDOUT

# Args: 1 - string to print; 2 - new lines to append to the resulting output.
print_critical() {
  # while read -r line; do
    printf "${c_crit}%s${c_off}" "$(printf %s "$1" | tr -d '\n\r\f\b\t\v' | sed -re 's/\s+/ /g')"
    printf "$2"
    # echo -en "${c_imp}${1}${c_off}"
  # done
}

# Args: 1 - string to print; 2 - new lines to append to the resulting output.
print_important() {
  # while read -r line; do
    printf "${c_imp}%s${c_off}" "$(printf %s "$1" | tr -d '\n\r\f\b\t\v' | sed -re 's/\s+/ /g')"
    printf "$2"
    # echo -en "${c_imp}${1}${c_off}"
  # done
}

# Args: 1 - string to print; 2 - new lines to append to the resulting output.
print_info() {
  # while read -r line; do
    printf "${c_info}%s${c_off}" "$(printf %s "$1" | tr -d '\n\r\f\b\t\v' | sed -re 's/\s+/ /g')"
    printf "$2"
    # echo -en "${c_imp}${1}${c_off}"
  # done
}

# Args: 1 - string to print; 2 - new lines to append to the resulting output.
print_act() {
  # while read -r line; do
    printf "${c_act}%s${c_off}" "$(printf %s "$1" | tr -d '\n\r\f\b\t\v' | sed -re 's/\s+/ /g')"
    printf "$2"
    # echo -en "${c_imp}${1}${c_off}"
  # done
}

# Return - Sets global var "USRCHOICE" with what the user entered.
wait_for_usr_char_input() {
  set +e # Ignore errors.

  # Does the environment have "stty"?
  which stty > /dev/null 2>&1
  local stty_error=$?

  # Wait for a single character of input; no return/enter key needed.
  if [ ${stty_error} -eq 0 ]; then
    local orig_stty="$(stty -g)"

    # Attempt the normal command to read input raw.
    # stty raw -echo
    stty raw > /dev/null 2>&1
    stty_error=$?

    # If the above command does not work, try a work around which is needed for "Git SCM" project v2.6.3 for Windows.
    if [ ${stty_error} -ne 0 ]; then
      stty raw isig > /dev/null 2>&1
      stty_error=$?
    fi

    # If we've modified stty without an error, wait for input.
    if [ ${stty_error} -eq 0 ]; then
      USRCHOICE=$(head -c 1)
      stty "${orig_stty}"
      return
    fi

    stty "${orig_stty}"
  fi

  IFS= read -n 1 -r USRCHOICE

  set -e # Stop the script on errors.
}



#-----------------------------------------------------------------------------------------------------------------------
# Functions : General

install_desirables() {
  sudo -E chef-client -z #-l info
  exit $?
}

install_core_desktop_components() {
  sudo -E chef-client -z -n 'default_workstation' #-l info
  exit $?
}

install_personal_desktop_components() {
  sudo -E chef-client -z -n 'default_personal_workstation' #-l info
  exit $?
}

install_gnome() {
  sudo -E chef-client -z -n 'gnome_workstation' #-l info
  exit $?
}

install_unity() {
  sudo -E chef-client -z -n 'unity_workstation' #-l info
  exit $?
}

present_menu() {
  # clear
  echo # blank line
  echo # blank line

  # "Empty" keyboard buffer. Only works on bash compliant shells so hide any output of errors and whatnot. Does not
  # handle multiple return keys in the buffer.
  set +e
  read -n 9999 -r -s -t 0.1
  set -e

  if [ -n "${FLASHERROR}" ]; then
    print_critical "${FLASHERROR}" "\n\n"
    FLASHERROR=''
  fi

  print_info "Welcome to the post-installation setup. :)" "\n"
  cat <<-'EOP'
    1) Install desired core packages, unrelated to desktop environments & applications.
    2) Install desired desktop related packages without changing desktop environment & install #1.
    3) Install desired personal desktop customizations & install #2.
    4) Change to Unity desktop environment & install #2.
    5) Change to GNOME desktop environment & install #2.
    q) Quit
EOP

  print_act 'What would you like to do? '

  # Wait for a single character of input; no return/enter key needed.
  wait_for_usr_char_input
  echo # blank line

  # Handle the user's input.
  case "${USRCHOICE}" in
    1)
      install_desirables
      ;;
    2)
      install_core_desktop_components
      ;;
    3)
      install_personal_desktop_components
      ;;
    4)
      install_unity
      ;;
    5)
      install_gnome
      ;;
    q*|Q*)
      exit 0
      ;;
    *)
      FLASHERROR='ERROR: You entered an unrecognized command. Please try again.'
      ;;
  esac
}



#-----------------------------------------------------------------------------------------------------------------------
# Main Logic

clear

# Has chef-client been installed?
set +e
which chef-client
RETVAL=$?
set -e
if [ ${RETVAL} -ne 0 ]; then
  # Install chef-client using Omnibus.
  wget -O- https://www.opscode.com/chef/install.sh | sudo bash -s
fi

cd chef-zero-ready

sudo chown -R "${CURRENT_USER}:${CURRENT_USER}" .

while true; do
  present_menu
done
