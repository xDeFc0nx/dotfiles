#!/usr/bin/env bash

QUICKSHELL_CONFIG_NAME="ii"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_DIR="$XDG_CONFIG_HOME/quickshell/$QUICKSHELL_CONFIG_NAME"
CACHE_DIR="$XDG_CACHE_HOME/quickshell"
STATE_DIR="$XDG_STATE_HOME/quickshell"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

term_alpha=100 #Set this to < 100 make all your terminals transparent
# sleep 0 # idk i wanted some delay or colors dont get applied properly
if [ ! -d "$STATE_DIR"/user/generated ]; then
  mkdir -p "$STATE_DIR"/user/generated
fi
cd "$CONFIG_DIR" || exit

colornames=''
colorstrings=''
colorlist=()
colorvalues=()

colornames=$(grep -E '^[[:space:]]*\$' "$STATE_DIR/user/generated/material_colors.scss" | cut -d: -f1 | tr -d '\r\t ')
colorstrings=$(grep -E '^[[:space:]]*\$' "$STATE_DIR/user/generated/material_colors.scss" | cut -d: -f2 | tr -d '\r\t ;' | cut -d '/' -f1)
IFS=$'\n'
colorlist=($colornames)     # Array of color names
colorvalues=($colorstrings) # Array of color values

apply_kitty() {  
  # Check if terminal escape sequence template exists
  if [ ! -f "$SCRIPT_DIR/terminal/kitty-theme.conf" ]; then
    echo "Template file not found for Kitty theme. Skipping that."
    return
  fi
  # Copy template
  mkdir -p "$STATE_DIR"/user/generated/terminal
  cp "$SCRIPT_DIR/terminal/kitty-theme.conf" "$STATE_DIR"/user/generated/terminal/kitty-theme.conf
  # Apply colors
  for i in "${!colorlist[@]}"; do
    local clean_name="${colorlist[$i]#\$}"
    local camel_name=$(echo "$clean_name" | sed -E 's/_([a-z])/\U\1/g')
    sed -i "s/${colorlist[$i]} #/${colorvalues[$i]#\#}/g" "$STATE_DIR"/user/generated/terminal/kitty-theme.conf
    sed -i "s/#${clean_name}#/${colorvalues[$i]}/g" "$STATE_DIR"/user/generated/terminal/kitty-theme.conf
    sed -i "s/#${camel_name}#/${colorvalues[$i]}/g" "$STATE_DIR"/user/generated/terminal/kitty-theme.conf
  done

  # Reload
  if ! pgrep -f kitty >/dev/null; then
    return
  fi
  kill -SIGUSR1 $(pidof kitty)
}

apply_alacritty() {
  if [ ! -f "$SCRIPT_DIR/terminal/alacritty-theme.toml" ]; then
    echo "Template file not found for Alacritty theme. Skipping that."
    return
  fi
  mkdir -p "$STATE_DIR"/user/generated/terminal
  cp "$SCRIPT_DIR/terminal/alacritty-theme.toml" "$STATE_DIR"/user/generated/terminal/alacritty-theme.toml
  
  for i in "${!colorlist[@]}"; do
    local clean_name="${colorlist[$i]#\$}"
    local camel_name=$(echo "$clean_name" | sed -E 's/_([a-z])/\U\1/g')
    sed -i "s/${colorlist[$i]} #/${colorvalues[$i]#\#}/g" "$STATE_DIR"/user/generated/terminal/alacritty-theme.toml
    sed -i "s/#${clean_name}#/${colorvalues[$i]}/g" "$STATE_DIR"/user/generated/terminal/alacritty-theme.toml
    sed -i "s/#${camel_name}#/${colorvalues[$i]}/g" "$STATE_DIR"/user/generated/terminal/alacritty-theme.toml
  done

  mkdir -p "$XDG_CONFIG_HOME/alacritty"
  cp "$STATE_DIR/user/generated/terminal/alacritty-theme.toml" "$XDG_CONFIG_HOME/alacritty/alacritty.toml"
}

