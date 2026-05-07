-- ============================================================================
-- throwable.lua - 管理投掷物系统
-- ============================================================================

-- 投掷物系统初始化
ThrowableSystem = ThrowableSystem or {}

function ThrowableSystem:init()
    -- 投掷物定义
    self.throwables = {
        -- 引力锚点
        gravityAnchor = {
            name = "Gravity Anchor",
            type = "throwable",
            price = 1000,
            description = "Creates a slow field, enemies -50% speed\nCooldown: 2 rounds",
            cooldownRounds = 2,
            damage = 0,
            effect = "slow",
            icon = "GA",
            color = {0.5, 0, 1},
            radius = 100,
            slowAmount = 0.5,
            duration = 8.0,
            onUse = function(x, y)
                print("Gravity Anchor used at: " .. math.floor(x) .. ", " .. math.floor(y))
                local field = {
                    x = x,
                    y = y,
                    radius = 100,
                    slowAmount = 0.5,
                    duration = 8.0,
                    timer = 0,
                    active = true,
                    type = "gravity",
                    update = function(self, dt)
                        self.timer = self.timer + dt
                        if self.timer >= self.duration then
                            self.active = false
                            return true
                        end
                        for _, enemy in ipairs(enemies) do
                            local ex = enemy.x + enemy.size/2
                            local ey = enemy.y + enemy.size/2
                            local dx = ex - self.x
                            local dy = ey - self.y
                            local dist = math.sqrt(dx*dx + dy*dy)
                            if dist < self.radius then
                                if not enemy.slowed then
                                    enemy.slowed = true
                                    enemy.originalSpeed = enemy.speed
                                    enemy.speed = enemy.speed * (1 - self.slowAmount)
                                end
                                enemy.slowTimer = 0.1
                            end
                        end
                        return false
                    end,
                    onRemove = function(self)
                        for _, enemy in ipairs(enemies) do
                            if enemy.slowed then
                                enemy.slowed = false
                                enemy.speed = enemy.originalSpeed or enemy.speed
                            end
                        end
                    end
                }
                table.insert(throwableFields, field)
                print("Gravity Anchor deployed!")
            end
        },

        -- 噬魂碎片
        soulShard = {
            name = "Soul Shard",
            type = "throwable",
            price = 3000,
            description = "Deals 300 area damage\nCooldown: 1 round",
            cooldownRounds = 1,
            damage = 300,
            effect = "damage",
            icon = "SS",
            color = {0.5, 0, 0.5},
            radius = 60,
            onUse = function(x, y)
                print("Soul Shard used at: " .. math.floor(x) .. ", " .. math.floor(y))
                local killCount = 0
                for i = #enemies, 1, -1 do
                    local enemy = enemies[i]
                    local ex = enemy.x + enemy.size/2
                    local ey = enemy.y + enemy.size/2
                    local dx = ex - x
                    local dy = ey - y
                    local dist = math.sqrt(dx*dx + dy*dy)
                    if dist < 60 then
                        enemy.health = enemy.health - 300
                        if enemy.health <= 0 then
                            if handleEnemyDeath then
                                handleEnemyDeath(enemy, "soulShard")
                            else
                                addBits(enemy.score)
                                table.remove(enemies, i)
                            end
                            killCount = killCount + 1
                        end
                    end
                end
                table.insert(throwableFields, {
                    x = x, y = y,
                    radius = 60,
                    duration = 0.3,
                    timer = 0,
                    active = true,
                    type = "explosion",
                    update = function(self, dt)
                        self.timer = self.timer + dt
                        return self.timer >= self.duration
                    end
                })
                print("Soul Shard exploded! Killed " .. killCount .. " enemies")
            end
        },

        -- 相位信标（修复版）
        phaseBeacon = {
            name = "Phase Beacon",
            type = "throwable",
            price = 2750,
            description = "Teleports back to beacon after 5s\nPress 7 near beacon to teleport early\nCooldown: 1 round",
            cooldownRounds = 1,
            effect = "teleport",
            icon = "PB",
            color = {0, 1, 1},
            duration = 5.0,
            onUse = function(x, y)
                print("Phase Beacon used at: " .. math.floor(x) .. ", " .. math.floor(y))
                local beacon = {
                    x = x,
                    y = y,
                    duration = 5.0,
                    timer = 0,
                    active = true,
                    type = "beacon",
                    update = function(self, dt)
                        self.timer = self.timer + dt
                        -- 5秒后自动传送
                        if self.timer >= self.duration then
                            if self.onTrigger then
                                self.onTrigger(self)   -- 执行传送
                            end
                            return true  -- 标记需要移除
                        end
                        return false
                    end,
                    onTrigger = function(self)
                        -- 传送玩家到信标位置（偏移中心）
                        player.x = self.x - 10
                        player.y = self.y - 10
                        print("Phase teleport!")
                    end,
                    onRemove = function(self)
                        -- 无需额外操作，因为传送已在update中完成
                    end
                }
                table.insert(throwableFields, beacon)
                print("Phase Beacon deployed, teleport in 5 seconds")
            end
        }
    }

    -- 玩家投掷物配置
    if not player.throwables then
        player.throwables = {
            owned = {},
            slots = { nil, nil, nil },
            charges = { 0, 0, 0 },
            lastUsedRound = { 0, 0, 0 }
        }
    end

    -- 投掷物效果列表
    throwableFields = throwableFields or {}

    print("✓ ThrowableSystem initialized")
