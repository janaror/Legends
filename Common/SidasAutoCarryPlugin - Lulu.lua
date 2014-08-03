if myHero.charName ~= "Lulu" then return end

--I finished using creeps to extend Q range yay!!
--Will also cast E on nearst enemy to extend range (ex: E the support and Q the adc)
--Mana manager on Q autoharass

--[[       ----------------------------------------------------------------------------------------------       ]]--
--[[							Kalman Filter, all credits too vadash for coding it		    	   	 	        ]]--
--[[       ----------------------------------------------------------------------------------------------       ]]--
class 'Kalman' -- {
function Kalman:__init()
        self.current_state_estimate = 0
        self.current_prob_estimate = 0
        self.Q = 1
        self.R = 15
end
function Kalman:STEP(control_vector, measurement_vector)
        local predicted_state_estimate = self.current_state_estimate + control_vector
        local predicted_prob_estimate = self.current_prob_estimate + self.Q
        local innovation = measurement_vector - predicted_state_estimate
        local innovation_covariance = predicted_prob_estimate + self.R
        local kalman_gain = predicted_prob_estimate / innovation_covariance
        self.current_state_estimate = predicted_state_estimate + kalman_gain * innovation
        self.current_prob_estimate = (1 - kalman_gain) * predicted_prob_estimate
        return self.current_state_estimate
end

local CurVer = 1.11
local NeedUpdate = false
local Do_Once = true
local ScriptName = "Lulu, The Queen of the Yordles"
local NetFile = "http://tekilla.cuccfree.org/SidasAutoCarryPlugin%20-%20Lulu.lua"
local LocalFile = BOL_PATH.."Scripts\\Common\\SidasAutoCarryPlugin - Lulu.lua"


function CheckVersion(data)
	local NetVersion = tonumber(data)
	if type(NetVersion) ~= "number" then
		return
	end
	if NetVersion and NetVersion > CurVer then
		print("<font color='#FF4000'>-- "..ScriptName..": Update found ! Don't F9 till done...</font>")
		NeedUpdate = true
	else
		print("<font color='#00BFFF'>-- "..ScriptName..": You have the lastest version</font>")
	end
end

function UpdateScript()
	if Do_Once then
		Do_Once = false
		if _G.UseUpdater == nil or _G.UseUpdater == true then
			GetAsyncWebResult("tekilla.cuccfree.org", "LuluQueen-Ver.txt", CheckVersion)
		end
	end

