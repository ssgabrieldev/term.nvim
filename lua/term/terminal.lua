local utils = require("term.utils")
local vim = vim

---@class Terminal
---@field id integer Unique numeric identifier of the terminal
---@field buf integer|nil ID of the terminal buffer
---@field wins integer[] List containing the ID of windows
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

---Adds a window to the terminal"s window list if valid and not already present
---@param win integer window ID
---@return boolean true if added successfully, false otherwise
function Terminal:window_add(win)
  if not win or not vim.api.nvim_win_is_valid(win) then
    return false
  end

  if vim.tbl_contains(self.wins, win) then
    return false
  end

  table.insert(self.wins, win)
  return true
end

---Removes a window from the terminal"s window list if present
---@param win integer window ID
---@return boolean true if removed successfully, false otherwise
function Terminal:win_remove(win)
  if not win then
    return false
  end

  for i, w in ipairs(self.wins) do
    if w == win then
      table.remove(self.wins, i)
      return true
    end
  end

  return false
end

---Creates or opens the terminal in a specific window or in a split
---@param opts? { win?: integer } Target window ID
function Terminal:open(opts)
  opts = opts or {}
  local target_win = opts.win
  local has_target_win = target_win and vim.api.nvim_win_is_valid(target_win)

  if self.buf and vim.api.nvim_buf_is_valid(self.buf) then
    if has_target_win and target_win then
      self:window_add(target_win)

      vim.api.nvim_win_set_buf(target_win, self.buf)
      vim.api.nvim_set_current_win(target_win)
    elseif not self:is_open() then
      vim.cmd("bo split")
      target_win = vim.api.nvim_get_current_win()

      self:window_add(target_win)
      vim.api.nvim_win_set_buf(target_win, self.buf)
    end
  else
    self.buf = vim.api.nvim_create_buf(false, false)
    vim.bo[self.buf].filetype = "term-nvim"
    vim.bo[self.buf].buflisted = false

    if has_target_win and target_win then
      self:window_add(target_win)

      vim.api.nvim_set_current_win(target_win)
    else
      vim.cmd("bo split")
      target_win = vim.api.nvim_get_current_win()

      self:window_add(target_win)
    end

    vim.api.nvim_win_set_buf(target_win, self.buf)

    vim.api.nvim_create_autocmd({ "WinEnter", "WinLeave", "BufWinEnter", "BufWinLeave" }, {
      buffer = self.buf,
      callback = function()
        local wins_with_buf = utils.list_wins_by_buf(self.buf)

        ---@diagnostic disable-next-line: unused-local
        for i, win in ipairs(wins_with_buf) do
          if not vim.tbl_contains(self.wins, win) then
            self:window_add(win)
          end
        end

        ---@diagnostic disable-next-line: unused-local
        for i, win in ipairs(self.wins) do
          if not vim.tbl_contains(wins_with_buf, win) then
            self:win_remove(win)
          end
        end
      end
    })

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

-- ---Hides the terminal by closing or unlinking the window without destroying the buffer
-- ---@param opts? { silent?: boolean }
-- function Terminal:close(opts)
--   opts = opts or {}
--
--   if self:is_open() then
--     if not opts.silent then
--       vim.api.nvim_win_close(self.wins[1], true)
--
--       if vim.bo.filetype == "term-nvim" then
--         vim.cmd("stopinsert")
--       end
--     end
--
--     self.wins = {}
--   end
-- end

function Terminal:close()
  ---@diagnostic disable-next-line: unused-local
  for i, w in ipairs(self.wins) do
    vim.api.nvim_win_close(w, true)

    if vim.bo.filetype == "term-nvim" then
      vim.cmd("stopinsert")
    end
  end

  self.wins = {}
end

function Terminal:toggle()
  if self:is_open() then
    self:close()
  else
    self:open()
  end
end

return Terminal
