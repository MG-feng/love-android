-- ============================================================================
-- datastore.lua - 管理玩家数据保存和加载
-- ============================================================================

-- ===== 加载数据 =====
function loadHighScore()
    -- 加载钱包
    local walletSuccess, walletData = pcall(function()
        return love.filesystem.read("wallet.txt")
    end)
    if walletSuccess and walletData then
        maxBits = tonumber(walletData) or 0
    else
        maxBits = 0
    end

    -- 加载背包
    local bagSuccess, bagData = pcall(function()
        return love.filesystem.read("bag.txt")
    end)
    
    if bagSuccess and type(bagData) == "string" and bagData ~= "" then
        local parts = {}
        for v in string.gmatch(bagData, "[^,]+") do
            table.insert(parts, v == "1")
        end
        -- 按顺序赋值
        player.Bag.hasRifle = parts[1] or false
        player.Bag.hasSniper = parts[2] or false
        player.Bag.pistolMods.fastMag = parts[3] or false
        player.Bag.pistolMods.extMag = parts[4] or false
        player.Bag.pistolMods.damage = parts[5] or false
        player.Bag.rifleMods.fastMag = parts[6] or false
        player.Bag.rifleMods.extMag = parts[7] or false
        player.Bag.rifleMods.damage = parts[8] or false
        player.Bag.sniperMods.damage = parts[9] or false
        player.Bag.sniperMods.pierce = parts[10] or false
        player.Bag.characterMods.speedWalk = parts[11] or false
        player.Bag.characterMods.speedRun = parts[12] or false
        
        -- 新武器
        player.Bag.hasSoulReaper = parts[13] or false
        player.Bag.hasLaserGun = parts[14] or false
        
        -- 新武器模组
        if not player.Bag.soulReaperMods then player.Bag.soulReaperMods = {} end
        if not player.Bag.laserGunMods then player.Bag.laserGunMods = {} end
        if not player.Bag.feastMods then player.Bag.feastMods = {} end
        if not player.Bag.lifedrainMods then player.Bag.lifedrainMods = {} end
        
        player.Bag.soulReaperMods.pierce = parts[15] or false
        player.Bag.soulReaperMods.damage = parts[16] or false
        player.Bag.laserGunMods.capacity = parts[17] or false
        
        -- 新武器拥有状态
        player.Bag.hasFeast = parts[18] or false
        player.Bag.hasLifedrain = parts[19] or false
        
        -- 新武器模组
        player.Bag.feastMods.dualCore = parts[20] or false
        player.Bag.feastMods.highExplosive = parts[21] or false
        player.Bag.lifedrainMods.extendedMag = parts[22] or false
        player.Bag.lifedrainMods.soulNourish = parts[23] or false
        
        -- 投掷物拥有状态
        if not player.throwables then player.throwables = { owned = {}, slots = { nil, nil, nil }, charges = { 0, 0, 0 }, lastUsedRound = { 0, 0, 0 } } end
        player.throwables.owned["gravityAnchor"] = parts[24] or false
        player.throwables.owned["soulShard"] = parts[25] or false
        player.throwables.owned["phaseBeacon"] = parts[26] or false
    else
        -- 重置背包为初始状态
        player.Bag.hasRifle = false
        player.Bag.hasSniper = false
        player.Bag.pistolMods.fastMag = false
        player.Bag.pistolMods.extMag = false
        player.Bag.pistolMods.damage = false
        player.Bag.rifleMods.fastMag = false
        player.Bag.rifleMods.extMag = false
        player.Bag.rifleMods.damage = false
        player.Bag.sniperMods.damage = false
        player.Bag.sniperMods.pierce = false
        player.Bag.characterMods.speedWalk = false
        player.Bag.characterMods.speedRun = false
        
        -- 新武器
        player.Bag.hasSoulReaper = false
        player.Bag.hasLaserGun = false
        player.Bag.hasFeast = false
        player.Bag.hasLifedrain = false
        
        -- 新武器模组
        if not player.Bag.soulReaperMods then player.Bag.soulReaperMods = {} end
        if not player.Bag.laserGunMods then player.Bag.laserGunMods = {} end
        if not player.Bag.feastMods then player.Bag.feastMods = {} end
        if not player.Bag.lifedrainMods then player.Bag.lifedrainMods = {} end
        
        player.Bag.soulReaperMods.pierce = false
        player.Bag.soulReaperMods.damage = false
        player.Bag.laserGunMods.capacity = false
        player.Bag.feastMods.dualCore = false
        player.Bag.feastMods.highExplosive = false
        player.Bag.lifedrainMods.extendedMag = false
        player.Bag.lifedrainMods.soulNourish = false
        
        -- 投掷物
        if not player.throwables then player.throwables = { owned = {}, slots = { nil, nil, nil }, charges = { 0, 0, 0 }, lastUsedRound = { 0, 0, 0 } } end
        player.throwables.owned["gravityAnchor"] = false
        player.throwables.owned["soulShard"] = false
        player.throwables.owned["phaseBeacon"] = false
        
        print("Bag reset to defaults due to missing or invalid save file.")
    end

    -- 加载武器槽位
    local slotsSuccess, slotsData = pcall(function()
        return love.filesystem.read("slots.txt")
    end)
    if slotsSuccess and slotsData then
        local slotTypes = {}
        for v in string.gmatch(slotsData, "[^,]+") do
            table.insert(slotTypes, v == "" and nil or v)
        end
        for i = 1, 4 do
            player.weaponSlots[i] = slotTypes[i]
        end
    else
        -- 如果没有槽位文件，设置默认：手枪到槽1
        player.weaponSlots = { nil, nil, nil, nil }
        if player.Bag.hasPistol then
            player.weaponSlots[1] = "pistol"
        end
        print("No slot file found, using default.")
    end
    
    -- 加载技能数据
    local skillsSuccess, skillsData = pcall(function()
        return love.filesystem.read("skills.txt")
    end)
    
    -- 确保player.abilities存在
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
    end
    
    if skillsSuccess and skillsData and skillsData ~= "" then
        -- 格式：已拥有技能列表|主动技能槽位|被动技能槽位
        local parts = {}
        for v in string.gmatch(skillsData, "[^|]+") do
            table.insert(parts, v)
        end
        
        if #parts >= 3 then
            -- 已拥有技能列表
            if parts[1] and parts[1] ~= "" then
                for v in string.gmatch(parts[1], "[^,]+") do
                    if v and v ~= "" then
                        player.abilities.owned[v] = true
                    end
                end
            end
            
            -- 主动技能槽位
            if parts[2] then
                local activeSlots = {}
                local idx = 1
                for v in string.gmatch(parts[2], "[^,]+") do
                    activeSlots[idx] = (v ~= "" and v or nil)
                    idx = idx + 1
                end
                for i = 1, 4 do
                    player.abilities.activeSlots[i] = activeSlots[i]
                end
            end
            
            -- 被动技能槽位
            if parts[3] then
                local passiveSlots = {}
                local idx = 1
                for v in string.gmatch(parts[3], "[^,]+") do
                    passiveSlots[idx] = (v ~= "" and v or nil)
                    idx = idx + 1
                end
                for i = 1, 2 do
                    player.abilities.passiveSlots[i] = passiveSlots[i]
                end
            end
        end
    end
    
    -- 加载投掷物数据
    local throwablesSuccess, throwablesData = pcall(function()
        return love.filesystem.read("throwables.txt")
    end)
    
    if throwablesSuccess and throwablesData and throwablesData ~= "" then
        -- 格式：投掷物槽位|充能|最后使用回合
        local parts = {}
        for v in string.gmatch(throwablesData, "[^|]+") do
            table.insert(parts, v)
        end
        
        if #parts >= 3 then
            -- 投掷物槽位
            if parts[1] then
                local slots = {}
                local idx = 1
                for v in string.gmatch(parts[1], "[^,]+") do
                    slots[idx] = (v ~= "" and v or nil)
                    idx = idx + 1
                end
                for i = 1, 3 do
                    player.throwables.slots[i] = slots[i]
                end
            end
            
            -- 充能
            if parts[2] then
                local charges = {}
                local idx = 1
                for v in string.gmatch(parts[2], "[^,]+") do
                    charges[idx] = tonumber(v) or 0
                    idx = idx + 1
                end
                for i = 1, 3 do
                    player.throwables.charges[i] = charges[i] or 0
                end
            end
            
            -- 最后使用回合
            if parts[3] then
                local rounds = {}
                local idx = 1
                for v in string.gmatch(parts[3], "[^,]+") do
                    rounds[idx] = tonumber(v) or 0
                    idx = idx + 1
                end
                for i = 1, 3 do
                    player.throwables.lastUsedRound[i] = rounds[i] or 0
                end
            end
        end
    end
    
    -- 应用已装备的被动技能效果
    if player.abilities then
        for i = 1, 2 do
            local abilityId = player.abilities.passiveSlots[i]
            if abilityId and AbilitySystem and AbilitySystem.abilities[abilityId] and AbilitySystem.abilities[abilityId].onEquip then
                AbilitySystem.abilities[abilityId].onEquip()
            end
        end
    end
