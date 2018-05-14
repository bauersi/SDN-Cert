--- Tex Table
-- @classmod TexTable

TexTable = class()

---
-- create a tex table.
--
-- @class function
-- @name TexTable
--
-- @string[opt=''] spec column specification
-- @string[opt=''] pos table position
--
-- @usage local table = TexTable()
--
function TexTable:_init(spec, pos)
  self.header = {}
  self.control = {}
  self.data = {}
  self.footer = {}
  self:setSpec(spec)
  self:setPos(pos)
  self:setCaption()
  self:setLabel()
end

--- table, header data
TexTable.header = nil
--- table, control data
TexTable.control = nil
--- table, data
TexTable.data = nil
--- table, footer data
TexTable.footer = nil


---
-- set position of table
--
-- @int[opt=''] value pos
--
function TexTable:setPos(value)
  if (value) then self.header.pos = "[" .. value .. "]"
  else  self.header.pos = "" end
end


---
-- set column specification of figure
--
-- @int[opt=''] value spec
--
function TexTable:setSpec(value)
  if (value) then self.header.spec = "{" .. value .. "}"
  else  self.header.spec = "" end
end

---
-- set caption specification of table
--
-- @int[opt=''] value caption
--
function TexTable:setCaption(value)
  if (value) then self.footer.caption = "\\caption{" .. value .. "}\n"
  else  self.footer.caption = "" end
end

---
-- set label specification of table
--
-- @int[opt=''] value label
--
function TexTable:setLabel(value)
  if (value) then self.footer.label = "\\label{tab:" .. value .. "}\n"
  else  self.footer.label = "" end
end


---
-- add lines to table
--
-- @tparam string ... lines
--
function TexTable:add(...)
  local args = { ... }
  local line = ""
  if (#self.data == 0) then line = "\\hline\n" end
  line = line .. table.concat(args, " & ") .. " \\\\ \\hline"
  table.insert(self.data, line)
end


---
-- generate tex code for table
--
-- @return string
--
function TexTable:getTex()
  local tex = {}
  table.insert(tex, "\\begin{table}")
  table.insert(tex, self.header.pos)
  table.insert(tex, "\n")
  table.insert(tex, "\\begin{center}\n")
  table.insert(tex, "\\begin{tabular}")
  table.insert(tex, self.header.spec)
  table.insert(tex, "\n")
  for i=1,#self.data do
    table.insert(tex, self.data[i])
    table.insert(tex, "\n")
  end
  table.insert(tex, "\\end{tabular}\n")
  table.insert(tex, "\\end{center}\n")
  table.insert(tex, self.footer.caption)
  table.insert(tex, self.footer.label)
  table.insert(tex, "\\end{table}\n")
  return table.concat(tex, '')
end

return TexTable