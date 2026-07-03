#!/usr/bin/env bash
# fcitx5 input-method indicator for waybar (continuous JSON stream).
# fcitx5 emits no session-bus signal on IM change, so poll cheaply and
# print only when the state changes.

last="__init__"
while :; do
  im=$(fcitx5-remote -n 2>/dev/null)
  if [[ $im != "$last" ]]; then
    last=$im
    case $im in
      hangul) printf '{"text":"한","class":"hangul","tooltip":"한글 (hangul)"}\n' ;;
      "")     printf '{"text":"","tooltip":"fcitx5 not running"}\n' ;;
      *)      printf '{"text":"Ａ","class":"latin","tooltip":"English (%s)"}\n' "$im" ;;
    esac
  fi
  sleep 0.5
done