	if NeedUpdate then
		NeedUpdate = false
		DownloadFile(NetFile, LocalFile, function()
											if FileExist(LocalFile) then
												print("<font color='#00BFFF'>-- "..ScriptName..": Script updated! Please reload.</font>")
											end
										end
					)
	end
end

AddTickCallback(UpdateScript)


--[[ Velocities ]]
local kalmanFilters = {}
local velocityTimers = {}
local oldPosx = {}
local oldPosz = {}
local oldTick = {}
local velocity = {}
local lastboost = {}
local velocity_TO = 10
local CONVERSATION_FACTOR = 975
local MS_MIN = 500
----------------------
local Minions = AutoCarry.EnemyMinions()
local castRTick = nil
local enemyList = {}
local ToInterrupt = {}
local InteruptionSpells = {
    { charName = "FiddleSticks", 	spellName = "Crowstorm", 					Skill = "W"},
	{ charName = "FiddleSticks", 	spellName = "Drain", 						Skill = "W"},
	{ charName = "Galio", 			spellName = "GalioIdolOfDurand", 			Skill = "W"},
	{ charName = "Pantheon", 		spellName = "Pantheon_Heartseeker", 		Skill = "W"},
	{ charName = "Pantheon", 		spellName = "Pantheon_GrandSkyfall_Jump", 	Skill = "W"},
	{ charName = "Warwick", 		spellName = "InfiniteDuress", 				Skill = "W"},
    { charName = "MissFortune", 	spellName = "MissFortuneBulletTime", 		Skill = "W"},
    { charName = "Nunu", 			spellName = "AbsoluteZero", 				Skill = "W"},
	{ charName = "Caitlyn", 		spellName = "CaitlynAceintheHole", 			Skill = "W"},
	{ charName = "Caitlyn", 		spellName = "CaitlynEntrapment", 			Skill = "W"},
	{ charName = "Shen", 			spellName = "ShenStandUnited", 				Skill = "W"},
	{ charName = "Urgot", 			spellName = "UrgotSwap2", 					Skill = "W"},
	{ charName = "Janna", 			spellName = "ReapTheWhirlwind", 			Skill = "W"},
	{ charName = "TwistedFate", 	spellName = "gate", 						Skill = "W"},
	{ charName = "Lucian", 			spellName = "LucianR", 						Skill = "W"},
	{ charName = "MasterYi", 		spellName = "Meditate", 					Skill = "W"},
	{ charName = "Varus", 			spellName = "VarusQ", 						Skill = "W"},
	{ charName = "Katarina", 		spellName = "KatarinaR", 					Skill = "W"},
	{ charName = "Karthus", 		spellName = "FallenOne", 					Skill = "W"},
	{ charName = "Malzahar",        spellName = "AlZaharNetherGrasp", 			Skill = "W"},
	{ charName = "Darius",          spellName = "DariusExecute", 				Skill = "W"},
	{ charName = "MonkeyKing",      spellName = "MonkeyKingSpinToWin", 			Skill = "W"},

	{ charName = "Akali",      		spellName = "AkaliSmokeBomb", 				Skill = "E"},
	{ charName = "Twitch",      	spellName = "HideInShadows", 				Skill = "E"},
	--{ charName = "Khazix",      	spellName = "KhazixR", 						Skill = "E"},
	{ charName = "Vayne",     	 	spellName = "vayneinquisition", 			Skill = "E"},
}
--[[       ----------------------------------------------------------------------------------------------       ]]--
--[[												AutoCarry			 	    	       	 			        ]]--
--[[       ----------------------------------------------------------------------------------------------       ]]--

function InitMenu()
	Menu:addSubMenu("-----> Ultimate options", "ultsub")
	Menu.ultsub:addParam("ultLowHP", "Use Auto-Ultimate on LowHP allies", SCRIPT_PARAM_ONOFF, true)
	Menu.ultsub:addParam("useRperc", "HP % to ult an ally", SCRIPT_PARAM_SLICE, 14, 0, 100, 0)
	Menu.ultsub:addParam("UltimateInfo1", "---------------------------", SCRIPT_PARAM_INFO, "")
	Menu.ultsub:addParam("useRMEC", "Use Auto-Ultimate MEC", SCRIPT_PARAM_ONOFF, true)
	Menu.ultsub:addParam("rMECminEnemies", "Number of enemies to cast R", SCRIPT_PARAM_SLICE, 2, 1, 5, 0)

	Menu:addSubMenu("-----> Mixed mode options", "mmsub")
	Menu.mmsub:addParam("qMix", "Harass with Q", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("T"))
	Menu.mmsub:addParam("wMix", "Harass with W", SCRIPT_PARAM_ONOFF, true)
	Menu.mmsub:addParam("eMix", "Harass with E", SCRIPT_PARAM_ONOFF, true)

	Menu:addSubMenu("-----> AutoHarass options", "ahsub")
	Menu.ahsub:addParam("qAuto", "Auto Harass with Q", SCRIPT_PARAM_ONOFF, false)
	Menu.ahsub:addParam("wAuto", "Auto Harass with W", SCRIPT_PARAM_ONOFF, false)
	Menu.ahsub:addParam("eAuto", "Auto Harass with E", SCRIPT_PARAM_ONOFF, false)


	Menu:addSubMenu("-----> Interuptions", "intsub")
	Menu.intsub:addParam("NinjaInteruption", "Interupt skills with W", SCRIPT_PARAM_ONOFF, false)
	Menu.intsub:addParam("InterupInfo0", "----------------------------", SCRIPT_PARAM_INFO, "")
	if #ToInterrupt > 0 then
		for _, Inter in pairs(ToInterrupt) do
			if Inter.Skill == "W" then
				Menu.intsub:addParam(Inter.spellName, "Stop "..Inter.charName.." "..Inter.spellName, SCRIPT_PARAM_ONOFF, true)
			end
		end
	else
		Menu.intsub:addParam("InterupInfo1", "No supported skills to interupt", SCRIPT_PARAM_INFO, "")
	end

