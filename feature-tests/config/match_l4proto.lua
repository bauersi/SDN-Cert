--[[
  Feature test for matching the protocol in the IP Header 
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow10"
Feature.state   = "required"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link=1 $link=2"
Feature.ofArgs  = "$link=2"
    
Feature.pkt = Feature.getDefaultPkt()

Feature.settings = {
  txIterations = 2,
  new_PROTO = Feature.enum.PROTO.tcp,
}
local conf = Feature.settings

Feature.flowEntries = function(openflowVersion, flowData, outPort)
    local tableId = ""
    if (compareVersion("OpenFlow10", openflowVersion) > 0) then
        tableId = "table=0, "
    end
    table.insert(flowData.flows, string.format("%sip, nw_proto=%s, actions=DROP", tableId, Feature.pkt.PROTO))
    table.insert(flowData.flows, string.format("%sip, nw_proto=%s, actions=output:%s", tableId, conf.new_PROTO, outPort))
  end
  
Feature.modifyPkt = function(pkt, iteration)
    pkt.PROTO = conf.new_PROTO
  end
  
return Feature