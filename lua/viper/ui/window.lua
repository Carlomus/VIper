-- modern popup-based picker for Conda environments
local popup = require("plenary.popup")
local M = {}

---Show a centred list of environments; call `cb(choice)` on <CR>.
---@param envs string[]
---@param cb   fun(choice:string)|nil
function M.select_env(envs, cb)
    local height = math.min(#envs + 2, 15)
    local width = 32
    local border = {"─", "│", "─", "│", "╭", "╮", "╯", "╰"}

    local win_id, win = popup.create(envs, {
        title = "Conda environments",
        highlight = "Normal",
        relative = "editor",
        line = math.floor((vim.o.lines - height) / 2),
        col = math.floor((vim.o.columns - width) / 2),
        minwidth = width,
        minheight = height,
        borderchars = border
    })
    local buf = vim.api.nvim_win_get_buf(win_id)

    -- modern option setters (0.10+)
    vim.api.nvim_set_option_value("number", false, {
        win = win_id
    })
    vim.api.nvim_set_option_value("wrap", false, {
        win = win_id
    })
    vim.api.nvim_set_option_value("winhl", "Normal:Normal", {
        win = win.border.win_id
    })
    vim.api.nvim_set_option_value("modifiable", false, {
        buf = buf
    })
    vim.api.nvim_set_option_value("bufhidden", "wipe", {
        buf = buf
    })

    local function close()
        pcall(vim.api.nvim_win_close, win_id, true)
    end

    local function choose()
        local l = vim.api.nvim_win_get_cursor(win_id)[1] -- 1-based
        local text = vim.api.nvim_buf_get_lines(buf, l - 1, l, false)[1]
        close()
        if text and cb then
            cb(text)
        end
    end

    vim.keymap.set("n", "<Esc>", close, {
        buffer = buf,
        nowait = true
    })
    vim.keymap.set("n", "q", close, {
        buffer = buf,
        nowait = true
    })
    vim.keymap.set("n", "<CR>", choose, {
        buffer = buf,
        nowait = true
    })

    local aug = vim.api.nvim_create_augroup("ViperEnvWindow", {
        clear = true
    })

    -- close on buffer leave
    vim.api.nvim_create_autocmd("BufLeave", {
        group = aug,
        buffer = buf,
        once = true,
        callback = close
    })

    -- recreate on window resize
    vim.api.nvim_create_autocmd("VimResized", {
        group = aug,
        callback = function()
            if vim.api.nvim_win_is_valid(win_id) then
                close()
                M.select_env(envs, cb)
            end
        end
    })
end

return M
