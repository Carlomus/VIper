local notify = vim.notify

local function req(mod)
    local ok, lib = pcall(require, mod)
    if not ok then
        notify(("VIper: cannot load %s; %s"):format(mod, lib), vim.log.levels.ERROR)
        return nil
    end
    return lib
end

local envs = req("viper.core.envlist") or {}
local lsp_util = req("viper.lsps.utils") or {}
local commands = req("viper.core.commands") or {}

if vim.fn.executable("conda") == 0 then
    notify("VIper: `conda` executable not found in $PATH.", vim.log.levels.WARN)
    return -- stop configuring commands until Conda is available
end

local function table_to_set(tab)
    local set = {}
    for _, v in ipairs(tab) do
        set[v] = true
    end
    return set
end

-- utility: (re-)fetch envs & create set on demand
local function fetch_envs()
    local list = envs.get_conda_environments() -- can be async ⇢ returns list
    return list, table_to_set(list)
end

---@param args string
local function conda_activate(args)
    local env_list, env_set = fetch_envs()
    local name = (args ~= "" and args) or nil

    if name then
        if not env_set[name] then
            notify(("VIper: environment %q does not exist."):format(name), vim.log.levels.WARN)
            return
        end

        local ok, err = pcall(commands.activate, name)
        if not ok then
            notify(("VIper: activate failed: %s"):format(err), vim.log.levels.ERROR)
            return
        end
        pcall(lsp_util.restart_lsps)
    else
        -- no argument → let the user pick interactively
        vim.ui.select(env_list, { prompt = "Activate Conda environment" }, function(choice)
            if not choice then
                return
            end
            conda_activate(choice) -- tail-call with chosen env
        end)
    end
end

vim.api.nvim_create_user_command("CondaActivate", function(opts)
    conda_activate(opts.args)
end, {
    desc = "conda activate <env>.  Without <env>, open an interactive picker.",
    nargs = "?",
    complete = function(arg_lead)
        local env_list = fetch_envs() -- fresh list each completion
        local matches = {}
        for _, env in ipairs(env_list) do
            if env:find("^" .. vim.pesc(arg_lead)) then
                table.insert(matches, env)
            end
        end
        return matches
    end,
})

vim.api.nvim_create_user_command("CondaDeactivate", function()
    local ok, err = pcall(commands.deactivate)
    if not ok then
        notify(("VIper: deactivate failed: %s"):format(err), vim.log.levels.ERROR)
        return
    end
    pcall(lsp_util.restart_lsps)
end, {
    desc = "conda deactivate (stop environment) inside this Neovim session.",
    nargs = 0,
})
