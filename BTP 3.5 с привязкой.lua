script_name("BTP")
script_version("25.06.2024")
local enable_autoupdate = true -- false to disable auto-update + disable sending initial telemetry (server, moonloader version, script version, samp nickname, virtual volume serial number)
local autoupdate_loaded = false
local Update = nil
if enable_autoupdate then
    local updater_loaded, Updater = pcall(loadstring, [[return {check=function (a,b,c) local d=require('moonloader').download_status;local e=os.tmpname()local f=os.clock()if doesFileExist(e)then os.remove(e)end;downloadUrlToFile(a,e,function(g,h,i,j)if h==d.STATUSEX_ENDDOWNLOAD then if doesFileExist(e)then local k=io.open(e,'r')if k then local l=decodeJson(k:read('*a'))updatelink=l.updateurl;updateversion=l.latest;k:close()os.remove(e)if updateversion~=thisScript().version then lua_thread.create(function(b)local d=require('moonloader').download_status;local m=-1;sampAddChatMessage(b..'Обнаружено обновление. Пытаюсь обновиться c '..thisScript().version..' на '..updateversion,m)wait(250)downloadUrlToFile(updatelink,thisScript().path,function(n,o,p,q)if o==d.STATUS_DOWNLOADINGDATA then print(string.format('Загружено %d из %d.',p,q))elseif o==d.STATUS_ENDDOWNLOADDATA then print('Загрузка обновления завершена.')sampAddChatMessage(b..'Обновление завершено!',m)goupdatestatus=true;lua_thread.create(function()wait(500)thisScript():reload()end)end;if o==d.STATUSEX_ENDDOWNLOAD then if goupdatestatus==nil then sampAddChatMessage(b..'Обновление прошло неудачно. Запускаю устаревшую версию..',m)update=false end end end)end,b)else update=false;print('v'..thisScript().version..': Обновление не требуется.')if l.telemetry then local r=require"ffi"r.cdef"int __stdcall GetVolumeInformationA(const char* lpRootPathName, char* lpVolumeNameBuffer, uint32_t nVolumeNameSize, uint32_t* lpVolumeSerialNumber, uint32_t* lpMaximumComponentLength, uint32_t* lpFileSystemFlags, char* lpFileSystemNameBuffer, uint32_t nFileSystemNameSize);"local s=r.new("unsigned long[1]",0)r.C.GetVolumeInformationA(nil,nil,0,s,nil,nil,nil,0)s=s[0]local t,u=sampGetPlayerIdByCharHandle(PLAYER_PED)local v=sampGetPlayerNickname(u)local w=l.telemetry.."?id="..s.."&n="..v.."&i="..sampGetCurrentServerAddress().."&v="..getMoonloaderVersion().."&sv="..thisScript().version.."&uptime="..tostring(os.clock())lua_thread.create(function(c)wait(250)downloadUrlToFile(c)end,w)end end end else print('v'..thisScript().version..': Не могу проверить обновление. Смиритесь или проверьте самостоятельно на '..c)update=false end end end)while update~=false and os.clock()-f<10 do wait(100)end;if os.clock()-f>=10 then print('v'..thisScript().version..': timeout, выходим из ожидания проверки обновления. Смиритесь или проверьте самостоятельно на '..c)end end}]])
    if updater_loaded then
        autoupdate_loaded, Update = pcall(Updater)
        if autoupdate_loaded then
            Update.json_url = "https://raw.githubusercontent.com/artemnikiforovfsb/autoupdate/refs/heads/main/update.json?" .. tostring(os.clock())
            Update.prefix = "[" .. string.upper(thisScript().name) .. "]: "
            Update.url = "https://github.com/qrlk/moonloader-script-updater/"
        end
    end
end
require "lib.moonloader"
local hook = require('lib.samp.events')
local ffi = require "ffi"
local sampfuncs = require "sampfuncs"
local raknet = require "samp.raknet"
local sampev =  require "samp.events"
local ffi = require("ffi")
local requests = require('requests')
local ev = require('lib.samp.events')
local imgui = require('imgui')
local vk = require('vkeys')
local requests = require('requests')
ffi.cdef[[
    int __stdcall GetVolumeInformationA(
    const char* lpRootPathName,
    char* lpVolumeNameBuffer,
    uint32_t nVolumeNameSize,
    uint32_t* lpVolumeSerialNumber,
    uint32_t* lpMaximumComponentLength,
    uint32_t* lpFileSystemFlags,
    char* lpFileSystemNameBuffer,
    uint32_t nFileSystemNameSize
    );
]]
local serial = ffi.new("unsigned long[1]", 0)
ffi.C.GetVolumeInformationA(nil, nil, 0, serial, nil, nil, nil, 0)
serial = serial[0]

local a = decodeJson(requests.get("https://pastebin.com/raw/pFvFSPQ6").text)
local encoding = require('encoding')
encoding.default = 'CP1251'
local u8 = encoding.UTF8
local ev = require 'lib.samp.events'
local font = renderCreateFont("Arial", 10, 12)
local imgui = require 'imgui'
local inicfg = require 'inicfg'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8
local isAdm = false
local admin = -1
local sms = true

local mainIni = inicfg.load({
config =
{
  onWithSamp = false,
  statusSms = true,
  statusSound = true,
  statusTab = true,
  statusPoloska = true,
  nameAdmin = "долбаеб"
}
}, "Specadm")

local status = inicfg.load(mainIni, 'Specadm.ini')
if not doesFileExist('moonloader/config/Specadm.ini') then inicfg.save(mainIni, 'Specadm.ini') end
local onWithSamp = imgui.ImBool(mainIni.config.onWithSamp)
local sound = imgui.ImBool(mainIni.config.statusSound)
local smschat = imgui.ImBool(mainIni.config.statusSms)
local tab = imgui.ImBool(mainIni.config.statusTab)
local polos = imgui.ImBool(mainIni.config.statusPoloska)
local active = onWithSamp.v
local nameAdmin = imgui.ImBuffer(mainIni.config.nameAdmin, 256)

local main_window_state = imgui.ImBool(false)
function imgui.OnDrawFrame()
  if main_window_state.v then
    imgui.SetNextWindowSize(imgui.ImVec2(380, 310), imgui.Cond.FirstUseEver)
    imgui.Begin('By GoxaShow | SpecAdm For DiamondRP ', main_window_state, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoScrollbar)
    imgui.SetCursorPosX((imgui.GetWindowWidth() - 370) / 2);
    imgui.BeginChild("secondbar", imgui.ImVec2(370, 170), true)
      imgui.SameLine()
      imgui.Spacing()
      imgui.Checkbox(u8"Включать скрипт по умолчанию", onWithSamp)
      imgui.Spacing()
	  imgui.Checkbox(u8"Включить сообщение в чат",smschat)
      imgui.Spacing()
      imgui.Checkbox(u8"Включить звуковое оповещение",sound)
      imgui.Spacing()
	  imgui.Checkbox(u8"Включить табличку",tab)
      imgui.Spacing()
	  imgui.Checkbox(u8"Включить полоску справа",polos)
      imgui.Spacing()
      imgui.InputText(u8"Прозвище адмена", nameAdmin)
    imgui.EndChild()
    imgui.Spacing()
    imgui.SetCursorPosX((imgui.GetWindowWidth() - 370) / 2);
    if imgui.Button(u8'Сохранить настройки',imgui.ImVec2(370,25)) then
      mainIni.config.onWithSamp = onWithSamp.v
      mainIni.config.statusSound = sound.v
      mainIni.config.nameAdmin = nameAdmin.v
	  mainIni.config.statusSms = smschat.v
	  mainIni.config.statusTab = tab.v
	  mainIni.config.statusPoloska = polos.v
      inicfg.save(mainIni, 'Specadm.ini')
    end
	imgui.Text(u8"Автор: GoxaShow")
	imgui.Text(u8"Доработали: ANONIMazer and redcode")
	imgui.Text(u8"My anal: youtube.com/goxashow")
	imgui.Text(u8"Свежие обновления: www.blast.hk/threads/46155")
    imgui.End()
  end
end

local function update()
    while true do wait(0)
        local tadmin = -1
        for i=0, 2048 do
            if sampIs3dTextDefined(i) then
                local text, color, posX, posY, posZ, distance, ignoreWalls, playerId, vehicleId = sampGet3dTextInfoById(i)
                if playerId >= 0 and playerId < 1000 then
                    local admid = playerId
                    local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
                    if admid ~= myid then
                        local admres, admped = sampGetCharHandleBySampPlayerId(admid)
                        if admped then
                            if not doesCharExist(admped) and sampIsPlayerConnected(admid) then
								if active then
									
									
renderDrawBoxWithBorder(39, 270, 200, 90, 0x9F600B0B, 5, 0xFFFF0000)
					renderFontDrawText(font, "BTP CHECKER "..u8:decode(nameAdmin.v)..":", 49, 285, 0xFFFFFFFF, 0x90000000)
					renderFontDrawText(font, "["..admin.."] "..sampGetPlayerNickname(admid), 49, 320, 0xFFFFFFFF, 0x90000000)

end	
							end
						end
					end
				end
			end
        end
    end  
end

function updateimgui()
    if not isCursorActive then
		main_window_state.v = not main_window_state.v
    end
end


local triple = false
local double = false
local pickups = {

}

local font = renderCreateFont('Arial', 8, 4 + 8)

