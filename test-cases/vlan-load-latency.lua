--- This script implements a simple QoS test by generating two flows and measuring their latencies.
local mg		= require "moongen"
local memory	= require "memory"
local device	= require "device"
local ts		= require "timestamping"
local stats		= require "stats"
local hist		= require "histogram"
local timer		= require "timer"
local log		= require "log"

-- define packet here
local PACKET = {
  eth_Type  = { ip4 = 0x0800, ip6 = 0x86dd, arp = 0x0806, wol = 0x0842 },
  SRC_MAC   = "aa:bb:cc:dd:ee:ff",
  DST_MAC   = "10:00:00:00:00:00",
  SRC_IP    = "10.0.0.0",
  DST_IP    = "10.128.0.0",
  SRC_PORT  = 1234,
  DST_PORT  = 5678,
}

function master(testId, txPort, rxPort, vlans, duration, rate, size, flowpattern, flowpattern_args, udp_dst_port)
	if not tonumber(testId) or not tonumber(txPort) or not tonumber(rxPort) or not tonumber(duration) or
			not tonumber(size) or not tonumber(rate) or flowpattern == nil or flowpattern_args == nil then
		print("usage: testId txDev rxDev duration size rate flowpattern flowpattern_args")
		return
	end

	if (size < 64) then
		print("Requested packet size below 64 Bytes")
		return
	end
	size = size - 4 -- moongen requires paket size without 4 byte for CRC

	if (duration < 3) then
		print("Requested duration below 3 seconds")
		return
	end

	local flowpatternArr = require('load-latency-patterns')
	if (type(flowpatternArr[flowpattern]) ~= "function") then
		print("Flowpattern not found")
	end

	-- 2 tx queues: traffic, and timestamped packets
	-- 2 rx queues: traffic and timestamped packets
	local txDev = device.config{ port = txPort, rxQueues = 1, txQueues = 2}
	local rxDev = device.config{ port = rxPort, rxQueues = 2 }

	local links = { txDev, rxDev }
	while #links > 0 do
		device.waitForLinks(unpack(links))
		for i = #links, 1, -1 do
			local link = links[i]
			if link:getLinkStatus().status then
				table.remove(links, i)
			end
		end
	end

	if (rate > 0) then
		txDev:getTxQueue(0):setRate(rate)
	end

	-- count the incoming packets
	mg.startTask("counterSlave", testId, rxDev:getRxQueue(0), duration+4)	-- +1 -> start früher | +2 -> +1 bei load, +1 da load 1 sek länger
	-- create traffic
	mg.startTask("loadSlave", testId, txDev:getTxQueue(0), size, duration+2, 1, vlans, flowpattern, flowpattern_args) -- +1 wegen Anzeige
	-- measure latency from a second queue
	mg.startSharedTask("timerSlave", testId, txDev:getTxQueue(1), rxDev:getRxQueue(1), size, duration+1, 2, flowpattern, flowpattern_args, udp_dst_port)
	-- wait until all tasks are finished
	mg.waitForTasks()
end

local function fillUdpPacket(buf, len)
	buf:getUdpPacket():fill{
		ethSrc = PACKET.SRC_MAC,
		ethDst = PACKET.DST_MAC,
		ip4Src = PACKET.SRC_IP,
		ip4Dst = PACKET.DST_IP,
		udpSrc = PACKET.SRC_PORT,
		udpDst = PACKET.DST_PORT,
		pktLength = len
	}
end

