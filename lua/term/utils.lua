local vim = vim

local M = {}

function M.list_wins_by_buf(buf)
  local all_windows = vim.api.nvim_tabpage_list_wins(0)
  local target_wins = {}

---@diagnostic disable-next-line: unused-local
  for i, win in ipairs(all_windows) do
    if buf == vim.api.nvim_win_get_buf(win) then
      table.insert(target_wins, win)
    end
  end

  return target_wins
end

return M
