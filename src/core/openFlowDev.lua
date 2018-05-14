OpenFlowDevice = {}
OpenFlowDevice.__index = OpenFlowDevice

require "src/tools/files"

--------------------------------------------------------------------------------
--  class for managing an OpenFlow device
--------------------------------------------------------------------------------

--- Creates a new instance for an OF-dev.
function OpenFlowDevice.create()
  local self = setmetatable({}, OpenFlowDevice)

  local adapter = settings.config[global.adapter]
  if type(adapter) == "string" and string.lower(adapter) == "ryu" then
    self.adapter = RyuAdapter.create()
  elseif type(adapter) == "string" and string.lower(adapter) == "floodlight" then
    self.adapter = FloodlightAdapter.create()
  else
    self.adapter = OvsOfctlAdapter.create()
  end
  self.version = settings.config[global.ofVersion]

  return self
end

--- Resets all flows, groups and meters on the device.
function OpenFlowDevice:reset()
  self.adapter:delFlows()
  if (compareVersion("OpenFlow11", self.version) >= 0) then
    self.adapter:delGroups()
  end
  if (compareVersion("OpenFlow13", self.version) >= 0) then
    self.adapter:delMeters()
  end
end

--- Returns the flow dump of the device in the representation of the used version.
function OpenFlowDevice:dumpFlows(version)
  return self.adapter:dumpFlows(version)
end

--- Returns the group dump of the device in the representation of the used version.
function OpenFlowDevice:dumpGroups(version)
  version = version or self.version
  if (compareVersion("OpenFlow11", self.version) < 0) then return "groups are not supported in " .. self.version end
  return self.adapter:dumpGroups(version)
end

--- Returns the meter dump of the device in the representation of the used version.
function OpenFlowDevice:dumpMeters(version)
  version = version or self.version
  if (compareVersion("OpenFlow13", self.version) < 0) then return "meters are not supported in " .. self.version end
  return self.adapter:dumpMeters(version)
end

--- Returns all OpenFLow flow rules.
function OpenFlowDevice:dumpAll(dump)
  local ret = "Flow dump:\n" .. self:dumpFlows() .. "\n\n"
  if (compareVersion("OpenFlow11", self.version) >= 0) then
    ret = ret .. "Group dump:\n" .. self:dumpGroups() .. "\n\n" end
  if (compareVersion("OpenFlow13", self.version) >= 0) then
    ret = ret .. "Meter dump:\n" .. self:dumpMeters() end
  if (not dump) then return ret end
  local dunpFile = io.open(dump, "w")
  dunpFile:write(ret)
  io.close(dunpFile)
  return ret
end

--- Installs a new flow.
function OpenFlowDevice:installFlow(flow)
  return self.adapter:installFlow(flow)
end

--- Install a file of flows.
function OpenFlowDevice:installFlows(file)
  if (not absfileExists(file)) then logger.err("Cannot add flows, no such file: '" .. file .. "'") return end
  return self.adapter:installFlows(file)
end

--- Installs a new group.
function OpenFlowDevice:installGroup(group)
  return self.adapter:installGroup(group)
end

--- Installs a file of groups.
function OpenFlowDevice:installGroups(file)
  if (not absfileExists(file)) then logger.err("Cannot add groups, no such file: '" .. file .. "'") return end
  return self.adapter:installGroups(file)
end

--- Installs a new meter.
function OpenFlowDevice:installMeter(meter)
  return self.adapter:installMeter(meter)
end

--- Installs a file of meters.
function OpenFlowDevice:installMeters(file)
  if (not absfileExists(file)) then logger.err("Cannot add meters, no such file: '" .. file .. "'") return end
        local lines = readlines(file)
        local output = ""
        for nr,line in pairs(lines) do
                output = output .. "\n" .. self.adapter:installMeter(line)
        end
  return output
end

--- Installs all files to the device. Files have to end with _type.
-- For example test_flows, test_groups and test_meters. 
function OpenFlowDevice:installAllFiles(file, dump)
  local ret = ""
  if (compareVersion("OpenFlow13", self.version) >= 0 and absfileExists(file .. "_meters")) then
    ret = ret .. "install meters file:\n" .. self:installMeters(file .. "_meters") .. "\n" end
  if (compareVersion("OpenFlow11", self.version) >= 0 and absfileExists(file .. "_groups")) then
    ret = ret .. "install group file:\n" ..  self:installGroups(file .. "_groups") .. "\n" end
  ret = ret .. "install flow file:\n" .. self:installFlows(file .. "_flows") .. "\n"
  if (not dump) then return ret end
  local dunpFile = io.open(file .. dump, "w")
  dunpFile:write(ret)
  io.close(dunpFile)
  return ret
end

--- Creates a file for flows, groups or meters.
function OpenFlowDevice:createFlowData(data, file)
  local stream = io.open(file, "w")
  if (not stream) then
    Setup.createParentFolder(file)
    stream = io.open(file, "w")
  end
  if (data) then for i,line in pairs(data) do stream:write(line .. "\n") end end
  io.close(stream)
end

--- Creates a file containing all flows.
function OpenFlowDevice:createFlowFile(flows, file)
  file = file .. "_flows" or global.tempdir .. "/switch_flows"
  return self:createFlowData(flows, file)
end

--- Creates a file containing all groups.
function OpenFlowDevice:createGroupFile(groups, file)
  file = file .. "_groups" or global.tempdir .. "/switch_groups"
  return self:createFlowData(groups, file)
end

--- Creates a file containing all meters.
function OpenFlowDevice:createMeterFile(meters, file)
  file = file .. "_meters" or global.tempdir .. "/switch_meters"
  return self:createFlowData(meters, file)
end

--- Creates all files at once.
function OpenFlowDevice:createAllFiles(flowData, file)
  self:createFlowFile(flowData.flows, file)
  if (#flowData.groups > 0 and compareVersion("OpenFlow11", self.version) >= 0) then
    self:createGroupFile(flowData.groups, file) end
  if (#flowData.meters > 0 and compareVersion("OpenFlow13", self.version) >= 0) then
    self:createMeterFile(flowData.meters, file) end
end

--- Retrieves the flow data from the test definition.
function OpenFlowDevice:getFlowData(test, isFeature)
  local flowData = { flows  = {}, groups = {}, meters = {} }
  local flowEntries = test.config.flowEntries
  if (not flowEntries) then
    local testname = (isFeature and test:getName()) or (test:getCompleteName())
    logger.err("Failed to create flow entries for '" .. testname .. "', check configuration file")
    return flowData
  end
  logger.debug("FlowEntries arguments: '" .. table.tostring(test.ofArgs) .. "'")
  flowEntries(self.version, flowData, unpack(test.ofArgs))
  return flowData
end

function OpenFlowDevice:getPorts()
  return self.adapter:getPorts()
end

return OpenFlowDevice

