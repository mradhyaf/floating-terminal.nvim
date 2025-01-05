local terminals = require("terminals")
local usercmd = vim.api.nvim_create_user_command

usercmd("Tman",
function()
    terminals.show()
end,
{})

usercmd("TmanHide",
function()
    terminals.hide()
end,
{})
