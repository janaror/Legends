--[[

	Vayne v.1.1  beta
	
	]]
if myHero.charName ~= "Vayne" then return end

_OwnEnv = GetCurrentEnv().FILE_NAME:gsub(".lua", "")
ShadowVersion = 1.4

------------------------
------ MainScript ------
------------------------
function OnLoad()
	TCPU = TCPUpdater()
	TCPU:AddScript("VPrediction","Lib","raw.githubusercontent.com","/Hellsing/BoL/master/common/VPrediction.lua","/Hellsing/BoL/master/version/VPrediction.version","local version", "Free")
	TCPU:AddScript("SOW","Lib","raw.githubusercontent.com","/Hellsing/BoL/master/common/SOW.lua","/Hellsing/BoL/master/version/SOW.version","local version", "Free")
--~ 	TCPU:AddScript("SourceLib","Lib","raw.githubusercontent.com","/TheRealSource/public/master/common/SourceLib.lua","/TheRealSource/public/master/common/SourceLib.version","local version", "Free")
--~ 	TCPU:AddScript("Selector","Lib","raw.githubusercontent.com","/pqmailer/BoL_Scripts/master/Paid/Selector.lua","/pqmailer/BoL_Scripts/master/Paid/Selector.revision","@version", "VIP")
	TCPU:AddScript("CustomPermaShow","Lib","raw.githubusercontent.com","/Superx321/BoL/master/common/CustomPermaShow.lua","/Superx321/BoL/master/common/CustomPermaShow.Version","version =", "Free")
	TCPU:AddScript("ShadowVayneLib","Lib","raw.githubusercontent.com","/Superx321/BoL/master/common/ShadowVayneLib.lua","/Superx321/BoL/master/common/ShadowVayneLib.Version","version =", "Free")
	if VIP_USER then TCPU:AddScript("Prodiction","Lib","bitbucket.org","/Klokje/public-klokjes-bol-scripts/raw/aef4be4e92a5b1ba70154752c49e4978e7178dd4/Test/Prodiction/Prodiction.lua",nil,"--Prodiction", "VIP", 1.2) end
	TCPU:AddScript(_OwnEnv,"Script","raw.githubusercontent.com","/Superx321/BoL/master/ShadowVayne.lua","/Superx321/BoL/master/ShadowVayne.Version","ShadowVersion =")
end

function OnTick()
	if not _G.ShadowVayneLoaded then
		local NeedWait = false
		for i, UpdateStatus in pairs(_G.TCPUpdates) do
			if UpdateStatus == false then
				NeedWait = true
				break
			end
		end
		if NeedWait == false then
			_G.ShadowVayneLoaded = true
			ShadowVayne()
		end
	end
end


------------------------
---- AddParam Hooks ----
------------------------
_G.scriptConfig.CustomaddParam = _G.scriptConfig.addParam
_G.scriptConfig.addParam = function(self, pVar, pText, pType, defaultValue, a, b, c, d)

 -- MMA Hook
if self.name == "MMA2013" and pText:find("OnHold") then
	pType = 5
end

-- SAC:Reborn r83 Hook
if self.name:find("sidasacsetup_sidasac") and (pText == "Auto Carry" or pText == "Mixed Mode" or pText == "Lane Clear" or pText == "Last Hit") then
	pType=5
end

-- SAC:Reborn r84 Hook
if self.name:find("sidasacsetup_sidasac") and (pText == "Hotkey") then
	pType=5
end

-- SAC:Reborn VayneMenu Hook
if self.name:find("sidasacvayne") then
	pType=5
end

-- SOW Hook
if self.name == "SV_SOW" and pVar:find("Mode") then
	pType=5
end

 _G.scriptConfig.CustomaddParam(self, pVar, pText, pType, defaultValue, a, b, c, d)
end

-------------------------
---- DrawParam Hooks ----
-------------------------
_G.scriptConfig.CustomDrawParam = _G.scriptConfig._DrawParam
_G.scriptConfig._DrawParam = function(self, varIndex)
	local HideParam = false

	if self.name:find("sidasacsetup_sidasac") and (self._param[varIndex].text == "Hotkey") then
		self._param[varIndex].text = "ShadowVayne found. Set the Keysettings there!"
		self._param[varIndex].var = "sep"
	end

	if self.name == "MMA2014" and (self._param[varIndex].text:find("Spells on") or self._param[varIndex].text:find("Version")) then
	HideParam = true
		if not MMAParams then
			MMAParams = true
			self:addParam("nil","ShadowVayne found. Set the Keysettings there!", SCRIPT_PARAM_INFO, "")
			self:addParam("nil","ShadowVayne found. Set the Keysettings there!", SCRIPT_PARAM_INFO, "")
			self:addParam("nil","ShadowVayne found. Set the Keysettings there!", SCRIPT_PARAM_INFO, "")
			self:addParam("nil","ShadowVayne found. Set the Keysettings there!", SCRIPT_PARAM_INFO, "")
			self:addParam(self._param[varIndex].var, "Use Spells On", SCRIPT_PARAM_LIST,1, {"None","All Units","Heroes Only","Minion Only"})
			self:addParam("mmaVersion","MMA - version:", SCRIPT_PARAM_INFO, "0.1416")
		end
	end

	if self.name:find("sidasacvayne") and not self._param[varIndex].text:find("ShadowVayne") then
		if not SACVayneParam then
			SACVayneParam = true
			self:addParam("nil","ShadowVayne found. Set the Keysettings there!", SCRIPT_PARAM_INFO, "")
		end
		HideParam = true
	end

	if self.name == "SV_MAIN_keysetting" and self._param[varIndex].text:find("Hidden") then
		HideParam = true
	end

	if self.name == "SV_SOW" and (self._param[varIndex].var == "Hotkeys" or self._param[varIndex].var:find("Mode")) then HideParam = true end

	if (self.name == "MMA2014" and self._param[varIndex].text:find("OnHold")) then HideParam = true end
	if not HideParam then
		_G.scriptConfig.CustomDrawParam(self, varIndex)
	end
end

-------------------------
----- SubMenu Hooks -----
-------------------------
_G.scriptConfig.CustomDrawSubInstance = _G.scriptConfig._DrawSubInstance
_G.scriptConfig._DrawSubInstance = function(self, index)
	if not self.name:find("sidasacvayne") then
		_G.scriptConfig.CustomDrawSubInstance(self, index)
	end
end

-------------------------
---- PermaShow Hooks ----
-------------------------
_G.scriptConfig.CustompermaShow = _G.scriptConfig.permaShow
_G.scriptConfig.permaShow = function(self, pVar)
	if not (self.name:find("sidasacvayne") or self.name == "MMA2014") then
		_G.scriptConfig.CustompermaShow(self, pVar)
	end
end


