--- File Content
-- @classmod FileContent

FileContent = class()

---
-- create a tex filecontent.
--
-- @class function
-- @name FileContent
--
-- @string file name of file
--
-- @usage local content = FileContent()
--
function FileContent:_init(filename)
  self.filename = filename
  self.lines = {}
end

--- name of file
FileContent.filename = nil
--- lines of file
FileContent.lines = nil

---
-- get filename
--
-- @treturn string filename{}
--
function FileContent:getFileName()
  self.type = self.type or ".out"
  self.filename = self.filename or "data_" .. string.sub(tostring(self), 8, -1)
  return self.filename .. self.type
end


---
-- read csv file
--
-- @string filename
-- @tparam [boolean] noHeader
--
function FileContent:addCsvFile(filename, noHeader)
  if (not filename) then return end
  self.type = ".csv"
  local dataFile = io.open(filename, "r")
  if (not dataFile) then return end
  if (noHeader) then dataFile:read() end
  if (not dataFile) then return end
  while (true) do
    local line = dataFile:read()
    if (line == nil) then break end
    table.insert(self.lines, line)
  end
  io.close(dataFile)
end

---
-- add csv lines
--
-- @tparam [string] lines list of strings
--
function FileContent:addCsvList(lines)
  if (not lines) then return end
  self.type = ".csv"
  for _, line in pairs(lines) do
    table.insert(self.lines, line)
  end
end

---
-- add csv line
--
-- @string line
--
function FileContent:addCsvLine(line)
  self.type = ".csv"
  if (line) then table.insert(self.lines, line) end
end

---
-- generate tex code for filecontent
--
-- @return string
--
function FileContent:getTex()
  local tex = "\\begin{filecontents*}{".. self:getFileName() .. "}\n"
  for i=1,#self.lines do
    tex = tex .. self.lines[i] .. "\n"
  end
  tex = tex .. "\\end{filecontents*}"
  return(tex)
end