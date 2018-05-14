--[[
  Test:   direct pass through with two ports depending on number of table entries
  Result: throughput and latency
]]

require "testcase_lib"
  
local Test = {} 

Test.loadGen = "moongen"
Test.files   = "load-latency.lua load-latency-patterns.lua"
Test.lgArgs  = "$file=1 $id $link=1 $link=2 $duration $rate $pktSize $flowpattern $flowpattern_args"
Test.ofArgs  = "$tableSize $link=2"
   
Test.settings = {
  BASE_IP = "10.128.0.0",
}

Test.checkFeatures = function(openflowVersion, testcase, isFeatureSupported)
  local requiredFeatures = {}
  if (compareVersion("OpenFlow10", openflowVersion) > 0) then
    table.insert(requiredFeatures, "match_ipv4_dst")
  else
    table.insert(requiredFeatures, "match_ipv4")
  end

  return TestcaseConfig.checkFeatures(requiredFeatures, isFeatureSupported)
end

Test.flowEntries = function(openflowVersion, flowData, tableSize, outPort)
  local tag = "nw"
  if (compareVersion("OpenFlow10", openflowVersion) > 0) then tag = "ipv4" end
  local pkt = Test.settings
  local ip = TestcaseConfig.IP.parseIP(pkt.BASE_IP)
  for i=1,tonumber(tableSize) do
    local currentMatch = TestcaseConfig.IP.getIP(ip)
    TestcaseConfig.IP.incAndWrap(ip)
    table.insert(flowData.flows, "ip, " ..tag .. "_dst=" .. currentMatch ..", actions=" .. "output:" .. outPort)
  end
end

Test.units = {
  duration = "s",
  rate = "MBit/s",
  pktsize = "Bytes",
  flowpattern = "Type Of Flowpattern",
  flowpatternargs = "Argument For Flowpattern",
  tablesize = "Number Of Flows"
}

Test.metric = { "load", "frameloss", "latency", "throughput" }

return Test