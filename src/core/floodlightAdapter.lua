FloodlightAdapter = {}
FloodlightAdapter.__index = FloodlightAdapter

--------------------------------------------------------------------------------
--  class for managing an OpenFlow Controller Floodlight
--------------------------------------------------------------------------------

--- Creates a new instance for an OF-Controller
function FloodlightAdapter.create()
    local self = setmetatable({}, FloodlightAdapter)
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

function FloodlightAdapter:delFlows()
    local delFlows = prepareGetCommand(self, "wm/staticflowpusher/clear/"..self.switch.."/json")
    local cmd = CommandLine.create(delFlows)
    cmd:execute(settings.config.verbose)
end

function FloodlightAdapter:delGroups()
    -- TODO: impementation
    return "not implemented"
end

function FloodlightAdapter:delMeters()
    -- TODO: impementation
    return "not implemented"
end

--- Returns the flow dump of the device in the representation of the used version.
function FloodlightAdapter:dumpFlows()
    local cmd = CommandLine.create(prepareGetCommand(self, "wm/staticflowpusher/list/"..self.switch.."/json"))
    return cmd:execute(settings.config.verbose)
end

--- Returns the group dump of the device in the representation of the used version.
function FloodlightAdapter:dumpGroups(version)
    -- TODO: impementation
    return "not implemented"
end

--- Returns the meter dump of the device in the representation of the used version.
function FloodlightAdapter:dumpMeters(version)
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
                data.table=value
                table.insert(itemsToRemove, id)
            elseif key == "priority" then
                local value = string.trim(keyValuePair[2])
                data.priority=value
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
                    match.eth_type = tostring(0x0800)
                elseif key == "ipv6" then
                    match.eth_type = tostring(0x86dd)
                elseif key == "icmp" then
                    match.eth_type = tostring(0x0800)
                    match.ip_proto = 1
                elseif key == "icmp6" then
                    match.eth_type = tostring(0x86dd)
                    match.ip_proto = "58"
                elseif key == "tcp" then
                    match.eth_type = tostring(0x0800)
                    match.ip_proto = "6"
                elseif key == "tcp6" then
                    match.eth_type = tostring(0x86dd)
                    match.ip_proto = "6"
                elseif key == "udp" then
                    match.eth_type = tostring(0x0800)
                    match.ip_proto = "17"
                elseif key == "udp6" then
                    match.eth_type = tostring(0x86dd)
                    match.ip_proto = "17"
                elseif key == "sctp" then
                    match.eth_type = tostring(0x0800)
                    match.ip_proto = "132"
                elseif key == "sctp6" then
                    match.eth_type = tostring(0x86dd)
                    match.ip_proto = "132"
                elseif key == "arp" then
                    match.eth_type = tostring(0x0800)
                    match.ip_proto = "132"
                elseif key == "rarp" then
                    match.eth_type = tostring(0x8035)
                elseif key == "mpls" then
                    match.eth_type = tostring(0x8847)
                elseif key == "mplsm" then
                    match.eth_type = tostring(0x8848)
                else
                    error("shorthand notation unkown : '" .. item .. "'")
                end
            elseif #keyValuePair == 2 then
                local parts = string.split(key, '_')
                local proto = parts[1]
                local field = parts[2]

                if     proto == "dl" then proto = "eth"
                elseif proto == "nw" and (field == "src" or field == "dst") then proto = "ipv4"
                elseif proto == "nw" and (field == "proto" or field == "tos") then proto = "ip"
                elseif proto ~= "tp" and key ~= "in_port" then error("invalid match data : '" .. item .. "'")
                end

                local value = string.trim(keyValuePair[2])

                match[string.format("%s_%s", proto, field)] = value
            else
                error("invalid match data : '" .. item .. "'")
            end
        end
    end
end

