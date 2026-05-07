-- ============================================================================
-- ability.lua - 管理玩家技能系统
-- ============================================================================

-- 技能系统初始化
AbilitySystem = AbilitySystem or {}

function AbilitySystem:init()
    -- 技能定义
    self.abilities = {
        -- 主动技能
        heal = {
            name = "Heal",
            type = "active",
            price = 1500,
            description = "Restore 25 HP\nCooldown: 30s",
            cooldown = 30,
            icon = "HP",
            color = {0, 1, 0},
            onUse = function()
                player.HealthSystem.Health = math.min(player.HealthSystem.HealthMax, player.HealthSystem.Health + 25)
                print("Heal used! Restored 25 HP")
            end,
            canUse = function()
                return player.HealthSystem.Health < player.HealthSystem.HealthMax
            end
        },
        harvest = {
            name = "Harvest",
            type = "active",
            price = 4000,
            description = "Execute enemies below 5% HP, deal 50 damage to others\nCooldown: 90s",
            cooldown = 90,
            icon = "HV",
            color = {1, 0.5, 0},
            onUse = function()
                local killCount = 0
                local damageCount = 0
                
                for i = #enemies, 1, -1 do
                    local enemy = enemies[i]
                    local healthPercent = enemy.health / enemy.maxHealth
                    
                    if healthPercent < 0.05 then
                        enemy.health = 0
                        handleEnemyDeath(enemy, "harvest")
                        killCount = killCount + 1
                    else
                        enemy.health = enemy.health - 50
                        if enemy.health <= 0 then
                            handleEnemyDeath(enemy, "harvest")
                            killCount = killCount + 1
                        else
                            damageCount = damageCount + 1
                        end
                    end
                end
                
                print("Harvest used! Executed " .. killCount .. " enemies, damaged " .. damageCount .. " enemies")
            end,
            canUse = function() return true end
        },
        siphon = {
            name = "Siphon",
            type = "active",
            price = 6000,
            description = "For 10 seconds, recover 50% of damage dealt as HP\nCooldown: 80s",
            cooldown = 80,
            icon = "SH",
            color = {0.5, 0, 1},
            duration = 10,
            onUse = function()
                player.abilities.siphonActive = true
                player.abilities.siphonTimer = 10
                print("Siphon activated! 50% damage converted to HP for 10s")
            end,
            onUpdate = function(dt)
                if player.abilities.siphonActive then
                    player.abilities.siphonTimer = player.abilities.siphonTimer - dt
                    if player.abilities.siphonTimer <= 0 then
                        player.abilities.siphonActive = false
                        print("Siphon effect ended")
                    end
                end
            end,
            canUse = function() return not player.abilities.siphonActive end
        },
        forcefield = {
            name = "Force Field",
            type = "active",
            price = 2000,
            description = "Knock back and stun nearby enemies for 1.5s\nCooldown: 30s",
            cooldown = 30,
            icon = "FF",
            color = {0, 0.5, 1},
            radius = 40,
            onUse = function()
                local px, py = player.x + 10, player.y + 10
                local stunnedCount = 0
                
                for _, enemy in ipairs(enemies) do
                    local ex, ey = enemy.x + enemy.size/2, enemy.y + enemy.size/2
                    local dx, dy = ex - px, ey - py
                    local dist = math.sqrt(dx*dx + dy*dy)
                    
                    if dist < 40 then
                        if dist > 0 then
                            local pushX = dx / dist * 100
                            local pushY = dy / dist * 100
                            enemy.x = enemy.x + pushX
                            enemy.y = enemy.y + pushY
                        end
                        
                        enemy.stunned = true
                        enemy.stunTimer = 1.5
                        enemy.originalSpeed = enemy.speed
                        enemy.speed = 0
                        stunnedCount = stunnedCount + 1
                    end
                end
                
                print("Force Field used! Stunned " .. stunnedCount .. " enemies")
            end,
            canUse = function() return true end
        },
        degradation = {
            name = "Degradation",
            type = "active",
            price = 10000,
            description = "Transform all enemies into weaker forms\nBoss -> Easy Boss, Others -> Tank\nCooldown: 150s",
            cooldown = 150,
            icon = "DG",
            color = {0.8, 0.2, 0.2},
            onUse = function()
                local convertedCount = 0
                local bossConverted = 0
                
                for i = #enemies, 1, -1 do
                    local enemy = enemies[i]
                    local healthPercent = enemy.health / enemy.maxHealth
                    
                    if enemy.type:find("boss") then
                        -- Boss转化为easy_boss
                        if enemy.type ~= "boss_easy" then
                            local newEnemy = spawnEnemy("boss_easy")
                            newEnemy.x = enemy.x
                            newEnemy.y = enemy.y
                            -- 保持血量比例
                            newEnemy.health = math.max(1, math.floor(newEnemy.maxHealth * healthPercent))
                            newEnemy.maxHealth = newEnemy.maxHealth
                            table.remove(enemies, i)
                            table.insert(enemies, newEnemy)
                            bossConverted = bossConverted + 1
                            convertedCount = convertedCount + 1
                            print("Boss transformed to Easy Boss, HP: " .. newEnemy.health .. "/" .. newEnemy.maxHealth)
                        end
                    else
                        -- 非Boss转化为Tank
                        local newEnemy = spawnEnemy("tank")
                        newEnemy.x = enemy.x
                        newEnemy.y = enemy.y
                        -- 保持血量比例
                        newEnemy.health = math.max(1, math.floor(newEnemy.maxHealth * healthPercent))
                        newEnemy.maxHealth = newEnemy.maxHealth
                        table.remove(enemies, i)
                        table.insert(enemies, newEnemy)
                        convertedCount = convertedCount + 1
                        print("Enemy transformed to Tank, HP: " .. newEnemy.health .. "/" .. newEnemy.maxHealth)
                    end
                end
                
                print("Degradation used! Converted " .. convertedCount .. " enemies, including " .. bossConverted .. " bosses")
            end,
            canUse = function() return #enemies > 0 end
        },
        
        -- 被动技能
        dragonslayer = {
            name = "Dragon Slayer",
            type = "passive",
            price = 3000,
            description = "+10% damage to bosses",
            icon = "DS",
            color = {1, 0.8, 0},
            onEquip = function()
                player.abilities.passive.dragonslayer = true
                print("Dragon Slayer activated")
            end,
            onUnequip = function()
                player.abilities.passive.dragonslayer = false
                print("Dragon Slayer deactivated")
            end
        },
        bloodthirst = {
            name = "Bloodthirst",
            type = "passive",
            price = 8000,
            description = "Killing an enemy restores 1 HP, bosses restore 20 HP",
            icon = "BT",
            color = {1, 0, 0},
            onEquip = function()
                player.abilities.passive.bloodthirst = true
                print("Bloodthirst activated")
            end,
            onUnequip = function()
                player.abilities.passive.bloodthirst = false
                print("Bloodthirst deactivated")
            end
        },
        constant = {
            name = "Constant Motion",
            type = "passive",
            price = 3000,
            description = "Cannot run, but speed is 260, no stamina consumption",
            icon = "CM",
            color = {1, 1, 0},
            onEquip = function()
                player.abilities.passive.constantMotion = true
                player.originalWalkspeed = player.RunSystem.Walkspeed
                player.originalRunspeed = player.RunSystem.Runspeed
                player.RunSystem.Walkspeed = 260
                player.RunSystem.Runspeed = 260
                print("Constant Motion activated, speed 260")
            end,
            onUnequip = function()
                player.abilities.passive.constantMotion = false
                if player.originalWalkspeed then
                    player.RunSystem.Walkspeed = player.originalWalkspeed
                    player.RunSystem.Runspeed = player.originalRunspeed
                end
                print("Constant Motion deactivated")
            end
        }
    }
    
    -- 玩家技能配置
    if not player.abilities then
        player.abilities = {
            owned = {},
            activeSlots = { nil, nil, nil, nil },
            activeCooldowns = { 0, 0, 0, 0 },
            activeKeys = { "q", "e", "z", "x" },
            passiveSlots = { nil, nil },
            siphonActive = false,
            siphonTimer = 0,
            passive = {
                dragonslayer = false,
                bloodthirst = false,
                constantMotion = false
            }
        }
    elseif not player.abilities.owned then
        player.abilities.owned = {}
    end
    
    self.shopCategory = "abilities"
    self.selectedAbilityType = "active"
    
    print("✓ AbilitySystem initialized")
