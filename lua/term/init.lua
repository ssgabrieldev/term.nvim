local Terminal = require("term.terminal")
local Panel = require("term.panel")

---@class OptsOpenTerm
---@field id? integer
---@field cmd? string

---@class Term
---@field opts table
---@field terms Terminal[]
---@field panels Panel[]
local M = {
  opts = {},
  terms = {},
  panels = {}
}

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

---@param panel Panel
---@return Panel?
local function panel_remove(panel)
  for i, pan in ipairs(M.panels) do
    if pan == panel then
      return table.remove(M.panels, i)
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
      term_remove_by_id(term.id)
    end
  })

  table.insert(M.terms, term)

  if #M.panels > 0 then
    ---@diagnostic disable-next-line: unused-local
    for index, panel in ipairs(M.panels) do
      if panel:is_open() then
        panel:set_term(term)

        break
      end
    end
  end

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

  local panel = M.panels[1]
  if not panel then
    panel = M.new_panel(opts)
  end

  panel:set_term(term)

  return term
end

---@param opts? OptsOpenTerm
function M.new_panel(opts)
  opts = opts or {}

  local panel = Panel:new(M.terms, function(panel)
    if panel.destroy then
      panel_remove(panel)
    end
  end)

  local term = nil

  if opts.id then
    term = term_find_by_id(opts.id)
  else
    term = M.terms[1]
  end

  if not term then
    local term_opts = vim.tbl_extend("force", M.opts.term, opts)
    term = M.new(term_opts)
  end

  table.insert(M.panels, panel)

  panel:set_term(term)
  panel:open()

  return panel
end

---@param opts? OptsOpenTerm
function M.toggle_panels(opts)
  if #M.panels == 0 then
    M.new_panel(opts)

    return
  end

  ---@diagnostic disable-next-line: unused-local
  for index, panel in ipairs(M.panels) do
    panel:toggle()
  end
end

---@param opts? table
function M.setup(opts)
  M.opts = vim.tbl_extend("force", {
    term = {}
  }, opts)
end

return M
