local theme = {}
local function getSetting(name)
	local f = fs.open("/zOS/Configuration/configuration.txt", "r")
	local configData = textutils.unserialize(f.readAll())
	local data = configData[name]
	f.close()
	return data
end

local function getLanguageData(language)
	local f = fs.open("/zOS/Language/"..language..".txt", "r")
	local data = textutils.unserialize(f.readAll())
	print(language)
	f.close()
	return data
end

local lang = getLanguageData(getSetting('language'))

local function loadTheme()
	local f = fs.open("/zOS/Configuration/configuration.txt", "r")
	local configData = textutils.unserialize(f.readAll())
	local sTheme = configData.selectedTheme
	f.close()

	local f = fs.open("/zOS/Configuration/themes.txt", "r")
	local data = textutils.unserialize(f.readAll())[sTheme]
	f.close()
	
	return data
end

theme = loadTheme()
term.setBackgroundColor(theme.background)
term.clear()

local dataFile = fs.open("/zOS/Configuration/configuration.txt", "r")
local data = textutils.unserialize(dataFile.readAll())
dataFile.close()

local w, h = term.getSize()
term.setBackgroundColor(colors.lightBlue)
term.clear()
paintutils.drawFilledBox(w/2-10, h/2-4, w/2+10, h/2+4, theme.background)
local colorsToID = {
	[1] = "0",
	[2] = "1",
	[4] = "2",
	[8] = "3",
	[16] = "4",
	[32] = "5",
	[64] = "6",
	[128] = "7",
	[256] = "8",
	[512] = "9",
	[1024] = "a",
	[2048] = "b",
	[4096] = "c",
	[8192] = "d",
	[16384] = "e",
	[32768] = "f"
}

term.setCursorPos(1,h)
term.setBackgroundColor(colors.lightBlue)
term.setTextColor(colors.gray)
local hData = fs.open('zOS/System/sysinfo.txt', "r")
local sysData = textutils.unserialize(hData.readAll())
hData.close()
term.write(sysData.displayVersion)

local themeBackground = colorsToID[theme.background]
local themeForeground = colorsToID[theme.text]
term.setCursorPos(w/2-string.len(lang.login.title)/2, h/2-3)
term.blit(lang.login.title, string.rep(themeForeground, string.len(lang.login.title)-3)..'d9b', string.rep(themeBackground, string.len(lang.login.title)))

term.setBackgroundColor(theme.background)
term.setTextColor(theme.text)
term.setCursorPos(w/2-9, h/2-1)
term.write(lang.login.username)
paintutils.drawLine(w/2-9, h/2, w/2+9, h/2, colors.gray)
term.setCursorPos(w/2-8, h/2)
term.setTextColor(colors.lightGray)
term.write(getSetting('username'))

term.setBackgroundColor(theme.background)
term.setTextColor(theme.text)
term.setCursorPos(w/2-9, h/2+2)
term.write(lang.login.password)
paintutils.drawLine(w/2-9, h/2+3, w/2+9, h/2+3, colors.gray)
term.setCursorPos(w/2-8, h/2+3)
term.setTextColor(colors.lightGray)



local function performLogin(decrypt, str)
	term.setBackgroundColor(colors.lightBlue)
	term.setTextColor(theme.text)
	term.clear()
	term.setCursorPos(w/2-string.len(lang.login.welcome)/2,h/2+1)
	term.write(lang.login.welcome)
	sleep(1)
	
	if decrypt == "yes" then
		local function decryptFiles(path)
			for i, v in pairs(fs.list(path)) do
				if fs.isDir(path..v) then
					decryptFiles(path..v.."/")
				else
					local r = fs.open(path..v, "r")
					cipher = aeslua.decrypt(str, r.readAll())
					r.close()
					local w = fs.open(path..v, "w")
					w.write(cipher)
					w.close()
				end
			end
		end
		fs.delete("/User/thishasbeenoofed.txt")
		decryptFiles("/User/")
	end

	shell.run("/zOS/System/System.lua", "/zOS/System/Kernel.lua")
end

local go = true
local usePass = true
if data.password == "" then
	go = false
	usePass = false
	performLogin()
end
while true do
	if go == true then
		input = read("\7")
	else
		break
	end

	os.loadAPI("/zOS/System/API/aeslua")
	local pass = aeslua.decrypt("zOS-super-secret-password-lol", data.password)
	if pass == input then
		local str = pass

		performLogin("yes", str)
	else
		term.setCursorPos(w/2-string.len("Incorrect password!")/2, h/2-3)
		term.setTextColor(colors.red)
		term.setBackgroundColor(theme.background)
		term.write(lang.login.incorrect)

		paintutils.drawLine(w/2-9, h/2+3, w/2+9, h/2+3, colors.gray)
		term.setCursorPos(w/2-8, h/2+3)
		term.setTextColor(colors.lightGray)
	end
end