--[[
  Test:   Forward packets with different tagged vlans and modify vlan vid
  Result: throughput and latency
]]

require "testcase_lib"

local Test = {}

Test.loadGen = "moongen"
Test.files   = "vlan-load-latency.lua load-latency-patterns.lua"
Test.lgArgs  = "$file=1 $id $link=1 $link=2 $vlans $duration $rate $pktSize rnd 1"
Test.ofArgs  = "$vlans $link=2"

Test.units = {
    rate = "Mbps",
    duration = "sec",
    pktsize = "Bytes",
}

Test.settings = {
}
local conf = Test.settings

Test.checkFeatures = function(openflowVersion, testcase, isFeatureSupported)
    if isFeatureSupported("modify_vlan") then
        return {}
    else
        return { "modify_vlan" }
    end
end

Test.flowEntries = function(openflowVersion, flowData, vlans, outPort)
    vlans  = tonumber(vlans)

    for i=1,vlans do
        table.insert(flowData.flows, string.format("dl_vlan=%s, actions=mod_vlan_vid:%s,output:%s", i, i+1, outPort))
    end
end

Test.metric = { "load", "latency" }

return Test
