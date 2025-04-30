local Job = require("plenary.job")

local function table_to_set(tab)
    local set = {}
    for _, v in ipairs(tab) do
        set[v] = true
    end
    return set
end

---@param matches table, table to store matches
---@param tab table, table containing elements to search, can be nested
---@param pattern string, regex parttern to match strings on table
---@return table # matches of given pattern
local function table_regex_match(matches, tab, pattern)
    for _, v in pairs(tab) do
        if type(v) == "table" then
            table_regex_match(matches, v, pattern)
        elseif v:match(pattern) then
            table.insert(matches, v:match(pattern))
        end
    end
    return matches
end

---@return table
---@return table
local function get_conda_environments()
    local shell_output = {}
    local conda_envs = {}
    Job:new({
        command = "conda",
        args = {"env", "list"},
        on_stdout = function(_, stdout)
            table.insert(shell_output, stdout)
        end,
        on_exit = function()
            local _conda_envs = table_regex_match({}, shell_output, "^.*[\\/]envs[\\/](.*)$")
            table.insert(conda_envs, "base")
            for _, env in ipairs(_conda_envs) do
                table.insert(conda_envs, env)
            end
        end
    }):sync()
    return conda_envs, table_to_set(conda_envs)
end

local env_list, env_set = get_conda_environments()

return {env_list, env_set}
