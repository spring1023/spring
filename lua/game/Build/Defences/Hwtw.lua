--哨塔22

local Hwtw = {}

function Hwtw:attack(target)
    self.coldTime = self.coldTime+self.avtInfo.aspeed
    local scene = self.vstate.scene
    --目标点坐标
    self.upV.hwtwX,self.upV.hwtwY = self.vstate.gx+self.vstate.gsize/2,self.vstate.gy+self.vstate.gsize/2
    self.upV:attack(target.V.gx,target.V.gy)
    self.attackTarget = target
end
function Hwtw:sg_update(diff)
    local scene = self.vstate.scene
    local avater = self.upV
    if not avater then
        print("error check", self.id, self.bid, self.level)
        return
    end
    avater:updateView(diff)
    if avater.state == PersonState.ATTACK then
        if avater.exeRealAtk then
            avater.exeRealAtk = false
            if avater.animaConfig.attack_music then
                music.play("sounds/" .. avater.animaConfig.attack_music)
            end
            
            local setting = self.vconfig.shotSetting[avater.direction]
            local p = {self.vstate.view:getPositionX(),self.vstate.view:getPositionY()+avater.view:getPositionY()+self.vstate.build:getPositionY()}
            p[3] = General.sceneHeight - p[2]+setting[3]*20
            local x,y = avater.personView:getPosition()
            p[1] = p[1] + x + setting[1]
            p[2] = p[2] + y + setting[2]
            local attackValue = BattleUtil.getHurt(self, self.attackTarget)
            local attackTarget = self.attackTarget
            if GEngine.rawConfig.DEBUG_NOBEFFECT then
                attackTarget:damage(attackValue,self)
            else
                local shot = ArrowShot.new(nil, 90, p[1], p[2], p[3],self.attackTarget,1,function()
                    attackTarget:damage(attackValue,self)
                end)
                shot.attacker = avater
                shot:addToScene(scene)
            end
        end
    end
end
--哨塔上的弓箭手
function Hwtw:onReloadView()
    if self.worklist then
        return
    end
    local vstate = self.vstate
    local vconfig = self.vconfig
    local bid = self.bsetting.bvid
    local blv = self.level
    if vconfig.maxLv and blv>vconfig.maxLv then
        blv = vconfig.maxLv
    end
    self.upV = Avater.new(300, self.vstate.build, self.vstate.build:getContentSize().width/2 + vconfig.avaterx, vconfig.avatery, nil, 1, self)
end

function Hwtw:dieEvent()
    if self.upV then
        self.upV.deleted = true
    end
    local buff = self.allBuff["SaiyanGodSkill2"]
    if buff then
        for k,v in pairs(self.battleMap2.build) do
            if v.bid == 22 then
                local px,py,pz = self:getDamagePoint()
                local tx,ty,tz = v:getDamagePoint()
                ShaiYaRen.new(self.vstate.scene.objs,px,py,pz,tx,ty,tz)
                BuffUtil.setBuff(v,buff,"SaiyanGodSkill2")
                break
            end
        end
    end
end

return Hwtw
