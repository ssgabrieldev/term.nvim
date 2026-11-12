local Terminal = require("term.terminal")
local vim = vim

local M = {}

local _opts = {}

---@type table<integer, Terminal>
local _terms = {}

---@param id integer
---@return Terminal?
local function term_find_by_id(id)
  ---@diagnostic disable-next-line: unused-local
  for i, term in ipairs(_terms) do
    if id == term.id then
      return term
    end
  end
end

---@param id integer
---@return Terminal?
local function term_remove_by_id(id)
  for i, term in ipairs(_terms) do
    if term.id == id then
      return table.remove(_terms, i)
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

---@param opts? { cmd?: string, id?: integer, on_exit?: function }
---@return Terminal
function M.new(opts)
  opts = vim.tbl_extend("force", _opts.terminal, opts)

  local term = Terminal:new({
    id = opts.id or term_next_id(),
    cmd = opts.cmd,
    on_exit = function(term)
      term_remove_by_id(term.id)

      if opts.on_exit then
        opts.on_exit(term)
      end
    end
  })

  table.insert(_terms, term)

  return term
end

---@param opts? { cmd?: string, id?: integer, on_exit?: function }
---@return Terminal
function M.toggle(opts)
  opts = vim.tbl_extend("force", _opts.terminal, opts)

  local term = term_find_by_id(opts.id)

  if not term then
    term = M.new(opts)
  end

  if term:is_open() then
    term:close()

    return term
  end

  term:open()

  return term
end

---@param opts? table
function M.setup(opts)
  _opts = vim.tbl_extend("force", { terminal = {} }, opts)
end

return M
