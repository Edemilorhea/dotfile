# Keybindings
$env.config.keybindings ++= [
    { name: fzf_history modifier: control_alt keycode: char_r mode: [emacs vi_normal vi_insert] event: { send: executehostcommand cmd: "commandline edit (history | get command | reverse | uniq | str join (char -i 0) | fzf --read0 --layout=reverse --height=40% --scheme=history --tiebreak=begin | str trim)" } }
    { name: accept_suggestion modifier: alt keycode: char_f mode: [emacs vi_insert] event: { send: HistoryHintWordComplete } }
    { name: fzf_files modifier: control keycode: char_f mode: [emacs vi_normal vi_insert] event: { send: executehostcommand cmd: "let __file = (if (which fd | is-not-empty) { ^fd --type f --hidden --exclude .git | lines } else { glob '**/*' --depth 4 | where { |p| ($p | path type) == 'file' } | each { |p| $p | path relative-to $env.PWD } } | str join (char -i 0) | fzf --read0 --layout=reverse --height=40% --prompt 'FILE > ' | str trim); if ($__file | is-not-empty) { commandline edit $__file }" } }
    { name: fzf_cd modifier: alt keycode: char_c mode: [emacs vi_normal vi_insert] event: { send: executehostcommand cmd: "let __dir = (if (which fd | is-not-empty) { ^fd --type d --hidden --exclude .git | lines } else { glob '**/*' --depth 4 | where { |p| ($p | path type) == 'dir' } | each { |p| $p | path relative-to $env.PWD } } | str join (char -i 0) | fzf --read0 --layout=reverse --height=40% --prompt 'CD > ' | str trim); if ($__dir | is-not-empty) { cd $__dir }" } }
    { name: accept_next_word modifier: none keycode: end mode: [emacs vi_insert] event: { send: HistoryHintWordComplete } }
    { name: completion_menu modifier: none keycode: tab mode: [emacs vi_normal vi_insert] event: { until: [{ send: menu name: completion_menu } { send: menunext } { edit: complete }] } }
]
