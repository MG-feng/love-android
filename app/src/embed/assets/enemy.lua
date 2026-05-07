-- ============================================================================
-- enemy.lua - 管理敌人、波次、护盾等（精简优化版）
-- ============================================================================
local info = require("info")

-- ===== 全局敌人列表 =====
enemies = {}
enemyBullets = {}
enemySpawnTimer = 0.5
enemySpawnQueue = {}

-- ===== 波次系统 =====
wave = {
    current = 1,
    isActive = false,
    enemiesToSpawn = 0,
    waveTimer = 0,
    waveBreakTime = 5.0,
    isBossWave = false,
    mode = "easy",
    reward = 0,
    maxWaves = { easy = 10, medium = 15, hard = 20, endless = 100, bossrush = 8 }
}

-- ===== 敌人基础类型 =====
local enemyTypesBase = {
    basic = { name="Basic", size=20, speed=180, health=30, color={1,0,0}, damage=10, score=5, canHaveShield=true },
    fast  = { name="Fast",  size=15, speed=300, health=20, color={1,0.5,0}, damage=8, score=10, canHaveShield=true },
    tank  = { name="Tank",  size=30, speed=90,  health=80, color={0.5,0,0}, damage=30, score=20, canHaveShield=true },
    elite = {
        name="Elite", size=25, speed=220, health=80, color={1,0,1}, damage=20, score=30, canHaveShield=true,
        onUpdate = function(e,dt)
            e.shootTimer = (e.shootTimer or 0) + dt
            if e.shootTimer >= 1.5 then e.shootTimer=0; shootEnemyBullet(e, e.damage) end
        end
    },
    assault = {
        name="Assault", size=20, speed=280, health=50, color={1,0.2,0.2}, damage=15, score=20, canHaveShield=true,
        onUpdate = function(e,dt)
            e.shootTimer = (e.shootTimer or 0) + dt
            if e.shootTimer >= 0.8 then e.shootTimer=0; for i=1,2 do shootEnemyBullet(e, e.damage) end end
        end
    },
    suicider = {
        name="Suicider", size=18, speed=350, health=15, color={1,1,0}, damage=40, score=15, canHaveShield=false, explosionRange=50,
        onSpawn = function(e) e.exploding=false; e.explodeTimer=0 end,
        onUpdate = function(e,dt)
            local dx,dy = getDirectionToPlayerWithObstacle(e)
            local dist = math.sqrt((player.x+10-e.x)^2 + (player.y+10-e.y)^2)
            if dist < e.explosionRange then
                if not e.exploding then e.exploding=true; e.explodeTimer=0.5 end
                e.explodeTimer = e.explodeTimer - dt
                if e.explodeTimer <= 0 then
                    if dist < e.explosionRange then player.HealthSystem.Health = player.HealthSystem.Health - e.damage end
                    return true
                end
            else
                e.exploding = false
            end
            if dist > 0 then e.x = e.x + dx * e.speed * dt; e.y = e.y + dy * e.speed * dt end
            return false
        end
    },
    splitter = {
        name="Splitter", size=22, speed=200, health=40, color={0,1,0.5}, damage=12, score=20, canHaveShield=false,
        onDeath = function(e)
            for i=1,2 do
                table.insert(enemies, {
                    type="splitter_small", name="Small Splitter", size=12, speed=250, health=15, maxHealth=15,
                    color={0,0.8,0.4}, damage=6, score=5, x=e.x+math.random(-10,10), y=e.y+math.random(-10,10),
                    onUpdate=function() end, onDeath=function() end
                })
            end
        end
    },
    healer = {
        name="Healer", size=25, speed=120, health=50, color={0,1,0}, damage=5, score=30, canHaveShield=true,
        healRadius=100, healAmount=5, healCooldown=2.0,
        onSpawn = function(e) e.healTimer=0 end,
        onUpdate = function(e,dt)
            e.healTimer = (e.healTimer or 0) + dt
            if e.healTimer >= e.healCooldown then
                e.healTimer = 0
                for _, other in ipairs(enemies) do
                    if other ~= e and other.health > 0 then
                        local dx,dy = other.x-e.x, other.y-e.y
                        if math.sqrt(dx*dx+dy*dy) < e.healRadius then
                            other.health = math.min(other.maxHealth, other.health + e.healAmount)
                        end
                    end
                end
            end
        end
    },
    shielder = {
        name="Shielder", size=28, speed=150, health=70, color={0.5,0.5,1}, damage=15, score=25, canHaveShield=true,
        onSpawn = function(e) e.shieldDirection=1 end,
        onUpdate = function(e,dt)
            e.shieldDirection = (player.x+10 - e.x > 0) and 1 or -1
        end
    },
    sniper = {
        name="Sniper", size=20, speed=80, health=40, color={0.8,0.2,0.8}, damage=35, score=30, canHaveShield=true,
        shootCooldown=3.0, bulletSpeed=800, bulletSize=6, bulletColor={1,0,1}, bulletDamage=35,
        onSpawn = function(e) e.shootTimer=0 end,
        onUpdate = function(e,dt)
            e.shootTimer = (e.shootTimer or 0) - dt
            if e.shootTimer <= 0 then e.shootTimer = e.shootCooldown; shootEnemyBullet(e, e.bulletDamage) end
        end
    },
    summoner = {
        name="Summoner", size=30, speed=100, health=60, color={1,0.5,0}, damage=10, score=40, canHaveShield=true,
        summonCooldown=5.0,
        onSpawn = function(e) e.summonTimer=0 end,
        onUpdate = function(e,dt)
            e.summonTimer = (e.summonTimer or 0) + dt
            if e.summonTimer >= e.summonCooldown then
                e.summonTimer = 0
                table.insert(enemies, {
                    type="summoned", name="Minion", size=15, speed=200, health=15, maxHealth=15,
                    color={1,0.3,0.3}, damage=8, score=5, x=e.x+math.random(-20,20), y=e.y+math.random(-20,20),
                    onUpdate=function() end, onDeath=function() end
                })
            end
        end
    },
    ghost = {
        name="Ghost", size=20, speed=180, health=30, color={0.8,0.8,1,0.5}, damage=12, score=25, canHaveShield=false,
        onSpawn = function(e) e.phaseShift=false; e.phaseTimer=0 end,
        onUpdate = function(e,dt)
            e.phaseTimer = (e.phaseTimer or 0) + dt
            if e.phaseTimer >= 2 then
                e.phaseTimer = 0
                e.phaseShift = not e.phaseShift
                e.color = e.phaseShift and {0.8,0.8,1,0.2} or {0.8,0.8,1,0.8}
            end
            return false
        end
    },    -- Boss 类型
    boss_easy = {
        name="ES-BOSS", size=50, speed=70, health=300, color={0.8,0,0.8}, damage=40, score=100, canHaveShield=true,
        shootCooldown=2.0, bulletSpeed=400, bulletSize=8, bulletColor={1,0,1}, bulletDamage=15,
        onSpawn = function(e) print("EASY BOSS SPAWNED!") end,
        onUpdate = function(e,dt)
            e.shootTimer = (e.shootTimer or 0) - dt
            if e.shootTimer <= 0 then e.shootTimer = e.shootCooldown; shootEnemyBullet(e, e.bulletDamage) end
        end,
        onDeath = function(e) print("EASY BOSS DEFEATED!") end
    },
    boss_medium = {
        name="MD-BOSS", size=60, speed=65, health=700, color={0.9,0.2,0.9}, damage=60, score=150, canHaveShield=true,
        shootCooldown=1.5, bulletSpeed=500, bulletSize=10, bulletColor={1,0.5,1}, bulletDamage=20,
        onSpawn = function(e) print("MEDIUM BOSS SPAWNED!") end,
        onUpdate = function(e,dt)
            e.shootTimer = (e.shootTimer or 0) - dt
            if e.shootTimer <= 0 then
                e.shootTimer = e.shootCooldown
                for i=1,3 do shootEnemyBullet(e, e.bulletDamage) end
            end
        end,
        onDeath = function(e) print("MEDIUM BOSS DEFEATED!") end
    },
    boss_hard = {
        name="HD-BOSS", size=70, speed=60, health=1500, color={1,0.3,0.3}, damage=80, score=200, canHaveShield=true,
        shootCooldown=1.2, bulletSpeed=600, bulletSize=12, bulletColor={1,0.2,0.2}, bulletDamage=25,
        onSpawn = function(e) e.phase=1; e.phaseTimer=0; print("HARD BOSS SPAWNED!") end,
        onUpdate = function(e,dt)
            e.phaseTimer = (e.phaseTimer or 0) + dt
            if e.phaseTimer >= 8 then e.phaseTimer=0; e.phase = (e.phase % 3) + 1 end
            e.shootTimer = (e.shootTimer or 0) - dt
            if e.shootTimer <= 0 then
                if e.phase == 1 then
                    e.shootTimer = 1.0; shootEnemyBullet(e, e.bulletDamage)
                elseif e.phase == 2 then
                    e.shootTimer = 1.5
                    for _, offset in ipairs({-0.3,0,0.3}) do
                        local dx,dy = player.x+10 - e.x, player.y+10 - e.y
                        local dist = math.sqrt(dx*dx+dy*dy)
                        if dist > 0 then dx,dy = dx/dist, dy/dist end
                        local angle = math.atan2(dy,dx) + offset
                        table.insert(enemyBullets, {
                            x=e.x+e.size/2, y=e.y+e.size/2, dx=math.cos(angle), dy=math.sin(angle),
                            speed=e.bulletSpeed, damage=e.bulletDamage, size=e.bulletSize-2,
                            color={1,0.5,0}, lifetime=2.5
                        })
                    end
                else
                    e.shootTimer = 2.0
                    for i=1,8 do
                        local angle = (i/8)*math.pi*2
                        table.insert(enemyBullets, {
                            x=e.x+e.size/2, y=e.y+e.size/2, dx=math.cos(angle), dy=math.sin(angle),
                            speed=350, damage=e.bulletDamage-5, size=e.bulletSize-4,
                            color={1,0.8,0}, lifetime=2.0
                        })
                    end
                end
            end
        end,
        onDeath = function(e) print("HARD BOSS DEFEATED!") end
    },
    finalBoss_Phase1 = {
        name="???", size=100, speed=40, health=5000, color={0,0,0}, damage=100, score=1000, canHaveShield=true,
        onSpawn = function(e) e.phase=1; e.phaseTimer=0; e.invulnerable=false; print("!!! FINAL BOSS SPAWNED !!!") end,
        onUpdate = function(e,dt)
            e.phaseTimer = e.phaseTimer + dt
            local hp = e.health/e.maxHealth
            if hp > 0.75 then e.phase=1
            elseif hp > 0.5 then e.phase=2
            elseif hp > 0.25 then e.phase=3
            else e.phase=4 end
            if e.phase == 1 then
                if e.phaseTimer >= 1.5 then
                    e.phaseTimer = 0
                    for i=1,3 do
                        local angle = (i/3)*math.pi*2 + math.random(-0.2,0.2)
                        table.insert(enemyBullets, {
                            x=e.x+e.size/2, y=e.y+e.size/2, dx=math.cos(angle), dy=math.sin(angle),
                            speed=400, damage=40, size=10, color={1,0,0}, lifetime=3.0,
                            isHoming=true, homingStrength=0.02
                        })
                    end
                end
            elseif e.phase == 2 then
                if e.phaseTimer >= 3 then
                    e.phaseTimer = 0
                    for i=1,4 do
                        table.insert(enemies, {
                            type="boss_minion", name="Minion", size=20, speed=200, health=50, maxHealth=50,
                            color={0.5,0,0.5}, damage=20, score=20,
                            x=e.x+math.random(-50,50), y=e.y+math.random(-50,50), onUpdate=function() end, onDeath=function() end
                        })
                    end
                end
            elseif e.phase == 3 then
                if e.phaseTimer >= 0.2 then
                    e.phaseTimer = 0
                    for i=1,12 do
                        local angle = (i/12)*math.pi*2
                        table.insert(enemyBullets, {
                            x=e.x+e.size/2, y=e.y+e.size/2, dx=math.cos(angle), dy=math.sin(angle),
                            speed=350, damage=30, size=8, color={1,1,0}, lifetime=2.5
                        })
                    end
                end
            else
                if e.phaseTimer >= 0.5 then
                    e.phaseTimer = 0
                    for i=1,5 do
                        local angle = math.atan2(player.y+10 - e.y, player.x+10 - e.x) + math.random(-0.3,0.3)
                        table.insert(enemyBullets, {
                            x=e.x+e.size/2, y=e.y+e.size/2, dx=math.cos(angle), dy=math.sin(angle),
                            speed=600, damage=50, size=12, color={1,0,0}, lifetime=2.0
                        })
                    end
                end
                e.speed = 60
            end
        end,
        onDeath = function(e) print("!!! FINAL BOSS PHASE 1 DEFEATED !!!"); addBits(1000) end
    },
    boss_summoner = {
        name="Summoner Boss", size=60, speed=50, health=1200, color={0.8,0.2,0.8}, damage=30, score=200, canHaveShield=true,
        shootCooldown=2.0, bulletSpeed=400, bulletSize=10, bulletColor={1,0,1}, bulletDamage=25, summonCooldown=6.0,
        onSpawn = function(e) e.shootTimer=0; e.summonTimer=0; e.summonCooldown=6.0; print("Summoner Boss spawned!") end,
        onUpdate = function(e,dt)
            e.shootTimer = (e.shootTimer or 0) - dt
            if e.shootTimer <= 0 then e.shootTimer = e.shootCooldown; shootEnemyBullet(e, e.bulletDamage) end
            e.summonTimer = (e.summonTimer or 0) + dt
            if e.summonTimer >= e.summonCooldown then
                e.summonTimer = 0
                for i=1,2 do
                    local minionType = math.random() < 0.5 and "elite" or "assault"
                    local base = enemyTypes[minionType]
                    table.insert(enemies, {
                        type=minionType, name=base.name, size=base.size, speed=base.speed,
                        health=base.health, maxHealth=base.health, color=base.color, damage=base.damage, score=base.score,
                        x=e.x+math.random(-50,50), y=e.y+math.random(-50,50), canHaveShield=base.canHaveShield,
                        onSpawn=base.onSpawn, onUpdate=base.onUpdate, onDeath=base.onDeath
                    })
                end
            end
        end,
        onDeath = function(e) print("Summoner Boss defeated!"); addBits(200) end
    },
    boss_sniper = {
        name="Sniper Boss", size=50, speed=40, health=800, color={1,0.5,0}, damage=50, score=200, canHaveShield=true,
        shootCooldown=3.5, bulletSpeed=1200, bulletSize=14, bulletColor={1,0.5,0}, bulletDamage=60,
        onSpawn = function(e) e.shootTimer=0; print("Sniper Boss spawned!") end,
        onUpdate = function(e,dt)
            e.shootTimer = (e.shootTimer or 0) - dt
            if e.shootTimer <= 0 then
                e.shootTimer = e.shootCooldown
                for i=1,3 do
                    local angleOffset = (i-2)*0.1
                    local dx,dy = player.x+10 - e.x, player.y+10 - e.y
                    local dist = math.sqrt(dx*dx+dy*dy)
                    if dist > 0 then dx,dy = dx/dist, dy/dist end
                    local angle = math.atan2(dy,dx) + angleOffset
                    table.insert(enemyBullets, {
                        x=e.x+e.size/2, y=e.y+e.size/2, dx=math.cos(angle), dy=math.sin(angle),
                        speed=e.bulletSpeed, damage=e.bulletDamage, size=e.bulletSize,
                        color=e.bulletColor, lifetime=3.0
                    })
                end
            end
        end,
        onDeath = function(e) print("Sniper Boss defeated!"); addBits(200) end
    },
    boss_phantom = {
        name="Phantom Boss", size=55, speed=60, health=1000, color={0.5,0.5,1,0.8}, damage=35, score=250, canHaveShield=false,
        shootCooldown=1.8, bulletSpeed=500, bulletSize=12, bulletColor={0.5,0.5,1}, bulletDamage=30,
        teleportCooldown=4.0, invulnerableAfterTeleport=0.5,
        onSpawn = function(e)
            e.shootTimer=0; e.teleportTimer=0; e.invulnerableTimer=0; e.invulnerable=false;
            e.teleportCooldown=4.0; e.invulnerableAfterTeleport=0.5; print("Phantom Boss spawned!")
        end,
        onUpdate = function(e,dt)
            e.shootTimer = (e.shootTimer or 0) - dt
            if e.shootTimer <= 0 then e.shootTimer = e.shootCooldown; shootEnemyBullet(e, e.bulletDamage) end
            e.teleportTimer = (e.teleportTimer or 0) + dt
            if e.teleportTimer >= e.teleportCooldown then
                e.teleportTimer = 0
                local angle = math.random() * 2 * math.pi
                local dist = math.random(100,200)
                local newX = player.x + 10 + math.cos(angle) * dist
                local newY = player.y + 10 + math.sin(angle) * dist
                newX = math.max(mapMinX + e.size, math.min(mapMaxX - e.size, newX))
                newY = math.max(mapMinY + e.size, math.min(mapMaxY - e.size, newY))
                e.x = newX; e.y = newY
                e.invulnerableTimer = e.invulnerableAfterTeleport
                e.color = {0.5,0.5,1,0.3}
            end
            if e.invulnerableTimer > 0 then
                e.invulnerable = true
                e.invulnerableTimer = e.invulnerableTimer - dt
                if e.invulnerableTimer <= 0 then e.invulnerable = false; e.color = {0.5,0.5,1,0.8} end
            else
                e.invulnerable = false
            end
        end,
        onDeath = function(e) print("Phantom Boss defeated!"); addBits(250) end
    },    -- 最终Boss第二形态弱点
    boss_final_weakpoint = {
        name = "Core", size = 30, speed = 0, health = 5000, color = {1,0.9,0,0.9}, damage = 0, score = 0, canHaveShield = false,
        onSpawn = function(e) e.parentBoss = nil; e.alpha = 1; e.pulse = 0 end,
        onUpdate = function(e, dt)
            if e.parentBoss then
                e.x = e.parentBoss.x + e.parentBoss.size/2 - e.size/2
                e.y = e.parentBoss.y - 40
            end
            e.pulse = e.pulse + dt * 5
            e.alpha = 0.7 + math.sin(e.pulse) * 0.3
            e.color = {1, 0.9, 0, e.alpha}
        end,
        onDeath = function(e) if e.parentBoss and e.parentBoss.onWeakpointDeath then e.parentBoss:onWeakpointDeath() end end
    },

    -- 最终Boss第二形态
    boss_final_phase2 = {
        name = "??? (Phase 2)", size = 150, speed = 0, health = 400000, color = {0.2,0.1,0.3,1}, damage = 0, score = 5000, canHaveShield = false,
        onSpawn = function(e)
            print("!!! FINAL BOSS PHASE 2 SPAWNED !!!")
            e.x = 0; e.y = mapMinY + 100; e.size = 150
            e.parts = {}
            for i = 1, 6 do
                table.insert(e.parts, { offsetX = math.random(-40,40), offsetY = math.random(-40,40), size = 20, angle = math.random()*math.pi*2 })
            end
            e.skillTimer = 0; e.skillCooldown = 2.0; e.rageMode = false; e.weakpointRespawnTimer = 0; e.currentWeakpoint = nil; e.pulsePhase = 0
            local weak = spawnEnemy("boss_final_weakpoint")
            if weak then weak.x = e.x + e.size/2 - weak.size/2; weak.y = e.y - 40; weak.parentBoss = e; e.currentWeakpoint = weak; print("Weakpoint spawned!") end
        end,
        onUpdate = function(e, dt)
            e.health = math.min(e.maxHealth, e.health + 500 * dt)
            if not e.rageMode and e.health / e.maxHealth < 0.3 then e.rageMode = true; print("!!! BOSS ENRAGED !!!") end
            e.skillTimer = e.skillTimer - dt
            if e.skillTimer <= 0 then
                local skillIndex = math.random(1,5)
                e.skillCooldown = e.rageMode and 1.0 or 2.0
                e:useSkill(skillIndex, e.rageMode)
                e.skillTimer = e.skillCooldown
            end
            if e.currentWeakpoint == nil and e.weakpointRespawnTimer > 0 then
                e.weakpointRespawnTimer = e.weakpointRespawnTimer - dt
                if e.weakpointRespawnTimer <= 0 then
                    local weak = spawnEnemy("boss_final_weakpoint")
                    if weak then weak.x = e.x + e.size/2 - weak.size/2; weak.y = e.y - 40; weak.parentBoss = e; e.currentWeakpoint = weak; print("Weakpoint respawned!") end
                end
            end
            if e.parts then for _, part in ipairs(e.parts) do part.angle = part.angle + dt * 2 end end
            e.pulsePhase = e.pulsePhase + dt * 3
        end,
        onDeath = function(e)
            print("!!! FINAL BOSS PHASE 2 DEFEATED !!!")
            addBits(5000)
            if e.currentWeakpoint then for i = #enemies,1,-1 do if enemies[i] == e.currentWeakpoint then table.remove(enemies,i); break end end end
        end,
        onWeakpointDeath = function(e)
            local damage = e.maxHealth * 0.1
            e.health = math.max(0, e.health - damage)
            print("Weakpoint destroyed! Boss takes " .. damage .. " damage!")
            e.currentWeakpoint = nil
            e.weakpointRespawnTimer = 10.0
        end,
        useSkill = function(e, skillIndex, enraged)
            local centerX, centerY = e.x + e.size/2, e.y + e.size/2
            local px, py = player.x + 10, player.y + 10
            local mult = enraged and 1.5 or 1.0
            if skillIndex == 1 then  -- 散弹
                for i = -2,2 do
                    local angle = math.atan2(py - centerY, px - centerX) + i * 0.15
                    local dx, dy = math.cos(angle), math.sin(angle)
                    table.insert(enemyBullets, { x=centerX, y=centerY, dx=dx, dy=dy, speed=500, damage=30*mult, size=8, color={1,0.3,0.3}, lifetime=3.0 })
                end
            elseif skillIndex == 2 then  -- 追踪弹
                local dx, dy = px - centerX, py - centerY
                local dist = math.sqrt(dx*dx+dy*dy)
                if dist > 0 then dx,dy = dx/dist, dy/dist end
                table.insert(enemyBullets, { x=centerX, y=centerY, dx=dx, dy=dy, speed=300, damage=45*mult, size=12, color={1,0.5,0}, lifetime=4.0, isHoming=true, homingStrength=0.05 })
            elseif skillIndex == 3 then  -- 环形弹幕
                for i = 1,12 do
                    local angle = (i/12)*math.pi*2
                    table.insert(enemyBullets, { x=centerX, y=centerY, dx=math.cos(angle), dy=math.sin(angle), speed=400, damage=25*mult, size=6, color={0.8,0.2,0.8}, lifetime=2.5 })
                end
            elseif skillIndex == 4 then  -- 激光扫射
                local angle = math.atan2(py - centerY, px - centerX)
                local dx, dy = math.cos(angle), math.sin(angle)
                table.insert(throwableFields, {
                    x=centerX, y=centerY, angle=angle, length=800, duration=0.5, timer=0, type="laser",
                    update = function(self, dt)
                        self.timer = self.timer + dt
                        for _, enemy in ipairs(enemies) do
                            if enemy ~= e then
                                local ex, ey = enemy.x + enemy.size/2, enemy.y + enemy.size/2
                                local dx2, dy2 = ex - self.x, ey - self.y
                                local proj = dx*dx2 + dy*dy2
                                if proj > 0 and proj < self.length then
                                    local perp = math.abs(dx*dy2 - dy*dx2)
                                    if perp < 20 then
                                        enemy.health = enemy.health - 50 * mult
                                        if enemy.health <= 0 and handleEnemyDeath then handleEnemyDeath(enemy, "boss_laser") end
                                    end
                                end
                            end
                        end
                        return self.timer >= self.duration
                    end
                })
            else  -- 召唤小怪
                local cnt = enraged and 4 or 2
                for i=1,cnt do
                    local angle = math.random() * math.pi * 2
                    local dist = 150
                    local mx, my = centerX + math.cos(angle)*dist, centerY + math.sin(angle)*dist
                    table.insert(enemies, {
                        type="elite", name="Elite", size=25, speed=100, health=80, maxHealth=80, color={1,0,1}, damage=20, score=30,
                        x=mx, y=my, canHaveShield=false, shootTimer=0,
                        onUpdate = function(m, dt)
                            local dx, dy = px - m.x, py - m.y
                            local dist = math.sqrt(dx*dx+dy*dy)
                            if dist > 0 then m.x = m.x + (dx/dist)*m.speed*dt; m.y = m.y + (dy/dist)*m.speed*dt end
                            m.shootTimer = (m.shootTimer or 0) - dt
                            if m.shootTimer <= 0 then m.shootTimer = 1.5; shootEnemyBullet(m, m.damage) end
                        end,
                        onDeath = function() end
                    })
                end
            end
        end
    }
}

