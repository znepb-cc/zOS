function drawImage(x,y,path)
	local ok = pcall(function()
		local f = fs.open(path, "r")
		local data = textutils.unserialize(f.readAll())
		f.close()
		
		for i, v in pairs(data) do
			term.setCursorPos(x,y+i-1)
			term.blit(v[1], v[2], v[3])
		end
	end)
	return ok
end

function drawImageTable(x,y,data)
	local ok = pcall(function()
		for i, v in pairs(data) do
			term.setCursorPos(x,y+i-1)
			term.blit(v[1], v[2], v[3])
		end
	end)
	return ok
end