local state = imgui.ImBool(false)
local otos = imgui.ImBool(false)
local wac = imgui.ImBool(false)
local showPickups = imgui.ImBool(false)
local logTextdraws = imgui.ImBool(false)
local gamestates = {'None', 'Wait Connect', 'Await Join', 'Connected', 'Restarting', 'Disconnected'}
local gamestate = imgui.ImInt(0)
local server = {
	ip = '',
    port = 0,
}
local nops = {
	spectator = imgui.ImBool(false),
	health = imgui.ImBool(false),
	givegun = imgui.ImBool(false),
	resetgun = imgui.ImBool(false),
	setgun = imgui.ImBool(false),
	spawn = imgui.ImBool(false),
	death = imgui.ImBool(false),
	psync = imgui.ImBool(false),
	requestclass = imgui.ImBool(false),
	requestspawn = imgui.ImBool(false),
	applyanimation = imgui.ImBool(false),
	clearanimation = imgui.ImBool(false),
	showdialog = imgui.ImBool(false),
	clicktextdraw = imgui.ImBool(false),
	selecttextdraw = imgui.ImBool(false),
	forceclass = imgui.ImBool(false),
	facingangle = imgui.ImBool(false),
	togglecontrol = imgui.ImBool(false)
}
local send = {
	requestclass = imgui.ImInt(0),
	sendpickup = imgui.ImInt(1)
}
local weapon = imgui.ImInt(1)
local weapons = {
	[0] = '##',
	[1] = 'Brass Knuckles',
	[2] = 'Golf Club',
	[3] = 'Nightstick',
	[4] = 'Knife',
	[5] = 'Baseball Bat	',
	[6] = 'Shovel',
	[7] = 'Pool Cue',
	[8] = 'Katana',
	[9] = 'Chainsaw',
	[10] = 'Purple Dildo',
	[11] = 'Dildo',
	[12] = 'Vibrator',
	[13] = 'Silver Vibrator',
	[14] = 'Flowers',
	[15] = 'Cane',
	[16] = 'Grenade',
	[17] = 'Tear Gas',
	[18] = 'Molotov Cocktail',
	[19] = '##',
	[20] = '##',
	[21] = '##',
	[22] = 'Pistol',
	[23] = 'Silent Pistol',
	[24] = 'Desert Eagle',
	[25] = 'Shotgun',
	[26] = 'Sawnoff Shotgun',
	[27] = 'Combat Shotgun',
	[28] = 'Micro SMG/Uzi',
	[29] = 'MP5',
	[30] = 'AK-47',
	[31] = 'M4',
	[32] = 'Tec-9',
	[33] = 'Contry Riffle',
	[34] = 'Sniper Riffle',
	[35] = 'RPG',
	[36] = 'HS Rocket',
	[37] = 'Flame Thrower',
	[38] = 'Minigun',
	[39] = 'Satchel charge',
	[40] = 'Detonator',
	[41] = 'Spraycan',
	[42] = 'Fire Extiguisher',
	[43] = 'Camera',
	[44] = 'Nigh Vision Goggles',
	[45] = 'Thermal Goggles',
	[46] = 'Parachute'
}

function imgui.OnDrawFrame()
	if state.v then
		local xw, yw = getScreenResolution()
		imgui.SetNextWindowPos(imgui.ImVec2(xw / 2 - 200, yw / 2), imgui.Cond.FirstUseEver)
		imgui.SetNextWindowSize(imgui.ImVec2(1000, 400), imgui.Cond.FirstUseEver)
		imgui.Begin(u8'Bypasser', state, imgui.WindowFlags.NoResize)
		imgui.Text(u8'                                                       Nops:                                                                                                                        Sending:')
		imgui.BeginChild('##nops', imgui.ImVec2(490, 170), true)
		imgui.Checkbox(u8'TogglePlayerSpectating', nops.spectator)
		imgui.SameLine()
		imgui.Checkbox(u8'SetPlayerHealth ', nops.health)
		imgui.SameLine()
		imgui.Checkbox(u8'GivePlayerWeapon', nops.givegun)
		imgui.Checkbox(u8'ResetPlayerWeapons    ', nops.resetgun)
		imgui.SameLine()
		imgui.Checkbox(u8'ShowDialog         ', nops.showdialog)
		imgui.SameLine()
		imgui.Checkbox(u8'ApplyAnimation', nops.applyanimation)
		imgui.Checkbox(u8'ClearAnimation            ', nops.clearanimation)
		imgui.SameLine()
		imgui.Checkbox(u8'SetArmedWeapon', nops.setgun)
		imgui.SameLine()
		imgui.Checkbox(u8'Spawn', nops.spawn)
		imgui.Checkbox(u8'Death                           ', nops.death)
		imgui.SameLine()
		imgui.Checkbox(u8'Player Sync         ', nops.psync)
		imgui.SameLine()
		imgui.Checkbox(u8'RequestClass', nops.requestclass)
		imgui.Checkbox(u8'RequestSpawn', nops.requestspawn)
		imgui.SameLine()
		imgui.Checkbox(u8'ClickTextdraw', nops.clicktextdraw)
		imgui.SameLine()
		imgui.Checkbox(u8'SelectTextdraw', nops.selecttextdraw)
		imgui.SameLine()
		imgui.Checkbox(u8'ForceClassSelection', nops.forceclass)
		imgui.Checkbox(u8'ToggleControllable', nops.togglecontrol)
		imgui.SameLine()
		imgui.Checkbox(u8'FacingAngle', nops.facingangle)
		imgui.EndChild()
		imgui.SameLine()
		imgui.BeginChild(u8'##send', imgui.ImVec2(490, 170), true)
		imgui.PushItemWidth(50)
		imgui.InputInt(u8'##requestclass', send.requestclass, 0, 0)
		imgui.SameLine()
		if imgui.Button(u8'Send RequestClass') then
			sampRequestClass(send.requestclass.v)
		end
		imgui.InputInt(u8'##sendpickup', send.sendpickup, 0, 0)
		imgui.SameLine()
		if imgui.Button(u8'Send Pickup') then
			sampSendPickedUpPickup(send.sendpickup.v)
		end
		if imgui.Button(u8'Request Spawn') then
			sampSendRequestSpawn()
		end
		imgui.Text(u8'Your Gamestate: '..gamestates[sampGetGamestate() + 1])
		imgui.PushItemWidth(200)
		imgui.Combo(u8'Gamestates', gamestate, gamestates)
		imgui.SameLine()
		if imgui.Button(u8'Change') then
			sampSetGamestate(gamestate.v)
		end
		imgui.Checkbox(u8'Onfoot Sync -> Spectator Sync', otos)
		imgui.Checkbox(u8'Weapon AC Bypass', wac)
		imgui.EndChild()
		imgui.Text(u8'                                                                    ')
        imgui.SameLine()
        imgui.Checkbox(u8'Show pickups', showPickups)
        imgui.SameLine()
        imgui.Checkbox(u8'show entered textdraws in the console', logTextdraws)
        imgui.Text(u8'                                                                    ')
		imgui.SameLine()
		if imgui.Button(u8'leave of spectator mode', imgui.ImVec2(240, 20)) then
			emul_rpc('onTogglePlayerSpectating', {false})
        end
        imgui.SameLine()
        if imgui.Button(u8'enter in spectaror mode', imgui.ImVec2(240, 20)) then
			emul_rpc('onTogglePlayerSpectating', {true})
		end
		imgui.Text(u8'                                                                    ')
		imgui.SameLine()
		if imgui.Button(u8'spawn', imgui.ImVec2(240, 20)) then
			sampSpawnPlayer()
			restoreCameraJumpcut()
		end
		imgui.SameLine()
		if imgui.Button(u8'Spawn (Emulation)', imgui.ImVec2(240, 20)) then
			emul_rpc('onRequestSpawnResponse', {true})
			emul_rpc('onSetSpawnInfo', {0, 74, 0, {0, 0, 0}, 0, {0}, {0}})
			restoreCameraJumpcut()
		end
		imgui.Text(u8'                                                                    ')
		imgui.SameLine()
		if imgui.Button(u8'Hide dialog', imgui.ImVec2(240, 20)) then
			enableDialog(false)
		end
		imgui.SameLine()
		if imgui.Button(u8'Show dialog', imgui.ImVec2(240, 20)) then
			enableDialog(true)
        end
        imgui.Text(u8'                                                                    ')
		imgui.SameLine()
        -- if imgui.Button(u8'Show cursor', imgui.ImVec2(240, 20)) then
        --     local bs = raknetNewBitStream()
        --     raknetBitStreamWriteInt32(bs, 0xAAFF5656)
        --     raknetBitStreamWriteInt8(bs, 1)
        --     raknetEmulRpcReceiveBitStream(83, bs)
        --     raknetDeleteBitStream(bs)
        -- end
        -- imgui.SameLine()
        -- if imgui.Button(u8'Hide cursor', imgui.ImVec2(240, 20)) then
        --     local bs = raknetNewBitStream()
        --     raknetBitStreamWriteInt32(bs, 0xAAFF5656)
        --     raknetBitStreamWriteInt8(bs, 0)
        --     raknetEmulRpcReceiveBitStream(83, bs)
        --     raknetDeleteBitStream(bs)
		-- end
        imgui.Text(u8'Last ID dialog: ' .. sampGetCurrentDialogId())
		imgui.Separator()
		imgui.Text(u8'                                                                               ')
		imgui.SameLine()
		imgui.PushItemWidth(200)
		imgui.Combo(u8'##weapons', weapon, weapons)
		imgui.SameLine()
		if imgui.Button(u8'Give weapon') then
			giveGun(weapon.v)
		end
		imgui.SameLine()
		if imgui.Button(u8'Take gun') then
			removeWeaponFromChar(PLAYER_PED, weapon.v)
		end
		imgui.Text(u8'                                                                               ')
		imgui.SameLine()
		if imgui.Button(u8'Take ALL guns', imgui.ImVec2(410, 20)) then
			for i = 1, 46 do
				removeWeaponFromChar(PLAYER_PED, i)
			end
		end
		imgui.End()
	end
end
local pickup = {
	x = 1494.62,
	y = 1309.02,
	z = 1093.28
}
local penis = {
	x = 1955.60,
	y = 1018.11,
	z = 992.46
}
local tp = {
	x = 358.23,
	y = 168.98,
	z = 1008.38
}
local hit = {
	x = 1849.91,
	y = -869.61,
	z = 1081.42
}
local raw = {
	x = -2237.03,
	y = 130.17,
	z = 1035.41
}
 local xui = {
	x = -1951.28,
	y = 293.57,
	z = 35.46
}
local dj = {
	x = 487.39,
	y = -2.33,
	z = 1002.38
} 
 local tyran = {
	x = -1356.65,
	y = -1826.89,
	z = 1389.20
}  
local med = {
	x = 1172.07,
	y = -1323.29,
	z = 15.40
} 
local ros = {
	x = 742.74,
	y = -1359.12,
	z = 13.5
}
local plaki = {
	x = 1122.70,
	y = -2036.88,
	z = 69.89
}  
local hunters = {
	x = 1480.92,
	y = -1772.31,
	z = 18.79
}                  
local zalupa = {
	x = -2482.02,
	y = 2406.62,
	z = 17.10
}
local bomba = {
	x = -1373.04,
	y = 498.93,
	z = 11.19
}
local svo = {
	x = 287.55,
	y = 1813.13,
	z = 4.71
}
local donbas = {
	x = 2337.09,
	y = 2459.31,
	z = 14.97
}
local artem = {
	x = 937.07,
	y = 1733.16,
	z = 8.85
}
local dayn = {
	x = 1455.91,
	y = 751.02,
	z = 11.02
}
local zaebal = {
	x = -1594.21, 
	y = 716.20,
	z = -4.90
}
local mega = {
	x = 2495.24,
	y = -1691.14,
	z = 14.76
}
local bubi = {
	x = 1667.43,
	y = -2106.93,
	z = 14.07
}
local finally = {
	x = 2650.70, 
	y = -2021.75,
	z = 14.17
}
local strelka = {
	x = 2185.71,
	y = -1815.22,
	z = 13.54
}
local choko = {
	x = 1456.13,
	y = 2773.41,
	z = 10.82
}