-- 将基础类型复制到 enemyTypes（全局可用）
enemyTypes = {}
for k, v in pairs(enemyTypesBase) do enemyTypes[k] = v end

-- ===== 波次配置表 =====
waveConfig = info.waveInfo

-- ===== 障碍物绕行辅助函数 =====
function lineIntersectsObstacle(x1, y1, x2, y2)
    if not mapExpanded or not obstacle then return false end
    local left, right = obstacle.x - obstacle.w/2, obstacle.x + obstacle.w/2
    local top, bottom = obstacle.y - obstacle.h/2, obstacle.y + obstacle.h/2
    if (x1 < left and x2 < left) or (x1 > right and x2 > right) or (y1 < top and y2 < top) or (y1 > bottom and y2 > bottom) then return false end
    local function outCode(x,y)
        local code = 0
        if x < left then code = code + 1 end
        if x > right then code = code + 2 end
        if y < top then code = code + 4 end
        if y > bottom then code = code + 8 end
        return code
    end
    local out1, out2 = outCode(x1,y1), outCode(x2,y2)
    while true do
        if (out1 + out2) ~= 0 then return false end
        if out1 == 0 and out2 == 0 then return true end
        local out = out1 ~= 0 and out1 or out2
        local x,y
        if (out + 1) ~= 0 then x = left; y = y1 + (y2-y1)*(left - x1)/(x2-x1)
        elseif (out + 2) ~= 0 then x = right; y = y1 + (y2-y1)*(right - x1)/(x2-x1)
        elseif (out + 4) ~= 0 then y = top; x = x1 + (x2-x1)*(top - y1)/(y2-y1)
        else y = bottom; x = x1 + (x2-x1)*(bottom - y1)/(y2-y1) end
        if out == out1 then x1,y1,out1 = x,y,outCode(x,y)
        else x2,y2,out2 = x,y,outCode(x,y) end
    end
