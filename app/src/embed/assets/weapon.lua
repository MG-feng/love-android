-- ============================================================================
-- weapon.lua - 管理武器、子弹、射击、重装和技能
-- ============================================================================

-- ===== 武器音效加载 =====
function loadWeaponSounds()
    for weaponType, weaponData in pairs(player.weaponStates) do
        if weaponData.shootSoundPath then
            if love.filesystem.getInfo(weaponData.shootSoundPath) then
                local success, sound = pcall(function()
                    return love.audio.newSource(weaponData.shootSoundPath, "static")
                end)
                if success then
                    sounds[weaponType .. "_shoot"] = sound
                    print("Loaded shoot sound for " .. weaponType)
                else
                    print("Failed to load shoot sound: " .. weaponData.shootSoundPath)
                end
            else
                print("Shoot sound file not found: " .. weaponData.shootSoundPath)
            end
        end
        if weaponData.reloadSoundPath then
            if love.filesystem.getInfo(weaponData.reloadSoundPath) then
                local success, sound = pcall(function()
                    return love.audio.newSource(weaponData.reloadSoundPath, "static")
                end)
                if success then
                    sounds[weaponType .. "_reload"] = sound
                    print("Loaded reload sound for " .. weaponType)
                else
                    print("Failed to load reload sound: " .. weaponData.reloadSoundPath)
                end
            else
                print("Reload sound file not found: " .. weaponData.reloadSoundPath)
            end
        end
    end
end

-- ===== 获取当前武器 =====
function getCurrentWeapon()
    if not player.weapon.equipped or not player.weapon.type then return nil end
    return player.weaponStates[player.weapon.type]
end

-- ===== 重装武器 =====
function reloadWeapon()
    local weapon = getCurrentWeapon()
    if not weapon then return end
    if weapon.isReloading then return end
    if weapon.ammo >= weapon.maxAmmo then return end
    weapon.isReloading = true
    weapon.reloadTimer = weapon.reloadTime
    playSound(player.weapon.type .. "_reload")
end

-- ===== 更新武器重装状态 =====
function updateWeaponReload(dt)
    local weapon = getCurrentWeapon()
    if weapon and weapon.isReloading then
        weapon.reloadTimer = weapon.reloadTimer - dt
        if weapon.reloadTimer <= 0 then
            weapon.isReloading = false
            weapon.ammo = weapon.maxAmmo
        end
    end
end

