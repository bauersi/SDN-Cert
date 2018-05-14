--[[
  Feature test for installing a meter
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow13"
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
    new_SRC_IP4 = "10.0.2.1",
}
local conf = Feature.settings

Feature.flowEntries = function(openflowVersion, flowData, inPort, outPort)
    table.insert(flowData.meters, "meter=1, kbps, band=type=drop, rate=1000")
    table.insert(flowData.flows, string.format("table=0, ip, in_port=%s, actions=meter:1,mod_nw_src:%s,output:%s", inPort, conf.new_SRC_IP4, outPort))
    table.insert(flowData.flows, string.format("in_port=%s, actions=drop", outPort))
end

Feature.modifyPkt = function(pkt, iteration)
    pkt.TX_DEV = conf.new_TX_DEV
end

Feature.pktClassifier = {
    function(pkt) return (pkt.src_ip == conf.new_SRC_IP4) end,
}

return Feature
