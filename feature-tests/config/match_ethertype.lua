--[[
  Feature test for matching Ethertype
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
  new_ETH_TYPE = Feature.enum.ETH_TYPE.wol,
}
local conf = Feature.settings

Feature.flowEntries = function(openflowVersion, flowData, outPort)
    local tableId = ""
    if (compareVersion("OpenFlow10", openflowVersion) > 0) then
        tableId = "table=0, "
    end
    table.insert(flowData.flows, string.format("%sdl_type=%s, actions=DROP", tableId, Feature.enum.ETH_TYPE.ip4, outPort))
    table.insert(flowData.flows, string.format("%sdl_type=%s, actions=DROP", tableId, Feature.enum.ETH_TYPE.ip6, outPort))
    table.insert(flowData.flows, string.format("%sdl_type=%s, actions=output:%s", tableId, conf.new_ETH_TYPE, outPort))
end
	
Feature.modifyPkt = function(pkt, iteration)
    pkt.ETH_TYPE = conf.new_ETH_TYPE
    pkt.PROTO = Feature.enum.PROTO.undef
end

return Feature