local popup = require("plenary.popup")

local M = {}

-- Helpers
local function center(width, height)
    return {
        line = math.floor(((vim.o.lines - height) / 2) - 1),
        col = math.floor((vim.o.columns - width) / 2),
    }
end

local function buf_map(buf, mode, lhs, rhs, opts)
    opts = vim.tbl_extend("keep", opts or {}, { silent = true, buffer = buf })
    vim.keymap.set(mode, lhs, rhs, opts)
end

---@param lines  string[]                text shown in the menu
---@param opts?  table                   extra popup-create options
---@param cb?    fun(line:string, idx:number)|nil  called on <CR>
---@return integer win_id                id of the created window
function M.env_activation_menu(lines, opts, cb)
    opts = vim.tbl_extend("force", {
        title = "Conda Activate",
        highlight = "Normal",
        relative = "editor",
        minwidth = 24,
        minheight = 8,
        borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
        enter = true, -- focus the window
    }, opts or {})

    local pos = center(opts.minwidth, opts.minheight)
    opts.line = pos.line
    opts.col = pos.col

    local win_id, win = popup.create(lines, opts)
    local border_win_id = win and win.border and win.border.win_id
    local bufnr = vim.api.nvim_win_get_buf(win_id)

    -- ░ Window & buffer options ░───────────────────────────────────
    vim.wo[win_id].number = false
    vim.wo[win_id].wrap = false

    if border_win_id and vim.api.nvim_win_is_valid(border_win_id) then
        vim.wo[border_win_id].winhl = "Normal:Normal"
    end

    vim.bo[bufnr].modifiable = false
    vim.bo[bufnr].bufhidden = "wipe"

    buf_map(bufnr, "n", { "q", "<Esc>" }, function()
        M.close_menu(win_id)
    end)
    buf_map(bufnr, "n", "<CR>", function()
        local line = vim.api.nvim_get_current_line()
        local idx = vim.fn.line(".")
        if cb then
            cb(line, idx)
        end
        M.close_menu(win_id)
    end)

    local aug = vim.api.nvim_create_augroup("CondaEnvMenu", { clear = false })

    vim.api.nvim_create_autocmd({ "BufLeave", "WinClosed" }, {
        group = aug,
        buffer = bufnr,
        once = true,
        callback = function()
            M.close_menu(win_id)
        end,
    })

    vim.api.nvim_create_autocmd("VimResized", {
        group = aug,
        once = true,
        callback = function()
            if vim.api.nvim_win_is_valid(win_id) then
                M.close_menu(win_id)
            end
            M.env_activation_menu(lines, opts, cb)
        end,
    })

    return win_id
end

function M.close_menu(id)
    if id and vim.api.nvim_win_is_valid(id) then
        vim.api.nvim_win_close(id, true)
    end
end

return M
