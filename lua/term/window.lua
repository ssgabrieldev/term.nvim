---@class Window
---@field id? integer
---@field aucmdid integer
---@field term Terminal
---@field destroy boolean
local Window = {}
Window.__index = Window

---@param on_win_close? function(window Window)
---@return Window
function Window:new(on_win_close)
  on_win_close = on_win_close or function(window) end

  local instance = setmetatable({
    id = nil,
    aucmdid = nil,
    term = nil,
    destroy = false,
  }, self)

  instance.aucmdid = vim.api.nvim_create_autocmd("WinClosed", {
    callback = function(args)
      if instance.id and tonumber(args.match) == instance.id then
        if on_win_close then
          on_win_close(instance)
        end

        if instance.destroy then
          instance:remove_events()
        end
      end
    end
  })

  return instance
end

---@param term Terminal
function Window:set_term(term)
  self.term = term

  if self:is_open() then
    vim.wo[self.id].winfixbuf = false
    vim.api.nvim_win_set_buf(self.id, self.term.buf)
    vim.wo[self.id].winfixbuf = true
    vim.wo[self.id].number = false
  end
end

function Window:remove_events()
  vim.api.nvim_del_autocmd(self.aucmdid)
end

---@return boolean
function Window:is_open()
  return not not (self.id and vim.api.nvim_win_is_valid(self.id))
end

---@return nil
function Window:open()
  self.destroy = true

  if not self:is_open() then
    self.id = vim.api.nvim_open_win(self.term.buf, true, {
      split = "below",
      vertical = false,
    })
  end

  vim.wo[self.id].winfixbuf = true
  vim.wo[self.id].number = false
  vim.wo[self.id].relativenumber = false

  vim.cmd("startinsert")
end

---@return nil
function Window:close()
  self.destroy = false

  if self:is_open() then
    vim.api.nvim_win_close(self.id, true)
  end
end

---@return nil
function Window:toggle()
  if self:is_open() then
    self:close()
  else
    self:open()
  end
end

return Window
