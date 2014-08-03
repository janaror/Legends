--[[(Jax The Real Weapon v.1.2) By stinkpie]]--
 
-- Credits!
--mr1r15h - Pretty much his script, with couple of edits and clean up!
--Bilbao  - For teaching me alot of stuff in LUA!
--Pyryoer - For teaching me also very much stuff in lua! 
--Galaxix - for fixing issues!
--If I have miss anyone I'm very sorry!! --				

 
if myHero.charName ~= "Jax" then return end
--Killable--
local waittxt = {}
local calculationenemy = 1
local floattext = {"Full Combo","Combo","Quick Combo","KillTime!","Harass",""}
local killable = {}
--Spells--
local QReady, WReady, EReady, RReady = false, false, false, false
--local swingDelay = 0.15
local swing = 0
local swingDelay = 0.15
local lastBasicAttack = 0

function OnLoad()
	--Range Values--
	QRange = 700
	ERange = 185
	ARange = 125
	--Tick Wait--
	tickWait = 0
	--Spell Values--
	WProc, EProc, QLanded, item = false, false, false, false
	AACount, lastAA, qTimer, timer, eStart, eTimer, eWait, timeout, stop, move, close, ksDelay, countDelay, calcDelay = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	--Item Wait--
	itemStart, itemEnd = 0, 0
	itemWait = false
	--Health Check--
	hStart, hEnd, hCheck1, hCheck2 = 0, 0, 0, 0
	hWait = false
	rActivate = false
	--JaxConfig--
	JaxConfig = scriptConfig("Jax Stinkpie", "Jax Stinkpie")
	JaxConfig:addParam("drawcircles", "Draw Circles", SCRIPT_PARAM_ONOFF, true)
	JaxConfig:addParam("AutoKS", "Auto KS", SCRIPT_PARAM_ONKEYTOGGLE, true, string.byte("K"))
	JaxConfig:addParam("AutoW", "Auto W", SCRIPT_PARAM_ONKEYTOGGLE, true, string.byte("Z"))
	JaxConfig:addParam("IntelCombo", "Intelligent Combo Mode", SCRIPT_PARAM_ONKEYTOGGLE, true, string.byte("X"))
	JaxConfig:addParam("BurstCombo", "Burst Combo Mode", SCRIPT_PARAM_ONOFF, false)
	JaxConfig:addParam("EQCombo", "E >> Q", SCRIPT_PARAM_ONKEYTOGGLE, true, string.byte("T"))
	JaxConfig:addParam("QECombo", "Q >> E", SCRIPT_PARAM_ONOFF, false)
	JaxConfig:addParam("JaxCombo", "Jax Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	JaxConfig:addParam("AutoIgnite", "Auto Ignite", SCRIPT_PARAM_ONOFF, true)
	JaxConfig:addParam("AutoUlt", "Use Ult in Combo", SCRIPT_PARAM_ONOFF, true)
	JaxConfig:addParam("minChamps", "Min. Champ for Auto Ulti", SCRIPT_PARAM_SLICE, 1, 0, 4, 0)
	JaxConfig:addParam("ultSen", "Auto Ulti Sensitivity", SCRIPT_PARAM_SLICE, 2, 0, 4, 0)
	JaxConfig:addParam("moveMouse", "Move To Mouse", SCRIPT_PARAM_ONKEYTOGGLE, true, string.byte("C"))
	JaxConfig:addParam("qeJump", "Q+E Jump", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("A"))
	JaxConfig:addParam("drawtext", "Draw Text", SCRIPT_PARAM_ONOFF, true)
	JaxConfig:permaShow("AutoKS")
	JaxConfig:permaShow("AutoW")
	JaxConfig:permaShow("JaxCombo")
	JaxConfig:permaShow("qeJump")
	JaxConfig:permaShow("IntelCombo")
	JaxConfig:permaShow("BurstCombo")
	JaxConfig:permaShow("EQCombo")
	JaxConfig:permaShow("QECombo")
	--Target Selector--
	ts = TargetSelector(TARGET_LOW_HP, QRange, DAMAGE_PHYSICAL, true)
	ts.name = "Jax"
	JaxConfig:addTS(ts)
	--Ignite--
	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then 
		ignite = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then 
		ignite = SUMMONER_2 
	end
	for i=1, heroManager.iCount do
		waittxt[i] = i*3
	end
	PrintChat(" >> Jax Stinkpie v1.2 Loaded!")
end
 
function OnProcessSpell(unit, spell)
	if unit.isMe and spell.name ~= nil and not string.find(spell.name, "JaxBasicAttack" or "JaxBasicAttack2" or "jaxrelentlessattack"  or "CritAttack") then --check if not AA
		WProc = false
		item = false
	elseif WProc == false and unit.isMe and spell.name ~= nil and string.find(spell.name, "JaxBasicAttack" or "JaxBasicAttack2" or "jaxrelentlessattack"  or "CritAttack") then --check if AA
		for i=1, heroManager.iCount do
			local enemy = heroManager:GetHero(i)
			if enemy ~= nil and enemy.visible and enemy.team ~= player.team and not enemy.dead and math.sqrt((enemy.x - spell.endPos.x)^2 + (enemy.z - spell.endPos.z)^2) < 1 then --checks if hit enemy champion
					setAW()
					item = true
					swing = 1              
					lastBasicAttack = os.clock()  
			end
			
		end
	end
	if unit.isMe and spell.name ~= nil and string.find(spell.name, "JaxCounterStrike") and not JaxConfig.JaxCombo then
		setE()
	end
end
 
function OnTick()
	if JaxConfig.IntelCombo then
		JaxConfig.BurstCombo = false
	elseif JaxConfig.IntelCombo == false then
		JaxConfig.BurstCombo = true
	end
	if JaxConfig.EQCombo then
		JaxConfig.QECombo = false
	elseif JaxConfig.EQCombo == false then
		JaxConfig.QECombo = true
	end
	if myHero.dead then return end
	--Target Selector Update--
	if tickWait == 0 then
		ts:update()
	end
	--Auto Attacks--
	AACount = 1/(((0.625/(1-0.02)))*(1*myHero.attackSpeed))
	if os.clock() > lastBasicAttack + ((AACount/6) + swingDelay) then
		swing = 0
	end  
	--Spells Ready--
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)
	--Items--
	BRKSlot, HXGSlot, BWCSlot = GetInventorySlotItem(3153), GetInventorySlotItem(3146), GetInventorySlotItem(3144)
	SheenSlot, TrinitySlot, LichBaneSlot = GetInventoryHaveItem(3057), GetInventoryHaveItem(3078), GetInventoryHaveItem(3100)
	TMatSlot, RHydraSlot, RANDSlot = GetInventorySlotItem(3077), GetInventorySlotItem(3074), GetInventorySlotItem(3143)
	HXGReady = (HXGSlot ~= nil and myHero:CanUseSpell(HXGSlot) == READY)
	BWCReady = (BWCSlot ~= nil and myHero:CanUseSpell(BWCSlot) == READY)
	BRKReady = (BRKSlot ~= nil and myHero:CanUseSpell(BRKSlot) == READY)
	RANDReady =(RANDSlot ~= nil and myHero:CanUseSpell(RANDSlot) == READY)
	TMatReady = (TMatSlot ~= nil and myHero:CanUseSpell(TMatSlot) == READY)
	RHydraReady = (RHydraSlot ~= nil and myHero:CanUseSpell(RHydraSlot) == READY)
	--Ignite--
	IReady = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
	--Functions--
	if tickWait == 1 then
		setHealth()
	elseif tickWait == 2 then
		calcDamage()
	elseif tickWait == 3 then
		killSteal()
	elseif tickWait == 4 then
	checkHealth()
	elseif tickWait == 5 then
	jaxCombo()
	elseif tickWait == 6 then
	autoEmpower()
	elseif tickWait == 7 then
	resetHealth()
	elseif tickWait == 8 then
	jump()
	end
	
	if tickWait < 8 then
		tickWait = tickWait + 1
	else
		tickWait = 0
	end
