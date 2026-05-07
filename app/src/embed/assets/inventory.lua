-- ============================================================================
-- inventory.lua - 管理玩家的背包，显示已拥有的武器、模组、技能和投掷物
-- ============================================================================

-- 背包当前查看的选项卡
inventoryState = {
    category = "weapons",  -- "weapons", "mods", "character", "skills", "throwables"
    subCategory = "pistol", -- "pistol", "rifle", "sniper", "soulreaper", "lasergun", "feast", "lifedrain"
    skillType = "active",   -- "active", "passive"
    throwableBinding = nil,
    scroll = 0,
    bindingWeapon = nil,
    bindingSkill = nil,
    bindingSlot = nil,
    bindingTimer = 0
}

-- ===== 获取武器绑定的槽位 =====
function getWeaponSlot(weaponType)
    for i, slot in ipairs(player.weaponSlots) do
        if slot == weaponType then
            return i
        end
    end
    return nil
end

-- ===== 获取技能绑定的槽位 =====
function getSkillSlot(skillId, skillType)
    if skillType == "active" then
        for i, slot in ipairs(player.abilities.activeSlots) do
            if slot == skillId then
                return i
            end
        end
    else
        for i, slot in ipairs(player.abilities.passiveSlots) do
            if slot == skillId then
                return i
            end
        end
    end
    return nil
end

-- ===== 绑定武器到槽位 =====
function bindWeaponToSlot(weaponType, slotIndex)
    if slotIndex < 1 or slotIndex > 4 then return end
    
    for i, wt in ipairs(player.weaponSlots) do
        if wt == weaponType then
            player.weaponSlots[i] = nil
            break
        end
    end
    
    player.weaponSlots[slotIndex] = weaponType
    
    print("Bound weapon " .. weaponType .. " to slot " .. slotIndex)
    saveHighScore()
end

-- ===== 绑定主动技能到槽位 =====
function bindActiveSkillToSlot(skillId, slotIndex)
    if slotIndex < 1 or slotIndex > 4 then return end
    
    for i, sid in ipairs(player.abilities.activeSlots) do
        if sid == skillId then
            player.abilities.activeSlots[i] = nil
            break
        end
    end
    
    player.abilities.activeSlots[slotIndex] = skillId
    print("Bound active skill " .. skillId .. " to slot " .. slotIndex .. " (key: " .. player.abilities.activeKeys[slotIndex]:upper() .. ")")
    saveHighScore()
end

-- ===== 绑定被动技能（直接装备，不需要选槽位）=====
function bindPassiveSkill(skillId)
    -- 查找空槽位
    local emptySlot = nil
    for i = 1, 2 do
        if player.abilities.passiveSlots[i] == nil then
            emptySlot = i
            break
        end
    end
    
    if emptySlot == nil then
        -- 如果没有空槽，替换第一个
        emptySlot = 1
        -- 卸下旧技能
        local oldAbility = AbilitySystem.abilities[player.abilities.passiveSlots[emptySlot]]
        if oldAbility and oldAbility.onUnequip then
            oldAbility.onUnequip()
        end
    end
    
    -- 装备新技能
    player.abilities.passiveSlots[emptySlot] = skillId
    local ability = AbilitySystem.abilities[skillId]
    if ability and ability.onEquip then
        ability.onEquip()
    end
    print("Equipped passive skill " .. skillId .. " to slot P" .. emptySlot)
    saveHighScore()
end

-- ===== 卸下被动技能 =====
function unequipPassiveSkill(slotIndex)
    if slotIndex < 1 or slotIndex > 2 then return end
    
    local skillId = player.abilities.passiveSlots[slotIndex]
    if skillId then
        local ability = AbilitySystem.abilities[skillId]
        if ability and ability.onUnequip then
            ability.onUnequip()
        end
        player.abilities.passiveSlots[slotIndex] = nil
        print("Unequipped passive skill from slot P" .. slotIndex)
        saveHighScore()
    end
end

