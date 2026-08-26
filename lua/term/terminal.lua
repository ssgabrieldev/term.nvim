local vim = vim

---@class Terminal
---@field id integer Unique numeric identifier of the terminal
---@field buf integer|nil ID of the terminal buffer
---@field job integer|nil ID of the terminal job/process
---@field cmd string Executed command
local Terminal = {}
Terminal.__index = Terminal

---Constructor to create a new Terminal instance using a parameter dictionary
---@param opts { id: integer, cmd?: string } Terminal configuration dictionary
---@return Terminal
function Terminal:new(opts)
  opts = opts or {}
  local instance = {
    id = opts.id or 1,
    buf = nil,
    job = nil,
    cmd = opts.cmd or vim.o.shell,
  }
  setmetatable(instance, self)
  return instance
end

---@return integer[] List containing the ID of windows with terminal buffer
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

---Creates or opens the terminal in a specific window or in a split
---@param opts? { win?: integer, create_win?: boolean } Target window ID
function Terminal:open(opts)
  opts = opts or {}
  local target_win = opts.win
  local has_target_win = target_win and vim.api.nvim_win_is_valid(target_win)

  if self.buf and vim.api.nvim_buf_is_valid(self.buf) then
    if has_target_win and target_win then
      vim.api.nvim_win_set_buf(target_win, self.buf)
      vim.api.nvim_set_current_win(target_win)
    elseif not self:is_open() then
      target_win = vim.api.nvim_open_win(self.buf, true, {
        split = "below",
        vertical = false,
        win = -1,
      })

      vim.api.nvim_win_set_buf(target_win, self.buf)
    end
  else
    self.buf = vim.api.nvim_create_buf(false, false)
    vim.bo[self.buf].filetype = "term-nvim"
    vim.bo[self.buf].buflisted = false

    if has_target_win and target_win then
      vim.api.nvim_set_current_win(target_win)
    else
      target_win = vim.api.nvim_open_win(self.buf, true, {
        split = "below",
        vertical = false,
        win = -1,
      })
    end

    vim.api.nvim_win_set_buf(target_win, self.buf)

    self.job = vim.fn.termopen(self.cmd, {
      on_exit = function()
        self:close()

        self.job = nil
        self.buf = nil
      end,
    })
  end

  vim.cmd("stopinsert")
end

---Hides the terminal by closing or unlinking the window without destroying the buffer
---@param opts? { win?: integer }
function Terminal:close(opts)
  opts = opts or {}

  for _, win in ipairs(self:wins()) do
    if not opts.win or opts.win == win then
      vim.api.nvim_win_close(win, true)

      if vim.bo.filetype == "term-nvim" then
        vim.cmd("stopinsert")
      end
    end
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