-- ===== 射击 =====
function shootWeapon()
    local weapon = getCurrentWeapon()
    if not weapon then return end
    if currentCooldown > 0 or weapon.isReloading then return end

    if player.weapon.type == "soulreaper" then
        if player.soulReaperCharge < 500 then
            return
        end
        player.soulReaperCharge = 0
        currentCooldown = weapon.cooldownMax
        playSound(player.weapon.type .. "_shoot")

        local dx = math.cos(currentAngle)
        local dy = math.sin(currentAngle)
        local tipX = player.x + 10 + dx * weapon.distance * 1.5
        local tipY = player.y + 10 + dy * weapon.distance * 1.5

        table.insert(bullets, {
            x = tipX, y = tipY,
            dx = dx, dy = dy,
            speed = weapon.bulletSpeed,
            damage = weapon.damage,
            size = weapon.bulletSize,
            lifetime = 2.0,
            color = weapon.color,
            pierce = weapon.pierce or false,
            maxPierce = weapon.maxPierce or 0,
            pierceCount = 0,
            sourceWeapon = "soulreaper",
            hitEnemies = {}
        })

    elseif player.weapon.type == "lasergun" then
        if player.laserGunCharge < 1 then return end
        player.laserGunCharge = player.laserGunCharge - 1
        currentCooldown = weapon.cooldownMax
        playSound(player.weapon.type .. "_shoot")
        player.lastLaserShotTime = love.timer.getTime()

        local mx, my = love.mouse.getPosition()
        local w, h = love.graphics.getDimensions()
        local worldX = mx + player.x - w/2
        local worldY = my + player.y - h/2
        local dx = worldX - (player.x + 10)
        local dy = worldY - (player.y + 10)
        local distToMouse = math.sqrt(dx*dx + dy*dy)
        if distToMouse > 0 then
            dx = dx / distToMouse
            dy = dy / distToMouse
        else
            dx, dy = 1, 0
        end

        local laserRange = 1000
        local laserWidth = 20

        for i = #enemies, 1, -1 do
            local enemy = enemies[i]
            local ex = enemy.x + enemy.size/2
            local ey = enemy.y + enemy.size/2
            local toEnemyX = ex - (player.x + 10)
            local toEnemyY = ey - (player.y + 10)
            local enemyDist = math.sqrt(toEnemyX^2 + toEnemyY^2)
            
            if enemyDist <= laserRange then
                local t = toEnemyX*dx + toEnemyY*dy
                if t > 0 then
                    local projX = (player.x + 10) + dx * t
                    local projY = (player.y + 10) + dy * t
                    local perpDist = math.sqrt((ex - projX)^2 + (ey - projY)^2)
                    if perpDist <= laserWidth then
                        local actualDamage = weapon.damage
                        
                        if enemy.type:find("boss") and player.abilities and player.abilities.passive and player.abilities.passive.dragonslayer then
                            actualDamage = actualDamage * 1.1
                        end
                        
                        if damageEnemyWithShield then
                            damageEnemyWithShield(enemy, actualDamage)
                        else
                            enemy.health = enemy.health - actualDamage
                        end

                        if enemy.health <= 0 then
                            handleEnemyDeath(enemy, "lasergun")
                        end
                    end
                end
            end
        end

    elseif player.weapon.type == "feast" then
        -- 饕宴武器
        if weapon.ammo <= 0 then return end
        weapon.ammo = weapon.ammo - 1
        currentCooldown = weapon.cooldownMax
        playSound(player.weapon.type .. "_shoot")

        local dx = math.cos(currentAngle)
        local dy = math.sin(currentAngle)
        local tipX = player.x + 10 + dx * weapon.distance * 1.5
        local tipY = player.y + 10 + dy * weapon.distance * 1.5

        -- 创建饕宴子弹
        table.insert(bullets, {
            x = tipX, y = tipY,
            dx = dx, dy = dy,
            speed = weapon.bulletSpeed,
            damage = weapon.damage,
            size = weapon.bulletSize,
            lifetime = weapon.feastDuration or 5.0,
            color = weapon.color,
            sourceWeapon = "feast",
            isFeast = true,
            feastTimer = 0,
            feastDuration = weapon.feastDuration or 5.0,
            feastRadius = weapon.feastRadius or 80,
            feastDamagePerSecond = weapon.feastDamagePerSecond or 25,
            feastExplosionDamage = weapon.feastExplosionDamage or 1000,
            active = true,
            affectedEnemies = {}
        })

    elseif player.weapon.type == "lifedrain" then
        -- 噬命武器（三连发）
        if weapon.ammo <= 0 then return end
        weapon.ammo = weapon.ammo - 1
        currentCooldown = weapon.cooldownMax
        playSound(player.weapon.type .. "_shoot")
        
        -- 创建三连发子弹
        local burstCount = weapon.burstCount or 3
        local burstDelay = weapon.burstDelay or 0.05
        
        for i = 1, burstCount do
            Timer.after((i-1) * burstDelay, function()
                if not player.isDead then
                    local dx = math.cos(currentAngle)
                    local dy = math.sin(currentAngle)
                    local tipX = player.x + 10 + dx * weapon.distance * 1.5
                    local tipY = player.y + 10 + dy * weapon.distance * 1.5
                    
                    table.insert(bullets, {
                        x = tipX, y = tipY,
                        dx = dx, dy = dy,
                        speed = weapon.bulletSpeed,
                        damage = weapon.damage + (player.lifedrainDamageBonus or 0),
                        size = weapon.bulletSize,
                        lifetime = 2.0,
                        color = weapon.color,
                        sourceWeapon = "lifedrain",
                        hitEnemies = {}
                    })
                end
            end)
        end

    else
        -- 普通武器（手枪、步枪、狙击）
        if weapon.ammo <= 0 then return end
        weapon.ammo = weapon.ammo - 1
        currentCooldown = weapon.cooldownMax
        playSound(player.weapon.type .. "_shoot")

        local dx = math.cos(currentAngle)
        local dy = math.sin(currentAngle)
        local tipX = player.x + 10 + dx * weapon.distance * 1.5
        local tipY = player.y + 10 + dy * weapon.distance * 1.5

        table.insert(bullets, {
            x = tipX, y = tipY,
            dx = dx, dy = dy,
            speed = weapon.bulletSpeed,
            damage = weapon.damage,
            size = weapon.bulletSize,
            lifetime = 2.0,
            color = weapon.color,
            pierce = weapon.pierce or false,
            sourceWeapon = player.weapon.type,
            hitEnemies = {}
        })
    end