-- ===== 获取当前分类的拥有物品列表 =====
function getInventoryList()
    local items = {}
    
    if inventoryState.category == "weapons" then
        if player.Bag.hasPistol then
            table.insert(items, {
                name = "Pistol",
                type = "pistol",
                data = player.weaponStates.pistol,
                icon = "P",
                color = {1,1,1},
                owned = true
            })
        end
        if player.Bag.hasRifle then
            table.insert(items, {
                name = "Rifle",
                type = "rifle",
                data = player.weaponStates.rifle,
                icon = "R",
                color = {1,0.8,0},
                owned = true
            })
        end
        if player.Bag.hasSniper then
            table.insert(items, {
                name = "Sniper",
                type = "sniper",
                data = player.weaponStates.sniper,
                icon = "S",
                color = {0.5,0.8,1},
                owned = true
            })
        end
        if player.Bag.hasSoulReaper then
            table.insert(items, {
                name = "Soul Reaper",
                type = "soulreaper",
                data = player.weaponStates.soulreaper,
                icon = "SR",
                color = {0.5, 0, 0.5},
                owned = true
            })
        end
        if player.Bag.hasLaserGun then
            table.insert(items, {
                name = "Laser Gun",
                type = "lasergun",
                data = player.weaponStates.lasergun,
                icon = "L",
                color = {1, 0, 0},
                owned = true
            })
        end
        if player.Bag.hasFeast then
            table.insert(items, {
                name = "Feast",
                type = "feast",
                data = player.weaponStates.feast,
                icon = "FT",
                color = {1, 0.5, 0},
                owned = true
            })
        end
        if player.Bag.hasLifedrain then
            table.insert(items, {
                name = "Life Drain",
                type = "lifedrain",
                data = player.weaponStates.lifedrain,
                icon = "LD",
                color = {1, 0.2, 0.2},
                owned = true
            })
        end
        
    elseif inventoryState.category == "mods" then
        if inventoryState.subCategory == "pistol" then
            if player.Bag.pistolMods.fastMag then
                table.insert(items, {
                    name = "Fast Pistol Mag",
                    description = "Ammo +3",
                    icon = "FM",
                    equipped = true
                })
            end
            if player.Bag.pistolMods.extMag then
                table.insert(items, {
                    name = "Extended Pistol Mag",
                    description = "Reload -0.5s",
                    icon = "EM",
                    equipped = true
                })
            end
            if player.Bag.pistolMods.damage then
                table.insert(items, {
                    name = "Pistol Damage +3",
                    description = "Damage +3",
                    icon = "D3",
                    equipped = true
                })
            end
            
        elseif inventoryState.subCategory == "rifle" then
            if player.Bag.rifleMods.fastMag then
                table.insert(items, {
                    name = "Fast Rifle Mag",
                    description = "Ammo +15",
                    icon = "FM",
                    equipped = true
                })
            end
            if player.Bag.rifleMods.extMag then
                table.insert(items, {
                    name = "Extended Rifle Mag",
                    description = "Reload -0.5s",
                    icon = "EM",
                    equipped = true
                })
            end
            if player.Bag.rifleMods.damage then
                table.insert(items, {
                    name = "Rifle Damage +2",
                    description = "Damage +2",
                    icon = "D2",
                    equipped = true
                })
            end
            
        elseif inventoryState.subCategory == "sniper" then
            if player.Bag.sniperMods.damage then
                table.insert(items, {
                    name = "Sniper Damage +10",
                    description = "Damage +10",
                    icon = "D10",
                    equipped = true
                })
            end
            if player.Bag.sniperMods.pierce then
                table.insert(items, {
                    name = "Piercing Round",
                    description = "Pierce 1 enemy",
                    icon = "PR",
                    equipped = true
                })
            end
            
        elseif inventoryState.subCategory == "soulreaper" then
            if player.Bag.soulReaperMods and player.Bag.soulReaperMods.pierce then
                table.insert(items, {
                    name = "Soul Reaper Pierce",
                    description = "Pierce 3 enemies, damage halved",
                    icon = "PP",
                    equipped = true
                })
            end
            if player.Bag.soulReaperMods and player.Bag.soulReaperMods.damage then
                table.insert(items, {
                    name = "Soul Reaper Damage +750",
                    description = "Damage +750",
                    icon = "D750",
                    equipped = true
                })
            end
            
        elseif inventoryState.subCategory == "lasergun" then
            if player.Bag.laserGunMods and player.Bag.laserGunMods.capacity then
                table.insert(items, {
                    name = "Laser Gun Capacity",
                    description = "Max charge +25",
                    icon = "LC",
                    equipped = true
                })
            end
            
        elseif inventoryState.subCategory == "feast" then
            if player.Bag.feastMods and player.Bag.feastMods.dualCore then
                table.insert(items, {
                    name = "Dual Core",
                    description = "Ammo becomes 2",
                    icon = "DC",
                    equipped = true
                })
            end
            if player.Bag.feastMods and player.Bag.feastMods.highExplosive then
                table.insert(items, {
                    name = "High Explosive",
                    description = "DoT 40/s | Explosion 2222 dmg",
                    icon = "HE",
                    equipped = true
                })
            end
            
        elseif inventoryState.subCategory == "lifedrain" then
            if player.Bag.lifedrainMods and player.Bag.lifedrainMods.extendedMag then
                table.insert(items, {
                    name = "Extended Mag",
                    description = "Ammo becomes 50",
                    icon = "EM",
                    equipped = true
                })
            end
            if player.Bag.lifedrainMods and player.Bag.lifedrainMods.soulNourish then
                table.insert(items, {
                    name = "Soul Nourish",
                    description = "30% chance heal 5 HP or +1 max HP on kill",
                    icon = "SN",
                    equipped = true
                })
            end
        end
        
    elseif inventoryState.category == "character" then
        if player.Bag.characterMods.speedWalk then
            table.insert(items, {
                name = "Speed Walk",
                description = "Walk speed +50",
                icon = "SW",
                equipped = true
            })
        end
        if player.Bag.characterMods.speedRun then
            table.insert(items, {
                name = "Speed Run",
                description = "Run speed +75",
                icon = "SR",
                equipped = true
            })
        end
    
    elseif inventoryState.category == "skills" then
        local skills = AbilitySystem:getOwnedAbilities(inventoryState.skillType)
        for _, skill in ipairs(skills) do
            table.insert(items, {
                name = skill.data.name,
                type = skill.id,
                data = skill.data,
                icon = skill.data.icon,
                color = skill.data.color,
                owned = true,
                isActive = (skill.data.type == "active"),
                isPassive = (skill.data.type == "passive")
            })
        end
        
    elseif inventoryState.category == "throwables" then
        local throwables = ThrowableSystem:getOwnedThrowables()
        for _, throwable in ipairs(throwables) do
            table.insert(items, {
                name = throwable.data.name,
                type = throwable.id,
                data = throwable.data,
                icon = throwable.data.icon,
                color = throwable.data.color,
                owned = true,
                cooldownRounds = throwable.data.cooldownRounds,
                description = throwable.data.description
            })
        end
    end

    return items
