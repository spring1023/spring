local DefencePlugin = {}

function DefencePlugin:onReloadView()
    local vstate = self.vstate
    local bviews = vstate.bviews
    local bformats = vstate.bformats
    if bviews[2] and bformats[2] then
        if not vstate.rotateInfo then
            vstate.rotateInfo = {dir=3, toDir=3}
        end
        local format = bformats[2]
        local params = format[2]
        params["num"] = nil
        vstate.rotateInfo.format = StringManager.formatString(format[1], params)
        self:changeDirectionView(vstate.rotateInfo.dir)
    else
        vstate.rotateInfo = nil
    end
end

function DefencePlugin:updateOperation(diff)
    if self:isInUpgrade() then
        return
    end
    local vstate = self.vstate
    local rotateInfo = vstate.rotateInfo
    if not rotateInfo then
        if self.sg_update then
            self:sg_update(diff)
        end
        return
    end
    if rotateInfo.cd and rotateInfo.cd>0 then
        rotateInfo.cd = rotateInfo.cd - diff
    else
        rotateInfo.cd = math.random(4)+2
        rotateInfo.tdir = math.random(18)-1
        local bview = vstate.bviews[2]
        RegTimeUpdate(bview, Handler(self.updateDirection, self), 0.1)
    end
end

function DefencePlugin:updateDirection()
    local vstate = self.vstate
    local rotateInfo = vstate.rotateInfo
    if rotateInfo and rotateInfo.tdir then
        local dir = rotateInfo.dir
        local tdir = rotateInfo.tdir
        if dir == tdir then
            rotateInfo.tdir = nil
            UnregTimeUpdate(vstate.bviews[2])
            return false
        end
        local aoff = math.abs(tdir-dir)
        if aoff>9 then
            dir = dir-(tdir-dir)/aoff
        else
            dir = dir+(tdir-dir)/aoff
        end
        dir = (dir+18)%18
        rotateInfo.dir = dir
        self:changeDirectionView(dir)
        return true
    end
end

function DefencePlugin:changeDirection(ox, oy)
    local dir = (math.floor((math.deg(math.atan2(oy, ox))+495+10)/20))%18
    local vstate = self.vstate
    local rotateInfo = vstate.rotateInfo
    rotateInfo.cd = 20
    rotateInfo.tdir = dir
    rotateInfo.tick = 0
    return rotateInfo.tdir ~= rotateInfo.dir
end

function DefencePlugin:changeDirectionView(dir)
    local vstate = self.vstate
    local rotateInfo = vstate.rotateInfo
    local bview = vstate.bviews[2]
    if bview and rotateInfo and rotateInfo.format then
        bview:setFlippedX(dir>9)
        if dir>9 then
            dir=18-dir
        end
        local frame = ui.reuseFrame(StringManager.formatString(rotateInfo.format, {num=dir}))
        if frame then
            bview:setSpriteFrame(frame)
        end
    end
end

function DefencePlugin:readyToBattle()
    self.params.atk = self.data.dps
    self.params.aspeed = self.info.aspeed
    self.params.autype = self.info.autype
    self.params.drange = self.info.drange
    self.params.range = self.info.maxRange
    self.params.mrange = self.info.minRange
    self.params.dtype = self.info.dtype or 0
    self.params.fav = self.info.fav or 0
    self.params.favRate = self.info.favRate or 1
    self.coldTime = 0
    if self.worklist or self.level == 0 then
        return
    end
    self.rd = RdUtil.new(self.vstate.gx * 100 + self.vstate.gy + self.id*10000)
    self.update = self.updateBattle
end

