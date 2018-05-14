--[[
  Feature test for flooding packets
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow10"
Feature.state   = "optional"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link=1 $link=2 $link=3"
    
Feature.pkt = Feature.getDefaultPkt()

Feature.settings = {
  ctrType = "all",
}

Feature.flowEntries = function(openflowVersion, flowData, outPort)
    table.insert(flowData.flows, "actions=FLOOD")
  end

Feature.evalCounters = function(ctrs, batch, threshold)
    return (Feature.eval(ctrs[1]/2,batch,threshold))
  end

return Feature