end

-- 购买投掷物
function ThrowableSystem:purchase(throwableId)
    local throwable = self.throwables[throwableId]
    if not throwable then return false, "Throwable not found" end

    if player.throwables.owned[throwableId] then
        return false, "Already owned!"
    end

    if maxBits < throwable.price then
        return false, "Not enough Bits! Need " .. throwable.price
    end

    maxBits = maxBits - throwable.price
    addBits(0)

    player.throwables.owned[throwableId] = true

    print("✓ Throwable unlocked: " .. throwable.name)
    return true, "Purchased: " .. throwable.name
end

-- 装备投掷物到槽位
function ThrowableSystem:equip(throwableId, slotIndex)
    if slotIndex < 1 or slotIndex > 3 then return false end

    if not player.throwables.owned[throwableId] then
        print("You don't own this throwable!")
        return false
    end

    for i, tid in ipairs(player.throwables.slots) do
        if tid == throwableId then
            player.throwables.slots[i] = nil
            player.throwables.charges[i] = 0
            break
        end
    end

    player.throwables.slots[slotIndex] = throwableId
    player.throwables.charges[slotIndex] = 1

    print("Equipped throwable: " .. self.throwables[throwableId].name .. " to slot " .. (slotIndex + 4))
    saveHighScore()
    return true
end

-- 使用投掷物
function ThrowableSystem:use(slotIndex, x, y)
    if slotIndex < 1 or slotIndex > 3 then
        print("Invalid slot index: " .. slotIndex)
        return false
    end

    local throwableId = player.throwables.slots[slotIndex]
    if not throwableId then
        print("No throwable in slot " .. slotIndex)
        return false
    end

    if player.throwables.charges[slotIndex] <= 0 then
        local throwable = self.throwables[throwableId]
        print("Throwable not ready! Needs " .. throwable.cooldownRounds .. " rounds")
        return false
    end

    local throwable = self.throwables[throwableId]
    print("Using throwable: " .. throwable.name)

    if throwable.onUse then
        throwable.onUse(x, y)
    end

    player.throwables.charges[slotIndex] = player.throwables.charges[slotIndex] - 1
    player.throwables.lastUsedRound[slotIndex] = wave.current

    print("Throwable used, remaining charges: " .. player.throwables.charges[slotIndex])
    return true
end

-- 波次开始时补充投掷物
function ThrowableSystem:onWaveStart()
    print("Checking throwable recharge...")
    for i = 1, 3 do
        local throwableId = player.throwables.slots[i]
        if throwableId then
            local throwable = self.throwables[throwableId]
            local lastUsed = player.throwables.lastUsedRound[i] or 0
            if lastUsed > 0 then
                local roundsPassed = wave.current - lastUsed
                if roundsPassed >= throwable.cooldownRounds then
                    player.throwables.charges[i] = 1
                    print("Throwable " .. throwable.name .. " recharged!")
                end
            else
                player.throwables.charges[i] = 1
                print("Throwable " .. throwable.name .. " initialized with 1 charge")
            end
        end
    end
end

-- 更新投掷物效果
function ThrowableSystem:update(dt)
    for i = #throwableFields, 1, -1 do
        local field = throwableFields[i]
        if field.active then
            local shouldRemove = field.update(field, dt)
            if shouldRemove then
                if field.onRemove then
                    field.onRemove(field)
                end
                table.remove(throwableFields, i)
            end
        else
            table.remove(throwableFields, i)
        end
    end
end

