local Terminal = require("term.terminal")
local vim = vim

local M = {}

---Internal table to map the numeric ID to its respective Terminal instance
---@type table<number, Terminal>
M._terminals = {}

---Internal table to map the numeric ID to its respective Terminal instance
---@return number
local function get_available_id()
  local id = 1

  while M._terminals[id] ~= nil do
    id = id + 1
  end

  return id
end

---Returns the list of terminals, with an option to filter for only those with a valid window.
---@param opts { active_only?: boolean }|nil Dicionário de opções
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
---@param buf number Buffer ID
---@return Terminal|nil
function M.find_by_buf(buf)
  for _, term in pairs(M._terminals) do
    if term.buf == buf then
      return term
    end
  end

  return nil
end

---Toggles terminal visibility by ID or based on the current buffer
---@param id number|nil ID opcional do terminal
function M.toggle(id)
  id = (id ~= nil and id > 0) and id or nil
  local has_id = id ~= nil and id > 0
  local curr_buf = vim.api.nvim_get_current_buf()
  local curr_win = vim.api.nvim_get_current_win()
  local curr_term = M.find_by_buf(curr_buf)
  local targ_term = nil
  local active_terminals = M.list({
    active_only = true
  })

  if has_id then
    targ_term = M._terminals[id]
  end

  if curr_term then
    if not has_id then
      curr_term:close()

      return
    elseif targ_term and targ_term.id == curr_term.id then
      curr_term:close()

      return
    end

    curr_term:close({ silent = true })

    if not targ_term then
      targ_term = M.new({ id = id })
    end

    targ_term:open({ win = curr_win })

    return
  end

  if #active_terminals > 0 then
    print("implementar resposta quando há terminais ativos")
    return
  end

  if #M._terminals > 0 then
    print("implementar resposta quando não há terminais ativos")
    M._terminals[#M._terminals]:open()
    return
  end

  if not targ_term then
    targ_term = M.new({ id = id })
    targ_term:open()

    return
  end

  targ_term:open()
end

---Toggles terminal visibility by ID or based on the current buffer
---@param opts { cmd?: string, id?: number }|nil
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
  })

  M._terminals[term.id] = term

  return term
end

---Global plugin configuration
---@param opts table|nil
function M.setup(opts)
  opts = opts or {}
end

return M
