sleep(0.5)
if not fs.exists("/zOS/Autorun/") then
	fs.makeDir("/zOS/Autorun")
end

for i, v in pairs(fs.list("/zOS/Autorun/")) do 
    multishell.launch({
        ['shell'] = shell,
        ['multishell'] = multishell,
    }, "/zOS/Autorun/"..v)
    os.queueEvent('multishell_redraw')
    sleep(0.1)
end