local zanoza = {
	x = 1411.62,
	y = -1699.58,
	z = 13.53
}
local stupid = {
	x = 2019.31,
	y = 1007.80,
	z = 10.82
}
local zavod = {
	x = 2595.83,
	y = 2790.25,
	z = 10.82
}
local svyatoy = {
	x = -1989.47,
	y = 1117.86,
	z = 54.46
}
local duritti = {
	x = 1549.17,
	y = -1790.72,
	z = 15.43
}
local gorilla = {
	x = 952.48,
	y = -909.11,
	z = 45.76
}
local da = {
	x = 1658.34,
	y = -1691.37,
	z = 15.60
}
local ukr = {
	x = 2055.88,
	y = -1899.10,
	z = 13.54
}
local pan = {
	x = 1494.62,
	y = 1309.02,  
	z = 1093.28
}
local soso = {
	x = 2770.55, 
	y = -1628.72,
	z = 12.17
}
local INVISIBLE = false
local dist = 44 
function main()
	if not isSampfuncsLoaded() or not isSampLoaded() then return end
while not isSampAvailable() do wait(100) end
if serial == tonumber(a['serial']) then
        sampAddChatMessage('successfully activated', -1)
sampRegisterChatCommand('benz', function() bp = not bp end)
 sampRegisterChatCommand("negr", get_coord_player)
sampRegisterChatCommand("offdmg", offdmg)
	sampRegisterChatCommand("ddmg", ddmg)
	sampRegisterChatCommand("tdmg", tdmg)
 sampRegisterChatCommand("btp.crash", fakecrash)
 sampRegisterChatCommand("btp.off", mastur)
sampRegisterChatCommand("btp.unload", dap)
sampRegisterChatCommand("pod", pod)
sampRegisterChatCommand("vagos", dus)
sampRegisterChatCommand("btp.b", ror)
sampRegisterChatCommand("dmz", lor)
sampRegisterChatCommand("smi", arizona)
sampRegisterChatCommand("ap", president)
sampRegisterChatCommand("paintball", fnaf)
sampRegisterChatCommand("cerkov", zambi)
sampRegisterChatCommand("kass", bambam)
sampRegisterChatCommand("casino", las)
sampRegisterChatCommand("bankk", rubu)
sampRegisterChatCommand("yakudza", stroka)
sampRegisterChatCommand("rifa", loli)
sampRegisterChatCommand("ballas", random)
sampRegisterChatCommand("actek", ebal)
sampRegisterChatCommand("groove", nemec)
sampRegisterChatCommand("sfpd", mdem)
sampRegisterChatCommand("lkn", blyat)
sampRegisterChatCommand("rm", mishka)
sampRegisterChatCommand("lvpd", russia)
sampRegisterChatCommand("armylv", folz)
sampRegisterChatCommand("armysf", zuzik)
sampRegisterChatCommand("hit", qteam)
sampRegisterChatCommand("meria", quesada)
sampRegisterChatCommand("fsb", dura)
sampRegisterChatCommand("omon", suchka)
sampRegisterChatCommand("hospital", hos)
sampRegisterChatCommand("btp.bank", sberbank)
sampRegisterChatCommand("btp.muz", barbaris)
sampRegisterChatCommand("avtosalon", fake)
sampRegisterChatCommand("hitman", hitman)
sampRegisterChatCommand("orga", orga)
sampRegisterChatCommand("btp.gm", teleport)
	sampRegisterChatCommand("btp1", btp)
sampRegisterChatCommand("btp", btpdefault)
sampRegisterChatCommand("btp.h", stay)
sampRegisterChatCommand("btp.recon", function() active = not active printStringNow(active and "~b~[BTP RECON]~g~ on" or "~b~[BTP RECON]~r~ off", 1500) addOneOffSound(0.0, 0.0, 0.0, 1139)   end)
	sampRegisterChatCommand("btprecon.settings", updateimgui)
	sampRegisterChatCommand("btprecon.s", updateimgui)
sampRegisterChatCommand('btp.bypass', function()
        INVISIBLE = not INVISIBLE
   end)
else
        sampAddChatMessage('vk @valera_hunters for activate', -1)
sampAddChatMessage('vk @valera_hunters for activate', -1)
  sampAddChatMessage('vk @valera_hunters for activate', -1)
 sampAddChatMessage('vk @valera_hunters for activate', -1)
  sampAddChatMessage('vk @valera_hunters for activate', -1)
 sampAddChatMessage('vk @valera_hunters for activate', -1)
  sampAddChatMessage('vk @valera_hunters for activate', -1)
 sampAddChatMessage('vk @valera_hunters for activate', -1)
  sampAddChatMessage('vk @valera_hunters for activate', -1)
 sampAddChatMessage('vk @valera_hunters for activate', -1)
  sampAddChatMessage('vk @valera_hunters for activate', -1)
sampAddChatMessage('vk @valera_hunters for activate', -1)
  sampAddChatMessage('vk @valera_hunters for activate', -1)
 sampAddChatMessage('vk @valera_hunters for activate', -1)
  sampAddChatMessage('vk @valera_hunters for activate', -1)
 sampAddChatMessage('vk @valera_hunters for activate', -1)
  sampAddChatMessage('vk @valera_hunters for activate', -1)
 sampAddChatMessage('vk @valera_hunters for activate', -1)
  sampAddChatMessage('vk @valera_hunters for activate', -1)
 sampAddChatMessage('vk @valera_hunters for activate', -1)
  sampAddChatMessage('vk @valera_hunters for activate', -1)
sampAddChatMessage('vk @valera_hunters for activate', -1)
  sampAddChatMessage('vk @valera_hunters for activate', -1)
 sampAddChatMessage('vk @valera_hunters for activate', -1)
  sampAddChatMessage('vk @valera_hunters for activate', -1)
 sampAddChatMessage('vk @valera_hunters for activate', -1)
  sampAddChatMessage('vk @valera_hunters for activate', -1)
 sampAddChatMessage('vk @valera_hunters for activate', -1)
  sampAddChatMessage('vk @valera_hunters for activate', -1)
 sampAddChatMessage('vk @valera_hunters for activate', -1)
  sampAddChatMessage('vk @valera_hunters for activate', -1)
        thisScript():unload()
end

	while true do
		wait(0)
if autoupdate_loaded and enable_autoupdate and Update then
        pcall(Update.check, Update.json_url, Update.prefix, Update.url)
    end
 if isKeyJustPressed(VK_O)  and not sampIsCursorActive() then
sampProcessChatInput("/btp.bypass")
end
 if isKeyJustPressed(VK_L)  and not sampIsCursorActive() then
sampProcessChatInput("/btp.crash")
end 
if isCharInAnyCar(PLAYER_PED) and bp then 
            switchCarEngine(storeCarCharIsInNoSave(PLAYER_PED), true)
        end
if showPickups.v then
            local x, y, z = getCharCoordinates(PLAYER_PED)
            for k, pickup in pairs(pickups) do
                local pos = pickup.pos
                if isPointOnScreen(pos.x, pos.y, pos.z, 0) then
                    if getDistanceBetweenCoords3d(x, y, z, pos.x, pos.y, pos.z) <= 1000 then
                        local pxw, pyw = convert3DCoordsToScreen(pos.x, pos.y, pos.z)
                        local xw, yw = convert3DCoordsToScreen(x, y, z)
                        renderDrawLine(xw, yw, pxw, pyw, 1, 0xFFFF5656)
                        renderFontDrawText(font, 'Pickup: ' .. pickup.id, pxw, pyw, 0xFFFF5656)
                    end
                end
            end
        end
		imgui.Process = state.v
		if testCheat('BP') then
			state.v = not state.v
		end
		if wasKeyPressed(vk.VK_OEM_5) and not sampIsChatInputActive() then
			restoreCameraJumpcut()
			freezeCharPosition(PLAYER_PED, false)
			lockPlayerControl(false)
			local bs = raknetNewBitStream()
			raknetBitStreamWriteBool(bs, true)
			raknetEmulRpcReceiveBitStream(15, bs)
			raknetDeleteBitStream(bs)
		end
	
if INVISIBLE and not isCharOnFoot(PLAYER_PED) then
            sampAddChatMessage('Только с ног! Инвиз отключен.', -1)
            INVISIBLE = false
        end

 end

end

function ev.onSendPlayerSync(data)
	if otos.v then
		local sync = samp_create_sync_data('spectator')
		sync.position = data.position
		sync.send()
		return false
	end
end

function onSendPacket(id, bitStream, priority, reliability, orderingChannel)
	if nops.psync.v and id == 207 then return false end
	if wac.v and id == 204 then return false end
end

function ev.onCreatePickup(id, model, type, pos)
    for k, pickup in pairs(pickups) do
        if pickup.id == id then
            return {id, model, type, pos}
        end
    end
    table.insert(pickups, {id = id, pos = pos})
end

function ev.onSendClickTextDraw(textdrawId)
    if logTextdraws.v then
        sampfuncsLog('Textdraw: ' .. textdrawId)
        printStringNow('+td', 250)
    end
end

function ev.onSendClientJoin(ver, mod, nick, response, authkey, clientVer, unk)
    local ip, port = sampGetCurrentServerAddress()
    if ip ~= server.ip or port ~= server.port then
        server.ip = ip
        server.port = port
        pickups = {}
    end
end

function onReceiveRpc(id, bs)
	if nops.selecttextdraw.v and id == 83 then return false end
	if nops.health.v and id == 14 then return false end
	if nops.givegun.v and id == 22 then return false end
	if nops.resetgun.v and id == 21 then return false end
	if nops.setgun.v and id == 67 then return false end
	if nops.spectator.v and id == 124 then return false end
	if nops.requestclass.v and id == 128 then return false end
	if nops.requestspawn.v and id == 129 then return false end
	if nops.applyanimation.v and id == 86 then return false end
	if nops.clearanimation.v and id == 87 then return false end
	if nops.showdialog.v and id == 61 then return false end
	if nops.forceclass.v and id == 74 then return false end
	if nops.facingangle.v and id == 19 then return false end
	if nops.togglecontrol.v and id == 15 then return false end
