------
-- Class for individual test-cases
-- @module TestCase

package.path = package.path .. ';' .. global.testFolder .. '/?.lua'
package.path = package.path .. ';' .. global.testFolder .. '/config/?.lua'

TestCase = {}
TestCase.__index = TestCase

--- Creates a new test-case from a given configuration line
-- within a benchmark file
function TestCase.create(cfgLine)
  local self = setmetatable({}, TestCase)
  self.disabled = false
  self:readConfig(cfgLine)
  return self
end

local function getConfigFileName(testcase) return global.testFolder .. "/config/" .. testcase:getName() end

local function loadConfigFile(testcase)
  -- on success result = config, on error result = error message
  local cfgFile = getConfigFileName(testcase)
  local status, result = pcall(require, cfgFile)
  if status then
    return result
  else
    return nil
  end
end

--- Reads in the configuration. Creates the parameter list and
-- imports all data from the test-case file.
function TestCase:readConfig(cfgLine)
  self.parameters = {}
  for _,arg in pairs(string.split(cfgLine, ",")) do
    local k,v = string.getKeyValue(arg)
    if (k and v) then
      self.parameters[normalizeKey(k)] = v
    end
  end

  self.settings = table.deepcopy(self.parameters)
  self.parameters.name = nil

  if (self:getName() == nil) then
    logger.warn("Skipping test, no name specified")
    self:disable()
    return
  end
  logger.debug("test '" .. self:getName() .. " added")

  if self.parameters.cond then
    self.cond = self.parameters.cond
    self.parameters.cond = nil
  end

  self.config = loadConfigFile(self)

  if not self.config then
    logger.warn("Skipping test, config file not found '" .. getConfigFileName() .. ".lua'")
    self:disable()
    return
  end

  if (self.config.settings) then
    for k,v in pairs(self.config.settings) do self.settings[normalizeKey(k)] = v end
  end

  self.files = CommonTest.readInFiles(self, global.testFolder, self.files)
  self.ofArgs = CommonTest.mapArgs(self, self.config.ofArgs, "of", true)
end

--- Checks if all required features are supported. Print a list+
-- of unsupported features
function TestCase:checkFeatures(openflowVersion, benchmark)
  if (settings:evalOnly()) then return end
  local unsupportedFeatures = self.config.checkFeatures(openflowVersion, self, function (feature) return benchmark:isFeatureSupported(feature) end)
    if (#unsupportedFeatures > 0) then
    self:disable()
    logger.warn("Skipping test, unsupported feature(s): " .. table.concat(unsupportedFeatures, ', '))
  end
end

--- Sets the Id of a test-case. The Id is used to identify a
-- test-case. Only valid test-cases should get an Id.
function TestCase:setId(id)
  self.settings.id = id
end

--- Retrieves the Id.
function TestCase:getId()
  return self.settings.id
end

--- Checks if the test-case is disabled.
function TestCase:isDisabled()
  return self.disabled
end

--- disable test-case
function TestCase:disable()
  self.disabled = true
end

--- Returns the name of the test-case..
function TestCase:getName()
  return self.settings.name
end

--- Returns the complete name (including the id) of the test-case
function TestCase:getCompleteName()
  if self:getId() then
    return "test_" .. self:getId() .. "_" .. self:getName()
  else
    return self:getName()
  end
end

--- returns test-case condition
function TestCase:getCondition()
  return self.cond
end

--- Returns the output path of files belonging to this test-case.
function TestCase:getOutputPath()
  return settings:getLocalPath() .. "/" .. global.results .. "/" .. self:getName() .. "/"
end

--- Returns the test duration.
function TestCase:getDuration()
  return self.settings.duration
end

--- Returns the specified load-generator.
function TestCase:getLoadGen()
  return self.config.loadGen
end

--- Returns the list of needed files for the load-generator.
function TestCase:getLoadGenFiles()
  return self.files
end

--- Returns the list of parameters.
function TestCase:getParameters()
  return self.parameters
end

--- Updates the parameters
function TestCase:updateParameter(name, value)
  if self.parameters[name] ~= nil then
    self.settings[name] = value
  end
end

--- returns current value of parameter
function TestCase:getCurrentValueOfParameter(name)
  if self.parameters[name] == nil then
    return nil
  else
    return self.settings[name]
  end
end

--- returns initial value of parameter
function TestCase:getInitalValueOfParameter(name)
  return self.parameters[name]
end

--- Returns the metric name for this test-case
function TestCase:getMetric()
  return self.config.metric
end

--- Returns a configuration string, containing all parameters and
-- their values. Is used to identify corresponding tests with similar
-- configuration.
function TestCase:toString()
  local conf = {}
  for parameter,value in pairs(self.parameters) do
    table.insert(conf, parameter .. "=" .. value)
  end
  table.sort(conf)
  table.insert(conf, 1, "name=" .. self:getName())
  return table.concat(conf, ",")
end

--- Returns a LaTex table of the parameter list.
function TestCase:getParameterTable(blacklist)
  local parameter = TexTable("|l|p{0.5\\linewidth}|l|", "ht")
  parameter:add("\\textbf{parameter}", "\\centering \\textbf{value}", "\\textbf{unit}")
  for k,_ in pairs(self.parameters) do
    if (k ~= blacklist) then
      parameter:add(Tex.sanitize(k), "\\centering " .. Tex.sanitize(self.settings[k]), Tex.sanitize(self.config.units[k] or ""))
    end
  end
  return parameter
end

--- Returns the list of arguments, which are passed to the OpenFlow
-- rule creation function.
function TestCase:getLgArgs()
  return CommonTest.mapArgs(self, self.config.lgArgs, "lg", false)
end

--- Dumps the current configuration.
function TestCase:print(dump)
  CommonTest.print(self.settings, dump)
end

--- Exports the current configuration.
function TestCase:export(dump)
  local params = {}
  for key,_ in pairs(self.parameters) do
    table.insert(params,key)
  end
  table.sort(params)

  local initValues = {}
  local currValues = {}
  for _,param in pairs(params) do
    table.insert(initValues, self.parameters[param])
    table.insert(currValues, self.settings[param])
  end
  table.insert(params, 1, 'name')
  table.insert(initValues, 1, self:getName())
  table.insert(currValues, 1, self:getName())

  params = table.concat(params, ', ')
  initValues = table.concat(initValues, ', ')
  currValues = table.concat(currValues, ', ')

  if (dump) then
    local file = io.open(dump, "w")
    file:write(params .. "\n")
    file:write(initValues .. "\n")
    file:write(currValues .. "\n")
  else
    show("  " .. params)
    show("  " .. initValues)
    show("  " .. currValues)
  end
end

--- Imports a configuration
--
-- @raise 'LoadingFileException' if file could not be loaded
--
function TestCase:import(file)
  TryCatchFinally(function ()
    local csv = CSV:parseFile(file)
    if csv:getRowCount() < 3 then return end
    local params = csv:getRow(1)
    local currValues = csv:getRow(3)

    local maxIndex = math.min(#params, #currValues)
    for i=1,maxIndex,1 do
      self:updateParameter(string.trim(params[i]), string.trim(currValues[i]))
    end
  end, {
    LoadingFileException = function (ex)
      Exception('LoadingFileException', 'importing configuration "' .. tostring(file) .. '" failed', ex):throw()
    end
  })
end

return TestCase