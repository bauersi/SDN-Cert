--[[
  Feature test for normal hybrid L2/L3 behavior
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow10"
Feature.state   = "optional"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link=1 $link=2"
    
Feature.pkt = Feature.getDefaultPkt()

Feature.settings = { 
}

Feature.flowEntries = function(openflowVersion, flowData, outPort)
    table.insert(flowData.flows, "priority=1, actions=NORMAL")
    table.insert(flowData.flows, "priority=0, actions=DROP")
  end

return Feature
