---@class Picker
---@field windows Window[]
local Picker = {}
Picker.__index = Picker

---@param windows Window[]
---@return Picker
function Picker:new(windows)
  return setmetatable({
    windows = windows or {},
  }, self)
end

---@return Window?
function Picker:pick()
  local choices = {}
  local previous_winbars = {}

  for _, window in ipairs(self.windows) do
    local winid = window.id

    if winid and vim.api.nvim_win_is_valid(winid) then
      choices[#choices + 1] = window

      previous_winbars[winid] = vim.api.nvim_get_option_value(
        "winbar",
        { win = winid }
      )
    end
  end

  if #choices == 0 then
    return nil
  end

  if #choices > 9 then
    vim.notify(
      "Picker supports a maximum of 9 windows",
      vim.log.levels.WARN
    )

    return nil
  end

  for index, window in ipairs(choices) do
    vim.api.nvim_set_option_value(
      "winbar",
      "%=" .. index .. "%=",
      { win = window.id }
    )
  end

  vim.cmd("redraw")

  local selected

  local ok, err = xpcall(function()
    while true do
      local key = vim.fn.getcharstr()

      if key == "\27" then
        break
      end

      local index = tonumber(key)

      if index and choices[index] then
        local window = choices[index]

        if window.id and vim.api.nvim_win_is_valid(window.id) then
          selected = window
          break
        end
      end
    end
  end, debug.traceback)

  for winid, winbar in pairs(previous_winbars) do
    if vim.api.nvim_win_is_valid(winid) then
      vim.api.nvim_set_option_value(
        "winbar",
        winbar,
        { win = winid }
      )
    end
  end

  if not ok then
    error(err)
  end

  return selected
end

return Picker
