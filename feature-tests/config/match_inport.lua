--[[
  Feature test for matching of OpenFlow ingress port
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow10"
Feature.state   = "required"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link=1 $link=2"
Feature.ofArgs  = "$link=1 $link=2"
  	
Feature.pkt = Feature.getDefaultPkt()

Feature.settings = {
    txIterations = 2,
    learnFrames  = 0,
    firstRxDev   = 1,
    new_TX_DEV   = 2,
}
local conf = Feature.settings

Feature.flowEntries = function(openflowVersion, flowData, inPort, outPort)
    local tableId = ""
    if (compareVersion("OpenFlow10", openflowVersion) > 0) then
        tableId = "table=0, "
    end
    table.insert(flowData.flows, string.format("%sin_port=%s, actions=DROP", tableId, outPort))
    table.insert(flowData.flows, string.format("%sin_port=%s, actions=output:%s", tableId, inPort, outPort))
end
  
Feature.modifyPkt = function(pkt, iteration)
    pkt.TX_DEV = conf.new_TX_DEV
end

return Feature