	Menu:addSubMenu("-----> Reveal", "revsub")
	Menu.revsub:addParam("NinjaReveal", "Reveal champions with E", SCRIPT_PARAM_ONOFF, false)
	Menu.revsub:addParam("RevealInfo0", "----------------------------", SCRIPT_PARAM_INFO, "")
	if #ToInterrupt > 0 then
		for _, Inter in pairs(ToInterrupt) do
			if Inter.Skill == "E" then
				Menu.revsub:addParam(Inter.spellName, "Reveal "..Inter.charName.." when "..Inter.spellName, SCRIPT_PARAM_ONOFF, true)
			end
		end
	else
		Menu.revsub:addParam("RevealInfo1", "No supported skills to interupt", SCRIPT_PARAM_INFO, "")
	end


	Menu:addSubMenu("-----> W Skill Usage", "wusesub")
	if #enemyList > 0 then
		for _, enem in pairs(enemyList) do
			Menu.wusesub:addParam(enem.charName, "Use W on "..enem.charName, SCRIPT_PARAM_ONOFF, true)
		end
	else
		Menu.wusesub:addParam("UseWInfo1", "Not enough enemies", SCRIPT_PARAM_INFO, "")
	end

	Menu:addSubMenu("-----> Visual options", "vissub")
	Menu.vissub:addParam("dQRange", "Draw Q Range", SCRIPT_PARAM_ONOFF, false)
	Menu.vissub:addParam("dQRangeColor","--Q Range Color", SCRIPT_PARAM_COLOR, { 255, 255, 50, 50 })

	Menu.vissub:addParam("dWRange", "Draw W Range", SCRIPT_PARAM_ONOFF, false)
	Menu.vissub:addParam("dWRangeColor","--W Range Color", SCRIPT_PARAM_COLOR, { 255, 255, 50, 50 })

	Menu.vissub:addParam("dERange", "Draw E Range", SCRIPT_PARAM_ONOFF, false)
	Menu.vissub:addParam("dERangeColor","--E Range Color", SCRIPT_PARAM_COLOR, { 255, 255, 50, 50 })

	Menu.vissub:addParam("dRRange", "Draw R Range", SCRIPT_PARAM_ONOFF, false)
	Menu.vissub:addParam("dRRangeColor","--R Range Color", SCRIPT_PARAM_COLOR, { 255, 255, 50, 50 })