end

function jump()
	if JaxConfig.qeJump then
		if JaxConfig.moveMouse and ts.target == nil then
			myHero:MoveTo(mousePos.x, mousePos.z)
		end
		if ts.target ~= nil then
			if QReady and GetDistance(ts.target) < QRange and GetDistance(ts.target) > ERange + 50 then
				CastSpell(_Q, ts.target)
				CastSpell(_E)
			end
			if swing == 0 then
				myHero:Attack(ts.target)
			end
		end
	end
end
 
function setAW()
	lastAA = os.clock()
	timer = lastAA + ((AACount/6) + swingDelay)
	timeout = lastAA + AACount
	WProc, ItemProc = true, true
end

function resetAW()
	lastAA, timer, timout = 0, 0, 0
	WProc, ItemProc = false, false
end
 
function setE()
	eStart = os.clock()
	eTimer = eStart + 2
	eWait = eStart + 1
	CastSpell(_E)
	EProc = true
end
 
function resetQE()
	qTimer, eStart, eTimer, EProc = 0, 0, 0, 0
	QLanded, EProc = false, false
end

function setItem()
	itemStart = os.clock()
	itemEnd = itemStart + 1
	itemWait = true
end

function resetItem()
	itemStart, itemEnd = 0, 0
	itemWait = false