end

-- 购买技能
function AbilitySystem:purchase(abilityId)
    local ability = self.abilities[abilityId]
    if not ability then return false, "Ability not found" end
    
    if player.abilities.owned[abilityId] then
        return false, "Already owned!"
    end
    
    if maxBits < ability.price then
        return false, "Not enough Bits! Need " .. ability.price
    end
    
    maxBits = maxBits - ability.price
    addBits(0)
    
    player.abilities.owned[abilityId] = true
    
    print("✓ Ability unlocked: " .. ability.name)
    return true, "Purchased: " .. ability.name
end

-- 检查是否可以装备技能
function AbilitySystem:canEquip(abilityId)
    local ability = self.abilities[abilityId]
    if not ability then return false, "Ability not found" end
    
    if not player.abilities.owned[abilityId] then
        return false, "You don't own this ability!"
    end
    
    if ability.type == "active" then
        for i, slot in ipairs(player.abilities.activeSlots) do
            if slot == nil then
                return true, i
            end
        end
        return false, "Active skill slots full (max 4)"
    else
        for i, slot in ipairs(player.abilities.passiveSlots) do
            if slot == nil then
                return true, i
            end
        end
        return false, "Passive skill slots full (max 2)"
    end
end

-- 装备技能
function AbilitySystem:equip(abilityId, slotIndex)
    local ability = self.abilities[abilityId]
    if not ability then return false end
    
    if ability.type == "active" then
        if slotIndex and slotIndex >= 1 and slotIndex <= 4 then
            player.abilities.activeSlots[slotIndex] = abilityId
            print("Equipped active skill: " .. ability.name .. " to slot " .. slotIndex .. " (key: " .. player.abilities.activeKeys[slotIndex]:upper() .. ")")
        end
    else
        if slotIndex and slotIndex >= 1 and slotIndex <= 2 then
            if player.abilities.passiveSlots[slotIndex] then
                local oldAbility = self.abilities[player.abilities.passiveSlots[slotIndex]]
                if oldAbility and oldAbility.onUnequip then
                    oldAbility.onUnequip()
                end
            end
            player.abilities.passiveSlots[slotIndex] = abilityId
            if ability.onEquip then
                ability.onEquip()
            end
            print("Equipped passive skill: " .. ability.name .. " to slot " .. slotIndex)
        end
    end
    saveHighScore()
    return true
