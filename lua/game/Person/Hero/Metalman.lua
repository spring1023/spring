local M = class(AvtInfo)













local V = {}
function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
    end

    local mode = self.C.rd:randomInt(3)
    local shot = AttackeffectShot.new(nil, 120,0,0,0,attackTarget,1,mode,0,1.25,callback)
    shot.attacker = self
    shot:addToScene(self.scene)
end
function V:skillState(skillLastTimeAll)
    self.skillLastTimeAll = skillLastTimeAll
    self.skillLastTime = 0
    if self.personView then
        self.personView:setScale(1.2)
        self.personView:setHValue(180)
    end
end

function V:skillAfter()
    self.skillLastTimeAll = nil
    self.skillLastTime = nil
    if self.personView then
        self.personView:setScale(1)
        self.personView:setHValue(0)
    end
end

local C = class(AvtControler)

--2001 金属人 持续[y]秒内，自身增加减伤率[c]%，消耗[x]怒，冷却时间[z]秒
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end

function C:sg_exeSkill(target)
    local params = self.actSkillParams
    local c,y = params.c,params.y
    BuffUtil.setBuff(self,{lastedTime = y, bfDefPct = c})
    self.V:skillState(y)
end

return {M,V,C}
