local Terminal = require("term.terminal")
local Window = require("term.window")
local Picker = require("term.picker")

---@class OptsOpenTerm
---@field id? integer
---@field cmd? string
---@field on_exit? function(terminal Terminal)

---@class Term
---@field opts table
---@field terms Terminal[]
---@field windows Window[]
local M = {
  opts = {},
  terms = {},
  windows = {}
}

local picker = Picker:new(M.windows)

---@param id integer
---@return Terminal?
local function term_find_by_id(id)
  ---@diagnostic disable-next-line: unused-local
  for i, term in ipairs(M.terms) do
    if id == term.id then
      return term
    end
  end
end

---@param id integer
---@return Terminal?
local function term_remove_by_id(id)
  for i, term in ipairs(M.terms) do
    if term.id == id then
      return table.remove(M.terms, i)
    end
  end
end

---@param id integer
---@return Window?
local function window_find_by_id(id)
  for i, window in ipairs(M.windows) do
    if window.id == id then
      return M.windows[i]
    end
  end
end

---@param id integer
---@return Window?
local function window_remove_by_id(id)
  for i, window in ipairs(M.windows) do
    if window.id == id then
      return table.remove(M.windows, i)
    end
  end
end

---@return integer
local function term_next_id()
  local id = 1

  while true do
    local term = term_find_by_id(id)

    if not term then
      return id
    end

    id = id + 1
  end
end

---@param opts? OptsOpenTerm
---@return Terminal
function M.new(opts)
  opts = opts and vim.tbl_extend("force", M.opts.term, opts) or M.opts.term

  local term = Terminal:new({
    id = (opts.id and opts.id > 0) and opts.id or term_next_id(),
    cmd = opts.cmd,
    on_exit = function(term)
      if opts.on_exit then
        opts.on_exit(term)
      end

      term_remove_by_id(term.id)
    end
  })

  table.insert(M.terms, term)

  return term
end

---@param opts? OptsOpenTerm
---@return Terminal
function M.open(opts)
  opts = opts or {}

  local term = term_find_by_id(opts.id)
  if not term then
    term = M.new(opts)
  end

  local window = M.windows[1]
  if not window then
    window = M.new_window(opts)
  elseif #M.windows > 1 then
    window = picker:pick() or window
  end

  window:set_term(term)

  if not window:is_open() then
    window:open()
  end

  return term
end

---@return nil
function M.pick()
  if #M.terms == 0 then
    vim.notify("No terminals available", vim.log.levels.WARN)
    return
  end

  vim.ui.select(M.terms, {
    prompt = "Select a terminal:",
    format_item = function(term)
      return string.format("Terminal #%d", term.id)
    end,
  }, function(term)
    if not term then
      return
    end

    M.open({ id = term.id })
  end)
end

---@param opts? OptsOpenTerm
function M.new_window(opts)
  opts = opts or {}

  local window = Window:new(function(window)
    ---@diagnostic disable-next-line: unused-local
    for index, win in ipairs(M.windows) do
      if win:is_open() then
        vim.api.nvim_set_current_win(win.id)
        break
      end
    end

    if window.destroy then
      window_remove_by_id(window.id)
    end
  end)

  ---@type Terminal?
  local term
  if opts.id then
    term = term_find_by_id(opts.id)
  else
    term = M.terms[1]
  end

  if not term then
    local term_opts = vim.tbl_extend("force", M.opts.term, opts)
    term = M.new(term_opts)
  end

  table.insert(M.windows, window)

  window:set_term(term)
  window:open()

  ---@type Window[]
  local windows_to_remove = {}
  ---@diagnostic disable-next-line: unused-local
  for index, win in ipairs(M.windows) do
    if not win:is_open() then
      table.insert(windows_to_remove, win)
    end
  end

  ---@diagnostic disable-next-line: unused-local
  for index, win in ipairs(windows_to_remove) do
    window_remove_by_id(win.id)
    win:remove_events()
  end

  return window
end

---@param opts? OptsOpenTerm
function M.toggle_windows(opts)
  if #M.windows == 0 then
    M.new_window(opts)

    return
  end

  ---@diagnostic disable-next-line: unused-local
  for index, window in ipairs(M.windows) do
    window:toggle()
  end
end

---@param opts? table
function M.setup(opts)
  M.opts = vim.tbl_extend("force", {
    term = {}
  }, opts)
end

return M
