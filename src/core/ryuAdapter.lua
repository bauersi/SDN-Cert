RyuAdapter = {}
RyuAdapter.__index = RyuAdapter

--------------------------------------------------------------------------------
--  class for managing an OpenFlow Controller Ryu
--------------------------------------------------------------------------------

--- Creates a new instance for an OF-Controller
function RyuAdapter.create()
    local self = setmetatable({}, RyuAdapter)
    self.ip      = settings.config[global.controllerIP] or "127.0.0.1"
    self.port    = tostring(settings.config[global.controllerPort]) or "8080"
    self.switch  = settings.config[global.controllerSwitchId]
    return self
end

local function getUrl(adapter, page)
    return string.format("http://%s:%s/%s", adapter.ip, adapter.port, page)
end

local function prepareGetCommand (adapter, page)
    return "curl -X GET " .. getUrl(adapter, page)
end

local function preparePostCommand (adapter, page, payload)
    return string.format("curl -X POST -d '%s' %s", payload, getUrl(adapter, page))
end

local function prepareDeleteCommand (adapter, page)
    return "curl -X DELETE " .. getUrl(adapter, page)
end

function RyuAdapter:delFlows()
    local delFlows = prepareDeleteCommand(self, "stats/flowentry/clear/"..self.switch)
    local cmd = CommandLine.create(delFlows)
    cmd:execute(settings.config.verbose)
end

function RyuAdapter:delGroups()
    -- TODO: impementation
    return "not implemented"
end

-- TODO: find better implementation!
function RyuAdapter:delMeters()
    local out = {}
    for i=1, 254 do
        local data = {
            dpid = self.switch,
            meter_id = i
        }
        local json = JSON:encode(data)
        table.insert(out, preparePostCommand(self, "stats/meterentry/delete", json))
    end
    return table.concat(out, "\n")
end

--- Returns the flow dump of the device in the representation of the used version.
function RyuAdapter:dumpFlows()
    local cmd = CommandLine.create(prepareGetCommand(self, "stats/flow/"..self.switch))
    return cmd:execute(settings.config.verbose)
end

--- Returns the group dump of the device in the representation of the used version.
function RyuAdapter:dumpGroups(version)
    -- TODO: impementation
    return "not implemented"
end

--- Returns the meter dump of the device in the representation of the used version.
function RyuAdapter:dumpMeters(version)
    -- TODO: impementation
    return "not implemented"
end

local function parseOptions(data, matchStr)
    local items = string.split(string.lower(matchStr), ',')
    local itemsToRemove = {}
    for id, item in pairs(items) do
        item = string.trim(item)
        if (item ~= "") then
            local keyValuePair = string.split(item, '=')
            local key = string.trim(keyValuePair[1])
            if key == "table" then
                local value = string.trim(keyValuePair[2])
                data.table_id=tonumber(value)
                table.insert(itemsToRemove, id)
            elseif key == "priority" then
                local value = string.trim(keyValuePair[2])
                data.priority=tonumber(value)
                table.insert(itemsToRemove, id)
            end
        end
    end
    for i=#itemsToRemove, 1,-1 do
        table.remove(items, itemsToRemove[i])
    end
    return table.concat(items, ', ')
end

local function parseMatch(match, matchStr)
    local items = string.split(string.lower(matchStr), ',')
    for _, item in pairs(items) do
        item = string.trim(item)
        if (item ~= "") then
            local keyValuePair = string.split(item, '=')
            local key = string.trim(keyValuePair[1])
            if #keyValuePair == 1 then
                if key == "ip" then
                    match.dl_type = 0x0800
                elseif key == "ipv6" then
                    match.dl_type = 0x86dd
                elseif key == "icmp" then
                    match.dl_type = 0x0800
                    match.nw_proto = 1
                elseif key == "icmp6" then
                    match.dl_type = 0x86dd
                    match.nw_proto = 58
                elseif key == "tcp" then
                    match.dl_type = 0x0800
                    match.nw_proto = 6
                elseif key == "tcp6" then
                    match.dl_type = 0x86dd
                    match.nw_proto = 6
                elseif key == "udp" then
                    match.dl_type = 0x0800
                    match.nw_proto = 17
                elseif key == "udp6" then
                    match.dl_type = 0x86dd
                    match.nw_proto = 17
                elseif key == "sctp" then
                    match.dl_type = 0x0800
                    match.nw_proto = 132
                elseif key == "sctp6" then
                    match.dl_type = 0x86dd
                    match.nw_proto = 132
                elseif key == "arp" then
                    match.dl_type = 0x0800
                    match.nw_proto = 132
                elseif key == "rarp" then
                    match.dl_type = 0x8035
                elseif key == "mpls" then
                    match.dl_type = 0x8847
                elseif key == "mplsm" then
                    match.dl_type = 0x8848
                else
                    error("shorthand notation unkown : '" .. item .. "'")
                end
            elseif #keyValuePair == 2 then
                local value = string.trim(keyValuePair[2])
                value = tonumber(value) or value
                match[key] = value
            else
                error("invalid match data : '" .. item .. "'")
            end
        end
    end
