--[[
  Test:   direct pass through with two ports
  Result: throughput and latency
]]

require "testcase_lib"

local Test = {}

Test.require = "match_inport"

Test.loadGen = "moongen"
Test.files   = "load-latency.lua load-latency-patterns.lua"
Test.lgArgs  = "$file=1 $id $link=1 $link=2 $duration $rate $pktSize rnd 1"
Test.ofArgs  = "$link=1 $link=2"

Test.units = {
    rate = "Mbps",
    duration = "sec",
    pktsize = "Bytes",
}

Test.checkFeatures = function(openflowVersion, testcase, isFeatureSupported)
    if isFeatureSupported("match_inport") then
        return {}
    else
        return { "match_inport" }
    end
end

Test.flowEntries = function(openflowVersion,flowData, inPort, outPort)
    local flow = string.format("in_port=%s, actions=output:%s", inPort, outPort)
    table.insert(flowData.flows, flow)
end

Test.metric = { "load", "latency" }

return Test