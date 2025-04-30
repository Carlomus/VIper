local notify = vim.notify

local function req(mod)
    local ok, lib = pcall(require, mod)
    if not ok or lib == {} then
        notify(("VIper: cannot load %s; %s"):format(mod, lib), vim.log.levels.ERROR)
        return nil
    end
    return lib
end

local envs = req("viper.core.envlist") or {}
local lsp_util = req("viper.lsps.utils") or {}
local commands = req("viper.core.commands") or {}
local ui_window = req("viper.ui.window") or {}

if vim.fn.executable("conda") == 0 then
    notify("VIper: `conda` executable not found in $PATH.", vim.log.levels.WARN)
    return -- stop configuring commands until Conda is available
end

local env_list = envs[1]
local env_set = envs[2]

local function run(cmd_string)
    local lines = vim.fn.systemlist(cmd_string)
    local exit = vim.v.shell_error -- 0 == success

    if exit ~= 0 then
        return false, ("shell returned exit-code %d\n%s"):format(exit, table.concat(lines, "\n"))
    end

    local script = table.concat(lines, "\n")
    local ok, exec_err = pcall(vim.api.nvim_exec2, script, {
        output = false
    })

    if not ok then
        return false, exec_err
    end
    return true
end

---@param args string
local function conda_activate(args)
    local name = (args ~= "" and args) or nil

    if name then
        if not env_set[name] then
            notify(("VIper: environment %q does not exist."):format(name), vim.log.levels.WARN)
            return
        end

        local cmd = commands.get_shell_cmds("activate", name)
        if not cmd then -- `nil, <why>` came back
            notify("VIper: could not obtain command", vim.log.levels.ERROR)
            return
        end

        local ok, run_err = run(cmd)
        if not ok then
            notify(("VIper: activate failed: %s"):format(run_err), vim.log.levels.ERROR)
            return
        end
        pcall(lsp_util.restart_lsps)
        notify("Activated environment: " .. name)
    else
        ui_window.select_env(env_list, vim.env.CONDA_DEFAULT_ENV or "", function(choice)
            if choice then
                conda_activate(choice)
            end
        end)
    end
end

vim.api.nvim_create_user_command("CondaActivate", function(opts)
    conda_activate(opts.args)
end, {
    desc = "conda activate <env>.  Without <env>, open an interactive picker.",
    nargs = "?",
    complete = function(arg_lead)
        local matches = {}
        for _, env in ipairs(env_list) do
            if env:find("^" .. vim.pesc(arg_lead)) then
                table.insert(matches, env)
            end
        end
        return matches
    end
})

vim.api.nvim_create_user_command("CondaDeactivate", function()
    local cmd = commands.get_shell_cmds("deactivate")
    if not cmd then
        notify("VIper: could not deactivate", vim.log.levels.ERROR)
        return
    end

    local ok, run_err = run(cmd)
    if not ok then
        notify(("VIper: deactivate failed: %s"):format(run_err), vim.log.levels.ERROR)
        return
    end
    pcall(lsp_util.restart_lsps)
    notify("Deactivated environment")
end, {
    desc = "conda deactivate (stop environment) inside this Neovim session.",
    nargs = 0
})
