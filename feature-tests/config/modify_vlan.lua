--[[
  Feature test for modifying the vlan field
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
Feature.pkt.vlan = 1

Feature.settings = {
    learnFrames  = 0,
    txIterations = 2,
}
local conf = Feature.settings

Feature.flowEntries = function(openflowVersion, flowData, outPort)
    table.insert(flowData.flows, string.format("dl_vlan=%s, actions=mod_vlan_vid:%s,output:%s", Feature.pkt.vlan, Feature.pkt.vlan + 2, outPort))
    table.insert(flowData.flows, string.format("dl_vlan=%s, actions=DROP", Feature.pkt.vlan + 1))
end

Feature.modifyPkt = function(pkt, iteration)
        Feature.pkt.vlan = Feature.pkt.vlan + 1
end

Feature.pktClassifier = {
        function(pkt) return (pkt.vlan == Feature.pkt.vlan + 2) end,
}

return Feature
