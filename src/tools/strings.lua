---
-- String Tools<br/>
-- extends the standard string library
-- @module string

-- seperate definition because of problems with ldoc framework
local SPECIAL_CHARS = {
    ['('] = "%(",
    [')'] = "%)",
    ['.'] = "%.",
    ['%'] = "%%",
    ['+'] = "%+",
    ['-'] = "%-",
    ['*'] = "%*",
    ['?'] = "%?",
    ['['] = "%[",
    [']'] = "%]",
    ['^'] = "%^",
    ['$'] = "%$"
}
---
-- list of magic characters for pattern matching (http://www.lua.org/pil/20.2.html) <br/>
-- % musst be specially treated
-- @field _SPECIAL_CHARS ( ) . % + - * ? [ ] ^ $
string._SPECIAL_CHARS = SPECIAL_CHARS

---
-- replaces magic characters for pattern matching
--
-- @string str string to sanitize
--
-- @treturn string sanitized string
--
string.sanitize = function(text)
    local result = string.gsub(text, "[().%%%+-*?%[%]^$]", SPECIAL_CHARS)
    return result
end

---
-- remove all spaces at the begin and end of the string
--
-- @string str string to trim
--
-- @treturn string trimed string
--
string.trim = function(str)
  if (type(str) ~= 'string') then return str end
  return str:match("^%s*(.-)%s*$")
end

---
-- replaces first occurence of 'find' (not a pattern) in the 'str' with 'replace'
--
-- @string str
-- @string find
-- @string replace
--
-- @treturn string new string
--
string.replace = function (str, find, replace)
  find = string.sanitize(find)
  replace = string.sanitize(replace)
  str = string.gsub(str, find, replace, 1)
  return str
end

---
-- replaces all occurence of 'find' (not a pattern) in the 'str' with 'replace'
--
-- @string str
-- @string find
-- @string replace
--
-- @treturn string new string
--
string.replaceAll = function (str, find, replace)
    find = string.sanitize(find)
    replace = string.sanitize(replace)
    str = string.gsub(str, find, replace)
    return str
end

---
-- Pads string 'str' to length 'len' with character 'char' from left
--
-- @string str string to pad
-- @int len length min length of padded string
-- @string char charater for padding the string
--
-- @treturn string padded string
--
string.lpad = function(str, len, char)
    if char == nil then char = ' ' end
    return string.rep(char, len - #str) .. str
end

---
-- Pads string 'str' to length 'len' with character 'char' from right
--
-- @string str string to pad
-- @int len length min length of padded string
-- @string char charater for padding the string
--
-- @treturn string padded string
--
string.rpad = function(str, len, char)
    if char == nil then char = ' ' end
    return str .. string.rep(char, len - #str)
end

---
-- splits the string 'str' by delimiter 'delim'
--
-- @string str string to split
-- @string delim delimiter
-- @int[opt=0] maxNb maximal number of parts (0 -> unlimited)
--
-- @treturn [string] list of partial strings
--
string.split = function (str, delim, maxNb)
    -- Eliminate bad cases...
    if type(str)~="string" then return {} end
    if type(delim)~="string" then return { str } end

    -- trivial case
    delim = string.sanitize(delim)
    if string.find(str, delim) == nil then
        return { str }
    end

    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit
    end

    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gmatch(str, pat) do
        table.insert(result, part)
        lastPos = pos
        nb = nb + 1
        if nb == maxNb then break end
    end
    table.insert(result, string.sub(str, lastPos))
    return result
end

---
-- gets the value of key-value-pair with is separated by character 'ch_split'
--
-- @string str
-- @string[opt='='] ch_split
--
-- @treturn[1] nil if key not found
-- @treturn[2] boolean|string trimed value
--
-- @usage string.getKeyValue("name=max") -> "max"
--
string.getKeyValue = function (str, ch_split)
  if (type(str)~="string") then return end

  if (ch_split == nil) then ch_split = global.ch_equal end
  local parts = string.split(str, ch_split, 1)
  if #parts ~= 2 then return end

  local k = string.trim(string.lower(string.replaceAll(parts[1], "_", "")))
  local v = string.trim(parts[2])
  if (v == "true") then v = true end
  if (v == "false") then v = false end
  return k, v
end

---
-- check if string starts with prefix
--
-- @string str
-- @string prefix
--
-- @treturn boolean
--
string.startsWith = function (str, prefix)
    return string.sub(str,1,string.len(prefix))==prefix
end