end

local function parseActions(actions, actionStr)
    local items = string.split(string.lower(actionStr), ',')
    for _, item in pairs(items) do
        item = string.trim(item)
        if (item ~= "") then
            if string.find(item,":") then
                local keyValuePair = string.split(item, ':', 1)
                local key = string.trim(keyValuePair[1])
                if key == "output" then
                    local value = string.trim(keyValuePair[2])
                    table.insert(actions, {
                        type="OUTPUT" , port=value
                    })
                elseif key == "set_field" then
                    keyValuePair = string.split(keyValuePair[2], '->')
                    key = string.trim(keyValuePair[2])
                    local value = string.trim(keyValuePair[1])
                    value = tonumber(value) or value
                    table.insert(actions, {
                        type="SET_FIELD", field=key, value=value
                    })
                elseif key == "goto_table" then
                    local value = string.trim(keyValuePair[2])
                    value = tonumber(value) or value
                    table.insert(actions, {
                        type="GOTO_TABLE", table_id=value
                    })
                elseif key == "meter" then
                    local value = string.trim(keyValuePair[2])
                    value = tonumber(value) or value
                    table.insert(actions, {
                        type="METER", meter_id=value
                    })
                elseif string.startsWith(key, "mod_") then
                    key = string.sub(key, 5)
                    local action = { type="SET_"..string.upper(key) }
                    local value = string.trim(keyValuePair[2])
                    value = tonumber(value) or value
                    action[key] = value
                    table.insert(actions, action)
                else
                    error("invalid action data : '" .. item .. "'")
                end
            else
                local key = string.trim(item)
                local lowerKey = string.lower(key)
                if lowerKey == "drop" then
                    -- nothing to do because empty actions == DROP
                else
                    error("invalid action data : '" .. item .. "'")
                end
            end
        end
    end
end

local function parseFlow (adapter, flow)
    local startPos, endPos = flow:find("actions=")
    if startPos == nil then
        error("actions is missing : " .. flow)
    end
    local matchStr = flow:sub(1, startPos-1)
    local actionStr = flow:sub(endPos+1)

    local data = {
        dpid=adapter.switch,
        table_id= 0,
        match={},
        actions={}
    }

    matchStr = parseOptions(data, matchStr)
    parseMatch(data.match, matchStr)
    parseActions(data.actions, actionStr)

    return data
end

local function getInstallFlowCommand(adapter, flow)
    local data = parseFlow(adapter, flow)
    local json = JSON:encode(data)
    json = string.replace(json, '"match":[]', '"match":{}')
    return preparePostCommand(adapter, "stats/flowentry/add", json)
end

--- Installs a new flow.
function RyuAdapter:installFlow(flow)
    logger.debug(string.format("Ryu: add flow: '%s'", flow ))
    local cmd = CommandLine.create(getInstallFlowCommand(self, flow))
    logger.debug(cmd:get())
    return cmd:execute(settings.config.verbose) or "none"
end

--- Install a file of flows.
function RyuAdapter:installFlows(file)
    local out = {}
    local f = io.open(file, "rb")
    while (true) do
        local line = f:read("*line")
        if line == nil then break end
        line = string.trim(line)
        if #line > 0 then
            table.insert(out, self:installFlow(line))
        end
    end
    f:close()
    return table.concat(out, "\n")
