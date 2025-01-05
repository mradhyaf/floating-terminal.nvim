-- namespaces
local a = vim.api
local autocmd = a.nvim_create_autocmd
local M = {}

-- variables
local term_data = {}
local win_opts = {
    number = false,
    relativenumber = false,
}

local gen_win_conf = function()
    local max_w = a.nvim_get_option_value("columns", {})
    local max_h = a.nvim_get_option_value("lines", {})

    local pad_x = 10
    local pad_y = 5

    return {
        relative = "editor",
        row = pad_y,
        col = pad_x,
        width = max_w - (2 * pad_x),
        height = max_h - (2 * pad_y),
    }
end

local new_buf = function()
    local bid = a.nvim_create_buf(false, false)
    if bid == 0 then return end

    autocmd({ "WinLeave", "TermLeave" }, {
        desc = "Close on leaving floating window",
        buffer = bid,
        callback = function()
            M.hide()
        end
    })

    autocmd({ "TermClose" }, {
        desc = "Delete buffer when terminal is closed",
        buffer = bid,
        callback = function()
            term_data.bid = nil
            M.hide()
            a.nvim_buf_delete(bid, { unload = true })
        end
    })

    autocmd({ "BufUnload", "BufDelete", "BufWipeout" }, {
        desc = "Clear data if buffer is deleted somehow",
        buffer = bid,
        callback = function()
            term_data.bid = nil
        end
    })

    autocmd({ "VimResized" }, {
        desc = "Auto-resize with Vim",
        buffer = bid,
        callback = function()
            a.nvim_win_set_config(term_data.wid, gen_win_conf())
        end
    })

    autocmd({ "TermOpen", "BufWinEnter" }, {
        desc = "Enter insert mode",
        buffer = bid,
        callback = function()
            a.nvim_cmd({ cmd = "startinsert" }, {})
        end
    })

    return bid
end

M.show = function()
    if term_data.wid ~= nil then return end

    local isNewBuf = term_data.bid == nil
    term_data.bid = term_data.bid or new_buf()
    if term_data.bid == nil then
        print("Tman: unable to create a new buffer")
        return
    end

    term_data.wid = a.nvim_open_win(term_data.bid, true, gen_win_conf())
    if term_data.wid == 0 then
        term_data.wid = nil
        print("Tman: unable to open a window")
        return
    end

    if isNewBuf then
        local cid = vim.fn.termopen(vim.o.shell)
        if cid <= 0 then
            print("Tman: unable to start terminal")
            return
        end
    end

    for k, v in pairs(win_opts) do
        a.nvim_set_option_value(k, v, { win = term_data.wid })
    end
end

M.hide = function()
    if term_data.wid == nil then return end

    a.nvim_win_close(term_data.wid, false)
    term_data.wid = nil
end

return M