function loadSlave(id, queue, size, duration, wait, vlans, flowpattern, flowpattern_args)
	local timeout = mg.getTime() + duration + wait

	local flowpatternArr = require('load-latency-patterns')
	local modifyPaket = flowpatternArr[flowpattern](flowpattern_args)

	local txDump = "../results/test_" .. id .. "_load_tx.csv"
	local txCtr = stats:newDevTxCounter(queue, "CSV", txDump)
	txCtr:update()

	local context = {
		baseIP = parseIPAddress(PACKET.DST_IP),
		baseMAC = parseMacAddress(PACKET.DST_MAC, true) -- second parameter true is important (use efficient format)
	}
	local mempool = memory.createMemPool(function(buf)
		fillUdpPacket(buf, size)
	end)
	local bufs = mempool:bufArray()
	mg.sleepMillis(wait*1000) -- wait a few milliseconds to ensure that the rx thread is running
	txCtr:update()
	local currentvlantag = 1
	while mg.running() do
		-- allocate buffers from the mem pool and store them in this array
		bufs:alloc(size)
		for _, buf in ipairs(bufs) do
			buf:setVlan(currentvlantag)
			currentvlantag = currentvlantag + 1
			if currentvlantag > vlans then currentvlantag = 1 end
			local pkt = buf:getUdpPacket()
			modifyPaket(context, pkt)
		end
		-- send packets
		bufs:offloadUdpChecksums()
		queue:send(bufs)
		txCtr:update()
		if mg.getTime() > timeout then break end
	end
	txCtr:update()

	-- wait until all pakets are send
	timeout = timeout + 1
	local lastPkts = 0
	local lastChance = true
	while mg.running() do
		txCtr:update()
		if mg.getTime() > timeout then
			-- txCtr:getThroughput returns: totalPkts, totalBytes
			local pkts = txCtr:getThroughput()
			if lastPkts >= pkts then
				if lastChance then lastChance = false
				else break end
			end
			lastPkts = pkts
			timeout = timeout + 1
		end
	end
	txCtr:update()
	txCtr:finalize()
	log:info("Saving txCounter to '" .. txDump .. "'")
end

function counterSlave(id, queue, duration)
	local timeout = mg.getTime() + duration

	local rxDump = "../results/test_" .. id .. "_load_rx.csv"
	local rxCtr = stats:newDevRxCounter(queue, "CSV", rxDump)
	rxCtr:update()

	local lastPkts = 0
	local lastChance = true
	while mg.running() do
		rxCtr:update()
		if mg.getTime() > timeout then
			-- wait unitl all pakets are received
			-- rxCtr:getThroughput returns: totalPkts, totalBytes
			local pkts = rxCtr:getThroughput()
			if lastPkts >= pkts then
				if lastChance then
					lastChance = false
				else break end
			end
			lastPkts = pkts
			timeout = timeout + 1
		end
	end
	rxCtr:update()
	rxCtr:finalize()
	log:info("Saving rxCounter to '" .. rxDump .. "'")
end

function timerSlave(id, txQueue, rxQueue, size, duration, wait, flowpattern, flowpattern_args, udp_dst_port)
	local timeout = mg.getTime() + duration + wait

	local flowpatternArr = require('load-latency-patterns')

	local latDump = "../results/test_" .. id .. "_latency.csv"
	local latDetailDump = "../results/test_" .. id .. "_latency_detail.csv"
	local hist = hist:new()

	local timestamper = ts:newTimestamper(txQueue, rxQueue)

	local context = {
		baseIP = parseIPAddress(PACKET.DST_IP),
		baseMAC = parseMacAddress(PACKET.DST_MAC, true) -- second parameter true is important (use efficient format)
	}
	local rateLimit = timer:new(0.001)

	local latencies = {}

	-- wait one second, otherwise we might start timestamping before the load is applied
	mg.sleepMillis(wait*1000)
	while mg.running() do
		local latency = timestamper:measureLatency(size, function(buf)
			buf:setVlan(1)
		end)
		if latency then table.insert(latencies, tostring(mg.getTime()) .. ',' .. tostring(latency)) end
		hist:update(latency)
		rateLimit:wait()
		rateLimit:reset()
		if mg.getTime() > timeout then break end
	end
	mg.sleepMillis(100) -- to prevent overlapping stdout
	hist:print()
	hist:save(latDump)

	local file = io.open(latDetailDump, "w")
	file:write(table.concat(latencies,'\n'))
	file:write('\n')
	file:write(timeout)
	file:close()
end

