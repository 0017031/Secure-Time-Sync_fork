#!/bin/bash

# orignal: https://gitlab.com/madaidan/secure-time-sync/-/blob/master/secure-time-sync.sh

#    Secure Time Synchronization
#    Copyright (C) 2019  madaidan
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.


while test $# -gt 0; do
  case "$1" in
  --use-tor)
    use_tor="true"
    break
    ;;
  esac
done

# Select a random website out of the pool.
select_pool() {
  # Use the onion service if the "--use-tor" flag was set.
  if [ "${use_tor}" = "true" ]; then
    POOL[1]="http://expyuzz4wqqyqhjn.onion"
  else
    POOL[1]="https://www.torproject.org"
  fi

  # Tails website.
  POOL[2]="https://tails.boum.org"

  # Whonix website.
  if [ "${use_tor}" = "true" ]; then
    POOL[3]="http://dds6qkxpwdeubwucdiaord2xgbbeyds25rbsgr73tbfpqpt4a6vjwsyd.onion"
  else
    POOL[3]="https://www.whonix.org"
  fi

  # DuckDuckGo.
  if [ "${use_tor}" = "true" ]; then
    POOL[4]="https://3g2upl4pq6kufc4m.onion"
  else
    POOL[4]="https://duckduckgo.com"
  fi

  # EFF.
  POOL[5]="https://www.eff.org"

  # The last one doesn't get selected. Without the following line, POOL[5] would never be selected.
  POOL[6]=""


  rand=$(($RANDOM % ${#POOL[@]}))
  SELECTED_POOL="${POOL[$rand]}"

  # If nothing was selected, run select_pool again.
  if [ "${SELECTED_POOL}" = "" ]; then
    select_pool
  fi
}

# select_pool
SELECTED_POOL="https://bing.com"


if [ "${use_tor}" = "true" ]; then
  # Configure curl to use a socks proxy at localhost on port 9050. This is the default Tor socksport.
  SECURE_CURL="curl -sI --socks5-hostname localhost:9050"
else
  # Protects against https downgrade attacks when not using Tor.
  SECURE_CURL="curl -sI --tlsv1.2 --proto =https"
fi

# if ! ${SECURE_CURL} -s ${SELECTED_POOL} &>/dev/null; then
if ! ${SECURE_CURL} -s ${SELECTED_POOL} ; then
  echo "ERROR: Could not connect to the website."
  exit 1
fi

# Extract the current time from the http header when connecting to one of the websites in the pool.
NEW_TIME=$(${SECURE_CURL} ${SELECTED_POOL} 2>&1 | grep -i "Date" | sed -e 's/Date: //' | sed -e 's/date: //')

# Output the extracted time and selected pool for debugging.
# if [ "${DEBUG_TS}" = "1" ]; then
  echo "${SELECTED_POOL}"
  echo "${NEW_TIME}"
# fi

# Set the time to the value we just extracted.
sudo date -s "${NEW_TIME}"
