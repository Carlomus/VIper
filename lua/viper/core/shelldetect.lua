---@return string
local function get_running_shell_implementation()
    return vim.o.shell:match("[^/\\]+$")
end

--retrieved from conda activate documentation
--supported shells as of conda 4.11
---@param shell_implement string
---@return string
local function get_shell_type(shell_implement)
    if shell_implement == "cmd.exe" then
        shell_implement = "cmd_exe"
    end
    local possible_shell_types = {
        ash = "posix",
        bash = "posix",
        dash = "posix",
        zsh = "posix",
        csh = "csh",
        tcsh = "csh",
        xonsh = "xonsh",
        cmd_exe = "cmd_exe",
        fish = "fish",
        powershell = "powershell",
        pwsh = "powershell", -- if client is using powershell in Unix
    }

    return possible_shell_types[shell_implement] or "unknown"
end

local shell_implement = get_running_shell_implementation()
local shell_type = get_shell_type(shell_implement)

local M = {
    shell_implement = shell_implement,
    shell_type = shell_type,
}

return M