end

-- ===== 保存数据 =====
function saveHighScore()
    -- 保存钱包
    pcall(function()
        love.filesystem.write("wallet.txt", tostring(maxBits))
    end)
    
    -- 保存背包
    local bagStr = ""
    bagStr = bagStr .. (player.Bag.hasRifle and "1" or "0") .. ","
    bagStr = bagStr .. (player.Bag.hasSniper and "1" or "0") .. ","
    bagStr = bagStr .. (player.Bag.pistolMods.fastMag and "1" or "0") .. ","
    bagStr = bagStr .. (player.Bag.pistolMods.extMag and "1" or "0") .. ","
    bagStr = bagStr .. (player.Bag.pistolMods.damage and "1" or "0") .. ","
    bagStr = bagStr .. (player.Bag.rifleMods.fastMag and "1" or "0") .. ","
    bagStr = bagStr .. (player.Bag.rifleMods.extMag and "1" or "0") .. ","
    bagStr = bagStr .. (player.Bag.rifleMods.damage and "1" or "0") .. ","
    bagStr = bagStr .. (player.Bag.sniperMods.damage and "1" or "0") .. ","
    bagStr = bagStr .. (player.Bag.sniperMods.pierce and "1" or "0") .. ","
    bagStr = bagStr .. (player.Bag.characterMods.speedWalk and "1" or "0") .. ","
    bagStr = bagStr .. (player.Bag.characterMods.speedRun and "1" or "0") .. ","
    
    -- 新武器
    bagStr = bagStr .. (player.Bag.hasSoulReaper and "1" or "0") .. ","
    bagStr = bagStr .. (player.Bag.hasLaserGun and "1" or "0") .. ","
    
    -- 新武器模组
    local soulPierce = player.Bag.soulReaperMods and player.Bag.soulReaperMods.pierce or false
    local soulDamage = player.Bag.soulReaperMods and player.Bag.soulReaperMods.damage or false
    local laserCapacity = player.Bag.laserGunMods and player.Bag.laserGunMods.capacity or false
    
    bagStr = bagStr .. (soulPierce and "1" or "0") .. ","
    bagStr = bagStr .. (soulDamage and "1" or "0") .. ","
    bagStr = bagStr .. (laserCapacity and "1" or "0") .. ","
    
    -- 饕宴和噬命武器拥有状态
    bagStr = bagStr .. (player.Bag.hasFeast and "1" or "0") .. ","
    bagStr = bagStr .. (player.Bag.hasLifedrain and "1" or "0") .. ","
    
    -- 饕宴模组
    local feastDual = player.Bag.feastMods and player.Bag.feastMods.dualCore or false
    local feastHigh = player.Bag.feastMods and player.Bag.feastMods.highExplosive or false
    bagStr = bagStr .. (feastDual and "1" or "0") .. ","
    bagStr = bagStr .. (feastHigh and "1" or "0") .. ","
    
    -- 噬命模组
    local lifedrainExt = player.Bag.lifedrainMods and player.Bag.lifedrainMods.extendedMag or false
    local lifedrainSoul = player.Bag.lifedrainMods and player.Bag.lifedrainMods.soulNourish or false
    bagStr = bagStr .. (lifedrainExt and "1" or "0") .. ","
    bagStr = bagStr .. (lifedrainSoul and "1" or "0") .. ","
    
    -- 投掷物拥有状态
    local gravityOwned = player.throwables and player.throwables.owned and player.throwables.owned["gravityAnchor"] or false
    local soulShardOwned = player.throwables and player.throwables.owned and player.throwables.owned["soulShard"] or false
    local phaseOwned = player.throwables and player.throwables.owned and player.throwables.owned["phaseBeacon"] or false
    
    bagStr = bagStr .. (gravityOwned and "1" or "0") .. ","
    bagStr = bagStr .. (soulShardOwned and "1" or "0") .. ","
    bagStr = bagStr .. (phaseOwned and "1" or "0")
    
    pcall(function()
        love.filesystem.write("bag.txt", bagStr)
    end)

    -- 保存武器槽位（4个槽位）
    local slotStrs = {}
    for i = 1, 4 do
        slotStrs[i] = player.weaponSlots[i] or ""
    end
    local slotsStr = table.concat(slotStrs, ",")
    pcall(function()
        love.filesystem.write("slots.txt", slotsStr)
    end)
    
    -- 保存技能数据
    if player.abilities then
        -- 已拥有技能列表
        local ownedStr = ""
        local first = true
        for id, owned in pairs(player.abilities.owned) do
            if owned then
                if not first then
                    ownedStr = ownedStr .. ","
                end
                ownedStr = ownedStr .. id
                first = false
            end
        end
        
        -- 主动技能槽位
        local activeStr = ""
        for i = 1, 4 do
            activeStr = activeStr .. (player.abilities.activeSlots[i] or "") .. (i < 4 and "," or "")
        end
        
        -- 被动技能槽位
        local passiveStr = ""
        for i = 1, 2 do
            passiveStr = passiveStr .. (player.abilities.passiveSlots[i] or "") .. (i < 2 and "," or "")
        end
        
        local skillsStr = ownedStr .. "|" .. activeStr .. "|" .. passiveStr
        pcall(function()
            love.filesystem.write("skills.txt", skillsStr)
        end)
    end
    
    -- 保存投掷物数据
    if player.throwables then
        -- 投掷物槽位
        local slotsStr = ""
        for i = 1, 3 do
            slotsStr = slotsStr .. (player.throwables.slots[i] or "") .. (i < 3 and "," or "")
        end
        
        -- 充能
        local chargesStr = ""
        for i = 1, 3 do
            chargesStr = chargesStr .. (player.throwables.charges[i] or 0) .. (i < 3 and "," or "")
        end
        
        -- 最后使用回合
        local roundsStr = ""
        for i = 1, 3 do
            roundsStr = roundsStr .. (player.throwables.lastUsedRound[i] or 0) .. (i < 3 and "," or "")
        end
        
        local throwablesStr = slotsStr .. "|" .. chargesStr .. "|" .. roundsStr
        pcall(function()
            love.filesystem.write("throwables.txt", throwablesStr)
        end)
    end
    
    print("Game data saved")
