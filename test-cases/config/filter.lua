--[[
  Test:   matching on all given fields of an UDP/TCP packet
          possible matches are macs, ips, proto, ports 
  Result: throughput and latency
]]

require "testcase_lib"
  
local Test = {}

Test.loadGen = "moongen"
Test.files   = "load-latency.lua load-latency-patterns.lua"
Test.lgArgs  = "$file=1 $id $link=1 $link=2 $duration $rate $pktSize $flowpattern $flowpattern_args"
Test.ofArgs  = "$link=1 $link=2 $filter"

Test.settings = {
  SRC_MAC = "aa:bb:cc:dd:ee:ff",
  DST_MAC = "ff:ff:ff:ff:ff:ff",
  SRC_IP = "10.0.0.0",
  DST_IP = "10.128.0.0",
  PROTO = "udp",
  SRC_PORT = 1234,
  DST_PORT = 5678,
}

Test.units = {
    rate = "Mbps",
    duration = "sec",
    numip = "",
    pktsize = "Bytes",
    filter = ""
}

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
        local udp, tcp = false, false
        for _,filter in pairs(filters) do
            if filter=="udp" then udp = true break end
            if filter=="tcp" then tcp = true break end
        end
        requiredFeatures["inport"] = "match_inport"
        requiredFeatures["mac_src"] = "match_eth_src"
        requiredFeatures["mac_dst"] = "match_eth_dst"
        requiredFeatures["ip"] = "match_eth_type"
        requiredFeatures["ip_src"] = "match_ipv4_src"
        requiredFeatures["ip_dst"] = "match_ipv4_dst"
        requiredFeatures["udp"] = "match_ip_proto"
        requiredFeatures["tcp"] = "match_ip_proto"
        requiredFeatures["port_src"] = (udp and "match_udp_src") or (tcp and "match_tcp_src")
        requiredFeatures["port_dst"] = (udp and "match_udp_dst") or (tcp and "match_tcp_dst")
    else
        requiredFeatures["inport"] = "match_inport"
        requiredFeatures["mac_src"] = "match_l2addr"
        requiredFeatures["mac_dst"] = "match_l2addr"
        requiredFeatures["ip"] = "match_ethertype"
        requiredFeatures["ip_src"] = "match_ipv4"
        requiredFeatures["ip_dst"] = "match_ipv4"
        requiredFeatures["udp"] = "match_l4proto"
        requiredFeatures["tcp"] = "match_l4proto"
        requiredFeatures["port_src"] = "match_l4port"
        requiredFeatures["port_dst"] = "match_l4port"
    end

    return TestcaseConfig.checkFeaturesForKeys(filters, requiredFeatures, isFeatureSupported)
end

Test.flowEntries = function(openflowVersion, flowData, inPort, outPort, filterString)
    local pkt = Test.settings
    local filters = parseFilterString(filterString)
    local match = {}
    local udp, tcp = false, false
    for _,filter in pairs(filters) do
        if (filter == "inport") then
            table.insert(match, "in_port=" .. tostring(inPort))
        elseif (filter == "mac_src") then
            local tag = "dl"
            if (compareVersion("OpenFlow10", openflowVersion) > 0) then tag = "eth" end
            table.insert(match, tag.."_src="..pkt.SRC_MAC)
        elseif (filter == "mac_dst") then
            local tag = "dl"
            if (compareVersion("OpenFlow10", openflowVersion) > 0) then tag = "eth" end
            table.insert(match, tag.."_dst="..pkt.DST_MAC)
        elseif (filter == "ip") then
            table.insert(match, "ip")
        elseif (filter == "ip_src") then
            local tag = "nw"
            if (compareVersion("OpenFlow10", openflowVersion) > 0) then  tag = "ipv4" end
            table.insert(match, tag.."_src="..pkt.SRC_IP)
        elseif (filter == "ip_dst") then
            local tag = "nw"
            if (compareVersion("OpenFlow10", openflowVersion) > 0) then tag = "ipv4" end
            table.insert(match, tag.."_dst="..pkt.DST_IP)
        elseif (filter == "udp") then
            udp = true
            table.insert(match, "udp")
        elseif (filter == "tcp") then
            tcp = true
            table.insert(match, "tcp")
        elseif (filter == "port_src") then
            local tag = "tp"
            if (compareVersion("OpenFlow10", openflowVersion) > 0) then
                if udp then     tag="udp"
                elseif tcp then tag="tcp"
                else error("requires udp or tcp")
                end
            end
            table.insert(match, tag.."_src="..pkt.SRC_PORT)
        elseif (filter == "port_dst") then
            local tag = "tp"
            if (compareVersion("OpenFlow10", openflowVersion) > 0) then
                if udp then     tag="udp"
                elseif tcp then tag="tcp"
                else error("requires udp or tcp")
                end
            end
            table.insert(match, tag.."_dst="..pkt.DST_PORT)
        else
            error("invalid filter")
        end
    end
    local flow = string.format("%s, actions=output:%d", table.concat(match,', '), outPort)
    table.insert(flowData.flows, flow)
end
  
Test.metric = { "load", "frameloss", "latency", "throughput" }

return Test