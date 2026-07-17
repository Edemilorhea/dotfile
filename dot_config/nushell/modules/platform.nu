# Apply after local.nu so all PATH additions are included.
if ("/proc/version" | path exists) and ((open /proc/version | str downcase | str contains "microsoft")) {
    $env.PATH = ($env.PATH | split row (char esep) | uniq | sort-by { |p| $p | str starts-with "/mnt/c" })
}
