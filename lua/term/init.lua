local Terminal = require("term.terminal")
local vim = vim

local M = {}

---Internal table to map the numeric ID to its respective Terminal instance
---@type table<integer, Terminal>
M._terminals = {}

---Internal table to map the numeric ID to its respective Terminal instance
---@type table<Terminal>
M._togglable_terminals = {}

---Internal table to map the numeric ID to its respective Terminal instance
---@return integer
local function get_available_id()
  local id = 1

  while M._terminals[id] ~= nil do
    id = id + 1
  end

  return id
end

---Returns the list of terminals, with an option to filter for only those with a valid window.
---@param opts? { active_only?: boolean }
---@return Terminal[]
function M.list(opts)
  opts = opts or {}
  local list = {}

  for _, term in pairs(M._terminals) do
    if not opts.active_only or term:is_open() then
      table.insert(list, term)
    end
  end

  return list
end

---Finds a terminal instance by its buffer ID
---@param buf integer Buffer ID
---@return Terminal|nil
function M.find_by_buf(buf)
  for _, term in pairs(M._terminals) do
    if term.buf == buf then
      return term
    end
  end

  return nil
end

---Opens a terminal by ID or based on the current buffer/active state
---@param opts? { id?: integer, win?: integer }
---@return Terminal
function M.open(opts)
  opts = opts or {}
  local id = (opts.id ~= nil and opts.id > 0) and opts.id or nil
  local curr_win = vim.api.nvim_get_current_win()
  local curr_buf = vim.api.nvim_get_current_buf()
  local curr_term = M.find_by_buf(curr_buf)
  local targ_term = nil
  local targ_win = nil
  local active_terminals = M.list({
    active_only = true,
  })

  if id then
    targ_term = M._terminals[id]
  end

  if not targ_term then
    targ_term = M.new({ id = id })
  end

  if curr_term then
    targ_win = curr_win
  else
    curr_term = active_terminals[1]

    if curr_term then
      targ_win = curr_term:wins()[1]
    end
  end

  targ_win = opts.win or targ_win
  targ_term:open({ win = targ_win })

  if #active_terminals == 0 then
    vim.cmd("wincmd J")
  end

  return targ_term
end

---Closes a terminal by ID or based on the current buffer
---@param opts? { id?: integer } Dicionário de opções
function M.close(opts)
  opts = opts or {}
  local id = (opts.id ~= nil and opts.id > 0) and opts.id or nil
  local curr_win = vim.api.nvim_get_current_win()
  local curr_buf = vim.api.nvim_get_current_buf()
  local curr_term = M.find_by_buf(curr_buf)
  local targ_term = nil

  if id then
    targ_term = M._terminals[id]

    if not targ_term or not targ_term:is_open() then
      return false
    else
      ---TODO: give the user the possibility to choose between close all or only one window
      targ_term:close()

      return true
    end
  end

  if curr_term then
    curr_term:close({ win = curr_win })

    return true
  end

  ---TODO: give the user the possibility to choose wich window to close
  return false
end

---Toggles terminal visibility by ID or based on the current buffer
---@param opts { id?:  integer }
function M.toggle(opts)
  opts = opts or {}
  local id = (opts.id ~= nil and opts.id > 0) and opts.id or nil
  local targ_term = nil

  if id then
    targ_term = M._terminals[id]

    if targ_term and targ_term:is_open() then
      M.close({ id = id })
    else
      M.open({ id = id })
    end
  elseif #M._terminals < 1 then
    M.open()
  else
    local active_terminals = M.list({ active_only = true })
    local close = #active_terminals > 0

    if close then
      M._togglable_terminals = active_terminals
    end

    for _, term in ipairs(M._togglable_terminals) do
      if close then
        term:close()
      else
        term:open()
      end
    end
  end
end

---Create new terminal
---@param opts? { cmd?: string, id?: integer }
---@return Terminal
function M.new(opts)
  opts = opts or {}

  local id = opts.id

  if not id then
    id = get_available_id()
  end

  local term = Terminal:new({
    id = id,
    cmd = opts.cmd,
    on_exit = function(term)
      table.remove(M._terminals, term.id)
    end
  })

  M._terminals[term.id] = term

  return term
end

---Global plugin configuration
---@param opts? table
function M.setup(opts)
  opts = opts or {}
end

return M
