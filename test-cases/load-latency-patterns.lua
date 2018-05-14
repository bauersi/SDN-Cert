function split (str, delim)
	local result = {}
	local lastPos=1
	for part, pos in string.gmatch(str, "(.-)" .. delim .. "()") do
		table.insert(result, part)
		lastPos=pos
	end
	table.insert(result, string.sub(str, lastPos))
	return result
end

return {
	seq=function (args)

		local first, last
		local parts = split(args, '-')
		if #parts == 1 then
			first = 0
			last = tonumber(parts[1])-1
		else
			first = tonumber(parts[1])
			last = tonumber(parts[2])
		end

		return function (context, paket)
			if (context.counter == nil or context.counter > last) then
				context.counter = first
			end
			paket.ip4.dst:set(context.baseIP + context.counter)
			context.counter = context.counter + 1
		end
	end,
	rnd=function (args)
		local numIP=tonumber(args)
		return function (context, paket)
			paket.ip4.dst:set(context.baseIP + math.random(numIP) - 1)
		end
	end
}