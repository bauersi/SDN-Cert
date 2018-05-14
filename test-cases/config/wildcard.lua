--[[
  Test:   matching on all given fields of an UDP/TCP packet
          possible matches are macs, ips, proto, ports 
  Result: throughput and latency
]]

require "testcase_lib"
  
local Test = {}

local parseFilterString = function (filterString)
    filterString = string.replaceAll(filterString,'"', "") -- remove "
    filterString = string.replaceAll(filterString,"'", "") -- remove '
    return string.split(filterString, "+")
end

Test.checkFeatures = function(openflowVersion, testcase, isFeatureSupported)
    local filterString = testcase:getInitalValueOfParameter('filter')
    local filters = parseFilterString(filterString)

    local requiredFeatures = {}
    if (compareVersion("OpenFlow10", openflowVersion) > 0) then
        requiredFeatures["mac_src"] = "match_eth_src"
        requiredFeatures["mac_dst"] = "match_eth_dst"
        requiredFeatures["ip_src"] = "match_ipv4_src"
        requiredFeatures["ip_dst"] = "match_ipv4_dst"
    else
        requiredFeatures["mac_src"] = "match_l2addr"
        requiredFeatures["mac_dst"] = "match_l2addr"
        requiredFeatures["ip_src"] = "match_ipv4"
        requiredFeatures["ip_dst"] = "match_ipv4"
    end

    return TestcaseConfig.checkFeaturesForKeys(filters, requiredFeatures, isFeatureSupported)
end
 
Test.loadGen = "moongen"
Test.files   = "load-latency.lua load-latency-patterns.lua"
Test.lgArgs  = "$file=1 $id $link=1 $link=2 $duration $rate $pktSize $flowpattern $flowpattern_args"
Test.ofArgs  = "$link=1 $link=2 $filter"

Test.settings = {
  SRC_MAC = "aa:bb:cc:dd:ee:ff",
  DST_MAC = "ff:ff:ff:ff:ff:ff",
  SRC_MAC_MASK = "ff:ff:00:00:ff:ff",
  DST_MAC_MASK = "00:ff:00:00:ff:00",
  SRC_IP = "10.0.0.0",
  DST_IP = "10.128.0.0",
  SRC_IP_MASK = "24",
  DST_IP_MASK = "24",
  PROTO = "udp",
  SRC_PORT = 1234,
  DST_PORT = 5678,
}

Test.flowEntries = function(openflowVersion, flowData, inPort, outPort, filterString)
    local pkt = Test.settings
    local match = {}
    local filters = parseFilterString(filterString)
    local ip = false
    for _,filter in pairs(filters) do
        if (filter == "mac_src") then
            local tag = "dl"
            if (compareVersion("OpenFlow10", openflowVersion) > 0) then tag = "eth" end
            table.insert(match, string.format("%s_src=%s/%s", tag, pkt.SRC_MAC, pkt.SRC_MAC_MASK))
        elseif (filter == "mac_dst") then
            local tag = "dl"
            if (compareVersion("OpenFlow10", openflowVersion) > 0) then tag = "eth" end
            table.insert(match, string.format("%s_dst=%s/%s", tag, pkt.DST_MAC, pkt.DST_MAC_MASK))
        elseif (filter == "ip_src") then
            ip = true
            local tag = "nw"
            if (compareVersion("OpenFlow10", openflowVersion) > 0) then tag = "ipv4" end
            table.insert(match, string.format("%s_src=%s/%s", tag, pkt.SRC_IP, pkt.SRC_IP_MASK))
        elseif (filter == "ip_dst") then
            ip = true
            local tag = "nw"
            if (compareVersion("OpenFlow10", openflowVersion) > 0) then tag = "ipv4" end
            table.insert(match, string.format("%s_dst=%s/%s", tag, pkt.DST_IP, pkt.DST_IP_MASK))
        end
    end
    if (ip) then table.insert(match, "ip") end
    local flow = string.format("%s, actions=output:%d", table.concat(match,', '), outPort)
    table.insert(flowData.flows, flow)
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