local w, h = term.getSize()
os.loadAPI("/zOS/System/API/zif.lua")

local tFiles = {}
local tFilePositions = {}
local selectedId = 0
local internetOkay = false
local scrollPos = 0
local maxY = 0
local alreadySet = false
local menu = 1
local selectedList
local dropdown = false
local listMaxX = 0

local lang = multishell.getLanguage()
multishell.setTitle(1, lang.launcher.name)
local username = multishell.getSetting("username")
local theme = multishell.loadTheme()

local menu = 1

local function printCenter(sText, nYpos)
	term.setCursorPos(w/2-string.len(sText)/2, nYpos)
	term.write(sText)
end

local function drawDropdown(x,y,list)
	menu = 2
	listX = x
	listY = y
	selectedList = list
	dropdown = true
	term.setCursorPos(x,y)
	local maxLength = 0
	
	for i, v in ipairs(list) do
		if string.len(v.text) > maxLength then
			maxLength = string.len(v.text)
		end
	end
	listMaxX = maxLength
	paintutils.drawFilledBox(x,y,x+maxLength+1,y+#list-1, colors.gray)
	
	for i, v in pairs(list) do
		term.setTextColor(colors.lightGray)
		if v.condition() == true then
			term.setTextColor(colors.white)
		end
		term.setCursorPos(x+1,y+i-1)
		print(v.text)
	end
end

local function drawTileApplication(tData, nX, nY, nID)
	if fs.exists("/zOS/Applications/Icons/"..tData.fileIconName) then
		if tData.fileIconName:match("^.+(%..+)$") == ".zif" then
			zif.drawImage(nX,nY,"/zOS/Applications/Icons/"..tData.fileIconName)
			term.setBackgroundColor(theme.background)
			term.setCursorPos(nX, nY+4)
		elseif tData.fileIconName:match("^.+(%..+)$") == ".nfp" then
			paintutils.drawImage(nX,nY,paintutils.loadImage("/zOS/Applications/Icons/"..tData.fileIconName))
			term.setBackgroundColor(theme.background)
			term.setCursorPos(nX, nY+4)
		else
			zif.drawImage(nX,nY,"/zOS/Applications/Icons/default.zif")
			term.setBackgroundColor(theme.background)
			term.setCursorPos(nX, nY+4)
		end
		
	else
		zif.drawImage(nX,nY,"/zOS/Applications/Icons/default.zif")
		term.setBackgroundColor(theme.background)
		term.setCursorPos(nX, nY+4)
	end
	if nID == selectedId then
		term.setBackgroundColor(theme.selectionBackground)
	end
	term.setTextColor(theme.text)
	if tData.nameType == 'default' or tData.nameType == nil then
		term.write(tData.fileName)
	elseif tData.nameType == 'lang' then
		term.write(lang.applications[tData.fileName].name)
	end
end

local function loadApplications()
	local hApplicationsFile = fs.open("/zOS/Applications/applications.txt", "r")
	tFiles = textutils.unserialize(hApplicationsFile.readAll())
	local perRow = math.floor(w/11)
	local cRow = 1
	local rowStart = w-perRow*11
	if w == 51 then
		perRow = 5
		rowStart = 2
	elseif w == 39 then
		perRow = 3
		rowStart = 5
	end
	local x = rowStart
	local y = 4+scrollPos
	
	tFilePositions = {}
	
	for i, v in pairs(tFiles) do
		drawTileApplication(v, x, y, i)
		table.insert(tFilePositions, {x = x, y = y, path = v.filePath})
		cRow = cRow + 1
		if cRow > perRow then
			y = y + 6
			if scrollPos == 0 then
				maxY = y+8
			end
			x = rowStart
			cRow = 1
		else
			x = x + 10
			
		end
		
	end
	
	hApplicationsFile.close()
end

local function drawMenu()
	term.setBackgroundColor(theme.background)
	term.clear()

	loadApplications()

	paintutils.drawFilledBox(1,1,w,3,theme.background)
	term.setCursorPos(2,2)
	term.setTextColor(theme.text)
	term.write(username.." \31")

	if w >= 30 then
		term.setBackgroundColor(theme.background)
		term.setTextColor(theme.text)
		printCenter(lang.launcher.welcome, 2)
	end

	term.setCursorPos(w-1,2)
	term.write("%")
	term.setCursorPos(w-3,2)
	term.write("+")
	
	term.setCursorPos(w-5,2)
	if internetOkay == false then
		term.setTextColor(colors.red)
		term.write("\7")
	else
		term.setTextColor(colors.lime)
		term.write("\7")
	end
	term.setTextColor(theme.text)
end

local userDropdown = {
	{
		text = lang.launcher.shutdown,
		condition = function() return true end,
		action = function()
			os.shutdown()
		end
	},
	{
		text = lang.launcher.reboot,
		condition = function() return true end,
		action = function()
			os.reboot()
		end
	},
}

drawMenu()

-- Main application event loop
local function events()
	while true do
		local e = {os.pullEventRaw()}
		if e[1] == "mouse_click" then
			local clickedOnce = false
			local m, x, y = e[2], e[3], e[4]
			if dropdown == true and menu == 2 then
				local found = false
				for i, v in pairs(selectedList) do
					if x >= listX and x <= listX+listMaxX and y == listY+i-1 then
						v.action()
						found = true
						
					end
				end

				if found == false then
					dropdown = false
					selectedList = nil
					menu = 1
					drawMenu()
				end
			elseif x >= 2 and x <= string.len(username)+3 and y == 2 and menu == 1 then
				drawDropdown(2,3,userDropdown)
				term.setTextColor(theme.text)
				term.setBackgroundColor(theme.selectionBackground)
				term.setCursorPos(2,2)
				term.write(username.." \31")
				menu = 2
			elseif x == w-1 and y == 2 and menu == 1 then
				drawMenu()
				term.setCursorPos(w-1, 2)
				term.setBackgroundColor(theme.selectionBackground)
				term.setTextColor(theme.text)
				term.write('%')
				sleep(0.1)
				term.setBackgroundColor(theme.background)
				term.setTextColor(theme.text)
				term.setCursorPos(w-1, 2)
				term.write('%')
			elseif x == w-3 and y == 2 and menu == 1 then
				term.setCursorPos(w-3, 2)
				term.setBackgroundColor(theme.selectionBackground)
				term.setTextColor(theme.text)
				term.write('+')
				sleep(0.1)
				multishell.setFocus(multishell.launch({
					['shell'] = shell,
					['multishell'] = multishell,
				}, "/zOS/System/AddProgram.lua"))
				os.queueEvent('multishell_redraw')
				term.setBackgroundColor(theme.background)
				term.setTextColor(theme.text)
				term.setCursorPos(w-3, 2)
				term.write('+')
			else
				for i, v in pairs(tFilePositions) do
					if m == 1 and x >= v.x and x <= v.x+9 and y >= v.y and y <= v.y+5 then
						if selectedId == i then
							selectedId = 0
							multishell.setFocus(multishell.launch({
								['shell'] = shell,
								['multishell'] = multishell,
							}, v.path))
							os.queueEvent('multishell_redraw')
						else
							selectedId = i
							drawMenu()
							clickedOnce = true
						end
						
					end
				end
			end

			if selectedId ~= 0 and clickedOnce == false then
				selectedId = 0
				drawMenu()
				menu = 1
			end
		elseif e[1] == "mouse_scroll" then
			local d, x, y = e[2], e[3], e[4]
			if d == 1 then --down
				
				if math.abs(scrollPos) < math.abs(maxY-h) then
					scrollPos = scrollPos - 1
				end
			elseif d == -1 then --up
				if scrollPos ~= 0 then
					scrollPos = scrollPos + 1
				end
            end
            
			drawMenu()
		end
	end
end

-- Internet testing function

local function internetTest()
	sleep(1)
	-- Checking internet: #
	-- Disconnected: !
	-- Online: ?
	while true do
		term.setCursorPos(w-5,2)
		term.setBackgroundColor(theme.background)
		term.setTextColor(colors.yellow)
		term.write("\7")
		term.setTextColor(theme.text)
		local data = http.get("https://cc.znepb.me/zOS/internet-test.txt")
		if not data then
			internetOkay = false
			term.setTextColor(colors.red)
			term.setCursorPos(w-5,2)
			term.write("\7")
		else
			internetOkay = true
			term.setTextColor(colors.lime)
			term.setCursorPos(w-5,2)
			term.write("\7")
		end
		term.setTextColor(theme.text)
		if not data then sleep(5) else sleep(30) end
	end
end

parallel.waitForAll(internetTest, events)