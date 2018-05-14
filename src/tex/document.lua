--- Tex Document
-- @classmod TexDocument

TexDocument = {}

--- create a set. <br>
-- @param obj list-like table
-- @class function
-- @name TexDocument
function TexDocument.create(class)
  local obj = {}
  setmetatable(obj, TexDocument)
  TexDocument.__index = TexDocument

  class = class or "report"

  obj.header = "\\documentclass{" .. class .. "}"
  obj.usepackage = {}
  obj.preamble = {}
  obj.content = {}

  obj:usePackage("color")
  obj:usePackage("geometry", "a4paper")
  obj:usePackage("fullpage")
  obj:usePackage("pgfplots")
  obj:usePackage("pgfplotstable")
  obj:usePackage("csvsimple")
  obj:usePackage("filecontents")
  obj:usePackage("float")

  obj:addPreamble(TexBlocks.boxplotSettings)

  return obj
end

function TexDocument:usePackage(name, args)
  if (args) then args = "[" .. args .. "]"
  else args = "" end
  local use = "\\usepackage" .. args .. "{" .. name .. "}"
  table.insert(self.usepackage, use)
  if (name == "hyperref") then
    self.compiletwice = true
  end
end

function TexDocument:addPreamble(...)
  local args = {... }
  for _,element in pairs(args) do
    table.insert(self.preamble, element)
  end
end

function TexDocument:addElement(element)
  table.insert(self.content, element)
end

function TexDocument:addElements(...)
  local args = { ... }
  for _,element in pairs(args) do
    table.insert(self.content, element)
  end
end

function TexDocument:addClearPage()
  local clearpage = TexText()
  clearpage:add("\\clearpage")
  table.insert(self.content, clearpage)
end

function TexDocument:getTex()
  local tex = {}
  table.insert(tex, self.header .. "\n")
  table.insert(tex, "\n")
  table.insert(tex, table.concat(self.usepackage, "\n"))
  table.insert(tex, "\n")
  table.insert(tex, table.concat(self.preamble, "\n"))
  table.insert(tex, "\n")
  table.insert(tex, "\n")
  table.insert(tex, "\\begin{document}\n\n")
  for i=1,#self.content do
    table.insert(tex, self.content[i]:getTex())
    table.insert(tex, "\n\n")
  end
  table.insert(tex, "\\end{document}")
  return table.concat(tex, "")
end

function TexDocument:saveToFile(path, file)
  self.file = file or "texDocument"
  self.path = path or settings:getlocalPath() .. "/" .. global.results
  Setup.createFolder(self.path)
  local reportFile = io.open(path .. "/" .. self.file .. ".tex", "w")
  reportFile:write(self:getTex())
  io.close(reportFile)  
end

function TexDocument:getFile()
  return self.path .. "/" .. self.file
end

function TexDocument:generatePDF(path, file)
  if (not settings:doRunTex()) then
    logger.debug("Skipping " .. global.tex)
    return
  end
  if (not self.file or not self.path) then self:saveToFile(path, file) end
  logger.print("Saving PDF to " .. self.file .. ".pdf",1)
  local cmd = CommandLine.create("cd " .. self.path)
  cmd:addCommand(global.tex .. " " .. self.file .. ".tex")
  if (self.compiletwice) then
    cmd:addCommand("pdflatex --halt-on-error " .. self.file .. ".tex")
  end
  cmd:addCommand("rm *.aux")
  cmd:addCommand("rm *.log")
  cmd:addCommand("rm *.csv")
  cmd:addCommand("rm *.dat")
  cmd:execute()
end

return TexDocument
