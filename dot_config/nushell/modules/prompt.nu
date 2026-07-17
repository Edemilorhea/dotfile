# Prompt
if ($env.OPENCODE_SESSION? | is-not-empty) {
    $env.PROMPT_COMMAND = {||
        let path_segment = ($env.PWD | str replace $nu.home-dir "~")
        $"(ansi green_bold)❯(ansi reset) (ansi cyan)($path_segment)(ansi reset) "
    }
    $env.PROMPT_COMMAND_RIGHT = {|| "" }
    $env.PROMPT_INDICATOR = ""
    $env.PROMPT_MULTILINE_INDICATOR = "::: "
} else if $nu.os-info.name == "windows" {
    if (which oh-my-posh | is-not-empty) {
        $env.POWERLINE_COMMAND = "oh-my-posh"
        $env.PROMPT_INDICATOR = ""
        $env.POSH_SESSION_ID = "e87f7998-38b8-4ffa-bbe7-d49a50ee8de6"
        $env.POSH_SHELL = "nu"
        $env.POSH_SHELL_VERSION = (version | get version)
        $env.VIRTUAL_ENV_DISABLE_PROMPT = 1
        $env.PYENV_VIRTUALENV_DISABLE_PROMPT = 1
        $env.PROMPT_MULTILINE_INDICATOR = "❯❯ "
        $env.PROMPT_COMMAND = {||
            if ($env.SET_POSHCONTEXT? | is-not-empty) { do --env $env.SET_POSHCONTEXT }
            mut config_arg = []
            if ($env.POSH_THEMES_PATH? | is-not-empty) {
                let t = ($env.POSH_THEMES_PATH | path join "M365Princess.omp.json")
                if ($t | path exists) { $config_arg = [$"--config=($t)"] }
            }
            (^oh-my-posh print primary --save-cache --shell=nu ...$config_arg $"--shell-version=($env.POSH_SHELL_VERSION)" $"--status=($env.LAST_EXIT_CODE)" "--no-status=false" $"--execution-time=($env.CMD_DURATION_MS)" $"--terminal-width=((term size).columns)" $"--job-count=(job list | length)" "--cleared=false")
        }
        $env.PROMPT_COMMAND_RIGHT = {|| "" }
    }
}