end

function getDirectionToPlayerWithObstacle(enemy)
    local px, py = player.x + 10, player.y + 10
    local ex, ey = enemy.x, enemy.y
    if not mapExpanded or not obstacle then
        local dx, dy = px - ex, py - ey
        local len = math.sqrt(dx*dx+dy*dy)
        if len > 0 then return dx/len, dy/len else return 0,0 end
    end
    if lineIntersectsObstacle(ex, ey, px, py) then
        local leftX, rightX = obstacle.x - obstacle.w/2 - 30, obstacle.x + obstacle.w/2 + 30
        local topY, bottomY = obstacle.y - obstacle.h/2 - 30, obstacle.y + obstacle.h/2 + 30
        local waypoints = { {x=leftX,y=topY}, {x=rightX,y=topY}, {x=leftX,y=bottomY}, {x=rightX,y=bottomY} }
        local bestDx, bestDy, minDist = 0,0, math.huge
        for _, wp in ipairs(waypoints) do
            if not lineIntersectsObstacle(ex, ey, wp.x, wp.y) then
                local dx, dy = wp.x - ex, wp.y - ey
                local dist = dx*dx + dy*dy
                if dist < minDist then
                    minDist = dist
                    local len = math.sqrt(dist)
                    if len > 0 then bestDx, bestDy = dx/len, dy/len end
                end
            end
        end
        if minDist ~= math.huge then return bestDx, bestDy end
        local dx, dy = px - ex, py - ey
        local len = math.sqrt(dx*dx+dy*dy)
        if len > 0 then return dx/len, dy/len else return 0,0 end
    else
        local dx, dy = px - ex, py - ey
        local len = math.sqrt(dx*dx+dy*dy)
        if len > 0 then return dx/len, dy/len else return 0,0 end
    end