end

function setHealth()
	if hWait == false and RReady then
		hStart = os.clock()
		hEnd = hStart + 1
		hWait = true
		hCheck1 = myHero.health
	end
end

function checkHealth()
	if hWait == true and os.clock() > hEnd then
		hCheck2 = myHero.health
		local sen = (JaxConfig.ultSen + 1)*0.05
		if (hCheck1 - (hCheck1*sen)) >= hCheck2 then
			rActivate = true
		end
	end
end

function resetHealth()
	if hWait == true and os.clock() > hEnd then
		hStart, hEnd, hCheck1, hCheck2 = 0, 0, 0, 0
		hWait, rActivate = false, false
	elseif RReady == false then
		hStart, hEnd, hCheck1, hCheck2 = 0, 0, 0, 0
		hWait, rActivate = false, false
	end
end

function autoEmpower()
	if JaxConfig.AutoW and WProc == true then
		if os.clock() < timeout then
			if os.clock() > timer then --checks to ensure efficiency of AA reset
				if WReady then
					CastSpell(_W)
					resetAW()
				elseif RHydraReady and item == true and WReady == false then
					CastSpell(RHydraSlot, ts.target)
					--setItem()
					resetAW()
				elseif TMatReady and item == true and WReady == false then
					CastSpell(TMatSlot, ts.target)
					--setItem()
					resetAW()
				end
			end
		elseif WProc == true and timeout <= os.clock() then
			resetAW()
		end
	end
end
 
