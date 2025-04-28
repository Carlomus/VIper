local M = {}

---@param tab table, table containing elements to search, can be nested
---@param search_value string, string to search for
---@return boolean, string? # lowest key of searched value if found
function M.has_value(tab, search_value)
    for k, v in pairs(tab) do
        if type(v) == "table" then
            if M.has_value(v, search_value) then
                return true, k
            end
        elseif v == search_value then
            return true, k
        end
    end
    return false, nil
end

return M