end

function shootEnemyBullet(enemy, damage)
    if not enemy then return end
    local ex, ey = enemy.x + enemy.size/2, enemy.y + enemy.size/2
    local px, py = player.x + 10, player.y + 10
    local dx, dy = px - ex, py - ey
    local dist = math.sqrt(dx*dx+dy*dy)
    if dist > 0 then dx, dy = dx/dist, dy/dist end
    table.insert(enemyBullets, {
        x=ex, y=ey, dx=dx, dy=dy, speed=enemy.bulletSpeed or 400,
        damage=damage or enemy.bulletDamage or 20, size=enemy.bulletSize or 8,
        color=enemy.bulletColor or {1,0,1}, lifetime=3.0
    })
end

function applyShield(enemy, chance)
    if enemy.canHaveShield and math.random() < chance then
        enemy.shield = enemy.maxHealth * 0.75
        enemy.maxShield = enemy.shield
        enemy.shieldRegenRate = 0.01
        enemy.lastDamageTime = 0
    end
end

function updateShield(enemy, dt)
    if enemy.shield and enemy.shield > 0 and enemy.lastDamageTime then
        local timeSinceDamage = love.timer.getTime() - enemy.lastDamageTime
        if timeSinceDamage > 3.0 and enemy.shield < enemy.maxShield then
            enemy.shield = enemy.shield + enemy.maxShield * enemy.shieldRegenRate * dt
            if enemy.shield > enemy.maxShield then enemy.shield = enemy.maxShield end
        end
    end
