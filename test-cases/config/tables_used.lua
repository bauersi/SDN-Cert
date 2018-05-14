--[[
  Test:   direct pass through with two ports depending on number of table entries
  Result: throughput and latency
]]

require "testcase_lib"
  
local Test = {} 

Test.loadGen = "moongen"
Test.files   = "load-latency.lua load-latency-patterns.lua"
Test.lgArgs  = "$file=1 $id $link=1 $link=2 $duration $rate $pktSize $flowpattern $flowpattern_args"
Test.ofArgs  = "$link=1 $link=2 $tableSize $tableCount"

Test.settings = {
  eth_src = "aa:bb:cc:dd:ee:ff",
  eth_dst = "ff:ff:ff:ff:ff:ff",
  eth_type = 0x0800,
  ipv4_src = "10.0.0.0",
  ipv4_dst = "10.128.0.0",
  ip_proto = 17,
  udp_src = 1234,
  udp_dst = 5678,
  BASE_IP = "10.0.0.0",
}

Test.checkFeatures = function(openflowVersion, testcase, isFeatureSupported)
  local requiredFeatures = { "match_inport", "match_eth_src", "match_eth_dst", "match_eth_type", "match_ipv4_src", "match_ipv4_dst", "match_ip_proto", "match_udp_src", "match_udp_dst" }
  return TestcaseConfig.checkFeatures(requiredFeatures, isFeatureSupported)
end

Test.flowEntries = function(openflowVersion, flowData, inPort, outPort, tableSize, tableCount)
  tableCount = tonumber(tableCount)
  tableSize = tonumber(tableSize)

  local addFlows = function (flows, flow, tableSize, x)
    local mac = TestcaseConfig.MAC.parse("10:00:00:00:00:00")
    for i=1,tableSize do
      local macStr = TestcaseConfig.MAC.tostring(mac)
      if x == 2 then
        table.insert(flows, string.format("eth_src=%s, %s", macStr, flow))
      else
        table.insert(flows, string.format("eth_dst=%s, %s", macStr, flow))
      end
      TestcaseConfig.MAC.incAndWrap(mac)
    end

    table.insert(flows, flow)
  end

  local flow
  if tableCount <= 1 then
    flow = string.format("table=0, in_port=%s , actions=OUTPUT:%s",  inPort, outPort)
    addFlows(flowData.flows, flow, tableSize, 0)
    return
  end

  flow = string.format("table=0, in_port=%s , actions=goto_table:1",  inPort)
  addFlows(flowData.flows, flow, tableSize, 0)

  local x = 0
  for i=1, tableCount-2, 1 do
    x = x + 1
    if x == 1 then
      flow = string.format("table=%s, eth_src=%s, actions=goto_table:%s",  i, Test.settings.eth_src, i+1)
    elseif x == 2 then
      flow = string.format("table=%s, eth_dst=%s, actions=goto_table:%s",  i, Test.settings.eth_dst, i+1)
    elseif x == 3 then
      flow = string.format("table=%s, eth_type=%s, actions=goto_table:%s",  i, Test.settings.eth_type, i+1)
    elseif x == 4 then
      flow = string.format("table=%s, eth_type=%s, ipv4_src=%s, actions=goto_table:%s",  i, Test.settings.eth_type, Test.settings.ipv4_src, i+1)
    elseif x == 5 then
      flow = string.format("table=%s, eth_type=%s, ipv4_dst=%s, actions=goto_table:%s",  i, Test.settings.eth_type, Test.settings.ipv4_dst, i+1)
    elseif x == 6 then
      flow = string.format("table=%s, eth_type=%s, ip_proto=%s, actions=goto_table:%s",  i, Test.settings.eth_type, Test.settings.ip_proto, i+1)
    elseif x == 7 then
      flow = string.format("table=%s, eth_type=%s, ip_proto=%s, udp_src=%s, actions=goto_table:%s",  i, Test.settings.eth_type, Test.settings.ip_proto, Test.settings.udp_src, i+1)
    elseif x == 8 then
      flow = string.format("table=%s, eth_type=%s, ip_proto=%s, udp_dst=%s, actions=goto_table:%s",  i, Test.settings.eth_type, Test.settings.ip_proto, Test.settings.udp_dst, i+1)
      x=0
    end

    addFlows(flowData.flows, flow, tableSize, x)
  end

  flow = string.format("table=%s, eth_src=%s, eth_type=%s, actions=OUTPUT:%s", tableCount-1, Test.settings.eth_src, Test.settings.eth_type, outPort)
  addFlows(flowData.flows, flow, tableSize, 0)
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