end

-- ===== 玩家子弹更新 =====
function updateBullets(dt)
    local screenWidth = love.graphics.getWidth()
    
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        
        b.x = b.x + b.dx * b.speed * dt
        b.y = b.y + b.dy * b.speed * dt
        b.lifetime = b.lifetime - dt
        
        -- 饕宴子弹的特殊处理
        if b.isFeast then
            b.feastTimer = (b.feastTimer or 0) + dt
            
            -- 吸附效果
            local centerX = b.x
            local centerY = b.y
            local radius = b.feastRadius or 80
            local pullStrength = 400
            
            for _, enemy in ipairs(enemies) do
                local ex = enemy.x + enemy.size/2
                local ey = enemy.y + enemy.size/2
                local dx = ex - centerX
                local dy = ey - centerY
                local dist = math.sqrt(dx*dx + dy*dy)
                
                if dist < radius and dist > 5 then
                    -- 向子弹中心移动
                    local moveX = -(dx / dist) * pullStrength * dt
                    local moveY = -(dy / dist) * pullStrength * dt
                    enemy.x = enemy.x + moveX
                    enemy.y = enemy.y + moveY
                    
                    -- 每秒持续伤害
                    if not b.damageTimer then
                        b.damageTimer = 0
                    end
                    b.damageTimer = b.damageTimer + dt
                    if b.damageTimer >= 1.0 then
                        b.damageTimer = 0
                        local actualDamage = b.feastDamagePerSecond or 25
                        if damageEnemyWithShield then
                            damageEnemyWithShield(enemy, actualDamage)
                        else
                            enemy.health = enemy.health - actualDamage
                        end
                        if enemy.health <= 0 then
                            handleEnemyDeath(enemy, "feast")
                        end
                    end
                end
            end
            
            -- 检查是否爆炸
            if b.feastTimer >= (b.feastDuration or 5.0) then
                -- 先保存爆炸位置（子弹当前位置）
                local explosionX = b.x
                local explosionY = b.y
                local explosionRadius = 120
                local explosionDamage = b.feastExplosionDamage or 1000
                
                -- 1. 先对敌人造成爆炸伤害
                for j = #enemies, 1, -1 do
                    local enemy = enemies[j]
                    local ex = enemy.x + enemy.size/2
                    local ey = enemy.y + enemy.size/2
                    local dx = ex - explosionX
                    local dy = ey - explosionY
                    local dist = math.sqrt(dx*dx + dy*dy)
                    
                    if dist < explosionRadius then
                        if damageEnemyWithShield then
                            damageEnemyWithShield(enemy, explosionDamage)
                        else
                            enemy.health = enemy.health - explosionDamage
                        end
                        if enemy.health <= 0 then
                            handleEnemyDeath(enemy, "feast")
                        end
                    end
                end
                
                -- 2. 再添加爆炸特效（使用保存的位置）
                if throwableFields then
                    table.insert(throwableFields, {
                        x = explosionX,
                        y = explosionY,
                        radius = explosionRadius,
                        duration = 0.5,
                        timer = 0,
                        active = true,
                        type = "explosion",
                        update = function(self, dt)
                            self.timer = self.timer + dt
                            return self.timer >= self.duration
                        end
                    })
                end
                
                -- 3. 最后才删除子弹
                table.remove(bullets, i)
            end
            
        elseif b.lifetime <= 0 or math.abs(b.x - player.x) > screenWidth * 2 then
            table.remove(bullets, i)
            
        else
            -- 普通子弹碰撞检测
            local bulletHit = false
            local totalDamageDealt = 0
            
            for j = #enemies, 1, -1 do
                local enemy = enemies[j]
                local ex = enemy.x + enemy.size/2
                local ey = enemy.y + enemy.size/2
                local dx = b.x - ex
                local dy = b.y - ey
                local dist = math.sqrt(dx*dx + dy*dy)
                
                if dist <= enemy.size/2 + b.size then
                    local alreadyHit = false
                    if b.hitEnemies then
                        for _, hitIndex in ipairs(b.hitEnemies) do
                            if hitIndex == j then
                                alreadyHit = true
                                break
                            end
                        end
                    end

                    if not alreadyHit then
                        local actualDamage = b.damage
                        if b.sourceWeapon == "soulreaper" and b.pierceCount and b.pierceCount > 0 then
                            actualDamage = b.damage / (2^b.pierceCount)
                        end
                        
                        if enemy.type:find("boss") and player.abilities and player.abilities.passive and player.abilities.passive.dragonslayer then
                            actualDamage = actualDamage * 1.1
                        end
                        
                        totalDamageDealt = totalDamageDealt + actualDamage

                        if damageEnemyWithShield then
                            damageEnemyWithShield(enemy, actualDamage)
                        else
                            enemy.health = enemy.health - actualDamage
                        end

                        if b.pierce then
                            if not b.hitEnemies then b.hitEnemies = {} end
                            table.insert(b.hitEnemies, j)
                            if b.maxPierce then
                                b.pierceCount = (b.pierceCount or 0) + 1
                                if b.pierceCount >= b.maxPierce then
                                    table.remove(bullets, i)
                                    break
                                end
                            end
                        end

                        bulletHit = true

                        if enemy.health <= 0 then
                            handleEnemyDeath(enemy, b.sourceWeapon)
                        end
                    end

                    if not b.pierce then
                        break
                    end
                end
            end
            
            if totalDamageDealt > 0 and player.abilities and player.abilities.siphonActive then
                local healAmount = math.floor(totalDamageDealt / 2)
                player.HealthSystem.Health = math.min(player.HealthSystem.HealthMax, player.HealthSystem.Health + healAmount)
            end

            if not b.pierce and bulletHit then
                table.remove(bullets, i)
            elseif b.pierce then
                if b.lifetime <= 0 or math.abs(b.x - player.x) > screenWidth * 2 then
                    table.remove(bullets, i)
                end
            end
        end
    end