end

-- ===== 获取投掷物当前绑定的槽位 =====
function getThrowableSlot(throwableId)
    for i, tid in ipairs(player.throwables.slots) do
        if tid == throwableId then
            return i + 4
        end
    end
    return nil
end

-- ===== 绑定投掷物到指定槽位 =====
function bindThrowableToSlot(throwableId, slotIndex)
    if slotIndex < 1 or slotIndex > 3 then return end
    
    for i, tid in ipairs(player.throwables.slots) do
        if tid == throwableId then
            player.throwables.slots[i] = nil
            player.throwables.charges[i] = 0
            break
        end
    end
    
    player.throwables.slots[slotIndex] = throwableId
    player.throwables.charges[slotIndex] = 1
    
    print("Bound throwable " .. throwableId .. " to slot " .. (slotIndex + 4))
    saveHighScore()
end

-- ===== 绘制背包界面 =====
function handledrawInventory()
    local w, h = love.graphics.getDimensions()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.2)
    
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1)
    local title = "INVENTORY"
    local titleWidth = titleFont:getWidth(title)
    love.graphics.print(title, (w - titleWidth)/2, 30)
    
    love.graphics.setFont(uiFont)
    love.graphics.setColor(1, 1, 0)
    love.graphics.print("Bits: " .. maxBits, 20, 20)
    
    -- 主分类标签
    local tabWidth, tabHeight, startY = 150, 50, 90
    local spacing = 15
    local totalWidth = tabWidth * 5 + spacing * 4
    local firstX = math.max(20, (w - totalWidth) / 2)
    
    local mainCategories = {
        { name = "WEAPONS", cat = "weapons", x = firstX },
        { name = "MODS", cat = "mods", x = firstX + tabWidth + spacing },
        { name = "CHARACTER", cat = "character", x = firstX + (tabWidth + spacing) * 2 },
        { name = "SKILLS", cat = "skills", x = firstX + (tabWidth + spacing) * 3 },
        { name = "THROWABLES", cat = "throwables", x = firstX + (tabWidth + spacing) * 4 }
    }
    
    love.graphics.setFont(uiFont)
    for _, cat in ipairs(mainCategories) do
        local mx, my = love.mouse.getPosition()
        local hover = mx >= cat.x and mx <= cat.x + tabWidth and my >= startY and my <= startY + tabHeight
        
        if inventoryState.category == cat.cat then
            love.graphics.setColor(0.8, 0.8, 1)
        elseif hover then
            love.graphics.setColor(0.6, 0.6, 0.9)
        else
            love.graphics.setColor(0.4, 0.4, 0.6)
        end
        love.graphics.rectangle("fill", cat.x, startY, tabWidth, tabHeight, 10)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(cat.name, cat.x, startY + 15, tabWidth, "center")
    end
    
    -- 子分类标签
    local subY = startY + 60
    if inventoryState.category == "mods" then
        local subTabWidth, subTabHeight = 80, 35
        local subSpacing = 5
        local subTotalWidth = subTabWidth * 7 + subSpacing * 6
        local subFirstX = math.max(20, (w - subTotalWidth) / 2)
        
        local subCategories = {
            { name = "PISTOL", weapon = "pistol", x = subFirstX },
            { name = "RIFLE", weapon = "rifle", x = subFirstX + subTabWidth + subSpacing },
            { name = "SNIPER", weapon = "sniper", x = subFirstX + (subTabWidth + subSpacing) * 2 },
            { name = "SOUL", weapon = "soulreaper", x = subFirstX + (subTabWidth + subSpacing) * 3 },
            { name = "LASER", weapon = "lasergun", x = subFirstX + (subTabWidth + subSpacing) * 4 },
            { name = "FEAST", weapon = "feast", x = subFirstX + (subTabWidth + subSpacing) * 5 },
            { name = "LIFE", weapon = "lifedrain", x = subFirstX + (subTabWidth + subSpacing) * 6 }
        }
        
        for _, sub in ipairs(subCategories) do
            local hover = love.mouse.getX() >= sub.x and love.mouse.getX() <= sub.x + subTabWidth and 
                         love.mouse.getY() >= subY and love.mouse.getY() <= subY + subTabHeight
            
            if inventoryState.subCategory == sub.weapon then
                love.graphics.setColor(0.7, 0.7, 0.9)
            elseif hover then
                love.graphics.setColor(0.5, 0.5, 0.8)
            else
                love.graphics.setColor(0.3, 0.3, 0.5)
            end
            love.graphics.rectangle("fill", sub.x, subY, subTabWidth, subTabHeight, 5)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(sub.name, sub.x, subY + 8, subTabWidth, "center")
        end
        
    elseif inventoryState.category == "skills" then
        local subTabWidth, subTabHeight = 120, 35
        local subSpacing = 30
        local subTotalWidth = subTabWidth * 2 + subSpacing
        local subFirstX = math.max(20, (w - subTotalWidth) / 2)
        
        local subCategories = {
            { name = "ACTIVE", type = "active", x = subFirstX },
            { name = "PASSIVE", type = "passive", x = subFirstX + subTabWidth + subSpacing }
        }
        
        for _, sub in ipairs(subCategories) do
            local hover = love.mouse.getX() >= sub.x and love.mouse.getX() <= sub.x + subTabWidth and 
                         love.mouse.getY() >= subY and love.mouse.getY() <= subY + subTabHeight
            
            if inventoryState.skillType == sub.type then
                love.graphics.setColor(0.7, 0.7, 0.9)
            elseif hover then
                love.graphics.setColor(0.5, 0.5, 0.8)
            else
                love.graphics.setColor(0.3, 0.3, 0.5)
            end
            love.graphics.rectangle("fill", sub.x, subY, subTabWidth, subTabHeight, 5)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(sub.name, sub.x, subY + 8, subTabWidth, "center")
        end
    end
    
    -- 物品列表
    local items = getInventoryList()
    local listX, listY, listW, listH = 150, subY + 50, w - 300, h - subY - 120
    
    if #items == 0 then
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.setFont(uiFont)
        local text = "No items in this category"
        local textWidth = uiFont:getWidth(text)
        love.graphics.print(text, (w - textWidth)/2, h/2 - 50)
    else
        local itemHeight = 90
        local visibleItems = math.floor(listH / itemHeight)
        local startIdx = inventoryState.scroll + 1
        local endIdx = math.min(startIdx + visibleItems - 1, #items)
        
        if #items > visibleItems then
            local scrollBarHeight = listH * (visibleItems / #items)
            local scrollBarY = listY + (inventoryState.scroll / (#items - visibleItems)) * (listH - scrollBarHeight)
            love.graphics.setColor(0.5, 0.5, 0.7)
            love.graphics.rectangle("fill", listX + listW - 10, scrollBarY, 8, scrollBarHeight, 4)
        end
        
        for i = startIdx, endIdx do
            local item = items[i]
            if item then
                local y = listY + (i - startIdx) * itemHeight
                
                local isBinding = false
                if inventoryState.category == "weapons" and inventoryState.bindingWeapon == item.type then
                    isBinding = true
                    love.graphics.setColor(0.5, 0.5, 0.3, 0.5)
                elseif inventoryState.category == "skills" and inventoryState.bindingSkill == item.type then
                    isBinding = true
                    love.graphics.setColor(0.5, 0.3, 0.5, 0.5)
                elseif inventoryState.category == "throwables" and inventoryState.throwableBinding == item.type then
                    isBinding = true
                    love.graphics.setColor(0.3, 0.5, 0.5, 0.5)
                else
                    love.graphics.setColor(0.2, 0.2, 0.3, 0.8)
                end
                love.graphics.rectangle("fill", listX, y, listW - 20, itemHeight - 5, 10)
                
                if inventoryState.category == "weapons" then
                    love.graphics.setColor(item.color[1], item.color[2], item.color[3])
                    love.graphics.rectangle("fill", listX + 15, y + 15, 30, 30, 5)
                    
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.setFont(love.graphics.newFont(20))
                    love.graphics.print(item.icon, listX + 20, y + 17)
                    
                    love.graphics.setFont(uiFont)
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.print(item.name, listX + 55, y + 15)
                    
                    if item.type == "soulreaper" then
                        love.graphics.print("DMG: " .. item.data.damage .. " | Charge: 500", listX + 55, y + 45)
                    elseif item.type == "lasergun" then
                        love.graphics.print("DMG: " .. item.data.damage .. " | Charge: " .. math.floor(player.laserGunCharge) .. "/" .. item.data.maxCharge, listX + 55, y + 45)
                    elseif item.type == "feast" then
                        love.graphics.print("DMG: " .. item.data.damage .. " | Ammo: " .. item.data.maxAmmo .. " | 5s Explosion", listX + 55, y + 45)
                    elseif item.type == "lifedrain" then
                        love.graphics.print("DMG: " .. (10 + (player.lifedrainDamageBonus or 0)) .. " | Ammo: " .. item.data.maxAmmo, listX + 55, y + 45)
                    else
                        love.graphics.print("DMG: " .. item.data.damage .. " | Ammo: " .. item.data.maxAmmo, listX + 55, y + 45)
                    end
                    
                    local slot = getWeaponSlot(item.type)
                    if slot then
                        love.graphics.setColor(0, 1, 0)
                        love.graphics.print("[" .. slot .. "]", listX + listW - 100, y + 25)
                    end
                    
                    if isBinding then
                        love.graphics.setColor(1, 1, 0)
                        love.graphics.print("Press 1-4 to bind", listX + listW - 150, y + 55)
                    end
                    
                elseif inventoryState.category == "skills" then
                    love.graphics.setColor(item.color[1], item.color[2], item.color[3])
                    love.graphics.rectangle("fill", listX + 15, y + 15, 30, 30, 5)
                    
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.setFont(love.graphics.newFont(20))
                    love.graphics.print(item.icon, listX + 20, y + 17)
                    
                    love.graphics.setFont(uiFont)
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.print(item.name, listX + 55, y + 15)
                    
                    love.graphics.setColor(0.8, 0.8, 0.8)
                    local desc = item.data.description or ""
                    local firstLine = string.match(desc, "[^\n]+") or desc
                    love.graphics.print(firstLine, listX + 55, y + 45)
                    
                    local slot = nil
                    if item.isActive then
                        slot = getSkillSlot(item.type, "active")
                        if slot then
                            love.graphics.setColor(0, 1, 0)
                            love.graphics.print("Bound " .. string.upper(player.abilities.activeKeys[slot]), listX + listW - 150, y + 25)
                        end
                    else
                        slot = getSkillSlot(item.type, "passive")
                        if slot then
                            love.graphics.setColor(0, 1, 0)
                            love.graphics.print("Bound P" .. slot, listX + listW - 120, y + 25)
                        end
                    end
                    
                    if isBinding then
                        love.graphics.setColor(1, 1, 0)
                        if item.isActive then
                            love.graphics.print("Press Q/E/Z/X to bind", listX + listW - 180, y + 55)
                        else
                            love.graphics.print("Click again to equip", listX + listW - 150, y + 55)
                        end
                    end
                    
                elseif inventoryState.category == "throwables" then
                    love.graphics.setColor(item.color[1], item.color[2], item.color[3])
                    love.graphics.rectangle("fill", listX + 15, y + 15, 30, 30, 5)
                    
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.setFont(love.graphics.newFont(20))
                    love.graphics.print(item.icon, listX + 20, y + 17)
                    
                    love.graphics.setFont(uiFont)
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.print(item.name, listX + 55, y + 15)
                    
                    love.graphics.setColor(0.8, 0.8, 0.8)
                    love.graphics.print("Cooldown: " .. item.data.cooldownRounds .. " rounds", listX + 55, y + 45)
                    
                    local slot = getThrowableSlot(item.type)
                    if slot then
                        love.graphics.setColor(0, 1, 0)
                        love.graphics.print("[" .. slot .. "]", listX + listW - 100, y + 25)
                    end
                    
                    if isBinding then
                        love.graphics.setColor(1, 1, 0)
                        love.graphics.print("Press 5-7 to bind", listX + listW - 150, y + 55)
                    end
                    
                else
                    love.graphics.setColor(0.5, 0.5, 1, 0.3)
                    love.graphics.rectangle("fill", listX + 15, y + 15, 30, 30, 5)
                    
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.setFont(love.graphics.newFont(20))
                    love.graphics.print(item.icon, listX + 20, y + 17)
                    
                    love.graphics.setFont(uiFont)
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.print(item.name, listX + 55, y + 20)
                    
                    love.graphics.setColor(0.8, 0.8, 0.8)
                    love.graphics.print(item.description, listX + 55, y + 50)
                    
                    love.graphics.setColor(0, 1, 0)
                    love.graphics.print("OWNED", listX + listW - 120, y + 30)
                end
            end
        end
    end
    
    -- 投掷物槽位
    if inventoryState.category == "throwables" then
        local slotY = h - 80
        local slotSize = 50
        local slotSpacing = 20
        local startSlotX = (w - (slotSize * 3 + slotSpacing * 2)) / 2
        
        love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
        love.graphics.rectangle("fill", startSlotX - 20, slotY - 20, slotSize * 3 + slotSpacing * 2 + 40, slotSize + 40, 10)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(uiFont)
        love.graphics.print("Throwable Slots (5-7)", startSlotX, slotY - 40)
        
        for i = 1, 3 do
            local slotX = startSlotX + (i-1) * (slotSize + slotSpacing)
            local throwableId = player.throwables.slots[i]
            local charge = player.throwables.charges[i]
            
            if throwableId then
                local throwable = ThrowableSystem.throwables[throwableId]
                love.graphics.setColor(throwable.color[1], throwable.color[2], throwable.color[3], 0.7)
            else
                love.graphics.setColor(0.3, 0.3, 0.4, 0.5)
            end
            love.graphics.rectangle("fill", slotX, slotY, slotSize, slotSize, 10)
            
            love.graphics.setColor(1, 1, 1)
            love.graphics.setLineWidth(3)
            love.graphics.rectangle("line", slotX, slotY, slotSize, slotSize, 10)
            
            if throwableId then
                local throwable = ThrowableSystem.throwables[throwableId]
                love.graphics.setColor(1, 1, 1)
                love.graphics.setFont(love.graphics.newFont(24))
                love.graphics.print(throwable.icon, slotX + 12, slotY + 10)
                
                if charge > 0 then
                    love.graphics.setColor(0, 1, 0)
                    love.graphics.circle("fill", slotX + slotSize - 10, slotY + 10, 5)
                end
                
                love.graphics.setColor(0.8, 0.8, 0.8)
                love.graphics.setFont(love.graphics.newFont(16))
                love.graphics.print(i + 4, slotX + 18, slotY - 20)
            else
                love.graphics.setColor(0.5, 0.5, 0.5)
                love.graphics.setFont(love.graphics.newFont(24))
                love.graphics.print("?", slotX + 15, slotY + 10)
                
                love.graphics.setColor(0.8, 0.8, 0.8)
                love.graphics.setFont(love.graphics.newFont(16))
                love.graphics.print(i + 4, slotX + 18, slotY - 20)
            end
        end
        
        if inventoryState.throwableBinding then
            love.graphics.setColor(1, 1, 0, 0.5 + 0.5 * math.sin(love.timer.getTime() * 5))
            love.graphics.setFont(uiFont)
            love.graphics.print("Click a slot above to bind", startSlotX, slotY + slotSize + 20)
        end
    end
    
    -- 被动技能槽位显示（在右侧）
    if inventoryState.category == "skills" and inventoryState.skillType == "passive" then
        local passiveX = listX + listW + 20
        local passiveY = subY + 50
        local passiveW = 200
        local passiveH = 120
        
        love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
        love.graphics.rectangle("fill", passiveX, passiveY, passiveW, passiveH, 10)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(uiFont)
        love.graphics.print("Equipped Passives", passiveX + 10, passiveY + 5)
        
        for i = 1, 2 do
            local skillId = player.abilities.passiveSlots[i]
            local y = passiveY + 35 + (i-1) * 40
            
            if skillId then
                local ability = AbilitySystem.abilities[skillId]
                love.graphics.setColor(ability.color[1], ability.color[2], ability.color[3])
                love.graphics.rectangle("fill", passiveX + 10, y, 30, 30, 5)
                
                love.graphics.setColor(1, 1, 1)
                love.graphics.setFont(love.graphics.newFont(20))
                love.graphics.print(ability.icon, passiveX + 15, y + 5)
                
                love.graphics.setFont(uiFont)
                love.graphics.print(ability.name, passiveX + 50, y + 8)
                
                love.graphics.setColor(1, 0.5, 0.5)
                love.graphics.setFont(love.graphics.newFont(14))
                love.graphics.print("Click to remove", passiveX + 50, y + 25)
            else
                love.graphics.setColor(0.3, 0.3, 0.5)
                love.graphics.rectangle("fill", passiveX + 10, y, 30, 30, 5)
                
                love.graphics.setColor(0.5, 0.5, 0.5)
                love.graphics.setFont(love.graphics.newFont(20))
                love.graphics.print("?", passiveX + 15, y + 5)
                
                love.graphics.setFont(uiFont)
                love.graphics.print("Empty Slot P" .. i, passiveX + 50, y + 10)
            end
        end
    end
    
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.setFont(uiFont)
    love.graphics.print("ESC: Return | ↑/↓: Scroll | Click item to bind", 20, h - 30)
end

-- ===== 处理背包鼠标点击 =====
function handleInventoryMouse(x, y, button)
    if button ~= 1 then return end
    
    local w, h = love.graphics.getDimensions()
    
    -- 主分类标签点击
    local tabWidth, tabHeight, startY = 150, 50, 90
    local spacing = 15
    local totalWidth = tabWidth * 5 + spacing * 4
    local firstX = math.max(20, (w - totalWidth) / 2)
    
    local mainCategories = {
        { name = "WEAPONS", cat = "weapons", x = firstX },
        { name = "MODS", cat = "mods", x = firstX + tabWidth + spacing },
        { name = "CHARACTER", cat = "character", x = firstX + (tabWidth + spacing) * 2 },
        { name = "SKILLS", cat = "skills", x = firstX + (tabWidth + spacing) * 3 },
        { name = "THROWABLES", cat = "throwables", x = firstX + (tabWidth + spacing) * 4 }
    }
    
    for _, cat in ipairs(mainCategories) do
        if x >= cat.x and x <= cat.x + tabWidth and y >= startY and y <= startY + tabHeight then
            inventoryState.category = cat.cat
            inventoryState.scroll = 0
            inventoryState.bindingWeapon = nil
            inventoryState.bindingSkill = nil
            inventoryState.throwableBinding = nil
            if cat.cat ~= "mods" then
                inventoryState.subCategory = "pistol"
            end
            if cat.cat ~= "skills" then
                inventoryState.skillType = "active"
            end
            return
        end
    end
    
    -- 子分类标签点击
    local subY = startY + 60
    if inventoryState.category == "mods" then
        local subTabWidth, subTabHeight = 80, 35
        local subSpacing = 5
        local subTotalWidth = subTabWidth * 7 + subSpacing * 6
        local subFirstX = math.max(20, (w - subTotalWidth) / 2)
        
        local subCategories = {
            { weapon = "pistol", x = subFirstX },
            { weapon = "rifle", x = subFirstX + subTabWidth + subSpacing },
            { weapon = "sniper", x = subFirstX + (subTabWidth + subSpacing) * 2 },
            { weapon = "soulreaper", x = subFirstX + (subTabWidth + subSpacing) * 3 },
            { weapon = "lasergun", x = subFirstX + (subTabWidth + subSpacing) * 4 },
            { weapon = "feast", x = subFirstX + (subTabWidth + subSpacing) * 5 },
            { weapon = "lifedrain", x = subFirstX + (subTabWidth + subSpacing) * 6 }
        }
        
        for _, sub in ipairs(subCategories) do
            if x >= sub.x and x <= sub.x + subTabWidth and y >= subY and y <= subY + subTabHeight then
                inventoryState.subCategory = sub.weapon
                inventoryState.scroll = 0
                return
            end
        end
        
    elseif inventoryState.category == "skills" then
        local subTabWidth, subTabHeight = 120, 35
        local subSpacing = 30
        local subTotalWidth = subTabWidth * 2 + subSpacing
        local subFirstX = math.max(20, (w - subTotalWidth) / 2)
        
        if x >= subFirstX and x <= subFirstX + subTabWidth and y >= subY and y <= subY + subTabHeight then
            inventoryState.skillType = "active"
            inventoryState.scroll = 0
            inventoryState.bindingSkill = nil
            return
        elseif x >= subFirstX + subTabWidth + subSpacing and x <= subFirstX + subTabWidth + subSpacing + subTabWidth and y >= subY and y <= subY + subTabHeight then
            inventoryState.skillType = "passive"
            inventoryState.scroll = 0
            inventoryState.bindingSkill = nil
            return
        end
    end
    
    -- 检查被动技能槽位点击（卸下技能）
    if inventoryState.category == "skills" and inventoryState.skillType == "passive" then
        local listX, listY, listW, listH = 150, subY + 50, w - 300, h - subY - 120
        local passiveX = listX + listW + 20
        local passiveY = subY + 50
        local passiveW = 200
        
        for i = 1, 2 do
            local slotY = passiveY + 35 + (i-1) * 40
            if x >= passiveX + 10 and x <= passiveX + passiveW - 10 and y >= slotY and y <= slotY + 30 then
                unequipPassiveSkill(i)
                return
            end
        end
    end
    
    -- 投掷物槽位点击
    if inventoryState.category == "throwables" and inventoryState.throwableBinding then
        local slotY = h - 80
        local slotSize = 50
        local slotSpacing = 20
        local startSlotX = (w - (slotSize * 3 + slotSpacing * 2)) / 2
        
        for i = 1, 3 do
            local slotX = startSlotX + (i-1) * (slotSize + slotSpacing)
            if x >= slotX and x <= slotX + slotSize and y >= slotY and y <= slotY + slotSize then
                bindThrowableToSlot(inventoryState.throwableBinding, i)
                inventoryState.throwableBinding = nil
                return
            end
        end
    end
    
    -- 物品点击
    local items = getInventoryList()
    local listX, listY, listW, listH = 150, subY + 50, w - 300, h - subY - 120
    local itemHeight = 90
    local visibleItems = math.floor(listH / itemHeight)
    local startIdx = inventoryState.scroll + 1
    local endIdx = math.min(startIdx + visibleItems - 1, #items)
    
    for i = startIdx, endIdx do
        local item = items[i]
        if item then
            local itemY = listY + (i - startIdx) * itemHeight
            if x >= listX and x <= listX + listW - 20 and y >= itemY and y <= itemY + itemHeight - 5 then
                
                if inventoryState.category == "weapons" then
                    inventoryState.bindingWeapon = item.type
                    inventoryState.bindingSkill = nil
                    inventoryState.throwableBinding = nil
                    print("Selected weapon: " .. item.type .. ", press 1-4 to bind")
                    return
                    
                elseif inventoryState.category == "skills" then
                    if item.isActive then
                        print("Selected active skill: " .. item.type .. ", press Q/E/Z/X to bind")
                        inventoryState.bindingSkill = item.type
                        inventoryState.skillType = "active"
                    else
                        -- 被动技能：直接装备
                        print("Equipping passive skill: " .. item.type)
                        bindPassiveSkill(item.type)
                    end
                    inventoryState.bindingWeapon = nil
                    inventoryState.throwableBinding = nil
                    return
                    
                elseif inventoryState.category == "throwables" then
                    print("Selected throwable: " .. item.type .. ", press 5-7 or click slot to bind")
                    inventoryState.throwableBinding = item.type
                    inventoryState.bindingWeapon = nil
                    inventoryState.bindingSkill = nil
                    return
                    
                elseif inventoryState.category == "mods" or inventoryState.category == "character" then
                    print("Owned: " .. item.name)
                    return
                end
            end
        end
    end
end

-- ===== 处理背包键盘按键 =====
function handleInventoryKeys(key)
    local items = getInventoryList()
    if #items == 0 then return end
    
    local visibleItems = math.floor((love.graphics.getHeight() - 280) / 90)
    
    if key == "up" then
        inventoryState.scroll = math.max(0, inventoryState.scroll - 1)
    elseif key == "down" then
        inventoryState.scroll = math.min(#items - visibleItems, inventoryState.scroll + 1)
    end
    
    if inventoryState.bindingWeapon then
        local slotNumber = tonumber(key)
        if slotNumber and slotNumber >= 1 and slotNumber <= 4 then
            bindWeaponToSlot(inventoryState.bindingWeapon, slotNumber)
            inventoryState.bindingWeapon = nil
        elseif key == "escape" then
            inventoryState.bindingWeapon = nil
        end
    end
    
    if inventoryState.bindingSkill and inventoryState.skillType == "active" then
        if key == "q" then
            bindActiveSkillToSlot(inventoryState.bindingSkill, 1)
            inventoryState.bindingSkill = nil
        elseif key == "e" then
            bindActiveSkillToSlot(inventoryState.bindingSkill, 2)
            inventoryState.bindingSkill = nil
        elseif key == "z" then
            bindActiveSkillToSlot(inventoryState.bindingSkill, 3)
            inventoryState.bindingSkill = nil
        elseif key == "x" then
            bindActiveSkillToSlot(inventoryState.bindingSkill, 4)
            inventoryState.bindingSkill = nil
        elseif key == "escape" then
            inventoryState.bindingSkill = nil
        end
    end
    
    if inventoryState.throwableBinding then
        local slotNumber = tonumber(key)
        if slotNumber and slotNumber >= 5 and slotNumber <= 7 then
            bindThrowableToSlot(inventoryState.throwableBinding, slotNumber - 4)
            inventoryState.throwableBinding = nil
        elseif key == "escape" then
            inventoryState.throwableBinding = nil
        end
    end
end

-- ===== 处理背包鼠标滚轮 =====
function handleInventoryWheel(y)
    local items = getInventoryList()
    local visibleItems = math.floor((love.graphics.getHeight() - 280) / 90)
    
    if y > 0 then
        inventoryState.scroll = math.max(0, inventoryState.scroll - 1)
    elseif y < 0 then
        inventoryState.scroll = math.min(#items - visibleItems, inventoryState.scroll + 1)
    end
end

print("✓ inventory.lua loaded")
return {
    getInventoryList = getInventoryList,
    drawInventory = handledrawInventory,
    handleInventoryKeys = handleInventoryKeys,
    handleInventoryMouse = handleInventoryMouse,
    handleInventoryWheel = handleInventoryWheel
}