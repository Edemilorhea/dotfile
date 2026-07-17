# Completion, history, menu, and display settings.
$env.config.completions.case_sensitive = false
$env.config.completions.quick = true
$env.config.completions.partial = true
$env.config.completions.algorithm = "fuzzy"
$env.config.completions.external.enable = true
$env.config.completions.external.max_results = 100
$env.config.history.max_size = 100_000
$env.config.history.sync_on_enter = true
$env.config.history.file_format = "sqlite"
$env.config.history.isolation = false
$env.config.menus = [
    { name: completion_menu only_buffer_difference: false marker: "| " type: { layout: columnar, columns: 4, col_width: 20, col_padding: 2 } style: { text: green, selected_text: { attr: r }, description_text: yellow } }
    { name: history_menu only_buffer_difference: false marker: "? " type: { layout: list, page_size: 10 } style: { text: green, selected_text: green_reverse, description_text: yellow } }
]
$env.config.use_ansi_coloring = true
$env.config.show_banner = false
$env.config.bracketed_paste = true
$env.config.render_right_prompt_on_last_line = true
if (which carapace | is-not-empty) {
    $env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'
    let carapace_skip_builtins = [cd ls cp mv rm mkdir open save touch]
    $env.config.completions.external.completer = {|spans|
        if $spans.0 in $carapace_skip_builtins { return null }
        carapace $spans.0 nushell ...$spans | from json
    }
} else {
    print "⚠️  carapace 未安裝"
}