local function parseActions(actionStr)
    local actions = {}
    local items = string.split(string.lower(actionStr), ',')
    for _, item in pairs(items) do
        item = string.trim(item)
        if (item ~= "") then
            if string.find(item,":") then
                local keyValuePair = string.split(item, ':', 1)
                local key = string.trim(keyValuePair[1])
                if key == "output" then
                    local value = string.trim(keyValuePair[2])
                    table.insert(actions, "output="..value)
                elseif string.startsWith(key, "mod_") then
                    local parts = string.split(key, '_')
                    local proto = parts[2]
                    local field = parts[3]

                    if     proto == "dl" then proto = "eth"
                    elseif proto == "nw" and (field == "src" or field == "dst") then proto = "ipv4"
                    elseif proto == "nw" and field == "tos" then proto = "ip"
                    elseif proto ~= "tp" then error("invalid action data : '" .. item .. "'")
                    end

                    local value = string.trim(keyValuePair[2])

                    table.insert(actions, string.format("set_%s_%s=%s", proto, field, value))
                else
                    error("invalid action data : '" .. item .. "'")
                end
            else
                local key = string.lower(string.trim(item))
                if key == "drop" then
                    -- nothing to do because empty actions == DROP
                else
                    error("invalid action data : '" .. item .. "'")
                end
            end
        end
    end
    return table.concat(actions, ',')
end

local function parseFlow (adapter, flow)
    local startPos, endPos = flow:find("actions=")
    if startPos == nil then
        error("actions is missing : " .. flow)
    end
    local matchStr = flow:sub(1, startPos-1)
    local actionStr = flow:sub(endPos+1)

    local data = {
        name=string.sub(tostring(math.random()),3),
        switch=adapter.switch,
        priority="32768",
        active="true",
    }

    matchStr = parseOptions(data, matchStr)
    parseMatch(data, matchStr)
    data.actions = parseActions(actionStr)

    return data
end

local function getInstallFlowCommand(adapter, flow)
    local data = parseFlow(adapter, flow)
    local json = JSON:encode(data)
    return preparePostCommand(adapter, "wm/staticflowpusher/json", json)
end

--- Installs a new flow.
function FloodlightAdapter:installFlow(flow)
    logger.debug(string.format("Floodlight: add flow: '%s'", flow ))
    local cmd = CommandLine.create(getInstallFlowCommand(self, flow))
    logger.debug(cmd:get())
    return cmd:execute(settings.config.verbose) or "none"
end

--- Install a file of flows.
function FloodlightAdapter:installFlows(file)
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
function FloodlightAdapter:installGroup(group)
    -- TODO
    return "not implemented"
end

--- Installs a file of groups.
function FloodlightAdapter:installGroups(file)
    -- TODO
    return "not implemented"
end

--- Installs a new meter.
function FloodlightAdapter:installMeter(meter)
    -- TODO
    return "not implemented"
end

--- Installs a file of meters.
function FloodlightAdapter:installMeters(file)
    -- TODO
    return "not implemented"
end

local function readFile(filepath)
    local file = assert(io.open(filepath, "r"))
    local content = file:read("*all")
    file:close()
    return content
end

function FloodlightAdapter:getPorts()
    local cmd = CommandLine.create(prepareGetCommand(self,"wm/core/switch/"..self.switch.."/port/json") .. " -o out.json")
    logger.debug(cmd:get())
    local out = cmd:execute(settings.config.verbose) or "none"
    if (string.find(out, "Traceback")) then
        logger.err("Communication Error with Floodlight Controller!")
        logger.printlog(string.replaceAll("  " .. out, "\n", " "))
        return nil
    end

    local content = readFile("out.json")
    logger.debug("out.json:\n" .. content)
    local json = JSON:decode(content)
    local portNumbers =  {}
    local ports = json["port_reply"]
    for _, port in pairs(ports) do
        table.insert(portNumbers, tostring(port["portNumber"]))
    end
    return portNumbers
end

return FloodlightAdapter