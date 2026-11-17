---@class Panel
---@field win? integer
---@field terms Terminal
---@field on_win_close function(panel Panel)
---@field destroy boolean
---@field term Terminal[]
local Panel = {}
Panel.__index = Panel

---@param terms Terminal[]
---@param on_win_close function(panel Panel)
---@return Panel
function Panel:new(terms, on_win_close)
  local instance = {
    id = nil,
    terms = terms,
    destory = false,
    on_win_close = on_win_close
  }

  setmetatable(instance, self)

  return instance
end

---@param term Terminal
function Panel:set_term(term)
  self.terms = term

  if self.win then
    vim.api.nvim_win_set_buf(self.win, self.terms.buf)
  end
end

function Panel:is_open()
  return self.win and vim.api.nvim_win_is_valid(self.win)
end

function Panel:open()
  self.destroy = true

  if not self:is_open() then
    self.win = vim.api.nvim_open_win(self.terms.buf, true, {
      split = "below",
      vertical = false,
    })

    local aucmd_id

    aucmd_id = vim.api.nvim_create_autocmd("WinClosed", {
      callback = function(args)
        if tonumber(args.match) == self.win then
          self:on_win_close(self)

          vim.api.nvim_del_autocmd(aucmd_id)
        end
      end,
    })
  end
end

function Panel:close()
  self.destroy = false

  if self:is_open() then
    vim.api.nvim_win_close(self.win, true)
  end
end

function Panel:toggle()
  if self:is_open() then
    self:close()
  else
    self:open()
  end
end

return Panel