function killSteal()
	if JaxConfig.AutoKS and os.clock() > ksDelay then
		for i = 1, heroManager.iCount do
			local enemy = heroManager:getHero(i)
			local qKS = getDmg("Q", enemy, myHero)
			local wKS = getDmg("W", enemy, myHero)
			local aKS = getDmg("AD", enemy, myHero)
			local iKS = 50 + (20*myHero.level)
			local hxgKS = (HXGSlot and getDmg("HXG", enemy, myHero) or 0)
			local bwcKS = (BWCSlot and getDmg("BWC", enemy, myHero) or 0)
			local brkKS = (BRKSlot and getDmg("RUINEDKING", enemy, myHero) or 0)
			local tmatKS = aKS*0.6
			local rhydraKS = aKS*0.6
			if ValidTarget(enemy, ARange) and aKS > enemy.health and swing == 0 then
				myHero:Attack(enemy)
			end
			if WReady then
				if ValidTarget(enemy, ARange) and (wKS + aKS) > enemy.health and swing == 0 then
					CastSpell(_W)
					myHero:Attack(enemy)
				end
			end
			if QReady then
				if ValidTarget(enemy, QRange) and qKS > enemy.health then
					CastSpell(_Q, enemy)
				end
			end
			if QReady and WReady then
				if ValidTarget(enemy, QRange) and (qKS + wKS) > enemy.health then
					CastSpell(_W)
					CastSpell(_Q, enemy)
				end
			end
			if WReady and IReady and JaxConfig.AutoIgnite then
				if ValidTarget(enemy, ARange) and (wKS + aKS + iKS) > enemy.health and swing == 0 then
					CastSpell(_W)
					myHero:Attack(enemy)
				end
			end
			if QReady and IReady and JaxConfig.AutoIgnite then
				if ValidTarget(enemy, QRange) and (qKS + iKS) > enemy.health then
					CastSpell(_Q, enemy)
				end
			end
			if QReady and WReady and IReady and JaxConfig.AutoIgnite then
				if ValidTarget(enemy, QRange) and (qKS + wKS + iKS) > enemy.health then
					CastSpell(_W)
					CastSpell(_Q, enemy)
				end
			end
			if QReady == false then
				if IReady then
					local total = iKS
					if GetDistance(enemy) > (ERange*1.6) then
						if HXGReady and GetDistance(enemy) < 700 then
							total = total + hxgKS
							if total > enemy.health then
								CastSpell(HXGSlot, enemy)
								setItem()
							end
						elseif BWCReady and GetDistance(enemy) < 500 then
							total = total + bwcKS
							if total > enemy.health then
								CastSpell(BWCSlot, enemy)
								setItem()
							end
						elseif BRKReady and GetDistance(enemy) < 500 then
							total = total + brkKS
							if total > enemy.health then
								CastSpell(BRKSlot, enemy)
								setItem()
							end
						end
					elseif GetDistance(enemy) < (ERange*1.6) then
						if TMatReady then
							total = total + tmatKS
							if total > enemy.health then
								CastSpell(TMatSlot, enemy)
								setItem()
							end
						end
						if RHydraReady then
							total = total + rhydraKS
							if total > enemy.health then
								CastSpell(RHydraSlot, enemy)
							end
						end
					end
				elseif IReady == false then
					local total = 0
					if GetDistance(enemy) > (ERange*1.6) then
						if HXGReady and GetDistance(enemy) < 700 then
							total = total + hxgKS
							if total > enemy.health then
								CastSpell(HXGSlot, enemy)
								setItem()
							end
						elseif BWCReady and GetDistance(enemy) < 500 then
							total = total + bwcKS
							if total > enemy.health then
								CastSpell(BWCSlot, enemy)
								setItem()
							end
						elseif BRKReady and GetDistance(enemy) < 500 then
							total = total + brkKS
							if total > enemy.health then
								CastSpell(BRKSlot, enemy)
								setItem()
							end
						end
					elseif GetDistance(enemy) < (ERange*1.6) then
						if TMatReady then
							total = total + tmatKS
							if total > enemy.health then
								CastSpell(TMatSlot)
								setItem()
							end
						end
						if RHydraReady then
							total = total + rhydraKS
							if total > enemy.health then
								CastSpell(RHydraSlot)
								setItem()
							end
						end
					end
				end
			end
				
			if IReady and JaxConfig.AutoIgnite and QReady == false and itemWait == false then
				if GetDistance(enemy) > (ERange*1.6) and GetDistance(enemy) < 600 and qTimer < os.clock() then
					if BRKReady == false and HXGReady == false and BWCReady == false and RANDReady == false then
						if ValidTarget(enemy, 600) and iKS > enemy.health then
							CastSpell(ignite, enemy)
						end
					end
				end
				if myHero.health < 250 and ValidTarget(enemy, 600) and iKS > enemy.health then
					CastSpell(ignite, enemy)
				end
			end
		end
		ksDelay = os.clock() + 0.1
	end