	Menu:addParam("GeneralInfo0", "----------------------------", SCRIPT_PARAM_INFO, "")
	Menu:addParam("extendQwithE", "Extend Q range with E on ally/creep", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("MinMana", "Mana Manager min %", SCRIPT_PARAM_SLICE, 35, 0, 100, 0)

	if VIP_USER then
		if Prodiction then
			Menu:addParam("Status", "---- PROdiction loaded ----", SCRIPT_PARAM_INFO, "")
		else
			Menu:addParam("minHitChance", "Min Hit Chance %", SCRIPT_PARAM_SLICE, 70, 1, 100, 0)
			Menu:addParam("Status", "---- VIP loaded ----", SCRIPT_PARAM_INFO, "")
		end
	else
		Menu:addParam("Status", "---- FREE User loaded ----", SCRIPT_PARAM_INFO, "")
	end

end


function PluginOnLoad()
	if AutoCarry.Skills then IsSACReborn = true else IsSACReborn = false end

	if IsSACReborn then
		AutoCarry.Crosshair:SetSkillCrosshairRange(1000)
		AutoCarry.Crosshair.isCaster = true
		AutoCarry.MyHero:AttacksEnabled(true)
		AutoCarry.Skills:DisableAll()
	else
		AutoCarry.SkillsCrosshair.range = 1000
		AutoCarry.CanAttack = true
    end
	Recalling = false
	Menu = AutoCarry.PluginMenu

	-------Skills info-------
	qRange, QSpeed, QDelay, QWidth = 925, 1.40, 250, 50
	wRange = 650
	eRange = 650
	rRange, RWidth = 900, 150
	-------/Skills info-------

	tpQ = VIP_USER and TargetPredictionVIP(qRange, QSpeed*1000, QDelay/1000, QWidth) or TargetPrediction(qRange, QSpeed, QDelay, QWidth)

	if VIP_USER then
		if FileExist(SCRIPT_PATH..'Common/Prodiction.lua') then
			require "Prodiction"

			Prodiction = ProdictManager.GetInstance()
			ProdictionQ = Prodiction:AddProdictionObject(_Q, qRange, QSpeed*1000, QDelay/1000, 80)

			PrintChat("<font color='#ab15d9'> > Lulu, The Queen of the Yordles v"..CurVer.." by TeKilla - PROdiction</font>")
		else
			PrintChat("<font color='#ab15d9'> > Lulu, The Queen of the Yordles v"..CurVer.." by TeKilla - VIP</font>")
		end
	else
		PrintChat("<font color='#ab15d9'> > Lulu, The Queen of the Yordles v"..CurVer.." by TeKilla - FREE</font>")
	end


	LoadInterupt()
	InitMenu()
end

function PluginOnTick()
	SpellsState()
	UpdateSpeed()

	if IsSACReborn then Target = AutoCarry.Crosshair:GetTarget() else Target = AutoCarry.GetAttackTarget(true) end

	if castRTick == nil or GetTickCount()-castRTick >= 90 then
		castRTick = GetTickCount()
		if Menu.ultsub.ultLowHP then UltimateLowHp() end
		if Menu.ultsub.useRMEC then UltimateMEC() end
	end

	if AutoCarry.MainMenu.AutoCarry then
		Combo()
	else
		if (AutoCarry.MainMenu.MixedMode and Menu.mmsub.qMix) or (Menu.ahsub.qAuto and not Recalling and not IsMyManaLow()) then
			HarassQ()
		end
		if ((AutoCarry.MainMenu.MixedMode and Menu.mmsub.eMix) or (Menu.ahsub.eAuto and not Recalling and not IsMyManaLow())) then
			HarassE()
		end
		if ((AutoCarry.MainMenu.MixedMode and Menu.mmsub.wMix) or (Menu.ahsub.wAuto and not Recalling)) then
			HarassW()
		end
	end

end

function PluginOnDraw()
	if not myHero.dead then
		if Menu.vissub.dQRange and QReady then
			DrawCircle(myHero.x, myHero.y, myHero.z, qRange, RGB(Menu.vissub.dQRangeColor[2], Menu.vissub.dQRangeColor[3], Menu.vissub.dQRangeColor[4]))
		end
		if Menu.vissub.dWRange and WReady then
			DrawCircle(myHero.x, myHero.y, myHero.z, wRange, RGB(Menu.vissub.dWRangeColor[2], Menu.vissub.dWRangeColor[3], Menu.vissub.dWRangeColor[4]))
		end
		if Menu.vissub.dERange and EReady then
			DrawCircle(myHero.x, myHero.y, myHero.z, eRange, RGB(Menu.vissub.dERangeColor[2], Menu.vissub.dERangeColor[3], Menu.vissub.dERangeColor[4]))
		end
		if Menu.vissub.dRRange and RReady then
			DrawCircle(myHero.x, myHero.y, myHero.z, rRange, RGB(Menu.vissub.dRRangeColor[2], Menu.vissub.dRRangeColor[3], Menu.vissub.dRRangeColor[4]))
		end
	end
end

function PluginOnProcessSpell(unit, spell)
	if Menu.intsub.NinjaInteruption or Menu.revsub.NinjaReveal then
		if #ToInterrupt > 0 then
			for _, Inter in pairs(ToInterrupt) do
				if spell.name == Inter.spellName and unit.team ~= myHero.team then
					if Inter.Skill == "W" and Menu.intsub.NinjaInteruption then
						if Menu.intsub[Inter.spellName] then
							if GetDistance(unit) <= wRange then
								CastSpellW(unit)
							end
						end
					elseif Inter.Skill == "E" and Menu.revsub.NinjaReveal then
						if Menu.revsub[Inter.spellName] then
							print(Inter.spellName)
							if GetDistance(unit) <= eRange then
								CastSpellE(unit)
							end
						end
					end
				end
			end
		end
	end
end

function PluginOnAnimation(unit, animation)
	if unit.isMe then
		if animation:lower():find("recall") then
			Recalling = true
		else
			Recalling = false
		end
	end
end

--[[       ----------------------------------------------------------------------------------------------       ]]--
--[[												OptionFunction			   				 	                ]]--
--[[       ----------------------------------------------------------------------------------------------       ]]--
function CastSpellQ(target)
	if not Prodiction then
		if VIP_USER then
			if AutoCarry.PluginMenu.minHitChance ~= 0 and tpQ:GetHitChance(target) >= AutoCarry.PluginMenu.minHitChance then
				QPos,_,_ = tpQ:GetPrediction(target)
				if QPos ~= nil then
					Packet('S_CAST', { spellId = _Q, fromX = QPos.x, fromY = QPos.z}):send()
				end
			end
		else
			QPos,_,_ = tpQ:GetPrediction(target)
			if QPos ~= nil then
				CastSpell(_Q, QPos.x, QPos.z)
			end
		end
	else
		local QPos = ProdictionQ:GetPrediction(target)
		if QPos ~= nil then
			Packet('S_CAST', { spellId = _Q, fromX = QPos.x, fromY = QPos.z}):send()
		end
	end
end


function CastSpellW(target)
	if target.team ~= myHero.team then
		if Menu.wusesub[target.charName] then
			if VIP_USER then
				Packet('S_CAST', { spellId = _W, targetNetworkId = target.networkID}):send()
			else
				CastSpell(_W, target)
			end
		end
	else
		if VIP_USER then
			Packet('S_CAST', { spellId = _W, targetNetworkId = target.networkID}):send()
		else
			CastSpell(_W, target)
		end
	end
end


function CastSpellE(target)
	if VIP_USER then
		Packet('S_CAST', { spellId = _E, targetNetworkId = target.networkID}):send()
	else
		CastSpell(_E, target)
	end
end


function CastSpellR(target)
	if VIP_USER then
		Packet('S_CAST', { spellId = _R, targetNetworkId = target.networkID}):send()
	else
		CastSpell(_R, target)
	end
end


function UltimateLowHp()
	if RReady then
		for i=1, heroManager.iCount do
			local Ally = heroManager:GetHero(i)
			if Ally.team == myHero.team and not Ally.dead then
				if GetDistance(Ally) <= rRange then
					if (Ally.health / Ally.maxHealth) < (Menu.ultsub.useRperc / 100) then
						if CountEnemies(Ally, 1000) >= 1 then
							CastSpellR(Ally)
						end
					end
				end
			end
		end
	end
end

function UltimateMEC()
	if RReady then
		for i=1, heroManager.iCount do
			local Ally = heroManager:GetHero(i)
			if Ally.team == myHero.team and not Ally.dead then
				if GetDistance(Ally) <= rRange then
					if CountEnemies(Ally, 170) >= Menu.ultsub.rMECminEnemies then
						CastSpellR(Ally)
					end
				end
			end
		end
	end
end

function Combo()

	if Target and not Target.dead then
		if QReady then
			if GetDistance(Target) <= qRange then
				CastSpellQ(Target)
			elseif GetDistance(Target) <= (2*qRange+eRange) then
				if Menu.extendQwithE then
					local ally, enemy1 = GetNearestAllyToHitEnemy()
					if ally ~= nil and enemy1 ~= nil then
						CastSpellE(ally)
						CastSpellQ(enemy1)
					else
						local Creep, enemy2 = GetNearestCreepToHitEnemy()
						if Creep ~= nil and enemy2 ~= nil then
							CastSpellE(Creep)
							CastSpellQ(enemy2)
						end
					end
				end
			end
		end

		if WReady and GetDistance(Target) <= wRange then
			CastSpellW(Target)
		end

		if EReady and GetDistance(Target) <= eRange then
			CastSpellE(Target)
		end
	end

end


function HarassQ()
	if Target then
		if GetDistance(Target) <= qRange and HaveLowVelocity(Target, 750) then
				CastSpellQ(Target)
			end
		end
end

function HarassE()
	if Target then
		if GetDistance(Target) <= eRange then
			CastSpellE(Target)
		end
	end
end

function HarassW()
	if Target then
		if GetDistance(Target) <= wRange then
			CastSpellW(Target)
		end
	end
end

--[[       ----------------------------------------------------------------------------------------------       ]]--
--[[					     	 		     	     Utility			   	      								]]--
--[[       ----------------------------------------------------------------------------------------------       ]]--
function CountEnemies(point, range)
	local count = 0
	for _, enemy in pairs(enemyHeroes) do
		if not enemy.dead and GetDistance(point, enemy) <= range then
			count = count+1
		end
	end
	return count
end

function GetNearbyUnit()
	local Units = {}
	for i = 1, heroManager.iCount, 1 do
		local unit = heroManager:getHero(i)
		if not unit.dead and GetDistance(unit) <= eRange and unit ~= myHero then
			table.insert(Units, unit)
		end
	end
	return Units
end

function GetNearbyCreep()
	local Units = {}

	for _, minion in pairs(Minions.objects) do
		if ValidTarget(minion) and GetDistance(minion) <= eRange then
			table.insert(Units, minion)
		end
	end

	return Units
end

function GetNearestCreepToHitEnemy()
	nearestAlly = nil
	enemyTarget = nil
	nearestDist = math.huge
	for _, Ally in pairs( GetNearbyCreep() ) do	--For each nearby ally
		if not Ally.dead then
			for i=1, #enemyList do
				local Enemy = enemyList[i]
				if not Enemy.dead then				--And for each enemy alive
					if GetDistance(Ally, Enemy) <= qRange and GetDistance(Ally, Enemy) <= nearestDist then
						nearestDist = GetDistance(Ally, Enemy)
						nearestAlly = Ally
						enemyTarget = Enemy
					end
				end
			end
		end
	end
	return nearestAlly, enemyTarget
end

function GetNearestAllyToHitEnemy()
	nearestAlly = nil
	enemyTarget = nil
	nearestDist = math.huge
	for _, Ally in pairs( GetNearbyUnit() ) do	--For each nearby ally
		if not Ally.dead then
			for i=1, #enemyList do
				local Enemy = enemyList[i]
				if not Enemy.dead then				--And for each enemy alive
					if GetDistance(Ally, Enemy) <= qRange and GetDistance(Ally, Enemy) <= nearestDist then
						nearestDist = GetDistance(Ally, Enemy)
						nearestAlly = Ally
						enemyTarget = Enemy
					end
				end
			end
		end
	end
	return nearestAlly, enemyTarget
end


function LoadInterupt()
	enemyHeroes = GetEnemyHeroes()
	for _, enemy in pairs(enemyHeroes) do	--thank's to pqmailer
		table.insert(enemyList, enemy)
		kalmanFilters[enemy.networkID] = Kalman()
		velocityTimers[enemy.networkID] = 0
		oldPosx[enemy.networkID] = 0
		oldPosz[enemy.networkID] = 0
		oldTick[enemy.networkID] = 0
		velocity[enemy.networkID] = 0
		lastboost[enemy.networkID] = 0
		for _, champ in pairs(InteruptionSpells) do
			if enemy.charName == champ.charName then
				table.insert(ToInterrupt, {charName = champ.charName, spellName = champ.spellName, Skill = champ.Skill})
			end
		end
	end
end

function HaveLowVelocity(target, time)
        if ValidTarget(target, 1200) then
                return (velocity[target.networkID] < MS_MIN and target.ms < MS_MIN and GetTickCount() - lastboost[target.networkID] > time)
        else
                return nil
        end
end

function _calcHeroVelocity(target, oldPosx, oldPosz, oldTick)
        if oldPosx and oldPosz and target.x and target.z then
                local dis = math.sqrt((oldPosx - target.x) ^ 2 + (oldPosz - target.z) ^ 2)
                velocity[target.networkID] = kalmanFilters[target.networkID]:STEP(0, (dis / (GetTickCount() - oldTick)) * CONVERSATION_FACTOR)
        end
end

function UpdateSpeed()
        local tick = GetTickCount()
        for i=1, #enemyList do
                local hero = enemyList[i]
                if ValidTarget(hero) then
                        if velocityTimers[hero.networkID] <= tick and hero and hero.x and hero.z and (tick - oldTick[hero.networkID]) > (velocity_TO-1) then
                                velocityTimers[hero.networkID] = tick + velocity_TO
                                _calcHeroVelocity(hero, oldPosx[hero.networkID], oldPosz[hero.networkID], oldTick[hero.networkID])
                                oldPosx[hero.networkID] = hero.x
                                oldPosz[hero.networkID] = hero.z
                                oldTick[hero.networkID] = tick
                                if velocity[hero.networkID] > MS_MIN then
                                        lastboost[hero.networkID] = tick
                                end
                        end
                end
        end
end


function SpellsState()
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)
	Minions:update()
end

--[Credits to Kain]--
function IsMyManaLow()
    if myHero.mana < (myHero.maxMana * ( AutoCarry.PluginMenu.MinMana / 100)) then
        return true
    else
        return false
    end
end