function DefencePlugin:updateBattle(diff)
    BuffUtil.updateBuff(self, diff)
    if self.deleted or self.avtInfo.bfDizziness>0 then
        return
    end
    if self.sg_update then
        self:sg_update(diff)
    end
    self.coldTime = self.coldTime - diff
    local vstate = self.vstate
    if self.coldTime <= 0 then
        local targetNeedReset = false
        local cx, cy = vstate.gx+vstate.gsize/2, vstate.gy+vstate.gsize/2
        if not self.target or self.target.deleted or self.target.isHide then
            targetNeedReset = true
        else
            local tx, ty = self.target.avater.gx, self.target.avater.gy
            local dis = vstate.scene.map.getDistance(tx-cx, ty-cy)
            if not self:canAttack(dis) then
                targetNeedReset = true
            end
        end

        if targetNeedReset then
            local minTarget = nil
            local minDis = nil
            --isFav = false, 目前建筑没有爱好
            local autype = self.avtInfo.autype
            for i, soldier in ipairs(self.battleMap.battler) do
                --local isFav = false
                -- if self.ddata.favorite >0 and self.avtInfo.fav==soldier.sid then
                --     isFav = true
                -- end
                if not soldier.deleted and (autype == 3 or autype == soldier.avtInfo.utype) then -- (isFav or not minTarget.isFav) then
                    local tx, ty = soldier.avater.gx, soldier.avater.gy
                    local dis = vstate.scene.map.getDistance(tx-cx, ty-cy)
                    if self:canAttack(dis) then
                        if not minTarget or dis < minDis then
                            minDis = dis
                            minTarget = soldier
                            --minTarget.isFav = isFav
                        end
                    end
                end
            end
            self.target = minTarget
        end
        if self.target then
            while self.coldTime<=0 do
                if self.vstate.rotateInfo then
                    local ox, oy = self.target.avater.gx-cx, self.target.avater.gy-cy
                    local nc = self:changeDirection(ox, oy)
                    if nc then
                        self:updateDirection()
                        self.coldTime = self.coldTime + 0.05
                    else
                        self:attack(self.target)
                        if self.vconfig.attackMusic then
                            if self.bid == 27 then
                                LogicEffects.onSpecialMusic(self.vconfig.attackMusic, 0.2, 4, 1)
                            else
                                music.play(self.vconfig.attackMusic)
                            end
                        end
                    end
                else
                    self:attack(self.target)
                    if self.vconfig.attackMusic then
                        music.play(self.vconfig.attackMusic)
                    end
                end
            end
        else
            self.coldTime = self.coldTime + 0.5
        end
    end
end

function DefencePlugin:canAttack(dis)
    if dis>self.avtInfo.range or dis<self.avtInfo.mrange then
        return false
    end
    return true
end

local tsTriangle = {[0]={0, -83}, [1]={-38, -77}, [2]={-70, -61}, [3]={-90, -39}, [4]={-96, -17},
                    [5]={-92, 9}, [6]={-78, 28}, [7]={-55, 42}, [8]={-28, 51}, [9]={0, 56}}

function DefencePlugin:getAttackPosition(offx, offy, r, dir, eh)
    local xk = 1
    if dir>9 then
        dir=18-dir
        xk=-1
    end
    if not eh then
        eh = 0
    end
    local x, y = self.vstate.view:getPosition()
    local triangle = tsTriangle[dir]
    x = x+offx+r*triangle[1]*xk
    y = y+offy+self.vstate.view:getContentSize().height/2+r*triangle[2]+eh
    local z = self.vstate.scene.map.maxZ - y+offy+eh
    return {x, y, z, math.deg(math.atan2(triangle[2]+eh, xk*triangle[1]))}
end

function DefencePlugin:getReuseShot(target,attackValue)
    local shot
    shot = self.fireShot
    if not shot or not shot.view or shot.target~=target then
        local p = {self.vstate.view:getPosition()}
        p[3] = self.vstate.scene.map.maxZ - p[2]
        p[2] = p[2] + 235
        shot = FireLineShot.new(attackValue, 60, p[1], p[2], p[3], target)
        shot.type = 1
        self.fireShot = shot
        shot.attacker = self
    end
    return shot
end

function DefencePlugin:getColdTime()
    return self.avtInfo.aspeed
end

return DefencePlugin