end

--- Installs a new group.
function RyuAdapter:installGroup(group)
    -- TODO
    return "not implemented"
end

--- Installs a file of groups.
function RyuAdapter:installGroups(file)
    -- TODO
    return "not implemented"
end

local function parseFlags(flags, flagStr)
    local items = string.split(string.lower(flagStr), ',')
    for _, item in pairs(items) do
        item = string.trim(item)
        if (item ~= "") then
            if item == "kbps" or item == "burst" or item == "stats" then
                table.insert(flags, item)
            else
                error("invalid flag : '" .. item .. "'")
            end
        end
    end
end

local function parseBands(bands, bandStr)
    local bandOption = {}
    local items = string.split(string.lower(bandStr), ',')
    for _, item in pairs(items) do
        item = string.trim(item)
        if (item ~= "") then
            local keyValuePair = string.split(item, '=', 1)
            if #keyValuePair < 2 then
                error("invalid band data : '" .. item .. "'")
            end

            local key = string.trim(keyValuePair[1])
            local value = string.trim(keyValuePair[2])
            if key == "type" then
                value = string.upper(value)
            elseif key == "rate" or key == "burst_size" then
                value = tonumber(value) or value
            else
                error("invalid band data : '" .. item .. "'")
            end
            bandOption[key] = value
        end
    end
    table.insert(bands, bandOption)
end

local function parseMeter(adapter, meter)
    local startPos, endPos = meter:find("bands=")
    if startPos == nil then
        error("actions is missing : " .. meter)
    end
    local optionsStr = meter:sub(1, startPos-1)
    local bandsStr = meter:sub(endPos+1)

    local data = {
        dpid=adapter.switch,
        meter_id= 0,
        flags={},
        bands={}
    }

    local startPos, endPos = optionsStr:find("meter=")
    if startPos == nil then
        error("meter id missing")
    else
        -- (table=1, kbps, ...) or (kbps, ..., meter=1)
        local parts = string.split(optionsStr:sub(endPos+1), ',', 1)
        data.meter_id=tonumber(parts[1])
        optionsStr = string.replace(optionsStr, "meter="..parts[1]..',', "")
    end

    parseFlags(data.flags, optionsStr)
    parseBands(data.bands, bandsStr)

    return data
end

local function getInstallMeterCommand(adapter, flow)
    local data = parseMeter(adapter, flow)
    local json = JSON:encode(data)
    return preparePostCommand(adapter, "stats/meterentry/add", json)
end

--- Installs a new meter.
function RyuAdapter:installMeter(meter)
    logger.debug(string.format("Ryu: add meter: '%s'", meter ))
    local cmd = CommandLine.create(getInstallMeterCommand(self, meter))
    logger.debug(cmd:get())
    return cmd:execute(settings.config.verbose) or "none"
end

--- Installs a file of meters.
function RyuAdapter:installMeters(file)
    local out = {}
    local f = io.open(file, "rb")
    while (true) do
        local line = f:read("*line")
        if line == nil then break end
        line = string.trim(line)
        if #line > 0 then
            table.insert(out, self:installMeter(line))
        end
    end
    f:close()
    return table.concat(out, "\n")
end

local function readFile(filepath)
    local file = assert(io.open(filepath, "r"))
    local content = file:read("*all")
    file:close()
    return content
end

function RyuAdapter:getPorts()
    local cmd = CommandLine.create(prepareGetCommand(self,"stats/port/"..self.switch) .. " -o out.json")
    logger.debug(cmd:get())
    local out = cmd:execute(settings.config.verbose) or "none"
    if (string.find(out, "Traceback")) then
        logger.err("Communication Error with Ryu Controller!")
        logger.printlog(string.replaceAll("  " .. out, "\n", " "))
        return nil
    end

    local content = readFile("out.json")
    logger.debug("out.json:\n" .. content)
    local json = JSON:decode(content)
    local portNumbers =  {}
    local ports = json[self.switch]
    for _, port in pairs(ports) do
        table.insert(portNumbers, tostring(port["port_no"]))
    end
    return portNumbers
end

return RyuAdapter