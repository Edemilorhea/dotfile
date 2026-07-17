# External tool integration.
def refresh-shell-integrations [] {
    let autoload_dir = ($nu.vendor-autoload-dirs | last)
    mkdir $autoload_dir

    if (which zoxide | is-not-empty) {
        let zoxide_autoload = ($autoload_dir | path join "zoxide.nu")
        ^zoxide init nushell | save --force $zoxide_autoload
        print $"✅ 已更新 ($zoxide_autoload)"
    } else {
        print "⚠️  zoxide 未安裝，已略過"
    }

    if (which atuin | is-not-empty) {
        let atuin_autoload = ($autoload_dir | path join "atuin.nu")
        ^atuin init nu | save --force $atuin_autoload
        print $"✅ 已更新 ($atuin_autoload)"
    } else {
        print "⚠️  atuin 未安裝，已略過"
    }

    print "請重新開啟 Nushell 以載入更新後的整合腳本。"
}

let __vendor_autoload_dir = ($nu.vendor-autoload-dirs | last)
let __zoxide_autoload = ($__vendor_autoload_dir | path join "zoxide.nu")
let __atuin_autoload = ($__vendor_autoload_dir | path join "atuin.nu")

if (which zoxide | is-empty) {
    print "⚠️  zoxide 未安裝"
} else if not ($__zoxide_autoload | path exists) {
    print "ℹ️  zoxide 整合尚未生成；請執行 refresh-shell-integrations"
}

if (which atuin | is-empty) {
    print "⚠️  atuin 未安裝"
} else if not ($__atuin_autoload | path exists) {
    print "ℹ️  Atuin 整合尚未生成；請執行 refresh-shell-integrations"
}

let fnm_bin = ($nu.home-dir | path join ".local" "bin" "fnm")
if ($nu.os-info.name != "windows") and ($fnm_bin | path exists) {
    let fnm_vars = (^$fnm_bin env --shell bash | lines | where { |l| $l | str starts-with "export " } | parse 'export {name}="{value}"' | where name != "PATH" | reduce --fold {} { |it, acc| $acc | upsert $it.name $it.value })
    load-env $fnm_vars
    $env.PATH = ($env.PATH | prepend $"($fnm_vars.FNM_MULTISHELL_PATH)/bin")
    with-env $fnm_vars { ^$fnm_bin use default --install-if-missing | ignore }
}