end

function damageEnemyWithShield(enemy, damage)
    if enemy.invulnerable then return end
    if enemy.type == "boss_final_weakpoint" then damage = damage * 5 end
    enemy.lastDamageTime = love.timer.getTime()
    if enemy.type:find("boss") and player.abilities and player.abilities.passive and player.abilities.passive.dragonslayer then
        damage = damage * 1.1
    end
    if enemy.type == "shielder" then
        local dx = player.x + 10 - enemy.x
        if (dx > 0 and enemy.shieldDirection == 1) or (dx < 0 and enemy.shieldDirection == -1) then
            damage = damage * 0.5
        end
    end
    if enemy.shield and enemy.shield > 0 then
        enemy.shield = enemy.shield - damage
        if enemy.shield < 0 then
            local remaining = -enemy.shield
            enemy.shield = 0
            enemy.health = enemy.health - remaining
        end
    else
        enemy.health = enemy.health - damage
    end
    if enemy.health < 0 then enemy.health = 0 end
end

function spawnEnemy(enemyType)
    local typeData = enemyTypes[enemyType]
    if not typeData then print("Unknown enemy type: " .. enemyType); return end
    local screenW, screenH = love.graphics.getDimensions()
    local side = math.random(1,4)
    local off = math.random(100,200)
    local x,y
    if side == 1 then x = player.x - screenW/2 - off; y = player.y + math.random(-screenH/2, screenH/2)
    elseif side == 2 then x = player.x + screenW/2 + off; y = player.y + math.random(-screenH/2, screenH/2)
    elseif side == 3 then x = player.x + math.random(-screenW/2, screenW/2); y = player.y - screenH/2 - off
    else x = player.x + math.random(-screenW/2, screenW/2); y = player.y + screenH/2 + off end
    local enemy = {
        type=enemyType, name=typeData.name, size=typeData.size, speed=typeData.speed,
        health=typeData.health, maxHealth=typeData.health, color=typeData.color,
        damage=typeData.damage, score=typeData.score, x=x, y=y,
        canHaveShield=typeData.canHaveShield, onSpawn=typeData.onSpawn, onUpdate=typeData.onUpdate,
        onDeath=typeData.onDeath, stunned=false, stunTimer=0, originalSpeed=typeData.speed
    }
    if enemyType:find("boss") then
        enemy.shootCooldown = typeData.shootCooldown; enemy.shootTimer = 0
        enemy.bulletSpeed = typeData.bulletSpeed; enemy.bulletSize = typeData.bulletSize
        enemy.bulletColor = typeData.bulletColor; enemy.bulletDamage = typeData.bulletDamage
    end
    if enemyType == "healer" then
        enemy.healRadius = typeData.healRadius; enemy.healAmount = typeData.healAmount
        enemy.healCooldown = typeData.healCooldown; enemy.healTimer = 0
    elseif enemyType == "summoner" then
        enemy.summonCooldown = typeData.summonCooldown; enemy.summonTimer = 0
    elseif enemyType == "ghost" then
        enemy.phaseShift = false; enemy.phaseTimer = 0
    elseif enemyType == "shielder" then
        enemy.shieldDirection = 1
    elseif enemyType == "suicider" then
        enemy.exploding = false; enemy.explodeTimer = 0; enemy.explosionRange = typeData.explosionRange
    end
    if wave.current >= 5 and not wave.isBossWave then
        local shieldChance = (selectedDifficulty == "hard" and 0.4) or (selectedDifficulty == "medium" and 0.3) or 0.2
        applyShield(enemy, shieldChance)
    end
    if wave.isBossWave then applyShield(enemy, 1.0) end
    if enemyType == "boss_final_phase2" then
        enemy.useSkill = typeData.useSkill
        enemy.onWeakpointDeath = typeData.onWeakpointDeath
    end
    if enemy.onSpawn then enemy.onSpawn(enemy) end
    table.insert(enemies, enemy)
    return enemy