end

-- 卸下技能
function AbilitySystem:unequip(slotIndex, slotType)
    if slotType == "active" then
        if slotIndex >= 1 and slotIndex <= 4 then
            player.abilities.activeSlots[slotIndex] = nil
            player.abilities.activeCooldowns[slotIndex] = 0
            print("Unequipped active skill slot " .. slotIndex)
        end
    else
        if slotIndex >= 1 and slotIndex <= 2 then
            local abilityId = player.abilities.passiveSlots[slotIndex]
            if abilityId then
                local ability = self.abilities[abilityId]
                if ability and ability.onUnequip then
                    ability.onUnequip()
                end
            end
            player.abilities.passiveSlots[slotIndex] = nil
            print("Unequipped passive skill slot " .. slotIndex)
        end
    end
    saveHighScore()
end

-- 使用主动技能
function AbilitySystem:useActiveSkill(slotIndex)
    if slotIndex < 1 or slotIndex > 4 then return end
    
    local abilityId = player.abilities.activeSlots[slotIndex]
    if not abilityId then
        print("No skill in this slot")
        return
    end
    
    if player.abilities.activeCooldowns[slotIndex] > 0 then
        print("Skill on cooldown: " .. math.ceil(player.abilities.activeCooldowns[slotIndex]) .. "s")
        return
    end
    
    local ability = self.abilities[abilityId]
    if ability and ability.canUse() then
        ability.onUse()
        player.abilities.activeCooldowns[slotIndex] = ability.cooldown
    end
end

-- 更新技能
function AbilitySystem:update(dt)
    for i = 1, 4 do
        if player.abilities.activeCooldowns[i] > 0 then
            player.abilities.activeCooldowns[i] = player.abilities.activeCooldowns[i] - dt
            if player.abilities.activeCooldowns[i] < 0 then
                player.abilities.activeCooldowns[i] = 0
            end
        end
    end
    
    if player.abilities.siphonActive then
        player.abilities.siphonTimer = player.abilities.siphonTimer - dt
        if player.abilities.siphonTimer <= 0 then
            player.abilities.siphonActive = false
        end
    end
    
    for _, enemy in ipairs(enemies) do
        if enemy.stunned then
            enemy.stunTimer = (enemy.stunTimer or 0) - dt
            if enemy.stunTimer <= 0 then
                enemy.stunned = false
                enemy.speed = enemy.originalSpeed or enemy.speed
            end
        end
    end
    
    for _, abilityId in ipairs(player.abilities.activeSlots) do
        if abilityId and self.abilities[abilityId] and self.abilities[abilityId].onUpdate then
            self.abilities[abilityId].onUpdate(dt)
        end
    end
end

-- 处理技能按键 (Q/E/Z/X)
function AbilitySystem:handleKey(key)
    for i, bindKey in ipairs(player.abilities.activeKeys) do
        if key == bindKey then
            print("Skill key pressed: " .. key .. " triggering slot " .. i)
            self:useActiveSkill(i)
            return true
        end
    end
    return false
end

-- 获取已拥有的技能列表
function AbilitySystem:getOwnedAbilities(typeFilter)
    local list = {}
    for id, owned in pairs(player.abilities.owned) do
        if owned and self.abilities[id] then
            if not typeFilter or self.abilities[id].type == typeFilter then
                table.insert(list, {
                    id = id,
                    data = self.abilities[id]
                })
            end
        end
    end
    table.sort(list, function(a, b) return a.data.name < b.data.name end)
    return list
end

-- 重置所有技能冷却
function AbilitySystem:resetCooldowns()
    for i = 1, 4 do
        player.abilities.activeCooldowns[i] = 0
    end
    player.abilities.siphonActive = false
    player.abilities.siphonTimer = 0
end

print("✓ ability.lua loaded")
return AbilitySystem