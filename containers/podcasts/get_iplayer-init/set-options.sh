#!/usr/bin/env sh
# Ensure required get_iplayer preferences are set on every startup.
# Resets command-radio on every startup to ensure changes are picked up.
mkdir -p /tmp/getiplayer-staging /podcasts/bbc
chown -R abc:abc /tmp/getiplayer-staging /podcasts/bbc
get_iplayer --profile-dir /config/.get_iplayer --prefs-del --command-radio 2>/dev/null
get_iplayer --profile-dir /config/.get_iplayer --prefs-add \
  --output /tmp/getiplayer-staging \
  --outputradio /tmp/getiplayer-staging \
  --subdir \
  --command-radio 'mkdir -p "/podcasts/bbc"/"<nameshort>" && ffmpeg -y -loglevel warning -i "<filename>" -vn -c:a libmp3lame -q:a 2 "/podcasts/bbc"/"<nameshort>"/"<fileprefix>.mp3" && rm "<filename>"'
