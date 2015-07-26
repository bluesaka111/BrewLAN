--------------------------------------------------------------------------------
--   Author:  Sean 'Balthazar' Wheeldon
--------------------------------------------------------------------------------
do
    local OldCreateInitialArmyGroup = CreateInitialArmyGroup
    function CreateInitialArmyGroup(strArmy, createCommander)
        if not ScenarioInfo.DodecahedronCrate then     
            ScenarioInfo.DodecahedronCrate = { }
            ScenarioInfo.DodecahedronCrate.Thread = ForkThread(
                function()
                    local crate = import('/lua/sim/Entity.lua').Entity()
                    local crateType = 'CRATE_Dodecahedron'
                    local flash
                    Warp(crate,getSafePos())
                    crate:SetMesh('/mods/cratedrop/effects/entities/' .. crateType .. '/' .. crateType ..'_mesh')
                    crate:SetDrawScale(.08)
                    crate:SetVizToAllies('Intel')
                    crate:SetVizToNeutrals('Intel')
                    crate:SetVizToEnemies('Intel')
                    while true do
                        WaitTicks(2)
                        
                        local search = arbitraryBrain():GetUnitsAroundPoint( categories.ALLUNITS, crate:GetPosition(), 1)
                        if search[1] and IsUnit(search[1]) then
                            PhatLewt(search[1], crate:GetPosition() )
                            flash = CreateEmitterAtEntity(crate, search[1]:GetArmy(), '/effects/emitters/flash_01_emit.bp'):ScaleEmitter(10)
                            Warp(crate,{crate:GetPosition()[1],crate:GetPosition()[2]-20,crate:GetPosition()[3]})
                            WaitTicks(5)
                            flash:Destroy()
                            
                            Warp(crate,getSafePos())
                            flash = CreateEmitterAtEntity(crate, search[1]:GetArmy(), '/effects/emitters/flash_01_emit.bp'):ScaleEmitter(4)
                            WaitTicks(5)
                            flash:Destroy()
                        end     
                    end 
                end
            )
        end
        return OldCreateInitialArmyGroup(strArmy, createCommander)
    end
            
    local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker
    local lewt = {
        -- Free stuff.
        {
            --5000 mass
            function(Unit, pos) LOG("Dat mass") Unit:GetAIBrain():GiveResource('Mass', 5000) end,
            --Clone at current health
            function(Unit, pos)
                LOG("Clone")
                local clone = CreateUnitHPR(Unit:GetBlueprint().BlueprintId, Unit:GetArmy(), pos[1], pos[2], pos[3], 0, math.random(0,360), 0)
                clone:SetMaxHealth(Unit:GetMaxHealth() )
                clone:SetHealth(Unit, Unit:GetHealth() )
            end,
            --Random buildable unit
            function(Unit, pos)
                LOG("Random dude")
                CreateUnitHPR(randomBuildable(gatedRandomBuildableType(Unit)), Unit:GetArmy(), pos[1], pos[2], pos[3], 0, math.random(0,360), 0)
            end,
            --Random buildable mobile engineer
            function(Unit, pos) LOG("Engineer") CreateUnitHPR(randomBuildable('Engineers'), Unit:GetArmy(), pos[1], pos[2], pos[3], 0, math.random(0,360), 0) end,
        },
        -- Unit buffs
        {
            --Double health and heal
            function(Unit, pos) LOG("Health buff") Unit:SetMaxHealth(Unit:GetMaxHealth() * 2) Unit:SetHealth(Unit, Unit:GetMaxHealth()) end,
            --Give larger vis range
            function(Unit, pos)
                LOG("Vision buff")
                if ScenarioInfo.Options.FogOfWar == 'none' then
                    WARN("Vision buff selected while fog of war disabled. Rolling again.")
                    PhatLewt(Unit, pos)
                else    
                    if not Unit.VisBuff then
                        local spec = {
                            X = pos[1],
                            Z = pos[3],
                            Radius = (Unit:GetIntelRadius('Vision') or 20) + 20,
                            LifeTime = -1,
                            Omni = false,
                            Radar = false,
                            Vision = true,
                            Army = Unit:GetAIBrain():GetArmyIndex(),
                        }
                        Unit.VisBuff = VizMarker(spec) 
                        Unit.VisBuff:AttachTo(Unit, -1)
                        Unit.Trash:Add(Unit.VisBuff)
                    else
                        Unit.VisBuff:SetIntelRadius('Vision', Unit.VisBuff:GetIntelRadius('Vision') + 20)
                    end
                end
            end,
            --Veterancy
            function(Unit, pos) LOG("Kills") Unit:AddKills(100) end,
        },
        -- Hats
        {
            function(Unit, pos)
                LOG("Hat")
                local hatTypes = {
                    'HAT_Tophat',
                    'HAT_Tophat_whiteband',
                    'HAT_Bowler_red',
                    'HAT_Boater',
                    'HAT_Cone_azn'
                }
                
                local bones = {
                    'HatPoint',
                    'Hat',
                    'Head',
                    'Attachpoint',
                    'AttachPoint',
                }
                local attachHatTo = false
                
                if not Unit.Hats then
                    for i, bone in bones do
                        if Unit:IsValidBone(bone) then
                            attachHatTo = bone
                            break
                        end 
                    end
                end
                if attachHatTo or Unit.Hats then
                    if not Unit.Hats then
                        Unit.Hats = {}
                    end
                    table.insert(Unit.Hats, import('/lua/sim/Entity.lua').Entity() )
                    local hat = Unit.Hats[table.getn(Unit.Hats)]
                    local hatType = hatTypes[math.random(1, table.getn(hatTypes) )] 
                    Warp(hat,Unit:GetPosition() )
                    hat:SetMesh('/mods/cratedrop/effects/entities/' .. hatType .. '/' .. hatType ..'_mesh')
                    if EntityCategoryContains(categories.EXPERIMENTAL , Unit) then
                        hat:SetDrawScale(.07)
                    elseif EntityCategoryContains(categories.STRUCTURE , Unit) then
                        hat:SetDrawScale(.055)
                    else
                        hat:SetDrawScale(.03)
                    end   
                    hat:SetVizToAllies('Intel')
                    hat:SetVizToNeutrals('Intel')
                    hat:SetVizToEnemies('Intel')
                    if table.getn(Unit.Hats) == 1 then
                        hat:AttachTo(Unit, attachHatTo)
                    else
                        local no = table.getn(Unit.Hats) - 1
                        hat:AttachTo(Unit.Hats[no], 'Attachpoint')
                    end    
                    Unit.Trash:Add(hat)
                else
                    if ScenarioInfo.Options.CrateHatsOnly == 'true' then
                        WARN("Unit with no noticable head attempted to pick up hats only crate.")
                    else    
                        WARN("Unit has no noticable head or attachpoint to wear a hat.")
                        PhatLewt(Unit, pos)
                    end
                end
            end,
        },
        -- Bad stuff table
        {         
            --Troll log
            function(Unit, pos) LOG("YOU GET NOTHING. YOU LOSE. GOOD DAY.") end,
            --Troll print
            function(Unit, pos) LOG("Cheating message") print(Unit:GetAIBrain().Nickname .. " " .. LOC("<LOC cheating_fragment_0000>is") .. LOC("<LOC cheating_fragment_0002> cheating!")  ) end,
            --Troll bomb
            function(Unit, pos) LOG("Explosion") CreateUnitHPR('xrl0302', Unit:GetArmy(), pos[1], pos[2], pos[3], 0, math.random(0,360), 0):GetWeaponByLabel('Suicide'):FireWeapon() end,
            --Nemesis dupe
            function(Unit, pos)
                LOG("Evil Twin")
                local clone = CreateUnitHPR(Unit:GetBlueprint().BlueprintId, randomEnemyBrain(Unit):GetArmyIndex(), pos[1], pos[2], pos[3], 0, math.random(0,360), 0)
                clone:SetMaxHealth(Unit:GetMaxHealth() )
                clone:SetHealth(Unit, Unit:GetHealth() )
            end,
            --Random nemesis 
            function(Unit, pos) LOG("Random Nemesis") CreateUnitHPR(randomBuildable(gatedRandomBuildableType(Unit)), randomEnemyBrain(Unit):GetArmyIndex(), pos[1], pos[2], pos[3], 0, math.random(0,360), 0) end,
            --Random warping
            function(Unit, pos) LOG("Teleport") Warp(Unit,getSafePos()) end,
        },
        --{
        --    function(Unit, pos) LOG(repr(Unit) ) end,
        --},
    }
    ----------------------------------------------------------------------------
    -- Main lewt picker
    ----------------------------------------------------------------------------
    function PhatLewt(triggerUnit, pos, note)
        local a = math.random(1, table.getn(lewt) )
        local b = math.random(1, table.getn(lewt[a]) )
        if note == 'Hat' or ScenarioInfo.Options.CrateHatsOnly == 'true' then
            lewt[3][1](triggerUnit, pos)
        else
            lewt[a][b](triggerUnit, pos)
        end
    end
    ----------------------------------------------------------------------------
    -- Utilities
    ----------------------------------------------------------------------------
    function TopLevelParent(Unit)
        if Unit.Parent then
            return TopLevelParent(Unit.Parent)
        else
            return Unit
        end 
    end
    
    function arbitraryBrain()     
        for i, brain in ArmyBrains do
            if not brain:IsDefeated() and not ArmyIsCivilian(brain:GetArmyIndex()) then    
                --LOG(brain.Nickname)
                return brain
            end
        end
    end
    
    function randomEnemyBrain(unit)
        local enemies = {}
        
        for i, brain in ArmyBrains do
            if not IsAlly(brain:GetArmyIndex(), unit:GetAIBrain():GetArmyIndex() ) and not brain:IsDefeated() then
                table.insert(enemies, brain)
            end
        end
        if not enemies[1] then
            return unit:GetAIBrain()
        else
            return enemies[math.random(1, table.getn(enemies) )]
        end
    end
    
    function getSafePos(tries) 
        if not tries then tries = 1 end
        local pos = {math.random(0+10,ScenarioInfo.size[1]-10), math.random(0+10,ScenarioInfo.size[2]-10)}
        local positionDummy = 'zzcrate' --need a big building that has no intel, doesn't flatten ground, and doesn't really care for evalation.      
        positionDummy = arbitraryBrain():CreateUnitNearSpot(positionDummy, pos[1], pos[2])
        if positionDummy and IsUnit(positionDummy) then    
            LOG("We tried " .. tries)
            local pos = positionDummy:GetPosition()
            positionDummy:Destroy()
            LOG(repr(pos))
            return pos 
        else
            return getSafePos(tries + 1)  
        end
    end
    
    function randomBuildable(thing)
        local buildable = 'RandomBuildable' .. tostring(thing)
        if not __blueprints.zzcrate[buildable] then
            if not __blueprints.zzcrate.RandomBuildableUnits then
                error("Random loot table refered to a random unit table that doesn't exist, and the default table also doesn't exist.")
            else
                WARN("Random loot table refered to a random unit table that doesn't exist. Returning value from all units table instead.")
                return __blueprints.zzcrate.RandomBuildableUnits[math.random(1,table.getn(__blueprints.zzcrate.RandomBuildableUnits) )]
            end
        else
            return __blueprints.zzcrate[buildable][math.random(1,table.getn(__blueprints.zzcrate[buildable]) )]
        end
    end
    
    function gatedRandomBuildableType(Unit)
        local unitTypes = {'UnitsT1','UnitsT2orLess','UnitsT3orLess','Units',} 
        local chosen
        if EntityCategoryContains(categories.EXPERIMENTAL + categories.TECH3, Unit) then
            LOG("ANYTHING GOES")
            chosen = unitTypes[math.random(1, 4)]
        elseif EntityCategoryContains(categories.TECH2, Unit) then
            LOG("Tech 3 or less")
            chosen = unitTypes[math.random(1, 3)]
        elseif EntityCategoryContains(categories.TECH1, Unit) then
            LOG("Tech 2 or less")
            chosen = unitTypes[1]     
        elseif EntityCategoryContains(categories.COMMAND, Unit) then
            LOG("Tech 3 or less")
            chosen = unitTypes[math.random(1, 3)]
        else
            LOG("ANYTHING GOES BITCHES")
            chosen = unitTypes[math.random(1, table.getn(unitTypes))]
        end
        return chosen
    end
end