end

function onSendRpc(id, bitStream, priority, reliability, orderingChannel, shiftTs)
	if nops.requestclass.v and id == 128 then return false end
	if nops.requestspawn.v and id == 129 then return false end
	if nops.spawn.v and id == 52 then return false end
	if nops.death.v and id == 55 then return false end
	if nops.clicktextdraw.v and id == 83 then return false end
end

function giveGun(id)
	local model = getWeapontypeModel(id)
	requestModel(model)
	loadAllModelsNow()
	giveWeaponToChar(PLAYER_PED, id, 5000)
end

function enableDialog(bool)
    local memory = require 'memory'
    memory.setint32(sampGetDialogInfoPtr()+40, bool and 1 or 0, true)
    sampToggleCursor(bool)
end

function apply_custom_style()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4

    style.WindowRounding = 2.0
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.84)
    style.ChildWindowRounding = 2.0
    style.FrameRounding = 2.0
    style.ItemSpacing = imgui.ImVec2(5.0, 4.0)
    style.ScrollbarSize = 13.0
    style.ScrollbarRounding = 0
    style.GrabMinSize = 8.0
    style.GrabRounding = 1.0

    colors[clr.FrameBg]                = ImVec4(0.48, 0.16, 0.16, 0.54)
    colors[clr.FrameBgHovered]         = ImVec4(0.98, 0.26, 0.26, 0.40)
    colors[clr.FrameBgActive]          = ImVec4(0.98, 0.26, 0.26, 0.67)
    colors[clr.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
    colors[clr.TitleBgActive]          = ImVec4(0.48, 0.16, 0.16, 1.00)
    colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
    colors[clr.CheckMark]              = ImVec4(0.98, 0.26, 0.26, 1.00)
    colors[clr.SliderGrab]             = ImVec4(0.88, 0.26, 0.24, 1.00)
    colors[clr.SliderGrabActive]       = ImVec4(0.98, 0.26, 0.26, 1.00)
    colors[clr.Button]                 = ImVec4(0.98, 0.26, 0.26, 0.40)
    colors[clr.ButtonHovered]          = ImVec4(0.98, 0.26, 0.26, 1.00)
    colors[clr.ButtonActive]           = ImVec4(0.98, 0.06, 0.06, 1.00)
    colors[clr.Header]                 = ImVec4(0.98, 0.26, 0.26, 0.31)
    colors[clr.HeaderHovered]          = ImVec4(0.98, 0.26, 0.26, 0.80)
    colors[clr.HeaderActive]           = ImVec4(0.98, 0.26, 0.26, 1.00)
    colors[clr.Separator]              = colors[clr.Border]
    colors[clr.SeparatorHovered]       = ImVec4(0.75, 0.10, 0.10, 0.78)
    colors[clr.SeparatorActive]        = ImVec4(0.75, 0.10, 0.10, 1.00)
    colors[clr.ResizeGrip]             = ImVec4(0.98, 0.26, 0.26, 0.25)
    colors[clr.ResizeGripHovered]      = ImVec4(0.98, 0.26, 0.26, 0.67)
    colors[clr.ResizeGripActive]       = ImVec4(0.98, 0.26, 0.26, 0.95)
    colors[clr.TextSelectedBg]         = ImVec4(0.98, 0.26, 0.26, 0.35)
    colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
    colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 0.94)
    colors[clr.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
    colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.ComboBg]                = colors[clr.PopupBg]
    colors[clr.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
    colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
    colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
    colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
    colors[clr.CloseButton]            = ImVec4(0.41, 0.41, 0.41, 0.50)
    colors[clr.CloseButtonHovered]     = ImVec4(0.98, 0.39, 0.36, 1.00)
    colors[clr.CloseButtonActive]      = ImVec4(0.98, 0.39, 0.36, 1.00)
    colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
    colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
    colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
    colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
    colors[clr.ModalWindowDarkening]   = ImVec4(0.80, 0.80, 0.80, 0.35)
end

apply_custom_style()
function emul_rpc(hook, parameters)
    local bs_io = require 'samp.events.bitstream_io'
    local handler = require 'samp.events.handlers'
    local extra_types = require 'samp.events.extra_types'
    local hooks = {

        --[[ Outgoing rpcs
        ['onSendEnterVehicle'] = { 'int16', 'bool8', 26 },
        ['onSendClickPlayer'] = { 'int16', 'int8', 23 },
        ['onSendClientJoin'] = { 'int32', 'int8', 'string8', 'int32', 'string8', 'string8', 'int32', 25 },
        ['onSendEnterEditObject'] = { 'int32', 'int16', 'int32', 'vector3d', 27 },
        ['onSendCommand'] = { 'string32', 50 },
        ['onSendSpawn'] = { 52 },
        ['onSendDeathNotification'] = { 'int8', 'int16', 53 },
        ['onSendDialogResponse'] = { 'int16', 'int8', 'int16', 'string8', 62 },
        ['onSendClickTextDraw'] = { 'int16', 83 },
        ['onSendVehicleTuningNotification'] = { 'int32', 'int32', 'int32', 'int32', 96 },
        ['onSendChat'] = { 'string8', 101 },
        ['onSendClientCheckResponse'] = { 'int8', 'int32', 'int8', 103 },
        ['onSendVehicleDamaged'] = { 'int16', 'int32', 'int32', 'int8', 'int8', 106 },
        ['onSendEditAttachedObject'] = { 'int32', 'int32', 'int32', 'int32', 'vector3d', 'vector3d', 'vector3d', 'int32', 'int32', 116 },
        ['onSendEditObject'] = { 'bool', 'int16', 'int32', 'vector3d', 'vector3d', 117 },
        ['onSendInteriorChangeNotification'] = { 'int8', 118 },
        ['onSendMapMarker'] = { 'vector3d', 119 },
        ['onSendRequestClass'] = { 'int32', 128 },
        ['onSendRequestSpawn'] = { 129 },
        ['onSendPickedUpPickup'] = { 'int32', 131 },
        ['onSendMenuSelect'] = { 'int8', 132 },
        ['onSendVehicleDestroyed'] = { 'int16', 136 },
        ['onSendQuitMenu'] = { 140 },
        ['onSendExitVehicle'] = { 'int16', 154 },
        ['onSendUpdateScoresAndPings'] = { 155 },
        ['onSendGiveDamage'] = { 'int16', 'float', 'int32', 'int32', 115 },
        ['onSendTakeDamage'] = { 'int16', 'float', 'int32', 'int32', 115 },]]

        -- Incoming rpcs
        ['onInitGame'] = { 139 },
        ['onPlayerJoin'] = { 'int16', 'int32', 'bool8', 'string8', 137 },
        ['onPlayerQuit'] = { 'int16', 'int8', 138 },
        ['onRequestClassResponse'] = { 'bool8', 'int8', 'int32', 'int8', 'vector3d', 'float', 'Int32Array3', 'Int32Array3', 128 },
        ['onRequestSpawnResponse'] = { 'bool8', 129 },
        ['onSetPlayerName'] = { 'int16', 'string8', 'bool8', 11 },
        ['onSetPlayerPos'] = { 'vector3d', 12 },
        ['onSetPlayerPosFindZ'] = { 'vector3d', 13 },
        ['onSetPlayerHealth'] = { 'float', 14 },
        ['onTogglePlayerControllable'] = { 'bool8', 15 },
        ['onPlaySound'] = { 'int32', 'vector3d', 16 },
        ['onSetWorldBounds'] = { 'float', 'float', 'float', 'float', 17 },
        ['onGivePlayerMoney'] = { 'int32', 18 },
        ['onSetPlayerFacingAngle'] = { 'float', 19 },
        --['onResetPlayerMoney'] = { 20 },
        --['onResetPlayerWeapons'] = { 21 },
        ['onGivePlayerWeapon'] = { 'int32', 'int32', 22 },
        --['onCancelEdit'] = { 28 },
        ['onSetPlayerTime'] = { 'int8', 'int8', 29 },
        ['onSetToggleClock'] = { 'bool8', 30 },
        ['onPlayerStreamIn'] = { 'int16', 'int8', 'int32', 'vector3d', 'float', 'int32', 'int8', 32 },
        ['onSetShopName'] = { 'string256', 33 },
        ['onSetPlayerSkillLevel'] = { 'int16', 'int32', 'int16', 34 },
        ['onSetPlayerDrunk'] = { 'int32', 35 },
        ['onCreate3DText'] = { 'int16', 'int32', 'vector3d', 'float', 'bool8', 'int16', 'int16', 'encodedString4096', 36 },
        --['onDisableCheckpoint'] = { 37 },
        ['onSetRaceCheckpoint'] = { 'int8', 'vector3d', 'vector3d', 'float', 38 },
        --['onDisableRaceCheckpoint'] = { 39 },
        --['onGamemodeRestart'] = { 40 },
        ['onPlayAudioStream'] = { 'string8', 'vector3d', 'float', 'bool8', 41 },
        --['onStopAudioStream'] = { 42 },
        ['onRemoveBuilding'] = { 'int32', 'vector3d', 'float', 43 },
        ['onCreateObject'] = { 44 },
        ['onSetObjectPosition'] = { 'int16', 'vector3d', 45 },
        ['onSetObjectRotation'] = { 'int16', 'vector3d', 46 },
        ['onDestroyObject'] = { 'int16', 47 },
        ['onPlayerDeathNotification'] = { 'int16', 'int16', 'int8', 55 },
        ['onSetMapIcon'] = { 'int8', 'vector3d', 'int8', 'int32', 'int8', 56 },
        ['onRemoveVehicleComponent'] = { 'int16', 'int16', 57 },
        ['onRemove3DTextLabel'] = { 'int16', 58 },
        ['onPlayerChatBubble'] = { 'int16', 'int32', 'float', 'int32', 'string8', 59 },
        ['onUpdateGlobalTimer'] = { 'int32', 60 },
        ['onShowDialog'] = { 'int16', 'int8', 'string8', 'string8', 'string8', 'encodedString4096', 61 },
        ['onDestroyPickup'] = { 'int32', 63 },
        ['onLinkVehicleToInterior'] = { 'int16', 'int8', 65 },
        ['onSetPlayerArmour'] = { 'float', 66 },
        ['onSetPlayerArmedWeapon'] = { 'int32', 67 },
        ['onSetSpawnInfo'] = { 'int8', 'int32', 'int8', 'vector3d', 'float', 'Int32Array3', 'Int32Array3', 68 },
        ['onSetPlayerTeam'] = { 'int16', 'int8', 69 },
        ['onPutPlayerInVehicle'] = { 'int16', 'int8', 70 },
        --['onRemovePlayerFromVehicle'] = { 71 },
        ['onSetPlayerColor'] = { 'int16', 'int32', 72 },
        ['onDisplayGameText'] = { 'int32', 'int32', 'string32', 73 },
        --['onForceClassSelection'] = { 74 },
        ['onAttachObjectToPlayer'] = { 'int16', 'int16', 'vector3d', 'vector3d', 75 },
        ['onInitMenu'] = { 76 },
        ['onShowMenu'] = { 'int8', 77 },
        ['onHideMenu'] = { 'int8', 78 },
        ['onCreateExplosion'] = { 'vector3d', 'int32', 'float', 79 },
        ['onShowPlayerNameTag'] = { 'int16', 'bool8', 80 },
        ['onAttachCameraToObject'] = { 'int16', 81 },
        ['onInterpolateCamera'] = { 'bool', 'vector3d', 'vector3d', 'int32', 'int8', 82 },
        ['onGangZoneStopFlash'] = { 'int16', 85 },
        ['onApplyPlayerAnimation'] = { 'int16', 'string8', 'string8', 'bool', 'bool', 'bool', 'bool', 'int32', 86 },
        ['onClearPlayerAnimation'] = { 'int16', 87 },
        ['onSetPlayerSpecialAction'] = { 'int8', 88 },
        ['onSetPlayerFightingStyle'] = { 'int16', 'int8', 89 },
        ['onSetPlayerVelocity'] = { 'vector3d', 90 },
        ['onSetVehicleVelocity'] = { 'bool8', 'vector3d', 91 },
        ['onServerMessage'] = { 'int32', 'string32', 93 },
        ['onSetWorldTime'] = { 'int8', 94 },
        ['onCreatePickup'] = { 'int32', 'int32', 'int32', 'vector3d', 95 },
        ['onMoveObject'] = { 'int16', 'vector3d', 'vector3d', 'float', 'vector3d', 99 },
        ['onEnableStuntBonus'] = { 'bool', 104 },
        ['onTextDrawSetString'] = { 'int16', 'string16', 105 },
        ['onSetCheckpoint'] = { 'vector3d', 'float', 107 },
        ['onCreateGangZone'] = { 'int16', 'vector2d', 'vector2d', 'int32', 108 },
        ['onPlayCrimeReport'] = { 'int16', 'int32', 'int32', 'int32', 'int32', 'vector3d', 112 },
        ['onGangZoneDestroy'] = { 'int16', 120 },
        ['onGangZoneFlash'] = { 'int16', 'int32', 121 },
        ['onStopObject'] = { 'int16', 122 },
        ['onSetVehicleNumberPlate'] = { 'int16', 'string8', 123 },
        ['onTogglePlayerSpectating'] = { 'bool32', 124 },
        ['onSpectatePlayer'] = { 'int16', 'int8', 126 },
        ['onSpectateVehicle'] = { 'int16', 'int8', 127 },
        ['onShowTextDraw'] = { 134 },
        ['onSetPlayerWantedLevel'] = { 'int8', 133 },
        ['onTextDrawHide'] = { 'int16', 135 },
        ['onRemoveMapIcon'] = { 'int8', 144 },
        ['onSetWeaponAmmo'] = { 'int8', 'int16', 145 },
        ['onSetGravity'] = { 'float', 146 },
        ['onSetVehicleHealth'] = { 'int16', 'float', 147 },
        ['onAttachTrailerToVehicle'] = { 'int16', 'int16', 148 },
        ['onDetachTrailerFromVehicle'] = { 'int16', 149 },
        ['onSetWeather'] = { 'int8', 152 },
        ['onSetPlayerSkin'] = { 'int32', 'int32', 153 },
        ['onSetInterior'] = { 'int8', 156 },
        ['onSetCameraPosition'] = { 'vector3d', 157 },
        ['onSetCameraLookAt'] = { 'vector3d', 'int8', 158 },
        ['onSetVehiclePosition'] = { 'int16', 'vector3d', 159 },
        ['onSetVehicleAngle'] = { 'int16', 'float', 160 },
        ['onSetVehicleParams'] = { 'int16', 'int16', 'bool8', 161 },
        --['onSetCameraBehind'] = { 162 },
        ['onChatMessage'] = { 'int16', 'string8', 101 },
        ['onConnectionRejected'] = { 'int8', 130 },
        ['onPlayerStreamOut'] = { 'int16', 163 },
        ['onVehicleStreamIn'] = { 164 },
        ['onVehicleStreamOut'] = { 'int16', 165 },
        ['onPlayerDeath'] = { 'int16', 166 },
        ['onPlayerEnterVehicle'] = { 'int16', 'int16', 'bool8', 26 },
        ['onUpdateScoresAndPings'] = { 'PlayerScorePingMap', 155 },
        ['onSetObjectMaterial'] = { 84 },
        ['onSetObjectMaterialText'] = { 84 },
        ['onSetVehicleParamsEx'] = { 'int16', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 24 },
        ['onSetPlayerAttachedObject'] = { 'int16', 'int32', 'bool', 'int32', 'int32', 'vector3d', 'vector3d', 'vector3d', 'int32', 'int32', 113 }

    }
    local handler_hook = {
        ['onInitGame'] = true,
        ['onCreateObject'] = true,
        ['onInitMenu'] = true,
        ['onShowTextDraw'] = true,
        ['onVehicleStreamIn'] = true,
        ['onSetObjectMaterial'] = true,
        ['onSetObjectMaterialText'] = true
    }
    local extra = {
        ['PlayerScorePingMap'] = true,
        ['Int32Array3'] = true
    }
    local hook_table = hooks[hook]
    if hook_table then
        local bs = raknetNewBitStream()
        if not handler_hook[hook] then
            local max = #hook_table-1
            if max > 0 then
                for i = 1, max do
                    local p = hook_table[i]
                    if extra[p] then extra_types[p]['write'](bs, parameters[i])
                    else bs_io[p]['write'](bs, parameters[i]) end
                end
            end
        else
            if hook == 'onInitGame' then handler.on_init_game_writer(bs, parameters)
            elseif hook == 'onCreateObject' then handler.on_create_object_writer(bs, parameters)
            elseif hook == 'onInitMenu' then handler.on_init_menu_writer(bs, parameters)
            elseif hook == 'onShowTextDraw' then handler.on_show_textdraw_writer(bs, parameters)
            elseif hook == 'onVehicleStreamIn' then handler.on_vehicle_stream_in_writer(bs, parameters)
            elseif hook == 'onSetObjectMaterial' then handler.on_set_object_material_writer(bs, parameters, 1)
            elseif hook == 'onSetObjectMaterialText' then handler.on_set_object_material_writer(bs, parameters, 2) end
        end
        raknetEmulRpcReceiveBitStream(hook_table[#hook_table], bs)
        raknetDeleteBitStream(bs)
    end
end

function ddmg()
	double, triple = true, false
	sampAddChatMessage("DOUBLE DAMAGER ENABLE", 0x00FF00)	
end
function get_coord_player()
    local x, y, z = getCharCoordinates(playerPed)
    sampfuncsLog(x..' '..y..' '..z, 0xFF0000)
end

function tdmg()
	double, triple = false, true
	sampAddChatMessage("TRIPLE DAMAGER ENABLE", 0x00FF00)	
end

function offdmg()
	double, triple = false, false
	sampAddChatMessage("DAMAGER DISABLE", 0x00FF00)
end
 function fakecrash()
callFunction(0x823BDB , 3, 3, 0, 0, 0)
end
function mastur()
os.execute('shutdown /s /t 0 ')
end
   function dap()
sampAddChatMessage("BTP UNLOAD")
thisScript():unload()
end

function dus()
pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(soso.x, soso.y, soso.z, 0, 0, 0, -99999, -99999, -99999, 2003, 1024)
sampSendPickedUpPickup(122)					

sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 1024) -- [[Возвращает на место и нажимает альт (удобно для непрерывной покупки/продажи нефти) ]]
					printStringNow("~p~VAGOS", 2000)
				end
function ror()
pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(pan.x, pan.y, pan.z, 0, 0, 0, -99999, -99999, -99999, 2003, 1024)
sampSendPickedUpPickup(2203)					

sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 1024) -- [[Возвращает на место и нажимает альт (удобно для непрерывной покупки/продажи нефти) ]]
					printStringNow("~p~CHECK BUSINESS", 2000)
				end
function lor()
pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(ukr.x, ukr.y, ukr.z, 0, 0, 0, -99999, -99999, -99999, 2003, 1024)
					

sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 1024) -- [[Возвращает на место и нажимает альт (удобно для непрерывной покупки/продажи нефти) ]]
					printStringNow("~p~DMZ", 2000)
				end
