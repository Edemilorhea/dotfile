
# 只在 Windows 上執行，其他平台直接跳過（由 Starship 透過 vendor/autoload 處理）
if $nu.os-info.name != "windows" { return }

let _omp_executable: string = "oh-my-posh"

let _omp_executable_is_path = (
    ($_omp_executable | str contains "/")
    or ($_omp_executable | str contains "\\")
    or ($_omp_executable | str starts-with ".")
    or ($_omp_executable | str starts-with "~")
)

# Exit early if the oh-my-posh executable is not available
if not (($_omp_executable_is_path and ($_omp_executable | path exists)) or (which $_omp_executable | is-not-empty)) { return }

# 智慧偵測 Oh-My-Posh 主題路徑
let _omp_theme_candidates = [
    ($env.POSH_THEMES_PATH? | default "" | path join "M365Princess.omp.json")
    ($env.LOCALAPPDATA? | default "" | path join "Programs/oh-my-posh/themes/M365Princess.omp.json")
    ($nu.home-dir | path join ".config/oh-my-posh/themes/M365Princess.omp.json")
    ($nu.home-dir | path join "AppData/Local/Programs/oh-my-posh/themes/M365Princess.omp.json")
]
let _omp_theme = ($_omp_theme_candidates | where {|p| $p | path exists} | first | default "")
if ($_omp_theme | is-empty) {
    print "⚠️  Oh-My-Posh 主題 M365Princess.omp.json 未找到,使用預設主題"
}

# make sure we have the right prompt render correctly
if ($env.config? | is-not-empty) {
    $env.config = ($env.config | upsert render_right_prompt_on_last_line true)
}

$env.POWERLINE_COMMAND = 'oh-my-posh'
$env.PROMPT_INDICATOR = ""
$env.POSH_SESSION_ID = "e87f7998-38b8-4ffa-bbe7-d49a50ee8de6"
$env.POSH_SHELL = "nu"
$env.POSH_SHELL_VERSION = (version | get version)

# disable all known python virtual environment prompts
$env.VIRTUAL_ENV_DISABLE_PROMPT = 1
$env.PYENV_VIRTUALENV_DISABLE_PROMPT = 1

# PROMPTS

def --wrapped _omp_get_prompt [
    type: string,
    ...args: string
] {
    mut execution_time = -1
    mut no_status = true
    # We have to do this because the initial value of `$env.CMD_DURATION_MS` is always `0823`, which is an official setting.
    # See https://github.com/nushell/nushell/discussions/6402#discussioncomment-3466687.
    if $env.CMD_DURATION_MS != '0823' {
        $execution_time = $env.CMD_DURATION_MS
        $no_status = false
    }

    mut config_arg = []
    if ($_omp_theme | is-not-empty) {
        $config_arg = [$"--config=($_omp_theme)"]
    }
    
    (
        ^$_omp_executable print $type
            --save-cache
            --shell=nu
            ...$config_arg
            $"--shell-version=($env.POSH_SHELL_VERSION)"
            $"--status=($env.LAST_EXIT_CODE)"
            $"--no-status=($no_status)"
            $"--execution-time=($execution_time)"
            $"--terminal-width=((term size).columns)"
            $"--job-count=(job list | length)"
            ...$args
    )
}

def _omp_get_multiline_indicator [] {
    mut config_arg = []
    if ($_omp_theme | is-not-empty) {
        $config_arg = [$"--config=($_omp_theme)"]
    }
    
    (
        ^$_omp_executable print secondary
            --shell=nu
            ...$config_arg
            $"--shell-version=($env.POSH_SHELL_VERSION)"
    )
}

# 🚀 效能優化: 改用靜態字串，避免啟動時同步阻塞 165ms
$env.PROMPT_MULTILINE_INDICATOR = "❯❯ "

$env.PROMPT_COMMAND = {||
    # hack to set the cursor line to 1 when the user clears the screen
    # this obviously isn't bulletproof, but it's a start
    mut clear = false
    if $nu.history-enabled {
        $clear = (history | is-empty) or ((history | last 1 | get --ignore-errors 0.command) == "clear")
    }

    if ($env.SET_POSHCONTEXT? | is-not-empty) {
        do --env $env.SET_POSHCONTEXT
    }

    _omp_get_prompt primary $"--cleared=($clear)"
}

# 🚀 效能優化: 關閉 right prompt，省掉每次 150ms 的 oh-my-posh 呼叫
$env.PROMPT_COMMAND_RIGHT = {|| "" }

