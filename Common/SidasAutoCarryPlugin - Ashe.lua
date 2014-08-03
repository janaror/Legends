--[[

        Auto Carry Plugin - Ashe

        Activates Q when attacking enemy hero and disables when attacking minions.
        Activates Muramana when attacking enemy hero.

--]]



local frostOn = false
AutoCarry.PluginMenu:addParam("AutoQ", "Activate Q Against Enemy", SCRIPT_PARAM_ONOFF, true)
AutoCarry.PluginMenu:addParam("MMana", "Activate Muramana Against Enemy", SCRIPT_PARAM_ONOFF, true)
AutoCarry.PluginMenu:addParam("ManaCheck", "Maximum % for Q activation", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)


function CustomAttackEnemy(enemy)
        if enemy.dead or not enemy.valid or not AutoCarry.CanAttack then return end

        if AutoCarry.PluginMenu.AutoQ then
                if ValidTarget(enemy) and enemy.type == "obj_AI_Hero" and not frostOn and (myHero.mana > ((myHero.maxMana / 100) * AutoCarry.PluginMenu.ManaCheck)) then
                        CastSpell(_Q)
                elseif ValidTarget(enemy) and enemy.type ~= "obj_AI_Hero" and frostOn then
                        CastSpell(_Q)
                end
        end

        if AutoCarry.PluginMenu.MMana then
                if ValidTarget(enemy) and enemy.type == "obj_AI_Hero" and (myHero.mana > ((myHero.maxMana / 100) * AutoCarry.PluginMenu.ManaCheck)) and not MuramanaIsActive() then
                        MuramanaOn()
                elseif ValidTarget(enemy) and enemy.type ~= "obj_AI_Hero" and MuramanaIsActive() then
                        MuramanaOff()
                end
        end

        myHero:Attack(enemy)
        AutoCarry.shotFired = true
end


function PluginOnCreateObj(obj)
        if GetDistance(obj) < 100 and obj.name:lower():find("icesparkle") then
                frostOn = true
        end
end

function PluginOnDeleteObj(obj)
        if GetDistance(obj) < 100 and obj.name:lower():find("icesparkle") then
                frostOn = false
        end
end
