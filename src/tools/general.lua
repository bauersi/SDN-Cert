---
-- General Tools
-- @script general


---
-- opposit of unpack (converts arg to array)
--
-- @param ... variable number of arguments
--
-- @return list with "variable number of arguments" as items
--
function pack(...)
  return {...}
end

---
-- opposit of unpack (converts arg to array)
--
-- @param ... variable number of arguments
--
-- @return list with "variable number of arguments" as items with list.n = number of arguments
--
function xpack(...)
  return arg
end

local function unpack_extended(arg, i)
  if (arg.n >= i) then
    return arg[i], unpack_extended(arg, i+1)
  else
    return
  end
end


---
-- opposit of xpack (converts array to multiple return values)
--
-- @table arg list with "variable number of arguments" as items with list.n = number of arguments
--
-- @return like unpack but also return nil at the end
--
function xunpack(arg)
  if (type(arg) ~= "table") then error("bad argument #1 to 'xunpack' (table expected, got no value)",2) end
  if arg.n == nil then return unpack(arg) end
  if arg.n == #arg then return unpack(arg) end
  return unpack_extended(arg,1)
end

---
-- normalizes string (lower characters and remove '_')
--
-- @string key string to normalize
--
-- @treturn string normalized string
--
function normalizeKey(key)
  return string.replaceAll(string.lower(key), "_", "")
end

---
-- compares two OpenFlow versions
--
-- @tparam string ver1 OpenFlow version 1, e.g. OpenFlow10
-- @tparam string ver2 OpenFlow version 2, e.g. OpenFlow12
--
-- @treturn[1] int <0 if v1 > v2, else >0 if v2 > v1, else =0 if v1 = v2
-- @treturn[2] nil if input not valid
function compareVersion(ver1, ver2)
  if (ver1 == nil or ver2 == nil) then return nil end
  if (ver1 == "unknown" or ver2 == "unknown") then return nil end
  local ver1 = string.match(string.replace(ver1, ".", ""),"%d+")
  local ver2 = string.match(string.replace(ver2, ".", ""),"%d+")
  local v1 = tonumber(string.lpad(ver1, 3, "0"))
  local v2 = tonumber(string.lpad(ver2, 3, "0"))
  if (v1 == nil or v1 == nil) then return nil end
  return v2 - v1
end

---
-- sleeps for n seconds
--
-- @int time time to sleep in seconds
--
function sleep(time)
  os.execute("sleep " .. time)
end

---
-- exit program
--
-- @string[opt] msg if set, program exit with message and error code 1
--
function exit(msg)
  local exitCode = 0
  if (msg) then
    exitCode = 1
    logger.log(msg)
    logger.err('ERROR DETECTED! Please see ' .. global.logFile .. ' for more information.')
  end

  logger.finalize()
  os.exit(exitCode)
end