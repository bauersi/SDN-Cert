--[[
  Test:   direct pass through with two ports depending on number of table entries
  Result: throughput and latency
]]

require "testcase_lib"

local Test = {}

Test.loadGen = "moongen"
Test.files   = "load-latency.lua load-latency-patterns.lua"
Test.lgArgs  = "$file=1 $id $link=1 $link=2 $duration $rate $pktSize $flowpattern $flowpattern_args"
Test.ofArgs  = "$meterCount $meterRate $link=2"

Test.settings = {
  BASE_IP = "10.128.0.0",
}

Test.checkFeatures = function(openflowVersion, testcase, isFeatureSupported)
  local requiredFeatures = {}
  table.insert(requiredFeatures, "match_ipv4_dst")
  table.insert(requiredFeatures, "install_meter")

  return TestcaseConfig.checkFeatures(requiredFeatures, isFeatureSupported)
end

Test.flowEntries = function(openflowVersion, flowData, meterCount, meterRate, outPort)
  local pkt = Test.settings
  local ip = TestcaseConfig.IP.parseIP(pkt.BASE_IP)
  for i=1,tonumber(meterCount) do
    local currentMatch = TestcaseConfig.IP.getIP(ip)
    TestcaseConfig.IP.incAndWrap(ip)
    table.insert(flowData.flows, string.format("ip, nw_dst=%s, actions=meter:%s,output:%s", currentMatch, i, outPort))
    table.insert(flowData.meters, string.format("meter=%s,kbps,bands=type=drop,rate=%s", i, tonumber(meterRate)))
  end
end

Test.units = {
  duration = "s",
  rate = "MBit/s",
  meterrate = "Kbit/s",
  pktsize = "Bytes",
  flowpattern = "Type Of Flowpattern",
  flowpatternargs = "Argument For Flowpattern",
  tablesize = "Number Of Flows"
}

Test.metric = { "load", "latency"}

return Test