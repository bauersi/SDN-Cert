--[[
  Feature test for modifying the IPv4 src and dst field
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
    new_DST_IP4 = "10.0.2.2",
}
local conf = Feature.settings

Feature.flowEntries = function(openflowVersion, flowData, outPort)
    table.insert(flowData.flows, string.format("table=0, ip, actions=mod_nw_dst:%s, output:%s", conf.new_DST_IP4, outPort))
end
  
Feature.modifyPkt = function(pkt, iteration)
    pkt.ip4Dst = conf.new_DST_IP4
end

Feature.pktClassifier = {
    function(pkt) return (pkt.dst_ip == conf.new_DST_IP4) end,
}

return Feature
