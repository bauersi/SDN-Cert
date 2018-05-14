--[[
  Test:   static L3-router with TTL decrement
  Result: throughput and latency
]]

require "testcase_lib"

local parseFilterString = function (filterString)
    filterString = string.replaceAll(filterString,'"', "") -- remove "
    filterString = string.replaceAll(filterString,"'", "") -- remove '
    return string.split(filterString, "+")
end

local Test = {} 

Test.checkFeatures = function(openflowVersion, testcase, isFeatureSupported)
    local filterString = testcase:getInitalValueOfParameter('filter')
    local filters = parseFilterString(filterString)

    local requiredFeatures = {}
    if (compareVersion("OpenFlow10", openflowVersion) > 0) then
        requiredFeatures["inport"] = "match_inport"
        requiredFeatures["ip"] = "match_eth_type"
        requiredFeatures["udp"] = "match_ip_proto"
        requiredFeatures["tcp"] = "match_ip_proto"
    else
        requiredFeatures["inport"] = "match_inport"
        requiredFeatures["ip"] = "match_ethertype"
        requiredFeatures["udp"] = "match_l4proto"
        requiredFeatures["tcp"] = "match_l4proto"
    end

    local modifierString = testcase:getInitalValueOfParameter('modifier')
    if string.find(modifierString, "udp_dst") ~= nil then
        testcase.settings["udpdstport"] = Test.settings.DST_PORT_Modify
    else
        testcase.settings["udpdstport"] = ''
    end

    return TestcaseConfig.checkFeaturesForKeys(filters, requiredFeatures, isFeatureSupported)
end

Test.loadGen = "moongen"
Test.files   = "load-latency.lua load-latency-patterns.lua"
Test.lgArgs  = "$file=1 $id $link=1 $link=2 $duration $rate $pktSize $flowpattern $flowpattern_args $udpDstPort"
Test.ofArgs  = "$link=1 $link=2 $filter $modifier"

Test.settings = {
    SRC_MAC_Filter = "aa:bb:cc:dd:ee:ff",
    DST_MAC_Filter = "ff:ff:ff:ff:ff:ff",
    SRC_MAC_Modify = "55:44:33:22:11:00",
    DST_MAC_Modify = "00:11:22:33:44:55",
    SRC_IP_Modify = "10.64.0.0",
    DST_IP_Modify = "10.192.0.0",
    SRC_PORT_Modify = 4321,
    DST_PORT_Modify = 8765,
}

Test.units = {
    rate = "Mbps",
    duration = "sec",
    numip = "",
    pktsize = "Bytes",
    filter = ""
}

Test.flowEntries = function(openflowVersion, flowData, inPort, outPort, filterString, modifyString)
    local pkt = Test.settings

    local match = {}
    local filters = parseFilterString(filterString)
    for _,filter in pairs(filters) do
        if (filter == "inport") then
            table.insert(match, "in_port=" .. tostring(inPort))
        elseif (filter == "ip") then
            table.insert(match, "ip")
        elseif (filter == "udp") then
            table.insert(match, "udp")
        elseif filter ~= "" then
            error("invalid filter")
        end
    end

    local modify = {}
    local modifiers = parseFilterString(modifyString)
    for _,modifier in pairs(modifiers) do
        if (modifier == "mac_src") then
            if (compareVersion("OpenFlow10", openflowVersion) > 0) then
                table.insert(modify, "set_field:"..pkt.SRC_MAC_Modify.."->eth_src")
            else
                table.insert(modify, "mod_dl_src:" .. pkt.SRC_MAC_Modify)
			end
        elseif (modifier == "mac_dst") then
            if (compareVersion("OpenFlow10", openflowVersion) > 0) then
				table.insert(modify, "set_field:"..pkt.DST_MAC_Modify.."->eth_dst")
			else
            	table.insert(modify, "mod_dl_dst:" .. pkt.DST_MAC_Modify)
            end
        elseif (modifier == "ip_src") then
            if (compareVersion("OpenFlow10", openflowVersion) > 0) then
                table.insert(modify, "set_field:"..pkt.SRC_IP_Modify.."->ipv4_src")
            else
                table.insert(modify, "mod_nw_src:" .. pkt.SRC_IP_Modify)
            end
        elseif (modifier == "ip_dst") then
            if (compareVersion("OpenFlow10", openflowVersion) > 0) then
                table.insert(modify, "set_field:"..pkt.DST_IP_Modify.."->ipv4_dst")
            else
                table.insert(modify, "mod_nw_dst:" .. pkt.DST_IP_Modify)
            end
        elseif (modifier == "udp_src") then
            if (compareVersion("OpenFlow10", openflowVersion) > 0) then
                table.insert(modify, "set_field:"..pkt.SRC_PORT_Modify.."->udp_src")
            else
                table.insert(modify, "mod_tp_src:" .. pkt.SRC_PORT_Modify)
            end
        elseif (modifier == "udp_dst") then
            if (compareVersion("OpenFlow10", openflowVersion) > 0) then
                table.insert(modify, "set_field:"..pkt.DST_PORT_Modify.."->udp_dst")
            else
                table.insert(modify, "mod_tp_dst:" .. pkt.DST_PORT_Modify)
            end
        elseif (modifier ~= "") then
            error("invalid modifier '"..modifier.."'")
        end
    end
    table.insert(modify, "output:" .. outPort)

    local flow = string.format("%s, actions=%s", table.concat(match,', '), table.concat(modify,', '))
    table.insert(flowData.flows, flow)
  end

Test.metric = { "load", "frameloss", "latency", "throughput" }

return Test