apply_ghostty() {
  if [ ! -f "$SCRIPT_DIR/terminal/ghostty-theme.conf" ]; then
    echo "Template file not found for Ghostty theme. Skipping that."
    return
  fi
  mkdir -p "$STATE_DIR"/user/generated/terminal
  cp "$SCRIPT_DIR/terminal/ghostty-theme.conf" "$STATE_DIR"/user/generated/terminal/ghostty-theme.conf
  for i in "${!colorlist[@]}"; do
    local clean_name="${colorlist[$i]#\$}"
    local camel_name=$(echo "$clean_name" | sed -E 's/_([a-z])/\U\1/g')
    sed -i "s/${colorlist[$i]} #/${colorvalues[$i]#\#}/g" "$STATE_DIR"/user/generated/terminal/ghostty-theme.conf
    sed -i "s/#${clean_name}#/${colorvalues[$i]}/g" "$STATE_DIR"/user/generated/terminal/ghostty-theme.conf
    sed -i "s/#${camel_name}#/${colorvalues[$i]}/g" "$STATE_DIR"/user/generated/terminal/ghostty-theme.conf
  done
}

apply_starship() {
  if [ ! -f "$SCRIPT_DIR/terminal/starship.toml" ]; then
    echo "Template file not found for Starship. Skipping that."
    return
  fi
  mkdir -p "$STATE_DIR"/user/generated/terminal
  cp "$SCRIPT_DIR/terminal/starship.toml" "$STATE_DIR"/user/generated/terminal/starship.toml
  for i in "${!colorlist[@]}"; do
    local clean_name="${colorlist[$i]#\$}"
    local camel_name=$(echo "$clean_name" | sed -E 's/_([a-z])/\U\1/g')
    sed -i "s/${colorlist[$i]} #/${colorvalues[$i]#\#}/g" "$STATE_DIR"/user/generated/terminal/starship.toml
    sed -i "s/#${clean_name}#/${colorvalues[$i]}/g" "$STATE_DIR"/user/generated/terminal/starship.toml
    sed -i "s/#${camel_name}#/${colorvalues[$i]}/g" "$STATE_DIR"/user/generated/terminal/starship.toml
  done

  mkdir -p "$XDG_CONFIG_HOME"
  cp "$STATE_DIR"/user/generated/terminal/starship.toml "$XDG_CONFIG_HOME/starship.toml"
  kill -WINCH $(pgrep -f fish) 2>/dev/null || true
}

apply_anyterm() {
  # Check if terminal escape sequence template exists
  if [ ! -f "$SCRIPT_DIR/terminal/sequences.txt" ]; then
    echo "Template file not found for Terminal. Skipping that."
    return
  fi
  # Copy template
  mkdir -p "$STATE_DIR"/user/generated/terminal
  cp "$SCRIPT_DIR/terminal/sequences.txt" "$STATE_DIR"/user/generated/terminal/sequences.txt
  # Apply colors
  for i in "${!colorlist[@]}"; do
    local clean_name="${colorlist[$i]#\$}"
    local camel_name=$(echo "$clean_name" | sed -E 's/_([a-z])/\U\1/g')
    sed -i "s/${colorlist[$i]} #/${colorvalues[$i]#\#}/g" "$STATE_DIR"/user/generated/terminal/sequences.txt
    sed -i "s/#${clean_name}#/${colorvalues[$i]}/g" "$STATE_DIR"/user/generated/terminal/sequences.txt
    sed -i "s/#${camel_name}#/${colorvalues[$i]}/g" "$STATE_DIR"/user/generated/terminal/sequences.txt
  done

  sed -i "s/\$alpha/$term_alpha/g" "$STATE_DIR/user/generated/terminal/sequences.txt"

  for file in /dev/pts/*; do
    if [[ $file =~ ^/dev/pts/[0-9]+$ ]]; then
      {
      cat "$STATE_DIR"/user/generated/terminal/sequences.txt >"$file"
      } & disown || true
    fi
  done
}

apply_term() {
  apply_anyterm &
  apply_kitty &
  apply_alacritty &
  apply_ghostty &
  apply_starship &
}

# Check if terminal theming is enabled in config
CONFIG_FILE="$XDG_CONFIG_HOME/illogical-impulse/config.json"
if [ -f "$CONFIG_FILE" ]; then
  enable_terminal=$(jq -r '.appearance.wallpaperTheming.enableTerminal' "$CONFIG_FILE")
  if [ "$enable_terminal" = "true" ]; then
    apply_term &
  fi
else
  echo "Config file not found at $CONFIG_FILE. Applying terminal theming by default."
  apply_term &
fi

# apply_qt & # Qt theming is already handled by kde-material-colors
