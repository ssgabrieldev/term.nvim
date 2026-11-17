local vim = vim

---@class Terminal
---@field id integer
---@field buf integer
---@field job integer
local Terminal = {}
Terminal.__index = Terminal

---@param opts {
---  id?: integer,
---  cmd?: string,
---  on_exit?: function,
---}
---@return Terminal
function Terminal:new(opts)
  opts = opts or {}

  local instance = {
    id = opts.id or 1,
    buf = nil,
    job = nil,
  }

  setmetatable(instance, self)

  instance.buf = vim.api.nvim_create_buf(false, false)
  vim.bo[instance.buf].filetype = "term-nvim"
  vim.bo[instance.buf].buflisted = false

  instance.job = vim.api.nvim_buf_call(instance.buf, function()
    return vim.fn.jobstart(opts.cmd or vim.o.shell, {
      term = true,
      on_exit = function()
        if opts.on_exit then
          opts.on_exit(instance)
        end
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

return Terminal
