local vim = vim

---@class Terminal
---@field id number Unique numeric identifier of the terminal
---@field buf number|nil ID of the terminal buffer
---@field wins number[] List containing the ID of windows
---@field job number|nil ID of the terminal job/process
---@field cmd string Executed command
local Terminal = {}
Terminal.__index = Terminal

---Constructor to create a new Terminal instance using a parameter dictionary
---@param opts { id: number, cmd?: string } Terminal configuration dictionary
---@return Terminal
function Terminal:new(opts)
  opts = opts or {}
  local instance = {
    id = opts.id or 1,
    buf = nil,
    wins = {},
    job = nil,
    cmd = opts.cmd or vim.o.shell,
  }
  setmetatable(instance, self)
  return instance
end

---@return boolean
function Terminal:is_open()
  return self.wins[1] ~= nil and vim.api.nvim_win_is_valid(self.wins[1])
end

---Creates or opens the terminal in a specific window or in a split
---@param opts? { win?: integer }
function Terminal:open(opts)
  opts = opts or {}
  local target_win = opts.win
  local has_target_win = target_win and vim.api.nvim_win_is_valid(target_win)

  if self.buf and vim.api.nvim_buf_is_valid(self.buf) then
    if has_target_win then
      self.wins[1] = target_win

      vim.api.nvim_win_set_buf(self.wins[1], self.buf)
      vim.api.nvim_set_current_win(target_win)
    elseif not self:is_open() then
      vim.cmd("bo split")

      self.wins[1] = vim.api.nvim_get_current_win()
      vim.api.nvim_win_set_buf(self.wins[1], self.buf)
    end
  else
    self.buf = vim.api.nvim_create_buf(false, false)
    vim.bo[self.buf].filetype = "term-nvim"
    vim.bo[self.buf].buflisted = false

    if has_target_win then
      self.wins[1] = target_win

      vim.api.nvim_set_current_win(self.wins[1])
    else
      vim.cmd("bo split")

      self.wins[1] = vim.api.nvim_get_current_win()
    end

    vim.api.nvim_win_set_buf(self.wins[1], self.buf)

    self.job = vim.fn.termopen(self.cmd, {
      on_exit = function()
        self:close()

        self.job = nil
        self.buf = nil
      end,
    })
  end

  vim.cmd("startinsert")
end

---Hides the terminal by closing or unlinking the window without destroying the buffer
---@param opts? { silent?: boolean }
function Terminal:close(opts)
  opts = opts or {}

  if self:is_open() then
    if not opts.silent then
      vim.api.nvim_win_close(self.wins[1], true)

      if vim.bo.filetype == "term-nvim" then
        vim.cmd("stopinsert")
      end
    end

    self.wins = {}
  end
end

function Terminal:toggle()
  if self:is_open() then
    self:close()
  else
    self:open()
  end
end

return Terminal
