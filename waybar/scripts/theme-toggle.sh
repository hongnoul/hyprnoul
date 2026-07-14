#!/usr/bin/env bash
# System dark/light toggle for waybar.
# Flips the three places apps detect the scheme from: gsettings
# (libadwaita/GTK4), gtk-3.0/gtk-4.0 settings.ini, and xsettingsd.
# "status" prints waybar JSON; "toggle" switches and signals the bar.

set -euo pipefail

GTK3=$HOME/.config/gtk-3.0/settings.ini
GTK4=$HOME/.config/gtk-4.0/settings.ini
XSET=$HOME/.config/xsettingsd/xsettingsd.conf
SIGNAL=8

current() {
  [[ $(gsettings get org.gnome.desktop.interface color-scheme) == "'prefer-dark'" ]] \
    && echo dark || echo light
}

status() {
  if [[ $(current) == dark ]]; then
    printf '{"text":"󰖔","class":"dark","tooltip":"Dark mode — click for light"}\n'
  else
    printf '{"text":"󰖨","class":"light","tooltip":"Light mode — click for dark"}\n'
  fi
}

apply() { # $1 = dark|light
  local scheme prefer theme
  if [[ $1 == dark ]]; then
    scheme=prefer-dark  prefer=true  theme=Adwaita-dark
  else
    scheme=prefer-light prefer=false theme=Adwaita
  fi

  gsettings set org.gnome.desktop.interface color-scheme "$scheme"
  gsettings set org.gnome.desktop.interface gtk-theme "$theme"

  local f
  for f in "$GTK3" "$GTK4"; do
    [[ -f $f ]] || continue
    sed -i \
      -e "s/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=$prefer/" \
      -e "s/^gtk-theme-name=.*/gtk-theme-name=$theme/" "$f"
  done

  if [[ -f $XSET ]]; then
    sed -i "s|^Net/ThemeName .*|Net/ThemeName \"$theme\"|" "$XSET"
    pkill -HUP -x xsettingsd 2>/dev/null || true
  fi
}

case ${1:-status} in
  toggle)
    [[ $(current) == dark ]] && apply light || apply dark
    pkill -RTMIN+$SIGNAL -x waybar 2>/dev/null || true
    ;;
  status) status ;;
  *) echo "usage: $0 [status|toggle]" >&2; exit 1 ;;
esac
