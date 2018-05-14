---
-- Table Tools<br/>
-- extends the standard table library
-- @module table

---
-- creates a deep copy f the table
--
-- @tparam table t table to copy from
-- @tparam[opt={}] table _t table to copy into. if nil, then create new table
--
-- @treturn table
--
table.deepcopy = function(t, _t)
  local _t = _t or {}
  for k,v in pairs(t) do
    if (type(v) == 'table') then _t[k] = table.deepcopy(v)
    else _t[k] = v end          
  end
  return _t
end

---
-- creates a string out of a table
--
-- @tparam table t
-- @string[opt=' '] seperator
--
-- @treturn string
--
table.tostring = function(t, seperator)
  local str = ""
  local seperator = seperator or " "
  for k,v in pairs(t) do
    if (type(v) == 'string') then str = str .. v .. seperator end
    if (type(v) == 'number') then str = str .. tostring(v) .. seperator end
  end
  if (string.len(str) > 0) then str = string.sub(str,1,str:len()-1) end
  return string.trim(str)
end