end
 
function jaxCombo()
	if JaxConfig.JaxCombo then
		if JaxConfig.moveMouse and ts.target == nil then
			myHero:MoveTo(mousePos.x, mousePos.z)
		end
		if ts.target ~= nil then
			if eTimer ~= 0 and eTimer < os.clock() then
				resetQE()
			end
			if JaxConfig.AutoUlt and RReady then
				if rActivate == true then
					CastSpell(_R)
				else 
					local champCount = 0
					if os.clock() > countDelay then
						for i = 1, heroManager.iCount do
							local enemy = heroManager:getHero(i)
							if ValidTarget(enemy, QRange) then
								champCount = champCount + 1
							end
						end
						countDelay = os.clock() + 1
					end
					if champCount >= (JaxConfig.minChamps + 1) then
						CastSpell(_R)
					end
				end
			end
			if JaxConfig.EQCombo then
				if EProc == true then
					if GetDistance(ts.target) < ERange then
						if ERange == GetDistance(ts.target) and eTimer > os.clock() and eWait < os.clock() then
							CastSpell(_E)
							resetQE()
						end
					end
					if QLanded == false and QReady and GetDistance(ts.target) < QRange and GetDistance(ts.target) > ERange then
						if eTimer > (os.clock() + 0.4) then
						elseif eWait > os.clock() then
						elseif eWait < os.clock() then
							CastSpell(_Q, ts.target)
							qTimer = os.clock() + 0.3
							QLanded = true
						end
					end
					if QLanded == true and qTimer < os.clock() and os.clock() < eTimer then
						CastSpell(_E)
						resetQE()                              
					end
				end
				if EProc == false then
					if EReady and GetDistance(ts.target) < ERange then
						setE()                 
					elseif EReady and QReady and GetDistance(ts.target) < (QRange - (ts.target.ms - myHero.ms)) and GetDistance(ts.target) > ERange then
						setE()
					elseif QReady and EReady == false and GetDistance(ts.target) < QRange and GetDistance(ts.target) > (ERange * 2) then
						CastSpell(_Q, ts.target)
						qTimer = os.clock() + 0.3
					end
				end
			elseif JaxConfig.QECombo then
				if QReady and GetDistance(ts.target) < QRange and GetDistance(ts.target) > (ERange + 10) then
					CastSpell(_Q, ts.target)
				end
				if EReady and EProc == false and GetDistance(ts.target) < ERange then
					setE()
				end
				if EProc == true and eWait < os.clock() and eTimer > os.clock() and GetDistance(ts.target) < ERange then
					CastSpell(_E)
					resetQE()
				end
			end			
			if GetDistance(ts.target) < QRange and swing == 0 then
				myHero:Attack(ts.target)
			end
		end
		if JaxConfig.BurstCombo and ts.target ~= nil then
			if JaxConfig.AutoIgnite and IReady and GetDistance(ts.target) < 600 then
				CastSpell(ignite, ts.target)
			end
			if BRKReady and GetDistance(ts.target) < 500 then
				CastSpell(BRKSlot, ts.target)
			end
			if GetDistance(ts.target) < ARange and ItemProc == true then
				if RHydraReady and ItemProc == true then
					if os.clock() < timeout then
						if os.clock() > timer then --checks to ensure efficiency of AA reset
							CastSpell(RHydraSlot, ts.target)
							resetAW()
						end
					end
				end
				if TMatReady and ItemProc == true then
					if os.clock() < timeout then
						if os.clock() > timer then --checks to ensure efficiency of AA reset
							CastSpell(TMatSlot, ts.target)
							resetAW()
						end
					end
				end
			elseif ItemProc == true and timeout <= os.clock() then
				resetAW()
			end
			if HXGReady and GetDistance(ts.target) < QRange then
				CastSpell(HXGSlot, ts.target)
			end
			if BWCReady and GetDistance(ts.target) < 500 then
				CastSpell(BWCSlot, ts.target)
			end
			if RANDReady then
				if GetDistance(ts.target) < 500 and GetDistance(ts.target) > (ERange*1.6) and QReady == false then
					CastSpell(RANDSlot, ts.target)
				end
			end
		end
		
		if JaxConfig.IntelCombo and ts.target ~= nil and itemWait == false then
			if ItemProc == true and timeout <= os.clock() then
				resetAW()
			end
			if BRKReady then
				if myHero.maxHealth > (myHero.health*2) and GetDistance(ts.target) < 500 then
					CastSpell(BRKSlot, ts.target)
					setItem()
				end
				if GetDistance(ts.target) < 500 and GetDistance(ts.target) > (ERange*1.6) and QReady == false and BWCReady == false and HXGReady == false and qTimer < os.clock() then
					CastSpell(BRKSlot, ts.target)
					setItem()
				end
			end
			if HXGReady then
				if GetDistance(ts.target) < QRange and GetDistance(ts.target) > (ERange*1.6) and QReady == false and qTimer < os.clock() then
					CastSpell(HXGSlot, ts.target)
					setItem()
				end
			end
			if BWCReady then
				if GetDistance(ts.target) < 500 and GetDistance(ts.target) > (ERange*1.6) and QReady == false and qTimer < os.clock() then
					CastSpell(BWCSlot, ts.target)
					setItem()
				end
			end
			if RANDReady then
				if GetDistance(ts.target) < 500 and GetDistance(ts.target) > (ERange*1.6) and QReady == false and qTimer < os.clock() then
					CastSpell(RANDSlot, ts.target)
					setItem()
				end
			end
		end
		if itemWait == true and os.clock() > itemEnd then
			resetItem()
		end
	end
