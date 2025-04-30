local ok, shell_info = pcall(require, "viper.core.shelldetect")

local M = {}

---@param subcommand string, modify conda function
---@param env_name string?, name of an existing conda environment. If nil,
function M.get_shell_cmds(subcommand, env_name)
    if env_name == nil then
        env_name = ""
    end

    local shell_type = shell_info.shell_type
    local shell_implement = shell_info.shell_implement

    local valid = { activate = true, deactivate = true }
    if not valid[subcommand] then
        return nil, ("invalid subcommand: %s"):format(tostring(subcommand))
    end

    local activator_commands = {
        posix = {
            activate = (
                [[conda shell.]]
                .. shell_implement
                .. [[ activate ]]
                .. env_name
                .. [[ | sed -e 's/export \([^=]*\)=\(.*\)/let \$\1=\2/g']]
                .. " -e 's/^\\([^[:space:]]*\\)=\\(.*\\)/let \\1=\\2/g'"
            ),
            deactivate = (
                [[conda shell.]]
                .. shell_implement
                .. [[ deactivate]]
                .. [[ | sed -e 's/export \([^=]*\)=\(.*\)/let \$\1=\2/g']]
                .. " -e 's/^\\([^[:space:]]*\\)=\\(.*\\)/let \\1=\\2/g'"
                .. [[ -e 's/unset \([^=]*\)/unlet \$\1/g']]
            ),
        },
        csh = {
            activate = (
                [[conda shell.]]
                .. shell_implement
                .. [[ activate ]]
                .. env_name
                .. " | sed -e 's/setenv \\([^[:space:]]*\\) \\(.*\\);/let \\$\\1=\\2/g'"
                .. [[ -e 's/set \([^=]*\)=\(.*\);/let \1=\2/g']]
            ),
            deactivate = (
                [[conda shell.]]
                .. shell_implement
                .. [[ deactivate]]
                .. " | sed -e 's/setenv \\([^[:space:]]*\\) \\(.*\\);/let \\$\\1=\\2/g'"
                .. [[ -e 's/set \([^=]*\)=\(.*\);/let \1=\2/g']]
                .. [[ -e 's/unsetenv \([^=]*\);/unlet \$\1/g']]
            ),
        },
        xonsh = {
            activate = (
                "conda shell."
                .. shell_implement
                .. " activate "
                .. env_name
                .. " | sed -e 's/^/let /g'"
            ),
            deactivate = (
                [[conda shell.]]
                .. shell_implement
                .. [[ deactivate]]
                .. [[ | sed -e 's/del/unlet/g']]
                .. [[ -e 's/\\([^=]*\\) = \\(.*\\)/let \\1 = \\2/g']]
            ),
        },
        cmd_exe = {
            activate = (
                [[powershell -command "Get-Content -Path (Invoke-Expression -Command 'cmd.exe /c conda shell.]]
                .. [[cmd.exe]]
                .. [[ activate ]]
                .. env_name
                .. [[') | ForEach-Object {$_ -replace '^^@SET \"([^^=]+)=(.*)\"', 'let $$$1=\"$2\"'}]]
                .. [[ | ForEach-Object {$_ -replace '\\', '\\'}"]]
            ),
            deactivate = (
                [[powershell -command "Get-Content -Path (Invoke-Expression -Command 'cmd.exe /c conda shell.]]
                .. [[cmd.exe]]
                .. [[ deactivate')]]
                .. [[ | ForEach-Object {$_ -replace '^^@SET \"([^^=]+)=(.*)\"', 'let $$$1=\"$2\"'}]]
                .. [[ | ForEach-Object {$_ -replace '\\', '\\'}"]]
            ),
        },
        fish = {
            activate = (
                [[conda shell.]]
                .. shell_implement
                .. [[ activate ]]
                .. env_name
                .. " | sed -e 's/set -gx \\([^[:space:]]*\\) \\(.*\\);/let \\$\\1=\\2/g'"
                .. [[ -e '/PATH=/ s/\("[^=][:space:]*\)"/:/g']]
            ),
            deactivate = (
                [[conda shell.]]
                .. shell_implement
                .. [[ deactivate]]
                .. " | sed -e 's/set -gx \\([^[:space:]]*\\) \\(.*\\);/let \\$\\1=\\2/g'"
                .. " -e 's/set -e \\([^[:space:]]*\\);/unlet \\$\\1/g'"
                .. [[ -e '/PATH=/ s/\("[^=][:space:]*\)"/:/g']]
            ),
        },
        powershell = {
            activate = (
                [[conda shell.]]
                .. [[powershell]]
                .. [[ activate ]]
                .. env_name
                .. [[ | ForEach-Object {$_ -replace '(.*?):(.*)', 'let $$$2' }]]
                .. [[ | ForEach-Object {$_ -replace '\\', '\\'}]]
            ),
            deactivate = (
                [[conda shell.]]
                .. [[powershell]]
                .. [[ deactivate]]
                .. [[ | ForEach-Object {$_ -replace '(.*?):(.*)', 'let $$$2' }]]
                .. [[ | ForEach-Object {$_ -replace '\\', '\\'}]]
            ),
        },
    }
    return activator_commands[shell_type][subcommand] or nil
end

return M