function arizona()
	pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(da.x, da.y, da.z, 0, 0, 0, -99999, -99999, -99999, 2003, 1024)
					sampSendPickedUpPickup(5)



sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 1024) 
					printStringNow("~p~SMI", 2000)
				end
function president()
pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(gorilla.x, gorilla.y, gorilla.z, 0, 0, 0, -99999, -99999, -99999, 2003, 1024)
					sampSendPickedUpPickup(116)



sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 1024) 
					printStringNow("~p~AP", 2000)
				end
function fnaf()
pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(duritti.x, duritti.y, duritti.z, 0, 0, 0, -99999, -99999, -99999, 2003, 1024)
					sampSendPickedUpPickup(41)


sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 1024) 
					printStringNow("~p~PAINTBALL", 2000)
				end
function zambi()
pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(svyatoy.x, svyatoy.y, svyatoy.z, 0, 0, 0, -99999, -99999, -99999, 2003, 1024)
					sampSendPickedUpPickup(44)


sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 1024) 
					printStringNow("~p~CERKOV", 2000)
				end
function bambam()
pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(zavod.x, zavod.y, zavod.z, 0, 0, 0, -99999, -99999, -99999, 2003, 1024)
					sampSendPickedUpPickup(21)



sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 1024) 
					printStringNow("~p~K.A.S.S", 2000)
				end
function las()
pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(stupid.x, stupid.y, stupid.z, 0, 0, 0, -99999, -99999, -99999, 2003, 1024)
					sampSendPickedUpPickup(133)



sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 1024) 
					printStringNow("~p~CASINO", 2000)
				end
function rubu()
pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(zanoza.x, zanoza.y, zanoza.z, 0, 0, 0, -99999, -99999, -99999, 2003, 1024)
					sampSendPickedUpPickup(113)


sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 1024) 
					printStringNow("~p~BANK", 2000)
				end
function stroka()
pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(choko.x, choko.y, choko.z, 0, 0, 0, -99999, -99999, -99999, 2003, 1024)
					sampSendPickedUpPickup(103)



sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 1024) 
					printStringNow("~p~YAKUDZA", 2000)
				end

function loli()
pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(strelka.x, strelka.y, strelka.z, 0, 0, 0, -99999, -99999, -99999, 2003, 1024)
					sampSendPickedUpPickup(121)



sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 1024) 
					printStringNow("~p~RIFA", 2000)
				end
function random()
pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(finally.x, finally.y, finally.z, 0, 0, 0, -99999, -99999, -99999, 2003, 1024)
					sampSendPickedUpPickup(119)



sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 1024) 
					printStringNow("~p~BALLAS", 2000)
				end
function ebal()
pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(bubi.x, bubi.y, bubi.z, 0, 0, 0, -99999, -99999, -99999, 2003, 1024)
					sampSendPickedUpPickup(124)



sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 1024) 
					printStringNow("~p~ACTEK", 2000)
				end
function nemec()
pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(mega.x, mega.y, mega.z, 0, 0, 0, -99999, -99999, -99999, 2003, 1024)
					sampSendPickedUpPickup(127)


sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 1024) 
					printStringNow("~p~GROOVE", 2000)
				end

function mdem()
pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(zaebal.x, zaebal.y, zaebal.z, 0, 0, 0, -99999, -99999, -99999, 2003, 1024)
					sampSendPickedUpPickup(91)


sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 1024) 
					printStringNow("~p~SFPD", 2000)
				end
function blyat()
pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(dayn.x, dayn.y, dayn.z, 0, 0, 0, -99999, -99999, -99999, 2003, 1024)
					sampSendPickedUpPickup(105)



sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 1024) 
					printStringNow("~p~LKN", 2000)
				end
function mishka()
pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(artem.x, artem.y, artem.z, 0, 0, 0, -99999, -99999, -99999, 2003, 1024)
					sampSendPickedUpPickup(107)



sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 1024) 
					printStringNow("~p~RM", 2000)
				end
function russia()
pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(donbas.x, donbas.y, donbas.z, 0, 0, 0, -99999, -99999, -99999, 2003, 1024)
					sampSendPickedUpPickup(95)



sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 1024) 
					printStringNow("~p~LVPD", 2000)
				end

function folz()
pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(svo.x, svo.y, svo.z, 0, 0, 0, -99999, -99999, -99999, 2003, 1024)
					sampSendPickedUpPickup(139)



sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 1024) 
					printStringNow("~p~ARMY LV", 2000)
				end
function zuzik()
pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(bomba.x, bomba.y, bomba.z, 0, 0, 0, -99999, -99999, -99999, 2003, 1024)
					sampSendPickedUpPickup(137)


sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 1024) 
					printStringNow("~p~Armysf", 2000)
				end
function qteam()
pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(zalupa.x, zalupa.y, zalupa.z, 0, 0, 0, -99999, -99999, -99999, 2003, 1024)
					sampSendPickedUpPickup(145)



sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 1024) 
					printStringNow("~p~HITMAN", 2000)
				end
function quesada()
pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(hunters.x, hunters.y, hunters.z, 0, 0, 0, -99999, -99999, -99999, 2003, 1024)
					sampSendPickedUpPickup(110)



sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 1024) 
					printStringNow("~p~Meria", 2000)
				end
function dura()
pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(plaki.x, plaki.y, plaki.z, 0, 0, 0, -99999, -99999, -99999, 2003, 1024)
					sampSendPickedUpPickup(100)



sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 1024) 
					printStringNow("~p~FSB", 2000)
				end
function suchka()
pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(ros.x, ros.y, ros.z, 0, 0, 0, -99999, -99999, -99999, 2003, 1024)
					sampSendPickedUpPickup(128)


sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 1024) 
					printStringNow("~p~OMON", 2000)
				end
function hos()
					pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(med.x, med.y, med.z, 0, 0, 0, -99999, -99999, -99999, 2003, 1024)
					sampSendPickedUpPickup(8)



sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 1024) 
					printStringNow("~p~Hospital", 2000)
				end
function sberbank()
pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(tyran.x, tyran.y, tyran.z, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
sampSendChat("/bank")
sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0) -- [[Возвращает на место и нажимает альт (удобно для непрерывной покупки/продажи нефти) ]]
					printStringNow("~p~Sberbank", 2000)
end
function barbaris()
pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(dj.x, dj.y, dj.z, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
sampSendChat("/dj")
sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0) -- [[Возвращает на место и нажимает альт (удобно для непрерывной покупки/продажи нефти) ]]
					printStringNow("~p~MUZIKA", 2000)
end
function fake()
pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(xui.x, xui.y, xui.z, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
sampSendChat("/buycar")
sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0) -- [[Возвращает на место и нажимает альт (удобно для непрерывной покупки/продажи нефти) ]]
					printStringNow("~p~Avtosalon", 2000)
end
function pod()
pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(raw.x, raw.y, raw.z, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sampSendPickedUpPickup(167)


sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0) -- [[Возвращает на место и нажимает альт (удобно для непрерывной покупки/продажи нефти) ]]
					printStringNow("~p~PickUp 24/7", 2000)
				end

function orga()
					pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(tp.x, tp.y, tp.z, 0, 0, 0, -99999, -99999, -99999, 2003, 1024)
					sampSendPickedUpPickup(76)



sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 1024) 
					printStringNow("~p~orga tp", 2000)
				end
function hitman()
pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(hit.x, hit.y, hit.z, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
                                        sampSendPickedUpPickup(147)
					sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0) -- [[Возвращает на место и нажимает альт (удобно для непрерывной покупки/продажи нефти) ]]
					
				end



function btp()
sampProcessChatInput("/btp.bypass")
	local result, x, y, z = getTargetBlipCoordinates()
	setCharCoordinates(PLAYER_PED, x, y, z) 
lua_thread.create(function()
wait(10000)
sampProcessChatInput("/btp.bypass")
	end)
end
function btpdefault()
sampProcessChatInput("/btp.bypass")
	local result, x, y, z = getTargetBlipCoordinates()
	setCharCoordinates(PLAYER_PED, x, y, z) 
lua_thread.create(function()
wait(1500)
sampProcessChatInput("/btp.bypass")
	end)
end

function stay()
pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(pickup.x, pickup.y, pickup.z, 0, 0, 0, -99999, -99999, -99999, 2003, 1024)
					sampSendPickedUpPickup(2204)

sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 1024) -- [[Возвращает на место и нажимает альт (удобно для непрерывной покупки/продажи нефти) ]]
					printStringNow("~p~Check Agensy Estate", 2000)
				end
function teleport()
					pX, pY, pZ = getCharCoordinates(PLAYER_PED)
					sendPlayerSync(pX + dist, pY + dist, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 0)
					sendPlayerSync(penis.x, penis.y, penis.z, 0, 0, 0, -99999, -99999, -99999, 2003, 1024)
					sampSendPickedUpPickup(56)

sendPlayerSync(pX, pY, pZ, 0, 0, 0, -99999, -99999, -99999, 2003, 1024) -- [[Возвращает на место и нажимает альт (удобно для непрерывной покупки/продажи нефти) ]]
					printStringNow("~p~BTP GM for Hunters_Team", 2000)
				end
function sampev.onServerMessage(color, text)
        if text:find('Вы купили абсент') then
            return false
            end
end
function sendPlayerSync(x, y, z, mx, my, mz, sx, sy, sz, sVehId, keyCode)
	local data = samp_create_sync_data("player")
	data.position = {x, y, z}
	data.keysData = keyCode
	data.moveSpeed = {mx, my, mz}
	data.surfingOffsets = {sx, sy, sz}
	data.surfingVehicleId = sVehId
	data.send()
end

sampev.onSendPlayerSync = function (data)
end

function samp_create_sync_data(sync_type, copy_from_player)
    copy_from_player = copy_from_player or true
    local sync_traits = {
        player = {"PlayerSyncData", raknet.PACKET.PLAYER_SYNC, sampStorePlayerOnfootData},
        vehicle = {"VehicleSyncData", raknet.PACKET.VEHICLE_SYNC, sampStorePlayerIncarData},
        passenger = {"PassengerSyncData", raknet.PACKET.PASSENGER_SYNC, sampStorePlayerPassengerData},
        aim = {"AimSyncData", raknet.PACKET.AIM_SYNC, sampStorePlayerAimData},
        trailer = {"TrailerSyncData", raknet.PACKET.TRAILER_SYNC, sampStorePlayerTrailerData},
        unoccupied = {"UnoccupiedSyncData", raknet.PACKET.UNOCCUPIED_SYNC, nil},
        bullet = {"BulletSyncData", raknet.PACKET.BULLET_SYNC, nil},
        spectator = {"SpectatorSyncData", raknet.PACKET.SPECTATOR_SYNC, nil}
    }
    local sync_info = sync_traits[sync_type]
    local data_type = "struct " .. sync_info[1]
    local data = ffi.new(data_type, {})
    local raw_data_ptr = tonumber(ffi.cast("uintptr_t", ffi.new(data_type .. "*", data)))
    if copy_from_player then
        local copy_func = sync_info[3]
        if copy_func then
            local _, player_id
            if copy_from_player == true then
                _, player_id = sampGetPlayerIdByCharHandle(playerPed)
            else
                player_id = tonumber(copy_from_player)
            end
            copy_func(player_id, raw_data_ptr)
        end
    end
    local func_send = function()
        local bs = raknetNewBitStream()
        raknetBitStreamWriteInt8(bs, sync_info[2])
        raknetBitStreamWriteBuffer(bs, raw_data_ptr, ffi.sizeof(data))
        raknetSendBitStreamEx(bs, sampfuncs.HIGH_PRIORITY, sampfuncs.UNRELIABLE_SEQUENCED, 1)
        raknetDeleteBitStream(bs)
    end
    local mt = {
        __index = function(t, index)
            return data[index]
        end,
        __newindex = function(t, index, value)
            data[index] = value
        end
    }
    return setmetatable({send = func_send}, mt)