end

function spawnWaveEnemies()
    local config = (wave.mode == "endless") and waveConfig.endless[wave.current] or waveConfig[wave.mode][wave.current]
    if not config then print("No config for wave "..wave.current); return end
    wave.enemiesToSpawn = 0
    enemySpawnQueue = {}
    local batch, batchCount = {}, 0
    for etype, cnt in pairs(config.enemies) do
        wave.enemiesToSpawn = wave.enemiesToSpawn + cnt
        for i=1,cnt do
            local delay = i * (enemySpawnTimer + math.max(0.1, 1 - (wave.current-1)*0.02))
            table.insert(batch, { enemyType=etype, delay=delay, timer=0 })
            batchCount = batchCount + 1
            if batchCount >= 15 then
                for _,item in ipairs(batch) do table.insert(enemySpawnQueue, item) end
                batch, batchCount = {}, 0
            end
        end
    end
    for _,item in ipairs(batch) do table.insert(enemySpawnQueue, item) end
    wave.reward = config.reward
    print("Wave "..wave.current.." will reward "..wave.reward.." bits")
end

function updateEnemies(dt)
    local pcx, pcy = player.x + 10, player.y + 10
    local hasSoulReaper = player.Bag and player.Bag.hasSoulReaper
    local currentWeapon = player.weapon and player.weapon.type
    local hasBloodthirst = player.abilities and player.abilities.passive and player.abilities.passive.bloodthirst
    for i = #enemies,1,-1 do
        local e = enemies[i]
        if e.health <= 0 then
            if e.onDeath then e.onDeath(e) end
            if hasSoulReaper and currentWeapon ~= "soulreaper" then
                player.soulReaperCharge = math.min(500, player.soulReaperCharge + math.floor(e.maxHealth/2))
            end
            if hasBloodthirst then
                local heal = e.type:find("boss") and 20 or 1
                player.HealthSystem.Health = math.min(player.HealthSystem.HealthMax, player.HealthSystem.Health + heal)
            end
            addBits(e.score)
            table.remove(enemies, i)
        else
            updateShield(e, dt)
            local shouldRemove = false
            if e.onUpdate then
                local result = e.onUpdate(e, dt)
                if result == true then shouldRemove = true end
            end
            if not shouldRemove and e.type ~= "suicider" and not e.stunned and e.type ~= "boss_final_phase2" then
                local dx, dy = getDirectionToPlayerWithObstacle(e)
                e.x = e.x + dx * e.speed * dt
                e.y = e.y + dy * e.speed * dt
            end
            local ex, ey = e.x + e.size/2, e.y + e.size/2
            local dist = math.sqrt((ex-pcx)^2 + (ey-pcy)^2)
            if not shouldRemove and dist < 20 and e.damage > 0 then
                player.HealthSystem.Health = player.HealthSystem.Health - e.damage
                table.remove(enemies, i)
                if player.HealthSystem.Health < 0 then player.HealthSystem.Health = 0 end
            elseif shouldRemove then
                table.remove(enemies, i)
            end
        end
    end
