OvsOfctlAdapter = {}
OvsOfctlAdapter.__index = OvsOfctlAdapter

--------------------------------------------------------------------------------
--  class for managing an OpenFlow device
--------------------------------------------------------------------------------
local error_messages = {
    general_fail     = "failes",
    failed_socket   = "failed to connect to socket"
}

local string_matches = {
    openflow_port     = "port",
    openflow_port_delm = ":"
}

--- Creates a new instance for an OF-dev.
function OvsOfctlAdapter.create()
    local self = setmetatable({}, OvsOfctlAdapter)
    self.ip      = settings.config[global.switchIP] or "127.0.0.1"
    self.port    = tostring(settings.config[global.switchPort]) or "6633"
    self.version = settings.config[global.ofVersion]
    self.bridge  = "tcp:" .. self.ip .. ":" .. self.port
    return self
end

local function getTarget(adapter, version)
    local target = adapter.bridge
    version = version or adapter.version
    if version then target = target .. " -O " .. version end
    return target
end

function OvsOfctlAdapter:delFlows()
    local cmd = CommandLine.create("ovs-ofctl del-flows " .. getTarget(self))
    cmd:execute(settings.config.verbose)
end

function OvsOfctlAdapter:delGroups()
    local cmd = CommandLine.create("ovs-ofctl del-groups " .. getTarget(self))
    cmd:execute(settings.config.verbose)
end

function OvsOfctlAdapter:delMeters()
    local cmd = CommandLine.create("ovs-ofctl del-meters " .. getTarget(self))
    cmd:execute(settings.config.verbose)
end

--- Returns the requested info in the representation of the used version.
function OvsOfctlAdapter:dump(type, version)
    local cmd = CommandLine.create("ovs-ofctl " .. type .. " " .. getTarget(self, version))
    return cmd:execute(settings.config.verbose) or "none"
end

--- Returns the flow dump of the device in the representation of the used version.
function OvsOfctlAdapter:dumpFlows(version)
    return self:dump("dump-flows", version)
end

--- Returns the group dump of the device in the representation of the used version.
function OvsOfctlAdapter:dumpGroups(version)
    return self:dump("dump-groups", version)
end

--- Returns the meter dump of the device in the representation of the used version.
function OvsOfctlAdapter:dumpMeters(version)
    version = version or self.version
    return self:dump("dump-meters", version)
end

--- Installs a new flow.
function OvsOfctlAdapter:installFlow(flow)
    local cmd = CommandLine.create("ovs-ofctl add-flow " .. getTarget(self) ..  " \"" .. flow .. "\"")
    return cmd:execute(settings.config.verbose) or "none"
end

--- Install a file of flows.
function OvsOfctlAdapter:installFlows(file)
    local cmd = CommandLine.create("ovs-ofctl add-flows " .. getTarget(self) .. " " .. file)
    return cmd:execute(settings.config.verbose) or "none"
end

--- Installs a new group.
function OvsOfctlAdapter:installGroup(group)
    local cmd = CommandLine.create("ovs-ofctl add-group " .. getTarget(self) ..  " \"" .. group .. "\"")
    return cmd:execute(settings.config.verbose) or "none"
end

--- Installs a file of groups.
function OvsOfctlAdapter:installGroups(file)
    local cmd = CommandLine.create("ovs-ofctl add-groups " .. getTarget(self) .. " " .. file)
    return cmd:execute(settings.config.verbose) or "none"
end

--- Installs a new meter.
function OvsOfctlAdapter:installMeter(meter)
    local cmd = CommandLine.create("ovs-ofctl add-meter " .. getTarget(self) ..  " \"" .. meter .. "\"")
    return cmd:execute(settings.config.verbose) or "none"
end

--- Installs a file of meters. (ovs-ofctl add-meters does not exist)
function OvsOfctlAdapter:installMeters(file)
    local cmd = CommandLine.create("ovs-ofctl add-meters " .. getTarget(self) .. " " .. file)
    return cmd:execute(settings.config.verbose) or "none"
end

function OvsOfctlAdapter:getPorts()
    local cmd = CommandLine.create("ovs-ofctl dump-ports tcp:" .. settings:get(global.switchIP) .. ":" .. settings:get(global.switchPort) .. " -O " .. settings:get(global.ofVersion))
    local out = cmd:execute()
    if (out == nil) then return nil end
    if (string.find(out, error_messages.failed_socket)) then
        logger.err("OpenFlow device is not reachable!")
        logger.printlog(string.replaceAll("  " .. out, "\n", " "))
        return nil
    elseif (string.find(out, error_messages.general_fail)) then
        logger.err("OpenFlow device seem not to be ready!")
        logger.printlog(string.replaceAll("  " .. out, "\n", " "))
        return nil
    else
        local ports = {}
        local find, find_ = string.find(out, "ports")
        if (not find) then return end
        out = string.sub(out, find_+1, -1)
        for n,p in pairs(string.split(out, "\n")) do
            local a = string.find(p, string_matches.openflow_port)
            local z = string.find(p, string_matches.openflow_port_delm)
            if (a and z) then
                local port = string.trim(string.sub(p, a+5, z-1))
                table.insert(ports, port)
            end
        end
        table.sort(ports)
        return ports
    end
end

return OvsOfctlAdapter