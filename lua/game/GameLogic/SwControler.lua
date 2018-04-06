local SwControler = class()
local Aoe = GMethod.loadScript("game.GameLogic.Aoe")
local SuperWeapon = GMethod.loadScript("game.GameLogic.SuperWeapon")
function SwControler:ctor(params)
    self.id = params.id
    self.effect = params.effect
    self.scene = params.scene
    self.gx = params.gx
    self.gy = params.gy
    self.totalTime = self.effect[5]
    self.totalNum = self.effect[4]
    self.effectRange = self.effect[1]
    if self.id==1003 then
        self.effectDis = 0.5
        self.effectMove = self.effect[2]
        self.effectAtk = self.effect[3]
    else
        self.effectDis = self.effect[2]
        self.effectValue = self.effect[3]
    end
    self:addToScene()
end

function SwControler:addToScene()
    self.lastedTime = 0      --持续时间
    self.time = 0            --计算执行的时间
    self.effectNum = 0          --影响个数       
    self.buffTab = {}          --狂暴
    local scene = self.scene
    local x,y = scene.map.convertToPosition(self.gx,self.gy)
    self.group = 1
    self.scene.battleData:addObj(self)
                    --特效
    music.play("sounds/weapon_music" .. self.id .. ".wav")
    if self.id == 1001 then  --治疗之环
        SuperWeapon.create_zhiliao(scene,self.id,x,y,self.totalTime,self.effectRange)
    elseif self.id == 1002 then --生化毒物
        SuperWeapon.createQuanzhang_zhaohuan(scene,self.id,x,y,self.totalTime,self.effectRange)
    elseif self.id == 1003 then  --狂暴号角
        SuperWeapon.createQuanzhang_kuangbao(scene,self.id,x,y,self.totalTime,self.effectRange)
    end

    self.scene.replay:addUpdateObj(self)
end

function SwControler:update(diff)
    self.lastedTime = self.lastedTime + diff
    self.time = self.time + diff
 
    if self.id == 1001 then --治疗之环
        if self.lastedTime>self.totalTime then
            self.deleted = true
            self.scene.replay:removeUpdateObj(self)
            return
        else
            if self.time>=self.effectDis then
                self.effectNum = 0
                self.time = self.time - self.effectDis
                self:exeTreatHalo(diff)
            end
        end
    elseif self.id ==1002 then   --生化毒物
        if self.lastedTime>self.totalTime then
            self.deleted = true
            self.scene.replay:removeUpdateObj(self)
            return
        else
            if self.time>=self.effectDis then
                self.effectNum = 0
                self.time = self.time - self.effectDis
                self:exePoison(diff)
            end      
        end      
    elseif self.id == 1003 then  --狂暴号角  
        if self.lastedTime>self.totalTime then      
            self.deleted = true    
            for k,v in pairs(self.buffTab) do
                v.lastedTime = 0
            end
            self.scene.replay:removeUpdateObj(self)
            return
        else
            if self.time>=self.effectDis then
                self.effectNum = 0
                self.time = self.time - self.effectDis
                self:exeRage(diff)
            end  
        end
    end
end

function SwControler:exeTreatHalo(diff)
    local scene,sgx,sgy = self.scene,self.gx,self.gy
    local function exe(persons)
        if self.effectNum>=self.totalNum then
            return
        end

        local pointTab = {}
        for k,v in pairs(persons) do
            if v.avtInfo.nowHp<v.avtInfo.maxHp then
                local tgx,tgy = v.avater.gx,v.avater.gy
                table.insert(pointTab,{tgx,tgy,0,v})
            end
        end
        local result = Aoe.circlePoint(pointTab,{sgx,sgy},self.effectRange)
        for i=1,#result-1 do
            for j=1,#result-i do
                if result[j][4].avtInfo.nowHp/result[j][4].avtInfo.maxHp>result[j+1][4].avtInfo.nowHp/result[j+1][4].avtInfo.maxHp then
                    result[j],result[j+1] = result[j+1],result[j]
                end
            end
        end

        for i,v in ipairs(result) do
            if self.effectNum<self.totalNum then
                self.effectNum = self.effectNum+1
                local hp = v[4].avtInfo.nowHp + self.effectValue
                local addHp = self.effectValue
                if hp>v[4].avtInfo.maxHp then
                    local addHp = v[4].avtInfo.maxHp-v[4].avtInfo.nowHp
                end
                v[4]:damage(-addHp)
            else
                break
            end
        end 
    end
    exe(self.battleMap2.hero)
    exe(self.battleMap2.mer)

end

function SwControler:exePoison(diff)
    local scene,sgx,sgy = self.scene,self.gx,self.gy
    local function exe(persons)
        if self.effectNum>=self.totalNum then
            return
        end

        local pointTab = {}
        for k,v in pairs(persons) do
            if v.avtInfo.nowHp>0 and (not v.cantAddBuff.swPoison) then
                local tgx, tgy = v.avater.gx,v.avater.gy
                table.insert(pointTab,{tgx,tgy,0,v})
            end
        end
        local result = Aoe.circlePoint(pointTab,{sgx,sgy},self.effectRange)
        for i=1,#result-1 do
            for j=1,#result-i do
                if result[j][4].avtInfo.nowHp/result[j][4].avtInfo.maxHp<result[j+1][4].avtInfo.nowHp/result[j+1][4].avtInfo.maxHp then
                    result[j],result[j+1] = result[j+1],result[j]
                end
            end
        end

        for i,v in ipairs(result) do
            if self.effectNum<self.totalNum then
                self.effectNum = self.effectNum+1
                local hp = v[4].avtInfo.nowHp - self.effectValue
                v[4].avtInfo.nowHp = hp>0 and hp or 0
                local cutHp = self.effectValue
                if hp<0 then
                    cutHp = v[4].avtInfo.nowHp
                end
                v[4]:damage(cutHp)
                v[4]:showHurtPerformance(math.floor(cutHp), 1)

                local buff = {lastedTime=0.5,cantKey = "swPoison"}
                BuffUtil.setBuff(v[4],buff)
            else
                break
            end
        end 
    end
    exe(self.battleMap.hero)
    exe(self.battleMap.mer)
end

function SwControler:exeRage(diff)
    local scene,sgx,sgy = self.scene,self.gx,self.gy
    local function delete(persons)
        for k,v in pairs(persons) do
            local tgx, tgy = v.avater.gx,v.avater.gy
            if (tgx-sgx)*(tgx-sgx)+(tgy-sgy)*(tgy-sgy)>self.effectRange*self.effectRange then
                if v.cantAddBuff.swRage then
                    v.cantAddBuff.swRage.lastedTime = 0
                    self.effectNum = self.effectNum-1
                end
            end    
        end
    end
    local function exe(persons)
        for k,v in pairs(persons) do
            local tgx, tgy = v.avater.gx,v.avater.gy
            if (tgx-sgx)*(tgx-sgx)+(tgy-sgy)*(tgy-sgy)<=self.effectRange*self.effectRange then
                if not v.cantAddBuff.swRage and self.effectNum<self.totalNum then
                    local buff = {bfAtkSpeedPct = self.effectAtk,bfMovePct = self.effectMove,lastedTime = 10000,cantKey = "swRage"}
                    BuffUtil.setBuff(v,buff)
                    self.effectNum = self.effectNum+1
                    table.insert(self.buffTab,buff) 
                end
            end    
        end
    end
    delete(self.battleMap2.hero)
    delete(self.battleMap2.mer)
    exe(self.battleMap2.hero)
    exe(self.battleMap2.mer)
end

GEngine.export("SwControler",SwControler)
return SwControler
