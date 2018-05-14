--[[
  Feature test for sending packets to 2 indirect groups in one action task
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow11"
Feature.state   = "required"

Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link=1 $link=2 $link=3"
Feature.ofArgs  = "$link=2 $link=3"

Feature.pkt = Feature.getDefaultPkt()

Feature.settings = {
  ctrType = "any",
  new_SRC_IP4 = "10.0.2.1",
  new_DST_IP4 = "10.0.2.2",
}
local conf = Feature.settings

Feature.flowEntries = function(openflowVersion, flowData, outPort1, outPort2)
  table.insert(flowData.groups, string.format("group_id=1, type=indirect, bucket=mod_nw_src=%s,output:%s", conf.new_SRC_IP4, outPort1))
  table.insert(flowData.groups, string.format("group_id=2, type=indirect, bucket=mod_nw_dst=%s,output:%s", conf.new_DST_IP4, outPort2))
  table.insert(flowData.flows, "actions=group:1,group:2")
end

Feature.pktClassifier = {
  function(pkt) return (pkt.src_ip == conf.new_SRC_IP4) end,
  function(pkt) return (pkt.dst_ip == conf.new_DST_IP4) end,
}

return Feature