-- 绘制投掷物效果
function ThrowableSystem:draw()
    for _, field in ipairs(throwableFields) do
        if field.type == "gravity" then
            local alpha = 0.3 + 0.2 * math.sin(love.timer.getTime() * 3)
            love.graphics.setColor(0.5, 0, 1, alpha)
            love.graphics.setLineWidth(2)
            love.graphics.circle("line", field.x, field.y, field.radius)
            love.graphics.setColor(0.5, 0, 1, alpha * 0.3)
            love.graphics.circle("fill", field.x, field.y, field.radius)
            love.graphics.setColor(1, 1, 1)
            love.graphics.circle("fill", field.x, field.y, 5)

        elseif field.type == "explosion" then
            local progress = field.timer / field.duration
            local alpha = 1 - progress
            local radius = field.radius * (1 + progress * 0.5)
            love.graphics.setColor(1, 0.5, 0, alpha)
            love.graphics.setLineWidth(3)
            love.graphics.circle("line", field.x, field.y, radius)
            love.graphics.setColor(1, 0.3, 0, alpha * 0.5)
            love.graphics.circle("fill", field.x, field.y, radius * 0.8)

        elseif field.type == "beacon" then
            local remaining = field.duration - field.timer
            local pulse = 0.5 + 0.5 * math.sin(love.timer.getTime() * 5)

            love.graphics.setColor(0, 1, 1, 0.8)
            love.graphics.circle("fill", field.x, field.y, 10)

            love.graphics.setColor(0, 1, 1, pulse * 0.5)
            love.graphics.setLineWidth(2)
            love.graphics.circle("line", field.x, field.y, 15 + pulse * 5)

            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(uiFont)
            love.graphics.print(math.ceil(remaining), field.x - 10, field.y - 25)

            local dx = player.x + 10 - field.x
            local dy = player.y + 10 - field.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist < 50 then
                love.graphics.setColor(1, 1, 0)
                love.graphics.print("Press 7 to teleport", field.x - 40, field.y - 50)
            end
        end
    end
end

-- 处理投掷物按键 (5-7)
function ThrowableSystem:handleKey(key)
    local slotNumber = tonumber(key)
    if slotNumber and slotNumber >= 5 and slotNumber <= 7 then
        local slotIndex = slotNumber - 4

        print("Throwable key pressed: " .. key .. " slotIndex: " .. slotIndex)

        local throwableId = player.throwables.slots[slotIndex]
        if not throwableId then
            print("Slot " .. slotNumber .. " is empty")
            return false
        end

        if player.throwables.charges[slotIndex] <= 0 then
            print("Throwable in slot " .. slotNumber .. " is on cooldown")
            return false
        end

        -- 获取鼠标位置（世界坐标）
        local mx, my = love.mouse.getPosition()
        local w, h = love.graphics.getDimensions()
        local worldX = mx + player.x - w/2
        local worldY = my + player.y - h/2

        -- 计算从玩家到鼠标的方向
        local playerCenterX = player.x + 10
        local playerCenterY = player.y + 10
        local dirX = worldX - playerCenterX
        local dirY = worldY - playerCenterY
        local distance = math.sqrt(dirX*dirX + dirY*dirY)

        if distance > 0 then
            dirX = dirX / distance
            dirY = dirY / distance
        else
            dirX, dirY = 1, 0
        end

        -- 投掷距离
        local throwDistance = 300
        local targetX = playerCenterX + dirX * throwDistance
        local targetY = playerCenterY + dirY * throwDistance

        -- 边界限制
        targetX = math.max(mapMinX + 20, math.min(mapMaxX - 20, targetX))
        targetY = math.max(mapMinY + 20, math.min(mapMaxY - 20, targetY))

        print("Using throwable in slot " .. slotNumber .. " at (" .. math.floor(targetX) .. ", " .. math.floor(targetY) .. ")")

        return self:use(slotIndex, targetX, targetY)
    end
    return false
end

-- 处理相位信标提前传送（修复：移除距离限制，无限距离传送）
function ThrowableSystem:handleBeaconTrigger()
    for i, field in ipairs(throwableFields) do
        if field.type == "beacon" and field.active then
            -- 无论距离多远，只要存在信标就立即传送
            if field.onTrigger then
                field.onTrigger(field)
            end
            table.remove(throwableFields, i)  -- 移除信标，防止5秒后再次传送
            return true
        end
    end
    return false
end

-- 获取已拥有的投掷物列表
function ThrowableSystem:getOwnedThrowables()
    local list = {}
    for id, owned in pairs(player.throwables.owned) do
        if owned and self.throwables[id] then
            table.insert(list, {
                id = id,
                data = self.throwables[id]
            })
        end
    end
    table.sort(list, function(a, b) return a.data.name < b.data.name end)
    return list
end

print("✓ throwable.lua loaded")
return ThrowableSystem