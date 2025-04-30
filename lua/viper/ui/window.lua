-- modern popup-based picker for Conda environments
local popup = require("plenary.popup")
local M = {}

---Show a centred list of environments; call `cb(choice)` on <CR>.
---@param envs string[]
---@param active string
---@param cb   fun(choice:string)|nil
function M.select_env(envs, active, cb)
    local lines = {}
    for i, name in ipairs(envs) do
        lines[i] = (name == active) and (" " .. name .. "  (active)") -- checked icon
            or (" " .. name) -- bullet icon
    end

    local height = math.min(#lines + 2, 15)
    local width = 32
    local border = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }

    local win_id, win = popup.create(lines, {
        title = "Conda environments",
        highlight = "Normal",
        relative = "editor",
        line = math.floor((vim.o.lines - height) / 2),
        col = math.floor((vim.o.columns - width) / 2),
        minwidth = width,
        minheight = height,
        borderchars = border,
    })
    local buf = vim.api.nvim_win_get_buf(win_id)

    -- modern option setters (0.10+)
    vim.api.nvim_set_option_value("number", false, {
        win = win_id,
    })
    vim.api.nvim_set_option_value("wrap", false, {
        win = win_id,
    })
    vim.api.nvim_set_option_value("winhl", "Normal:Normal", {
        win = win.border.win_id,
    })
    vim.api.nvim_set_option_value("modifiable", false, {
        buf = buf,
    })
    vim.api.nvim_set_option_value("bufhidden", "wipe", {
        buf = buf,
    })

    local function close()
        pcall(vim.api.nvim_win_close, win_id, true)
    end

    local function choose()
        local row = vim.api.nvim_win_get_cursor(win_id)[1]
        local text = envs[row] -- no icons, exact name
        close()
        if text and cb then
            cb(text)
        end
    end

    vim.keymap.set("n", "<Esc>", close, {
        buffer = buf,
        nowait = true,
    })
    vim.keymap.set("n", "q", close, {
        buffer = buf,
        nowait = true,
    })
    vim.keymap.set("n", "<CR>", choose, {
        buffer = buf,
        nowait = true,
    })

    local aug = vim.api.nvim_create_augroup("ViperEnvWindow", {
        clear = true,
    })

    -- close on buffer leave
    vim.api.nvim_create_autocmd("BufLeave", {
        group = aug,
        buffer = buf,
        once = true,
        callback = close,
    })

    -- recreate on window resize
    vim.api.nvim_create_autocmd("VimResized", {
        group = aug,
        callback = function()
            if vim.api.nvim_win_is_valid(win_id) then
                close()
                M.select_env(envs, cb)
            end
        end,
    })
end

return M
