-- Test-case library

TestcaseConfig = {}
TestcaseConfig.__index = TestcaseConfig

function TestcaseConfig.new()
  return setmetatable({}, TestcaseConfig)
end

TestcaseConfig.IP = {
    parseIP = function(addr)
        local oct1,oct2,oct3,oct4 = addr:match("(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)")
        return {oct1, oct2, oct3, oct4}
    end,
    incAndWrap = function(ip)
        ip[4] = ip[4] + 1
        for oct=4,1,-1 do
            if (ip[oct] > 255) then
                ip[oct] = 0
                ip[oct-1] = ip[oct-1] + 1
            else break end
        end
        if (ip[0]) then
            ip[0] = nil
            ip[4] = 0
        end
    end,
    getIP = function(ip)
        local addr = tostring(ip[1])
        for i=2,4 do addr = addr .. "." .. tostring(ip[i]) end
        return addr
    end
}

TestcaseConfig.MAC = {
    parse = function(mac)
        local bytes = {string.match(mac:lower(), '(%x+)[-:](%x+)[-:](%x+)[-:](%x+)[-:](%x+)[-:](%x+)')}
        if bytes == nil then
            return
        end
        for i = 1, 6 do
            if bytes[i] == nil then
                return
            end
            bytes[i] = tonumber(bytes[i], 16)
            if  bytes[i] < 0 or bytes[i] > 0xFF then
                return
            end
        end
        return bytes
    end,
    incAndWrap = function(mac)
        mac[6] = mac[6] + 1
        for oct=6,1,-1 do
            if (mac[oct] > 255) then
                mac[oct] = 0
                mac[oct-1] = mac[oct-1] + 1
            else break end
        end
        if (mac[0]) then
            mac[0] = nil
            mac[6] = 0
        end
    end,
    tostring = function(mac)
        local addr = string.format("%02x", mac[1])
        for i=2,6 do addr = addr .. ":" .. string.format("%02x", mac[i]) end
        return addr
    end,
}

TestcaseConfig.checkFeatures = function (requiredFeature, isFeatureSupported)
    local unsupportedFeatures = {}
    for _,feature in pairs(requiredFeature) do
        if not isFeatureSupported(feature) then
            table.insert(unsupportedFeatures,feature)
        end
    end
    return unsupportedFeatures
end


TestcaseConfig.checkFeaturesForKeys = function (keys, requiredFeature, isFeatureSupported)
    local unsupportedFeatures = {}
    for _,key in pairs(keys) do
        local feature = requiredFeature[key]
        if not isFeatureSupported(feature) then
            table.insert(unsupportedFeatures,feature)
        end
    end
    return unsupportedFeatures
end

return TestcaseConfig