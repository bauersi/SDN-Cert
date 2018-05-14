local device	= require "device"

function master(testId, ...)
	if not tonumber(testId) then
		print("usage: testId port [port ...]")
		return
	end
	local ports = { ... }
	for _, port in pairs(ports) do
		if not tonumber(port) then
			print("usage: testId port [port ...]")
			return
		end
	end

	local links = {}
	for _,port in pairs(ports) do
		local link = device.config{ port = port, rxQueues = 1, txQueues = 1 }
		table.insert(links, link)
	end

	waitForLinks(unpack(links))

	local file = io.open("../results/test_" .. testId .. "_wire-rate.csv", "w")
	file:write("port,mac,speed\n")
	for _,link in pairs(links) do
		file:write(string.format("%s,%s,%s\n", link.id, link:getMacString(), link.speed))
	end
	file:close()
end

function waitForLinks(...)
	local links = { ... }
	while #links > 0 do
		device.waitForLinks(unpack(links))
		for i = #links, 1, -1 do
			local link = links[i]
			local linkStatus = link:getLinkStatus()
			if linkStatus.status then
				table.remove(links, i)
			end
		end
	end
end