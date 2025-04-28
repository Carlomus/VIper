local M = {}

---@return string? # lsp client name
M.get_active_lsp_client = function()
    local lspconfig_status, _ = pcall(require, "lspconfig")
    if lspconfig_status then
        return "lspconfig"
    else
        return nil
    end
end

---@return nil
M.restart_lsps = function()
    local lsp_client = M.get_active_lsp_client()

    if lsp_client == "lspconfig" then
        require("conda.lsps.lspconfig"):restart_lsps()
    else
        return nil
    end
end

return M
