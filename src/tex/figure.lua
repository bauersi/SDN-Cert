--- Tex Figure
-- @classmod TexFigure

TexFigure = class()

---
-- create a tex figure.
--
-- @class function
-- @name TexFigure
--
-- @int[opt=''] pos
--
-- @usage local figure = TexFigure()
--
function TexFigure:_init(pos)
  self.header = {}
  self.data = {}
  self:setPos(pos)
end

--- table, header of tex figure
TexFigure.header = nil
--- table, data of tex figure
TexFigure.data = nil

---
-- set position of figure
--
-- @int[opt=''] pos
--
function TexFigure:setPos(pos)
  if (pos) then self.header.pos = "[" .. pos .. "]"
  else  self.header.pos = "" end
end

---
-- add TexGraphs to figure
--
-- @tparam [TexGraphs] ... list of TexGraphs
--
function TexFigure:add(...)
  local args = { ... }
  for i,value in pairs(args) do
    table.insert(self.data, value)
  end
end

---
-- generate tex code for figure
--
-- @return string
--
function TexFigure:getTex()
  local tex = "\\begin{figure}" ..  self.header.pos .. "\n"
  tex = tex .. "\\begin{center}\n"
  for i=1,#self.data do
    tex = tex .. self.data[i] .. "\n"
  end
  tex = tex .. "\\end{center}\n"
  tex = tex .. "\\end{figure}"
  return tex
end