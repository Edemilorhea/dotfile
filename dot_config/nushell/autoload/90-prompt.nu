# Load the managed prompt after vendor integrations so prompt ownership is deterministic.
const prompt_module = ($nu.default-config-dir | path join "modules" "prompt.nu")
source $prompt_module