end

-- ===== 处理敌人死亡（增加噬命永久伤害）=====
function handleEnemyDeath(enemy, sourceWeapon)
    addBits(enemy.score)

    if enemy.onDeath then
        enemy.onDeath(enemy)
    end

    if sourceWeapon ~= "soulreaper" and player.Bag and player.Bag.hasSoulReaper then
        local chargeGain = math.floor(enemy.maxHealth / 2)
        player.soulReaperCharge = math.min(500, player.soulReaperCharge + chargeGain)
    end
    
    -- 嗜血被动
    if player.abilities and player.abilities.passive and player.abilities.passive.bloodthirst then
        local healAmount = 1
        if enemy.type:find("boss") then
            healAmount = 20
        end
        player.HealthSystem.Health = math.min(player.HealthSystem.HealthMax, player.HealthSystem.Health + healAmount)
    end
    
    -- 噬命武器效果：每击杀一名敌人，永久提升1点伤害
    if sourceWeapon == "lifedrain" and player.Bag.hasLifedrain then
        player.lifedrainDamageBonus = (player.lifedrainDamageBonus or 0) + 1
        player.weaponStates.lifedrain.damage = 10 + player.lifedrainDamageBonus
        
        -- 每25击杀增加1点最大生命值
        player.lifedrainKillCounter = (player.lifedrainKillCounter or 0) + 1
        if player.lifedrainKillCounter >= 25 then
            player.lifedrainKillCounter = 0
            player.HealthSystem.HealthMax = player.HealthSystem.HealthMax + 1
            player.HealthSystem.Health = player.HealthSystem.Health + 1
            print("Life Drain passive: Max HP +1")
        end
    end
    
    -- 噬命模组：噬魂滋养效果
    if sourceWeapon == "lifedrain" and player.Bag.lifedrainMods and player.Bag.lifedrainMods.soulNourish then
        if math.random() < 0.3 then
            if player.HealthSystem.Health < player.HealthSystem.HealthMax then
                player.HealthSystem.Health = math.min(player.HealthSystem.HealthMax, player.HealthSystem.Health + 5)
                print("Soul Nourish: Healed 5 HP")
            else
                player.HealthSystem.HealthMax = player.HealthSystem.HealthMax + 1
                player.HealthSystem.Health = player.HealthSystem.Health + 1
                print("Soul Nourish: Max HP +1")
            end
        end
    end