end

function calcDamage()
	if not myHero.dead and os.clock() > calcDelay then
		for i=1, heroManager.iCount do
			local enemy = heroManager:GetHero(i)
			if ValidTarget(enemy) and GetDistance(enemy) < 1000 then
				local qDamage = getDmg("Q", enemy, myHero)
				local wDamage = getDmg("W", enemy, myHero)
				local eDamage = getDmg("E", enemy, myHero)
				local rDamage = getDmg("R", enemy, myHero)
				local aDamage = getDmg("AD", enemy, myHero)
				local hxgDamage = (HXGSlot and getDmg("HXG", enemy, myHero) or 0)
				local bwcDamage = (BWCSlot and getDmg("BWC", enemy, myHero) or 0)
				local brkDamage = (BRKSlot and getDmg("RUINEDKING", enemy, myHero) or 0)
				local tmatDamage = aDamage*0.6
				local rhydraDamage = aDamage*0.6
				local SheenDamage = (SheenSlot and getDmg("SHEEN", enemy, myHero) or 0)
				local TrinityDamage = (TrinitySlot and getDmg("TRINITY", enemy, myHero) or 0)
				local LichBaneDamage = (LichBaneSlot and getDmg("LICHBANE", enemy, myHero) or 0)
				local iDamage = 50 + (20*myHero.level)
				local myDamage = SheenDamage + TrinityDamage + LichBaneDamage + aDamage
				if QReady then
					myDamage = myDamage + qDamage
				end
				if WReady or WProc == true then
					myDamage = myDamage + wDamage + (aDamage*2)
				end
				if EReady or EProc == true then
					myDamage = myDamage + eDamage + ((1/(1/(((0.625/(1-0.02)))*(1*myHero.attackSpeed))))*aDamage)
				end
				if myHero.level >= 6 and (2.5/(1/(((0.625/(1-0.02)))*(1*myHero.attackSpeed)))) >= 3 then
					myDamage = myDamage + (rDamage*2) + (aDamage*2)
				elseif myHero.level >= 6 and (2.5/(1/(((0.625/(1-0.02)))*(1*myHero.attackSpeed)))) < 3 then
					myDamage = myDamage + rDamage + aDamage
				end
				if HXGReady then
					myDamage = myDamage + hxgDamage
				end
				if BWCReady then
					myDamage = myDamage + bwcDamage
				end
				if BRKReady then
					myDamage = myDamage + brkDamage
				end
				if IReady then
					myDamage = myDamage + iDamage
				end
				if TMatReady then
					myDamage = myDamage + tmatDamage + aDamage
				end
				if RHydraReady then
					myDamage = myDamage + rhydraDamage + aDamage
				end
				if myDamage < enemy.health then
					killable[i] = 5
				elseif (myDamage/4) >= enemy.health then
					killable[i] = 4
				elseif (myDamage/3) >= enemy.health then
					killable[i] = 3
				elseif (myDamage/2) >= enemy.health then
					killable[i] = 2
				elseif myDamage >= enemy.health then
					killable[i] = 1
				else
					killable[i] = 0
				end
			else
				killable[i] = 5
			end
		end  
		calcDelay = os.clock() + 0.2
	elseif myHero.dead then
		resetAW()
		resetQE()
	end
