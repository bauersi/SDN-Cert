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
    new_SRC_PORT = 4321,
}
local conf = Feature.settings

Feature.flowEntries = function(openflowVersion, flowData, outPort)
    table.insert(flowData.flows, string.format("table=0, ip, udp, actions=set_field:%s->udp_src, output:%s", conf.new_SRC_PORT, outPort))
end

Feature.modifyPkt = function(pkt, iteration)
    pkt.udpSrc = conf.new_SRC_PORT
end

Feature.pktClassifier = {
    function(pkt) return (pkt.src_port == conf.new_SRC_PORT) end,
}

return Feature