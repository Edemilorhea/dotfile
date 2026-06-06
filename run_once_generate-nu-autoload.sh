#!/bin/bash
# Auto-generate nushell vendor/autoload scripts
# run_once: only runs when this file content changes

mkdir -p ~/.local/share/nushell/vendor/autoload

if command -v starship &>/dev/null; then
  starship init nu > ~/.local/share/nushell/vendor/autoload/starship.nu
fi

if command -v zoxide &>/dev/null; then
  zoxide init nushell > ~/.local/share/nushell/vendor/autoload/zoxide.nu
fi

if command -v atuin &>/dev/null; then
  atuin init nu > ~/.local/share/nushell/vendor/autoload/atuin.nu
fi
