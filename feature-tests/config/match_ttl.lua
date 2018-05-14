--[[
  Feature test for matching IP TTL or IPv6 hop limit value
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow11"
Feature.state   = "optional"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link=1 $link=2"
Feature.ofArgs  = "$link=2"
    
Feature.pkt = Feature.getDefaultPkt()

Feature.settings = {
  txIterations = 2,
  new_TTL = FeatureConfig.enum.TTL.min,
}
local conf = Feature.settings

Feature.flowEntries = function(openflowVersion, flowData, outPort)
    local tableId = ""
    if (compareVersion("OpenFlow10", openflowVersion) > 0) then
        tableId = "table=0, "
    end
    table.insert(flowData.flows, string.format("%sip, nw_ttl=%s, actions=DROP", tableId, Feature.pkt.TTL))
    table.insert(flowData.flows, string.format("%sip, nw_ttl=%s, actions=output:%s", tableId, conf.new_TTL, outPort))
  end
  
Feature.modifyPkt = function(pkt, iteration)
    pkt.TTL = conf.new_TTL
  end
  
  
return Feature