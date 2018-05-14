--[[
  Feature test for modifying IP TTL or IPv6 hop limit value
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow11"
Feature.state   = "recommended"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link=1 $link=2"
Feature.ofArgs  = "$link=2"
    
Feature.pkt = Feature.getDefaultPkt()

Feature.settings = {
  new_TTL = Feature.enum.TTL.min,
}
local conf = Feature.settings

Feature.flowEntries = function(openflowVersion, flowData, outPort)
    local tableId = ""
    if (compareVersion("OpenFlow10", openflowVersion) > 0) then
        tableId = "table=0, "
    end
    table.insert(flowData.flows, string.format("%sip, actions=mod_nw_ttl:%s, output:%s", tableId, conf.new_TTL, outPort))
    table.insert(flowData.flows, string.format("%sipv6, actions=mod_nw_ttl:%s, output:%s", tableId, conf.new_TTL, outPort))
  end

Feature.pktClassifier = {
    function(pkt) return (pkt.ttl == conf.new_TTL) end
  }

return Feature