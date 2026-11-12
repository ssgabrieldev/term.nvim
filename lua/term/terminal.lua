local vim = vim

---@class Terminal
---@field id integer
---@field buf integer
---@field job integer
---@field cmd string
---@field on_exit function(term: Terminal)
local Terminal = {}
Terminal.__index = Terminal

---@param opts { id: integer, cmd?: string, on_exit?: function }
---@return Terminal
function Terminal:new(opts)
  opts = opts or {}

  local instance = {
    id = opts.id or 1,
    buf = nil,
    job = nil,
    cmd = opts.cmd or vim.o.shell,
    on_exit = opts.on_exit or function(term) end
  }

  setmetatable(instance, self)

  instance.buf = vim.api.nvim_create_buf(false, false)
  vim.bo[instance.buf].filetype = "term-nvim"
  vim.bo[instance.buf].buflisted = false

  instance.job = vim.api.nvim_buf_call(instance.buf, function()
    return vim.fn.jobstart(instance.cmd, {
      term = true,
      on_exit = function()
        print(instance.buf)
        instance:close()

        instance.on_exit(instance)
      end,
    })
  end)

  return instance
end

---@return integer[]
function Terminal:wins()
  local all_windows = vim.api.nvim_tabpage_list_wins(0)
  local wins = {}

  ---@diagnostic disable-next-line: unused-local
  for i, win in ipairs(all_windows) do
    if self.buf == vim.api.nvim_win_get_buf(win) then
      table.insert(wins, win)
    end
  end

  return wins
end

---@return boolean
function Terminal:is_open()
  return #self:wins() > 0
end

---@param opts? { win?: integer }
function Terminal:open(opts)
  opts = opts or {}

  local win = opts.win
  local has_win = win ~= nil and vim.api.nvim_win_is_valid(win)

  if not has_win then
    win = vim.api.nvim_open_win(self.buf, true, {
      split = "below",
      vertical = false,
    })
  end

  vim.api.nvim_win_set_buf(win, self.buf)
end

function Terminal:close()
  for _, win in ipairs(self:wins()) do
    vim.api.nvim_win_close(win, true)
  end
end

return Terminal