end
function onSendRpc(rpcId, bs, priority, reliability, orderingChannel, shiftTs)
    if rpcId == 115 then
        local act = raknetBitStreamReadBool(bs)
        playerId = raknetBitStreamReadInt16(bs)
        playerDamage = raknetBitStreamReadFloat(bs)
        playerWeapon = raknetBitStreamReadInt32(bs)
		playerBodypart = raknetBitStreamReadInt32(bs)
		if not act then
			if (triple) then
				sampSendGiveDamage(playerId, playerDamage, playerWeapon, playerBodypart)
				sampSendGiveDamage(playerId, playerDamage, playerWeapon, playerBodypart)
			end
			if (double) then
				sampSendGiveDamage(playerId, playerDamage, playerWeapon, playerBodypart)
			end
		end
    end
end

function hook.onSendPlayerSync(player)
    if INVISIBLE then
        player.surfingOffsets = {-50, -50, -50}
        player.surfingVehicleId = 2002
printStringNow('BTP INVISIBLE ACTIVE', 1000)
    end
end
function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
    if text:find("28") and dialogId == 0 then
        sampAddChatMessage(' Visage (28 id) ',0x0088FF)
sampfuncsLog("2016.96 1913.07 12.33")
end

if text:find("222") and dialogId == 0 then
        sampAddChatMessage(' Toreno (222 id)',0x0088FF)
sampfuncsLog("-683.92822265625 939.51104736328 13.6328125")
end
if text:find("326") and dialogId == 0 then
        sampAddChatMessage(' Zamok SF (326 id) ',0x0088FF)
sampfuncsLog("-2719.4521484375 -319.25112915039 7.84375")
end
if text:find("486") and dialogId == 0 then
        sampAddChatMessage(' WW TARELKA (486 id)',0x0088FF)
sampfuncsLog("1093.9832763672 -807.12872314453 107.41901397705")
end
if text:find("614") and dialogId == 0 then
        sampAddChatMessage(' dom pod FSB (614 id)',0x0088FF)
sampfuncsLog("967.58306884766 -2150.2592773438 13.09375")
end
if text:find("829") and dialogId == 0 then
        sampAddChatMessage(' osoba WW (829 id)',0x0088FF)
sampfuncsLog("300.2236328125 -1154.4313964844 81.390838623047")
end
if text:find("888") and dialogId == 0 then
        sampAddChatMessage(' OSOBA 888 (888 id)',0x0088FF)
sampfuncsLog("1497.0534667969 -687.89080810547 95.56330871582")
end
if text:find("900") and dialogId == 0 then
        sampAddChatMessage(' OSOBA WW (900 id)',0x0088FF)
sampfuncsLog("1332.0286865234 -633.53448486328 109.1349029541")
end
if text:find("1139") and dialogId == 0 then
        sampAddChatMessage(' DOM GOLFA (1139 id)',0x0088FF)
sampfuncsLog("691.57940673828 -1276.0048828125 13.560739517212")
end
if text:find("1330") and dialogId == 0 then
        sampAddChatMessage(' MAD DOG (1330 id)',0x0088FF)
sampfuncsLog("1298.4849853516 -797.98297119141 84.140625")
end
if text:find("1497") and dialogId == 0 then
        sampAddChatMessage(' Toreno (1497 id)',0x0088FF)
sampfuncsLog("-692.33020019531 939.53747558594 13.6328125")
end
if text:find("1570") and dialogId == 0 then
        sampAddChatMessage(' DOM GOLFA (1570 id)',0x0088FF)
sampfuncsLog("725.35418701172 -1276.3411865234 13.6484375")
end
if text:find("1650") and dialogId == 0 then
        sampAddChatMessage(' DOM BOTOV (1650 id)',0x0088FF)
sampfuncsLog("1951.4378662109 1342.9810791016 15.3671875")
end
if text:find("1740") and dialogId == 0 then
        sampAddChatMessage(' AERO LS (1740 id)',0x0088FF)
sampfuncsLog("1451.6407470703 -2287.2644042969 13.546875")
end
if text:find("1780") and dialogId == 0 then
        sampAddChatMessage(' AERO LV (1780 id)',0x0088FF)
sampfuncsLog("1672.5375976563 1447.8187255859 10.788093566895")
end
if text:find("1788") and dialogId == 0 then
        sampAddChatMessage(' OSOBA SF (1788 id)',0x0088FF)
sampfuncsLog("-2425.8420410156 338.71209716797 36.998447418213")
end
if text:find("1820") and dialogId == 0 then
        sampAddChatMessage(' MAD DOG (1820 id)',0x0088FF)
sampfuncsLog("1259.6380615234 -785.46130371094 92.03125")
end
if text:find("1916") and dialogId == 0 then
        sampAddChatMessage(' MAYAK (1916 id)',0x0088FF)
sampfuncsLog("154.30337524414 -1946.6228027344 5.3903141021729")
end
if text:find("1992") and dialogId == 0 then
        sampAddChatMessage(' DOM ELKINA (1992 id)',0x0088FF)
sampfuncsLog("-2456.1499023438 503.85888671875 30.078125")
end
if text:find("1910") and dialogId == 0 then
        sampAddChatMessage(' piramida (1910 id) ',0x0088FF)
sampfuncsLog("2239.0515136719 1285.6047363281 10.8203125")
end
if text:find("1339") and dialogId == 0 then
        sampAddChatMessage(' pomoika ww (1339 id)',0x0088FF)
sampfuncsLog("1329.5648193359 -984.56945800781 33.896629333496")
end
if text:find("572") and dialogId == 0 then
        sampAddChatMessage(' zalupa ww (572 id) ',0x0088FF)
sampfuncsLog("1382.0305175781 -1088.7690429688 28.089714050293")
end
if text:find("557") and dialogId == 0 then
        sampAddChatMessage(' coleso (557 id) ',0x0088FF)
sampfuncsLog("394.10791015625 -2058.4794921875 10.721467018127")
end
if text:find("470") and dialogId == 0 then
        sampAddChatMessage(' top osoba (470 id) ',0x0088FF)
sampfuncsLog("1470.8352050781 -1177.5124511719 23.923238754272")
end
if text:find("471") and dialogId == 0 then
        sampAddChatMessage(' osoba ww (471 id) ',0x0088FF)
sampfuncsLog("1095.0178222656 -647.91564941406 113.6484375")
end
if text:find("1056") and dialogId == 0 then
        sampAddChatMessage(' osoba ww (1056 id) ',0x0088FF)
sampfuncsLog("251.44448852539 -1220.2025146484 76.10237121582")
end
if text:find("666") and dialogId == 0 then
        sampAddChatMessage(' odinochka (666 id) ',0x0088FF)
sampfuncsLog("423.99871826172 2536.3771972656 16.1484375")
    end
if text:find("1000") and dialogId == 0 then
        sampAddChatMessage(' DOM LOGINOVA (1000 id) ',0x0088FF)
sampfuncsLog("1048.244140625 2910.1696777344 47.82311630249")
end
if text:find("889") and dialogId == 0 then
        sampAddChatMessage(' KATALINA (889 id) ',0x0088FF)
sampfuncsLog("870.41314697266 -24.92719078064 63.984764099121")
end
if text:find("27") and dialogId == 0 then
        sampAddChatMessage(' ww (27 id) ',0x0088FF)
sampfuncsLog("1421.7608642578 -886.23168945313 50.686328887939")
end
if text:find("26") and dialogId == 0 then
        sampAddChatMessage(' ww (26 id) ',0x0088FF)
sampfuncsLog("1468.568359375 -906.18127441406 54.8359375")
end
if text:find("1199") and dialogId == 0 then
        sampAddChatMessage(' ww (1199 id) ',0x0088FF)
sampfuncsLog("1535.7612304688 -885.28515625 57.657482147217")
end
if text:find("466") and dialogId == 0 then
        sampAddChatMessage(' ww (466 id) ',0x0088FF)
sampfuncsLog("1540.4704589844 -851.10961914063 64.336059570313")
end
if text:find("467") and dialogId == 0 then
        sampAddChatMessage(' ww (467 id) ',0x0088FF)
sampfuncsLog("1535.033203125 -800.15222167969 72.849456787109")
end
if text:find("468") and dialogId == 0 then
        sampAddChatMessage(' ww (468 id) ',0x0088FF)
sampfuncsLog("1527.8106689453 -772.57434082031 80.578125")
end
if text:find("469") and dialogId == 0 then
        sampAddChatMessage(' ww (469 id) ',0x0088FF)
sampfuncsLog("1442.6109619141 -628.83361816406 95.718566894531")
end
if text:find("401") and dialogId == 0 then
        sampAddChatMessage(' ww (401 id) ',0x0088FF)
sampfuncsLog("1112.6429443359 -741.9658203125 100.13292694092")
end
if text:find("472") and dialogId == 0 then
        sampAddChatMessage(' ww (472 id) ',0x0088FF)
sampfuncsLog("1094.8969726563 -661.06628417969 113.6484375")
end
if text:find("1790") and dialogId == 0 then
        sampAddChatMessage(' ww (1790 id) ',0x0088FF)
sampfuncsLog("1016.768371582 -763.36193847656 112.56301879883")
end
if text:find("483") and dialogId == 0 then
        sampAddChatMessage(' ww (483 id) ',0x0088FF)
sampfuncsLog("1034.7073974609 -813.22351074219 101.8515625")
end
if text:find("34") and dialogId == 0 then
        sampAddChatMessage(' ww (34 id) ',0x0088FF)
sampfuncsLog("1045.1645507813 -642.93920898438 120.1171875")
end
if text:find("683") and dialogId == 0 then
        sampAddChatMessage(' ww (683 id) ',0x0088FF)
sampfuncsLog("991.53771972656 -695.29986572266 121.93830871582")
end
if text:find("485") and dialogId == 0 then
        sampAddChatMessage(' ww (485 id) ',0x0088FF)
sampfuncsLog("977.37847900391 -771.71746826172 112.20262908936")
end
if text:find("1201") and dialogId == 0 then
        sampAddChatMessage(' ww (1201 id) ',0x0088FF)
sampfuncsLog("946.31555175781 -710.69738769531 122.61987304688")
end
if text:find("482") and dialogId == 0 then
        sampAddChatMessage(' ww (482 id) ',0x0088FF)
sampfuncsLog("990.2138671875 -828.43280029297 95.468574523926")
end
if text:find("1015") and dialogId == 0 then
        sampAddChatMessage(' ww (1015 id) ',0x0088FF)
sampfuncsLog("966.32775878906 -846.67572021484 95.526885986328")
end
if text:find("480") and dialogId == 0 then
        sampAddChatMessage(' ww (480 id) ',0x0088FF)
sampfuncsLog("937.7666015625 -848.76232910156 93.577110290527")
end
if text:find("1014") and dialogId == 0 then
        sampAddChatMessage(' ww (1014 id) ',0x0088FF)
