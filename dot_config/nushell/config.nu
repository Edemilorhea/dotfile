# config.nu — composition root. Environment variables and PATH stay in env.nu.
source ~/.config/nushell/modules/commands.nu
source ~/.config/nushell/modules/project.nu
source ~/.config/nushell/modules/aliases.nu
source ~/.config/nushell/modules/keybindings.nu
source ~/.config/nushell/modules/interface.nu
source ~/.config/nushell/modules/tools.nu
source ~/.config/nushell/modules/diagnostics.nu

# Prompt is loaded from autoload/90-prompt.nu after vendor integrations.

# Machine-local aliases and functions; env.nu ensures this file exists.
source ~/.config/nushell/local.nu
source ~/.config/nushell/modules/platform.nu

let __user = ($env.USERNAME? | default ($env.USER? | default "User"))
print $"\n🕐 (date now | format date '%Y-%m-%d %H:%M:%S')  |  🐚 Nushell (version | get version)  |  👤 ($__user)\n"