end

-- ===== 添加比特 =====
function addBits(points)
    if not points or points <= 0 then 
        return 
    end
    
    -- 确保变量存在
    if not maxBits then maxBits = 0 end
    if not bits then bits = 0 end
    
    maxBits = maxBits + points
    bits = bits + points
    
    return true
end

-- ===== 重置所有数据（用于调试）=====
function resetAllData()
    -- 删除所有保存文件
    pcall(function() love.filesystem.remove("wallet.txt") end)
    pcall(function() love.filesystem.remove("bag.txt") end)
    pcall(function() love.filesystem.remove("slots.txt") end)
    pcall(function() love.filesystem.remove("skills.txt") end)
    pcall(function() love.filesystem.remove("throwables.txt") end)
    
    -- 重置玩家背包
    player.Bag.hasRifle = false
    player.Bag.hasSniper = false
    player.Bag.hasSoulReaper = false
    player.Bag.hasLaserGun = false
    player.Bag.hasFeast = false
    player.Bag.hasLifedrain = false
    player.Bag.pistolMods.fastMag = false
    player.Bag.pistolMods.extMag = false
    player.Bag.pistolMods.damage = false
    player.Bag.rifleMods.fastMag = false
    player.Bag.rifleMods.extMag = false
    player.Bag.rifleMods.damage = false
    player.Bag.sniperMods.damage = false
    player.Bag.sniperMods.pierce = false
    player.Bag.characterMods.speedWalk = false
    player.Bag.characterMods.speedRun = false
    
    -- 重置新武器模组
    if player.Bag.soulReaperMods then
        player.Bag.soulReaperMods.pierce = false
        player.Bag.soulReaperMods.damage = false
    end
    if player.Bag.laserGunMods then
        player.Bag.laserGunMods.capacity = false
    end
    if player.Bag.feastMods then
        player.Bag.feastMods.dualCore = false
        player.Bag.feastMods.highExplosive = false
    end
    if player.Bag.lifedrainMods then
        player.Bag.lifedrainMods.extendedMag = false
        player.Bag.lifedrainMods.soulNourish = false
    end
    
    -- 重置技能
    player.abilities.owned = {}
    player.abilities.activeSlots = { nil, nil, nil, nil }
    player.abilities.passiveSlots = { nil, nil }
    
    -- 重置投掷物
    player.throwables.owned = {}
    player.throwables.slots = { nil, nil, nil }
    player.throwables.charges = { 0, 0, 0 }
    player.throwables.lastUsedRound = { 0, 0, 0 }
    
    -- 重置钱包
    maxBits = 0
    bits = 0
    
    print("All data has been reset!")
end

print("✓ datastore.lua loaded")
return {
    loadHighScore = loadHighScore,
    saveHighScore = saveHighScore,
    addBits = addBits,
    resetAllData = resetAllData
}