end

function updateWaveAndEnemies(dt)
    for i = #enemySpawnQueue,1,-1 do
        local s = enemySpawnQueue[i]
        s.timer = s.timer + dt
        if s.timer >= s.delay then
            spawnEnemy(s.enemyType)
            table.remove(enemySpawnQueue, i)
        end
    end
    if wave.isActive then
        if #enemies == 0 and #enemySpawnQueue == 0 then endWave() end
    else
        if wave.current < wave.maxWaves[wave.mode] then
            wave.waveTimer = wave.waveTimer - dt
            if wave.waveTimer <= 0 then nextWave() end
        end
    end
    updateEnemies(dt)
end

function startWave(waveNumber, mode)
    wave.current = waveNumber
    wave.mode = mode or "easy"
    wave.isActive = true
    wave.isBossWave = false
    if ThrowableSystem and ThrowableSystem.onWaveStart then ThrowableSystem:onWaveStart() end
    if wave.mode == "endless" then
        wave.isBossWave = (waveNumber % 10 == 0) or (waveNumber == 100)
    else
        local cfg = waveConfig[wave.mode][waveNumber]
        if cfg and next(cfg.enemies) then
            for etype,_ in pairs(cfg.enemies) do
                if etype:find("boss") then wave.isBossWave = true; break end
            end
        end
    end
    spawnWaveEnemies()
    print("=== WAVE "..waveNumber..(wave.isBossWave and " BOSS" or "").." START ===")
end

function endWave()
    wave.isActive = false
    wave.waveTimer = wave.waveBreakTime
    if wave.reward then addBits(wave.reward) end
    if wave.isBossWave and wave.mode ~= "bossrush" then
        local healthPercent = player.HealthSystem.Health / player.HealthSystem.HealthMax
        addBits(math.floor(750 * healthPercent))
    end
    if wave.current >= wave.maxWaves[wave.mode] then
        print("=== GAME COMPLETE! You finished all "..wave.maxWaves[wave.mode].." waves! ===")
    end
end

function nextWave()
    local maxWaves = wave.maxWaves[wave.mode]
    if wave.current < maxWaves then
        startWave(wave.current + 1, wave.mode)
    else
        wave.isActive = false
        local msg = (wave.mode == "endless") and "CONGRATULATIONS! ALL 100 WAVES COMPLETED!" or ("CONGRATULATIONS! ALL "..maxWaves.." WAVES COMPLETED!")
        print("=== "..msg.." ===")
        print("Press M to return to menu or X to play again")
    end
end

