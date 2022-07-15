#!/usr/bin/env bash
# Dependencies: bash>=3.2, coreutils, file, spotify, procps-ng, wmctrl, xdotool

# Makes the script more portable
readonly DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Optional icon to display before the text
# Insert the absolute path of the icon
# Recommended size is 24x24 px
readonly ICON="${DIR}/icons/music/spotify.png"

if pidof spotify &> /dev/null; then
  # Spotify song's info
  readonly ARTIST=$(bash "${DIR}/spotify.sh" artist | sed 's/&/&#38;/g')
  readonly TITLE=$(bash "${DIR}/spotify.sh" title | sed 's/&/&#38;/g')
  readonly ALBUM=$(bash "${DIR}/spotify.sh" album | sed 's/&/&#38;/g')
  ARTIST_TITLE=$(echo "${ARTIST} - ${TITLE}")
  WINDOW_ID=$(wmctrl -l | grep "${ARTIST_TITLE}" | awk '{print $1}')

  #If Spotify doesnt have now playing information fallback to literal Spotify
  if [[ -z $WINDOW_ID ]]; then
      WINDOW_ID=$(wmctrl -l | grep "Spotify" | awk '{print $1}')
  fi
  readonly WINDOW_ID

  # Proper length handling
  readonly MAX_CHARS=52
  readonly STRING_LENGTH="${#ARTIST_TITLE}"
  readonly CHARS_TO_REMOVE=$(( STRING_LENGTH - MAX_CHARS ))
  [ "${#ARTIST_TITLE}" -gt "${MAX_CHARS}" ] \
    && ARTIST_TITLE="${ARTIST_TITLE:0:-CHARS_TO_REMOVE} …"

  # Panel
  if [[ $(file -b "${ICON}") =~ PNG|SVG ]]; then
    INFO="<txt>${ARTIST_TITLE}</txt>"
    INFO+="<img>${ICON}</img>"
  else
    INFO="<txt>${ARTIST_TITLE}</txt>"
  fi

  #Switch from activating the window to toggling the window
  INFO+="<click>"
  INFO+="xdotool windowstate --toggle HIDDEN ${WINDOW_ID} windowstate --toggle SKIP_TASKBAR ${WINDOW_ID}"
  INFO+='if [[ -n "$(xwininfo -id $WINDOW_ID | grep '\''IsViewable'\'')" ]]; then xdotool windowactivate --sync ${WINDOW_ID}; fi'
  INFO+="</click>"

  # Tooltip
  MORE_INFO="<tool>"
  MORE_INFO+="Artist     : ${ARTIST}\n"
  MORE_INFO+="Album   : ${ALBUM}\n"
  MORE_INFO+="Title        : ${TITLE}"
  MORE_INFO+="</tool>"
else
  # Panel
  if [[ $(file -b "${ICON}") =~ PNG|SVG ]]; then
    INFO="<txt>Offline</txt>"
    INFO+="<img>${ICON}</img>"
  else
    INFO="<txt>Offline</txt>"
  fi

  INFO+="<click>"
  INFO+="$(which spotify) &;"
  INFO+="xdotool search --sync --all --onlyvisible --name --classname Spotify windowsize --sync 25% 25% windowmove --sync 0 0 windowstate --add MAXIMIZED_VERT --add MAXIMIZED_HORZ"
  INFO+="</click>"

  # Tooltip
  MORE_INFO="<tool>Spotify is not running. Click the icon to start it!</tool>"
fi

# Panel Print
echo -e "${INFO}"

# Tooltip Print
echo -e "${MORE_INFO}"
