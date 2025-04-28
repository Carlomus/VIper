local Job = require("plenary.job")

---@param matches table, table to store matches
---@param tab table, table containing elements to search, can be nested
---@param pattern string, regex parttern to match strings on table
---@return table # matches of given pattern
local function table_regex_match(matches, tab, pattern)
    for _, v in pairs(tab) do
        if type(v) == "table" then
            table_regex_match(matches, v, pattern)
        elseif string.match(v, pattern) then
            local match = string.match(v, pattern)
            table.insert(matches, match)
        end
    end
    return matches
end

local M = {}
---@return table
function M.get_conda_environments()
    local shell_output = {}
    local conda_envs = {}
    Job:new({
        command = "conda",
        args = { "env", "list" },
        on_stdout = function(_, stdout)
            table.insert(shell_output, stdout)
        end,
        on_exit = function()
            local _conda_envs = table_regex_match({}, shell_output, "^.*[\\/]envs[\\/](.*)$")
            table.insert(conda_envs, "base")
            for _, env in ipairs(_conda_envs) do
                table.insert(conda_envs, env)
            end
        end,
    }):start()
    return conda_envs
end

return M