end

function OnDraw()
        if not myHero.dead then
                if JaxConfig.drawcircles then
                        DrawCircle(myHero.x, myHero.y, myHero.z, QRange, 0xFF80FF00)
                end
                if ValidTarget(ts.target) then
                        if JaxConfig.drawcircles then
                                DrawCircle(ts.target.x, ts.target.y, ts.target.z, 100, 0x099B2299)
                        end
                        if JaxConfig.drawtext then
                                DrawText("Targetting: " .. ts.target.charName, 18, 650, 25, 0xFFFF0000)
                        end
                end
        for i=1, heroManager.iCount do
                local enemydraw = heroManager:GetHero(i)
                if ValidTarget(enemydraw) then
                        if JaxConfig.drawcircles then
                                if killable[i] == 1 then
                                        for j=0, 20 do
                                                DrawCircle(enemydraw.x, enemydraw.y, enemydraw.z, 80 + j*1.5, 0x0000FF)
                                        end
                                        elseif killable[i] == 2 then
                                                for j=0, 10 do
                                                        DrawCircle(enemydraw.x, enemydraw.y, enemydraw.z, 80 + j*1.5, 0xFF0000)
                                                end
                                        elseif killable[i] == 3 then
                                                for j=0, 10 do
                                                        DrawCircle(enemydraw.x, enemydraw.y, enemydraw.z, 80 + j*1.5, 0xFF0000)
                                                        DrawCircle(enemydraw.x, enemydraw.y, enemydraw.z, 110 + j*1.5, 0xFF0000)
                                                end
                                        elseif killable[i] == 4 then
                                                for j=0, 10 do
                                                        DrawCircle(enemydraw.x, enemydraw.y, enemydraw.z, 80 + j*1.5, 0xFF0000)
                                                        DrawCircle(enemydraw.x, enemydraw.y, enemydraw.z, 110 + j*1.5, 0xFF0000)
                                                        DrawCircle(enemydraw.x, enemydraw.y, enemydraw.z, 140 + j*1.5, 0xFF0000)
                                                end
                                        end
                                end
                                if JaxConfig.drawtext and waittxt[i] == 1 and killable[i] ~= 0 then
                                        PrintFloatText(enemydraw,0,floattext[killable[i]])
                                end
                        end
                        if waittxt[i] == 1 then
                                waittxt[i] = 30
                        else
                                waittxt[i] = waittxt[i]-1
                  end
             end
       end
end
                      