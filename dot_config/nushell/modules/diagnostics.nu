# Optional command and startup diagnostics.
let __nu_command_log_enabled = (($env.NU_COMMAND_LOG? | default "0") == "1")
let __nu_command_log_path = ($nu.home-dir | path join "nu_cmd.log")
if $__nu_command_log_enabled {
    $env.config.hooks.pre_execution = ($env.config.hooks.pre_execution? | default [] | append {||
        let command = (commandline)
        let timestamp = (date now | format date "%Y-%m-%dT%H:%M:%S%.3f%z")
        $"[START] ($timestamp) ($command)\n" | save --append $__nu_command_log_path
    })
    $env.config.hooks.pre_prompt = ($env.config.hooks.pre_prompt? | default [] | append {||
        let timestamp = (date now | format date "%Y-%m-%dT%H:%M:%S%.3f%z")
        $"[END]   ($timestamp)\n" | save --append $__nu_command_log_path
    })
}
let __nu_startup_debug_enabled = (($env.NU_STARTUP_DEBUG? | default "0") == "1")
let __nu_startup_log_path = ($nu.home-dir | path join "nu-startup-debug.log")
if $__nu_startup_debug_enabled {
    let timestamp = (date now | format date "%Y-%m-%dT%H:%M:%S%.3f%z")
    $"[CONFIG_ENTER] ($timestamp)\n" | save --append $__nu_startup_log_path
    $env.config.hooks.pre_prompt = ($env.config.hooks.pre_prompt? | default [] | append {||
        let ready_timestamp = (date now | format date "%Y-%m-%dT%H:%M:%S%.3f%z")
        $"[PROMPT_READY] ($ready_timestamp)\n" | save --append $__nu_startup_log_path
    })
}