end

-- ===== 武器冷却更新 =====
function updateCooldowns(dt)
    if currentCooldown > 0 then
        currentCooldown = currentCooldown - dt
    end
end

-- ===== 音效播放 =====
function playSound(soundKey)
    local sound = sounds[soundKey]
    if sound then
        sound:stop()
        sound:play()
    end
end

-- ===== 应用背包效果 =====
function applyBagToWeapons()
    if player.Bag.pistolMods.fastMag then
        player.weaponStates.pistol.maxAmmo = (player.weaponStates.pistol.maxAmmo or 7) + 3
        player.weaponStates.pistol.ammo = player.weaponStates.pistol.maxAmmo
    end
    if player.Bag.pistolMods.extMag then
        player.weaponStates.pistol.reloadTime = math.max(0.5, (player.weaponStates.pistol.reloadTime or 2) - 0.5)
    end
    if player.Bag.pistolMods.damage then
        player.weaponStates.pistol.damage = (player.weaponStates.pistol.damage or 10) + 3
    end
    
    if player.Bag.rifleMods.fastMag then
        player.weaponStates.rifle.maxAmmo = (player.weaponStates.rifle.maxAmmo or 35) + 15
        player.weaponStates.rifle.ammo = player.weaponStates.rifle.maxAmmo
    end
    if player.Bag.rifleMods.extMag then
        player.weaponStates.rifle.reloadTime = math.max(0.5, (player.weaponStates.rifle.reloadTime or 3.4) - 0.5)
    end
    if player.Bag.rifleMods.damage then
        player.weaponStates.rifle.damage = (player.weaponStates.rifle.damage or 6) + 2
    end
    
    if player.Bag.sniperMods.damage then
        player.weaponStates.sniper.damage = (player.weaponStates.sniper.damage or 25) + 10
    end
    if player.Bag.sniperMods.pierce then
        player.weaponStates.sniper.pierce = true
    end

    if player.Bag.soulReaperMods then
        if player.Bag.soulReaperMods.pierce then
            player.weaponStates.soulreaper.pierce = true
            player.weaponStates.soulreaper.maxPierce = 3
        end
        if player.Bag.soulReaperMods.damage then
            player.weaponStates.soulreaper.damage = (player.weaponStates.soulreaper.damage or 750) + 750
        end
    end

    if player.Bag.laserGunMods then
        if player.Bag.laserGunMods.capacity then
            player.weaponStates.lasergun.maxCharge = (player.weaponStates.lasergun.maxCharge or 50) + 25
            player.laserGunCharge = player.weaponStates.lasergun.maxCharge
        end
    end
    
    -- 饕宴模组
    if player.Bag.feastMods then
        if player.Bag.feastMods.dualCore then
            player.weaponStates.feast.maxAmmo = 2
            player.weaponStates.feast.ammo = 2
        end
        if player.Bag.feastMods.highExplosive then
            player.weaponStates.feast.feastDamagePerSecond = 40
            player.weaponStates.feast.feastExplosionDamage = 2222
        end
    end
    
    -- 噬命模组
    if player.Bag.lifedrainMods then
        if player.Bag.lifedrainMods.extendedMag then
            player.weaponStates.lifedrain.maxAmmo = 50
            player.weaponStates.lifedrain.ammo = 50
        end
        -- soulNourish 效果在处理敌人死亡时触发
    end

    if player.Bag.characterMods.speedWalk then
        player.RunSystem.Walkspeed = (player.RunSystem.Walkspeed or 125) + 50
    end
    if player.Bag.characterMods.speedRun then
        player.RunSystem.Runspeed = (player.RunSystem.Runspeed or 250) + 75
    end
end

print("✓ weapon.lua loaded")
return {
    loadWeaponSounds = loadWeaponSounds,
    getCurrentWeapon = getCurrentWeapon,
    reloadWeapon = reloadWeapon,
    updateWeaponReload = updateWeaponReload,
    shootWeapon = shootWeapon,
    updateBullets = updateBullets,
    applyBagToWeapons = applyBagToWeapons,
    updateCooldowns = updateCooldowns,
    playSound = playSound,
    handleEnemyDeath = handleEnemyDeath
}