--[[
  Test:   Chain Packets through several groups
  Result: throughput and latency
]]

require "testcase_lib"

local Test = {}

Test.loadGen = "moongen"
Test.files   = "load-latency.lua load-latency-patterns.lua"
Test.lgArgs  = "$file=1 $id $link=1 $link=2 $duration $rate $pktSize rnd 1"
Test.ofArgs  = "$chainLength $link=2"

Test.units = {
    rate = "Mbps",
    duration = "sec",
    pktsize = "Bytes",
}

Test.settings = {
}
local conf = Test.settings

Test.checkFeatures = function(openflowVersion, testcase, isFeatureSupported)
    if isFeatureSupported("action_group_all_2port") then
        return {}
    else
        return { "action_group_all_2port" }
    end
end

Test.flowEntries = function(openflowVersion, flowData, chainLength, outPort)
    chainLength = tonumber(chainLength)

    table.insert(flowData.groups, string.format("group_id=%s, type=all, bucket=mod_nw_src=10.0.2.%s,output:%s", chainLength, chainLength, outPort))
    for i=1,chainLength-1 do
        table.insert(flowData.groups, string.format("group_id=%s, type=all, bucket=mod_nw_src=10.0.2.%s,group:%s", chainLength-i, chainLength-i, chainLength-i+1))
    end
    table.insert(flowData.flows, "actions=group:1")
end

Test.metric = { "load", "latency" }

return Test
