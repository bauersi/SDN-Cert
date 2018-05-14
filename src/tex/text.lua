--- Tex Text
-- @classmod TexText

TexText = class()

---
-- create a tex table.
--
-- @class function
-- @name TexText
--
-- @usage local text = TexText()
--
function TexText:_init()
  self.lines = {}
end

--- lines of text
TexText.lines = nil


---
-- add lines to text
--
-- @tparam string ... lines
--
function TexText:add(...)
  local args = { ... }
  for _,line in pairs(args) do
    table.insert(self.lines, line)
  end
end


---
-- generate tex code for text
--
-- @return string
--
function TexText:getTex()
  local tex = ""
  for i=1,#self.lines do
    tex = tex .. self.lines[i] .. "\n"
  end
  return tex
end