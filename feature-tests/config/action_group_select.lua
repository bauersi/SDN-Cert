--[[
  Feature test for group type SELECT
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow15" --because of selection_method with fields
Feature.state   = "optional"

Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link=1 $link=2 $link=3"
Feature.ofArgs  = "$link=2 $link=3"

Feature.pkt = Feature.getDefaultPkt()

Feature.settings = {
  ctrType = "all",
  txIterations = 2,
  new_SRC_IP4 = "10.0.2.1",
  new_DST_IP4 = "10.0.2.2",
}
local conf = Feature.settings
local OF_selection_algorithm = "selection_method=hash, selection_method_param=3, fields(ip_src, ip_dst)"

Feature.flowEntries = function(openflowVersion, flowData, outPort1, outPort2)
  table.insert(flowData.groups, string.format("group_id=1, type=select, %s, bucket=output:%s, bucket=output:%s", OF_selection_algorithm, outPort1, outPort2))
  table.insert(flowData.flows, "actions=group:1")
end

Feature.pktClassifier = {
  function(pkt) return (pkt.src_ip == conf.new_SRC_IP4 and pkt.dst_ip == conf.new_DST_IP4) end,
  function(pkt) return (pkt.src_ip ~= conf.new_SRC_IP4 and pkt.dst_ip ~= conf.new_DST_IP4) end,
}

Feature.evalCounters = function(ctrs, batch, threshold)
  return (Feature.eval(ctrs[1],batch,threshold) and Feature.eval(ctrs[2],batch,threshold))
end

Feature.modifyPkt = function(pkt, iteration)
  pkt.SRC_IP4 = conf.new_SRC_IP4
  pkt.DST_IP4 = conf.new_DST_IP4
end

return Feature