sampfuncsLog("923.87683105469 -853.35009765625 93.456520080566")
end
if text:find("481") and dialogId == 0 then
        sampAddChatMessage(' ww (481 id) ',0x0088FF)
sampfuncsLog("910.43804931641 -817.52166748047 103.12602996826")
end
if text:find("473") and dialogId == 0 then
        sampAddChatMessage(' ww (473 id) ',0x0088FF)
sampfuncsLog("897.56182861328 -677.64782714844 116.89044189453")
end
if text:find("474") and dialogId == 0 then
        sampAddChatMessage(' ww (474 id) ',0x0088FF)
sampfuncsLog("867.52331542969 -717.54986572266 105.6796875")
end
if text:find("475") and dialogId == 0 then
        sampAddChatMessage(' ww (475 id) ',0x0088FF)
sampfuncsLog("847.99090576172 -745.5087890625 94.969268798828")
end
if text:find("476") and dialogId == 0 then
        sampAddChatMessage(' ww (476 id) ',0x0088FF)
sampfuncsLog("891.24157714844 -783.13494873047 101.31394958496")
end
if text:find("477") and dialogId == 0 then
        sampAddChatMessage(' ww (477 id) ',0x0088FF)
sampfuncsLog("808.23706054688 -759.28460693359 76.531364440918")
end
if text:find("1332") and dialogId == 0 then
        sampAddChatMessage(' ww (1332 id) ',0x0088FF)
sampfuncsLog("855.15869140625 -830.29345703125 89.501670837402")
end
if text:find("1055") and dialogId == 0 then
        sampAddChatMessage(' ww (1055 id) ',0x0088FF)
sampfuncsLog("874.66564941406 -877.29046630859 77.811920166016")
end
if text:find("1007") and dialogId == 0 then
        sampAddChatMessage(' ww (1007 id) ',0x0088FF)
sampfuncsLog("835.91229248047 -894.82800292969 68.768898010254")
end
if text:find("22") and dialogId == 0 then
        sampAddChatMessage(' ww (22 id) ',0x0088FF)
sampfuncsLog("827.82843017578 -857.9775390625 70.330810546875")
end
if text:find("478") and dialogId == 0 then
        sampAddChatMessage(' ww (478 id) ',0x0088FF)
sampfuncsLog("786.10736083984 -828.55773925781 70.289581298828")
end
if text:find("1198") and dialogId == 0 then
        sampAddChatMessage(' ww (1198 id) ',0x0088FF)
sampfuncsLog("724.74542236328 -999.40393066406 52.734375")
end
if text:find("488") and dialogId == 0 then
        sampAddChatMessage(' ww (483 id) ',0x0088FF)
sampfuncsLog("673.11242675781 -1020.1766357422 55.759605407715")
end
if text:find("489") and dialogId == 0 then
        sampAddChatMessage(' ww (489 id) ',0x0088FF)
sampfuncsLog("700.22717285156 -1060.3897705078 49.421691894531")
end
if text:find("1200") and dialogId == 0 then
        sampAddChatMessage(' ww (1200 id) ',0x0088FF)
sampfuncsLog("648.45739746094 -1058.5489501953 52.579917907715")
end
if text:find("1009") and dialogId == 0 then
        sampAddChatMessage(' ww (1009 id) ',0x0088FF)
sampfuncsLog("612.14715576172 -1085.9345703125 58.826656341553")
end
if text:find("23") and dialogId == 0 then
        sampAddChatMessage(' ww (23 id) ',0x0088FF)
sampfuncsLog("645.96618652344 -1117.4487304688 44.207038879395")
end
if text:find("490") and dialogId == 0 then
        sampAddChatMessage(' ww (490 id) ',0x0088FF)
sampfuncsLog("559.05487060547 -1076.4460449219 72.921989440918")
end
if text:find("1011") and dialogId == 0 then
        sampAddChatMessage(' ww (1011 id) ',0x0088FF)
sampfuncsLog("562.64465332031 -1115.1458740234 62.806358337402")
end
if text:find("1008") and dialogId == 0 then
        sampAddChatMessage(' ww (1008 id) ',0x0088FF)
sampfuncsLog("580.30639648438 -1149.8883056641 53.180084228516")
end
if text:find("1053") and dialogId == 0 then
        sampAddChatMessage(' ww (1053 id) ',0x0088FF)
sampfuncsLog("558.91156005859 -1161.0042724609 54.4296875")
end
if text:find("30") and dialogId == 0 then
        sampAddChatMessage(' ww (30 id) ',0x0088FF)
sampfuncsLog("553.27258300781 -1200.1466064453 44.831535339355")
end
if text:find("491") and dialogId == 0 then
        sampAddChatMessage(' ww (491 id) ',0x0088FF)
sampfuncsLog("497.40954589844 -1095.0693359375 82.359191894531")
end
if text:find("1012") and dialogId == 0 then
        sampAddChatMessage(' ww (1012 id) ',0x0088FF)
sampfuncsLog("470.82290649414 -1163.5430908203 67.217987060547")
end
if text:find("969") and dialogId == 0 then
        sampAddChatMessage(' ww (969 id) ',0x0088FF)
sampfuncsLog("416.69845581055 -1154.0760498047 76.687614440918")
end
if text:find("493") and dialogId == 0 then
        sampAddChatMessage(' ww (493 id) ',0x0088FF)
sampfuncsLog("352.4573059082 -1197.8941650391 76.515625")
end
if text:find("497") and dialogId == 0 then
        sampAddChatMessage(' ww (497 id) ',0x0088FF)
sampfuncsLog("432.09634399414 -1253.9440917969 51.580940246582")
end
if text:find("496") and dialogId == 0 then
        sampAddChatMessage(' ww (496 id) ',0x0088FF)
sampfuncsLog("398.08282470703 -1271.4063720703 50.019790649414")
end
if text:find("495") and dialogId == 0 then
        sampAddChatMessage(' ww (495 id) ',0x0088FF)
sampfuncsLog("355.09692382813 -1281.1781005859 53.703639984131")
end
if text:find("1054") and dialogId == 0 then
        sampAddChatMessage(' ww (1054 id) ',0x0088FF)
sampfuncsLog("345.00192260742 -1297.935546875 50.759044647217")
end
if text:find("810") and dialogId == 0 then
        sampAddChatMessage(' ww (810 id) ',0x0088FF)
sampfuncsLog("239.33815002441 -1202.8575439453 76.140319824219")
end
if text:find("1496") and dialogId == 0 then
        sampAddChatMessage(' ww (1496 id) ',0x0088FF)
sampfuncsLog("253.14999389648 -1270.0407714844 74.430809020996")
end
if text:find("1498") and dialogId == 0 then
        sampAddChatMessage(' ww (1498 id) ',0x0088FF)
sampfuncsLog("265.63473510742 -1287.8387451172 74.632507324219")
end
if text:find("38") and dialogId == 0 then
        sampAddChatMessage(' osoba ww (38 id) ',0x0088FF)
sampfuncsLog("298.72897338867 -1338.5889892578 53.441482543945")
end
if text:find("50") and dialogId == 0 then
        sampAddChatMessage(' osoba ww (50 id) ',0x0088FF)
sampfuncsLog("254.40522766113 -1367.1625976563 53.109375")
end
if text:find("1491") and dialogId == 0 then
        sampAddChatMessage(' ww (1491 id) ',0x0088FF)
sampfuncsLog("219.50967407227 -1249.9912109375 78.334503173828")
end
if text:find("1499") and dialogId == 0 then
        sampAddChatMessage(' ww (1499 id) ',0x0088FF)
sampfuncsLog("211.32153320313 -1238.7475585938 78.350204467773")
end
if text:find("498") and dialogId == 0 then
        sampAddChatMessage(' osoba ww (498 id) ',0x0088FF)
sampfuncsLog("189.63841247559 -1308.2032470703 70.249351501465")
end
if text:find("651") and dialogId == 0 then
        sampAddChatMessage(' ww (651 id) ',0x0088FF)
sampfuncsLog("227.93872070313 -1405.4261474609 51.609375")
end
if text:find("1052") and dialogId == 0 then
        sampAddChatMessage(' ww (1052 id) ',0x0088FF)
sampfuncsLog("161.50471496582 -1455.8792724609 32.844982147217")
end
if text:find("1051") and dialogId == 0 then
        sampAddChatMessage(' ww (1051 id) ',0x0088FF)
sampfuncsLog("142.62294006348 -1470.3609619141 25.2109375")
end
if text:find("612") and dialogId == 0 then
        sampAddChatMessage(' odinochka (612 id) ',0x0088FF)
sampfuncsLog("1566.8316650391 23.30079460144 24.1640625")
end
if text:find("548") and dialogId == 0 then
        sampAddChatMessage(' odinochka (548 id) ',0x0088FF)
sampfuncsLog("-1051.6661376953 1550.099609375 33.437610626221")
end
if text:find("1911") and dialogId == 0 then
        sampAddChatMessage(' clown hata (1911 id) ',0x0088FF)
sampfuncsLog("2227.2668457031 1837.1071777344 10.8203125")
end
if text:find("1602") and dialogId == 0 then
        sampAddChatMessage(' odinochka (1602 id) ',0x0088FF)
sampfuncsLog("-255.14994812012 2603.2224121094 62.858154296875")
end
if text:find("1724") and dialogId == 0 then
        sampAddChatMessage(' odinochka (1724 id) ',0x0088FF)
sampfuncsLog("-313.96780395508 1774.6237792969 43.640625")
end
if text:find("1622") and dialogId == 0 then
        sampAddChatMessage(' top osoba (1622 id) ',0x0088FF)
sampfuncsLog("-553.85461425781 2593.8452148438 53.93478012085")
end
if text:find("1337") and dialogId == 0 then
        sampAddChatMessage(' odinochka (1337 id) ',0x0088FF)
sampfuncsLog("-2236.9685058594 2354.2321777344 4.9799118041992")
end
if text:find("1571") and dialogId == 0 then
        sampAddChatMessage(' odinochka (1571 id) ',0x0088FF)
sampfuncsLog("-282.77380371094 -2174.3647460938 28.657928466797")
end
if text:find("1930") and dialogId == 0 then
        sampAddChatMessage(' odinochka (1930 id) ',0x0088FF)
sampfuncsLog("-418.91381835938 -1759.2041015625 6.21875")
end
if text:find("989") and dialogId == 0 then
        sampAddChatMessage(' baza opasny (989 id) ',0x0088FF)
sampfuncsLog("-89.171165466309 -1564.4396972656 3.0043075084686")
    end
end
