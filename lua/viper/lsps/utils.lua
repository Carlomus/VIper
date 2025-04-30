local M = {}

---@return string? # lsp client name
function M.get_active_lsp_client()
    local lspconfig_status, _ = pcall(require, "lspconfig")
    if lspconfig_status then
        return "lspconfig"
    else
        return nil
    end
end

---@return nil
function M.restart_lsps()
    local lsp_client = M.get_active_lsp_client()
    if lsp_client == "lspconfig" then
        require("viper.lsps.lspconfig"):restart_lsps()
    else
        return nil
    end
end

return M
