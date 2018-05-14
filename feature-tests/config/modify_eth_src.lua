--[[
  Feature test for modifying Ethernet source and destination address
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow12"
Feature.state   = "recommended"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link=1 $link=2"
Feature.ofArgs  = "$link=2"
    
Feature.pkt = Feature.getDefaultPkt()

Feature.settings = {
  new_SRC_MAC = "aa:00:00:00:00:a2"
}
local conf = Feature.settings

Feature.flowEntries = function(openflowVersion, flowData, outPort)
    table.insert(flowData.flows, string.format("table=0, actions=set_field:%s->eth_src, output:%s", conf.new_SRC_MAC, outPort))
  end
 
Feature.pktClassifier = {
    function(pkt) return (pkt.src_mac == conf.new_SRC_MAC) end
  }

return Feature