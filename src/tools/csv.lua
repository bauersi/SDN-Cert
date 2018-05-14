---
-- CSV
--
-- @classmod CSV


CSV = class()


--- create a csv.
-- @class function
-- @name CSV
-- @usage local csv = CSV()
function CSV:_init()
  self.data = {}
end


--- data (list of lists)
CSV.data = nil

---
-- gets the number of rows
--
-- @treturn int number of rows
--
function CSV:getRowCount ()
  return #self.data
end

---
-- access row 'id'
--
-- @int id number of row
--
-- @treturn[1] table list of column values
-- @treturn[2] nil if not (1 <= id <= getRowCount())
--
function CSV:getRow (id)
  return self.data[id]
end


---
-- add row
--
-- @tparam table row list of column values
--
function CSV:addRow (row)
  if type(row) ~= "table" then error("table required") end
  table.insert(self.data, row)
end

---
-- add column
--
-- @tparam table column list of row values
--
function CSV:addColumn (column)
  if type(column) ~= "table" then error("table required") end
  for i=1,#self.data do
    self.data[i][#self.data[i]+1] = column[i]
  end
end


---
-- adds a new row by parsing a line
--
-- @string line
-- @string[opt='&#44;'] separator separator between values
--
function CSV:addLine (line, separator)
  separator = separator or ","
  line = string.trim(line)
  if #line > 0 then
    table.insert(self.data,string.split(line, separator))
  end
end

---
-- remove row by id
--
-- @tparam number id id of row
--
function CSV:removeRow (id)
  if type(id) ~= "number" then error("number required") end
  table.remove(self.data, id)
end

function CSV:select(from, to)

  local first = math.max(1, from or 1)
  local last = math.min(#self.data, to or #self.data)

  local csv = CSV()
  for i=first, last, 1 do
    table.insert(csv.data, self.data[i])
  end

  return csv
end


---
-- access row 'id' as line
--
-- @int id number of row
-- @string[opt='&#44;'] separator separator between values
--
-- @treturn[1] string list of column values
-- @treturn[2] nil if not (1 <= id <= getRowCount())
--
function CSV:getLine (id, separator)
  local row = self:getRow(id)
  if row == nil then return nil end
  separator = separator or ","
  return table.concat(row, separator)
end


---
-- access all rows as line
--
-- @string[opt='&#44;'] separator separator between values
--
-- @treturn [string] list of lines
--
function CSV:getLines (separator)
  separator = separator or ","
  local lines = {}
  for _,row in pairs(self.data) do
    table.insert(lines, table.concat(row, separator))
  end
  return lines
end


---
-- parses a csv-file
--
-- @string filepath path to the csv-file
-- @string[opt='&#44;'] separator separator between values
--
-- @treturn CSV
--
-- @raise 'LoadingFileException' if file could not be loaded
--
function CSV:parseFile (filepath, separator)
  local csv = CSV()

  local file, err = io.open(filepath, "r")
  if (not file) then Exception('LoadingFileException', err):throw() end

  for line in file:lines() do
    csv:addLine(line, separator)
  end
  file:close()
  return csv
end


---
-- print csv-file to current io
--
-- @tparam[opt=true] boolean withHeaders if true then headers are printed
-- @string[opt='&#44;'] separator separator between values
--
function CSV:print (withHeaders, separator)
  if withHeaders == nil then withHeaders = true end
  local firstRow = (withHeaders and 1) or 2   -- withHeader = true then 1 else 2
  local lastRow = self:getRowCount ()
  for row=firstRow, lastRow, 1 do
    io.write(self:getLine(row, separator))
    io.write("\n")
  end
end


---
-- transposes data (rows become columns and vice versa)
--
-- @treturn CSV
--
function CSV:transpose()
  local csv = CSV()
  if (not self.data[1]) then return csv end
  for i = 1, #self.data[1] do
    csv.data[i] = {}
    for j = 1, #self.data do
      csv.data[i][j] = self.data[j][i]
    end
  end
  return csv
end


---
-- write to file
--
-- @string filepath
--
function CSV:toFile(filepath)

  local file = io.open(filepath, "w")
  if (not file) then error('error on open file') end

  for _,line in ipairs(self:getLines()) do
    file:write(line)
    file:write('\n')
  end
  file:close()

end
