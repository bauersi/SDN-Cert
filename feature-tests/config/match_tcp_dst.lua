--[[
  Feature test for matching the UDP source and destination port
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
Feature.pkt.PROTO = FeatureConfig.enum.PROTO.tcp

Feature.settings = {
    txIterations = 2,
    new_DST_PORT = 8765,
}
local conf = Feature.settings

Feature.flowEntries = function(openflowVersion, flowData, outPort)
    table.insert(flowData.flows, string.format("table=0, ip, tcp, tcp_dst=%s, actions=DROP", Feature.pkt.DST_PORT))
    table.insert(flowData.flows, string.format("table=0, ip, tcp, tcp_dst=%s, actions=output:%s", conf.new_DST_PORT, outPort))
end

Feature.modifyPkt = function(pkt, iteration)
    pkt.DST_PORT = conf.new_DST_PORT
end

return Feature