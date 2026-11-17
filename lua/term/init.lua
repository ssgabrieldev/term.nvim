local Terminal = require("term.terminal")
local Panel = require("term.panel")

---@class OptsOpenTerm
---@field id? integer
---@field cmd? string

local M = {}

local _opts = {}
---@type Terminal[]
local _terms = {}
---@type Panel[]
local _panels = {}

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

---@param panel Panel
---@return Panel?
local function panel_remove(panel)
  for i, pan in ipairs(_panels) do
    if pan == panel then
      return table.remove(_panels, i)
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
  opts = vim.tbl_extend("force", _opts.term, opts)

  local term = Terminal:new({
    id = (opts.id and opts.id > 0) and opts.id or term_next_id(),
    cmd = opts.cmd,
    on_exit = function(term)
      term_remove_by_id(term.id)
    end
  })

  table.insert(_terms, term)

  return term
end

---@param opts? OptsOpenTerm
function M.new_panel(opts)
  local panel = Panel:new(_terms, function (panel)
    if panel.destroy then
      panel_remove(panel)
    end
  end)
  local term = nil

  if #_terms == 0 then
    local term_opts = vim.tbl_extend("force", _opts.term, opts or {})
    M.new(term_opts)
  end

  term = _terms[1]
  table.insert(_panels, panel)

  panel:set_term(term)
  panel:open()
end

---@param opts? OptsOpenTerm
function M.toggle(opts)
  if #_panels == 0 then
    M.new_panel(opts)

    return
  end

  ---@diagnostic disable-next-line: unused-local
  for index, panel in ipairs(_panels) do
    panel:toggle()
  end
end

---@param opts? table
function M.setup(opts)
  _opts = vim.tbl_extend("force", {
    term = {}
  }, opts)
end

return M