function updateEnemyBullets(dt)
    local pcx, pcy = player.x + 10, player.y + 10
    local sw = love.graphics.getWidth()
    for i = #enemyBullets,1,-1 do
        local b = enemyBullets[i]
        b.x = b.x + b.dx * b.speed * dt
        b.y = b.y + b.dy * b.speed * dt
        b.lifetime = b.lifetime - dt
        if b.isHoming then
            local dx, dy = pcx - b.x, pcy - b.y
            local dist = math.sqrt(dx*dx+dy*dy)
            if dist > 0 then
                b.dx = b.dx + (dx/dist - b.dx) * b.homingStrength
                b.dy = b.dy + (dy/dist - b.dy) * b.homingStrength
                local len = math.sqrt(b.dx^2 + b.dy^2)
                if len > 0 then b.dx, b.dy = b.dx/len, b.dy/len end
            end
        end
        local bx, by = b.x, b.y
        local dist = math.sqrt((bx-pcx)^2 + (by-pcy)^2)
        if dist < 15 then
            player.HealthSystem.Health = player.HealthSystem.Health - b.damage
            table.remove(enemyBullets, i)
            if player.HealthSystem.Health < 0 then player.HealthSystem.Health = 0 end
        elseif b.lifetime <= 0 or math.abs(b.x - player.x) > sw*2 then
            table.remove(enemyBullets, i)
        end
    end
end

function drawEnemies()
    for _, e in ipairs(enemies) do
        if e.health > 0 then
            if e.type == "boss_final_phase2" then
                local pulse = 0.8 + math.sin(e.pulsePhase) * 0.2
                love.graphics.setColor(0.2 * pulse, 0.1 * pulse, 0.3 * pulse, 1)
                love.graphics.rectangle("fill", e.x, e.y, e.size, e.size)
                for _, part in ipairs(e.parts) do
                    local px = e.x + e.size/2 + part.offsetX
                    local py = e.y + e.size/2 + part.offsetY
                    love.graphics.push()
                    love.graphics.translate(px, py)
                    love.graphics.rotate(part.angle)
                    love.graphics.setColor(0.5, 0.2, 0.6, 0.8)
                    love.graphics.rectangle("fill", -part.size/2, -part.size/2, part.size, part.size)
                    love.graphics.pop()
                end
                local hpPercent = e.health / e.maxHealth
                love.graphics.setColor(1,0,0)
                love.graphics.rectangle("fill", e.x, e.y-20, e.size * hpPercent, 8)
                if e.rageMode then
                    love.graphics.setColor(1,0,0,0.3 + math.sin(love.timer.getTime()*10)*0.2)
                    love.graphics.rectangle("fill", e.x, e.y, e.size, e.size)
                end
            elseif e.type == "boss_final_weakpoint" then
                love.graphics.setColor(e.color[1], e.color[2], e.color[3], e.color[4])
                love.graphics.circle("fill", e.x + e.size/2, e.y + e.size/2, e.size/2)
                love.graphics.setColor(1,1,1,0.8)
                love.graphics.circle("line", e.x + e.size/2, e.y + e.size/2, e.size/2)
                love.graphics.setColor(1,0.8,0)
                love.graphics.rectangle("fill", e.x, e.y-10, e.size * (e.health/e.maxHealth), 4)
            else
                if e.stunned then
                    local alpha = 0.5 + 0.5 * math.sin(love.timer.getTime()*10)
                    love.graphics.setColor(e.color[1], e.color[2], e.color[3], alpha)
                else
                    love.graphics.setColor(e.color[1], e.color[2], e.color[3], e.color[4] or 1)
                end
                love.graphics.setLineWidth(2)
                love.graphics.rectangle("line", e.x, e.y, e.size, e.size)
                local maxH = e.maxHealth or e.health
                love.graphics.setColor(1,0,0)
                love.graphics.rectangle("fill", e.x, e.y-10, e.size * (e.health/maxH), 3)
                if e.shield and e.shield > 0 then
                    local maxS = e.maxShield or e.shield
                    love.graphics.setColor(0,0.5,1)
                    love.graphics.rectangle("fill", e.x, e.y-15, e.size * (e.shield/maxS), 3)
                end
                if e.type == "fast" then
                    love.graphics.setColor(1,1,1)
                    love.graphics.circle("fill", e.x+e.size/2, e.y-5, 2)
                elseif e.type == "tank" then
                    love.graphics.setColor(1,1,1,0.5)
                    love.graphics.setLineWidth(4)
                    love.graphics.rectangle("line", e.x-2, e.y-2, e.size+4, e.size+4)
                elseif e.type:find("boss") and e.type ~= "boss_final_phase2" then
                    love.graphics.setColor(1,1,1)
                    love.graphics.circle("fill", e.x+e.size/2, e.y-20, 3)
                    love.graphics.circle("fill", e.x+e.size/2-10, e.y-20, 3)
                elseif e.type == "elite" then
                    love.graphics.setColor(1,1,0)
                    love.graphics.circle("fill", e.x+e.size/2, e.y-5, 3)
                elseif e.type == "assault" then
                    love.graphics.setColor(1,0,0)
                    love.graphics.polygon("fill", e.x+e.size/2, e.y-10, e.x+e.size/2-5, e.y-15, e.x+e.size/2+5, e.y-15)
                elseif e.type == "suicider" and e.exploding then
                    love.graphics.setColor(1,1,1,0.5+0.5*math.sin(love.timer.getTime()*10))
                    love.graphics.circle("fill", e.x+e.size/2, e.y+e.size/2, 25)
                elseif e.type == "healer" then
                    love.graphics.setColor(0,1,0,0.3)
                    love.graphics.circle("line", e.x+e.size/2, e.y+e.size/2, 50)
                elseif e.type == "shielder" then
                    love.graphics.setColor(0.5,0.5,1,0.3)
                    if e.shieldDirection == 1 then
                        love.graphics.rectangle("fill", e.x+e.size, e.y, 10, e.size)
                    else
                        love.graphics.rectangle("fill", e.x-10, e.y, 10, e.size)
                    end
                end
            end
        end
    end
end

print("✓ enemy.lua fully loaded")
return enemyTypesBase