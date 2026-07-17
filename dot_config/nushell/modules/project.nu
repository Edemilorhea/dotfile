# Trusted project commands.
def __project-trust-file [] { $nu.home-dir | path join ".config" "nushell" "trusted-projects.nuon" }
def __project-trusted-roots [] {
    let trust_file = (__project-trust-file)
    if not ($trust_file | path exists) { return [] }
    try { open $trust_file | where { |root| $root | describe | str starts-with "string" } } catch { print $"⚠️ 無法讀取可信專案清單：($trust_file)"; [] }
}
def __project-root [directory: string] {
    let current = try { $directory | path expand --strict } catch { return null }
    __project-trusted-roots | each { |root|
        let canonical_root = try { $root | path expand --strict } catch { return null }
        if $canonical_root == null { return null }
        let relative = ($current | path relative-to $canonical_root)
        let first_component = ($relative | path split | first)
        if $first_component != ".." { $canonical_root } else { null }
    } | compact | sort-by { |root| $root | str length } | last
}
def "project trust" [directory?: string] {
    let requested_root = ($directory | default $env.PWD)
    let root = try { $requested_root | path expand --strict } catch { print $"❌ 無法解析專案路徑：($requested_root)"; return }
    let module = ($root | path join ".nu" "project.nu")
    if not ($module | path exists) { print $"❌ 找不到專案入口：($module)"; return }
    let trusted_roots = (__project-trusted-roots)
    if $root in $trusted_roots { print $"✓ 已信任：($root)"; return }
    (($trusted_roots | append $root) | to nuon) | save --force (__project-trust-file)
    print $"✓ 已信任：($root)"
}
def "project untrust" [directory?: string] {
    let requested_root = ($directory | default $env.PWD)
    let root = try { $requested_root | path expand --strict } catch { print $"❌ 無法解析專案路徑：($requested_root)"; return }
    ((__project-trusted-roots | where { |trusted| $trusted != $root }) | to nuon) | save --force (__project-trust-file)
    print $"✓ 已取消信任：($root)"
}
def "project status" [] {
    let root = (__project-root $env.PWD)
    if $root == null { print "目前不在可信專案內。"; return }
    print $"可信專案：($root)"
    print $"入口：($root | path join '.nu' 'project.nu')"
}
def "project run" [command: string, ...args] {
    let root = (__project-root $env.PWD)
    if $root == null { print "❌ 目前不在可信專案內；請先在專案根目錄執行 `project trust`。"; return }
    let module = ($root | path join ".nu" "project.nu")
    if not ($module | path exists) { print $"❌ 找不到專案入口：($module)"; return }
    ^nu $module $command ...$args
}
def p [command: string, ...args] { project run $command ...$args }
