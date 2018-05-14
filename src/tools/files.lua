--- File Tools
-- @module File


---
--  check if the file exists in the local path (setting.cfg)
--
-- @string file path to file
--
-- @treturn boolean
--
function localfileExists(file)
  if (not file) then return false end
  local path = settings:getLocalPath() or "."
  return absfileExists(path .. "/" .. file)
end

---
-- check if the file exists
--
-- @string file absolut path to file
--
-- @treturn boolean
--
function absfileExists(file)
  if (not file) then return false end
  local f = io.open(file, "rb")  
  if f then f:close() end
  return f ~= nil
end

---
-- get all lines from a file
--
-- @string file absolut path to file
--
-- @treturn lines
---
function readlines(file)
  if not absfileExists(file) then return {} end
  lines = {}
  for line in io.lines(file) do
    lines[#lines + 1] = line
  end
  return lines
end