--[[
  Feature test for matching of L2 MAC-addresses
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow12"
Feature.state   = "required"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link=1 $link=2"
Feature.ofArgs  = "$link=2"
    
Feature.pkt = Feature.getDefaultPkt()

Feature.settings = {
    txIterations = 2,
    new_DST_MAC = "aa:00:00:00:00:a2"
}
local conf = Feature.settings

Feature.flowEntries = function(openflowVersion, flowData, outPort)
    table.insert(flowData.flows, string.format("table=0, eth_dst=%s, actions=DROP", Feature.pkt.DST_MAC))
    table.insert(flowData.flows, string.format("table=0, eth_dst=%s, actions=output:%s", conf.new_DST_MAC, outPort))
end
  
Feature.modifyPkt = function(pkt, iteration)
    pkt.DST_MAC = conf.new_DST_MAC
end

return Feature