HeroTrialSkill = class()

--1击杀令 标记一个当前血量最低的敌方英雄，己方所有单位优先攻击该目标，直至目标死亡。
--2兴奋剂 我方全体单位增加15%攻击速度并提升15%的最终伤害，持续10秒。
--3火焰弹 敌方所有场上单位每隔1秒损失3%血量，持续10秒。
--4集火令 标记一个当前攻击最高的敌方英雄，己方所有单位优先攻击该目标，直至目标死亡。
--5屠魔令 标记一个即将释放技能的敌方英雄，己方所有单位优先攻击该目标，直至目标死亡。
--6补给包 己方所有场上单位每隔1秒损恢复自身3%血量，持续10秒。
function HeroTrialSkill:ctor(stype)
	self.stype = stype
	self.scene = GMethod.loadScript("game.View.Scene")
	self.bmap = self.scene.battleMap
	self.bmap2 = self.scene.battleMap2

	local TeamSkillsEffect=GMethod.loadScript("game.GameEffect.TeamSkillsEffect")
	self.teamSkill=TeamSkillsEffect.new()

	if stype == 1 then
		self:initEffect1()
	elseif stype == 2 then
		self:initEffect2()
	elseif stype == 3 or stype == 6 then
		self.allTime = 0
		self.utime = 0
		self.scene.replay:addUpdateObj(self)
	elseif stype == 4 then
		self:initEffect4()
	elseif stype == 5 then
		self:initEffect5()
	end
end

function HeroTrialSkill:initEffect1()
	local hp,target = 2,self.bmap.hero[1]

	for i,v in ipairs(self.bmap.hero) do
		if v.avtInfo.nowHp/v.avtInfo.maxHp<hp then
			hp = v.avtInfo.nowHp/v.avtInfo.maxHp
			target = v
		end
	end
	for i,v in ipairs(self.bmap2.hero) do
		self.scene.menu.lockTarget = target
	end
	self.teamSkill:showEffect_JiShaLing(target.V.view,0,target.V.animaConfig.Ymove,{mode=3})
end

function HeroTrialSkill:initEffect2()
	local buff = {lastedTime = 10,bfAtkSpeedPct = 15,bfHurt = 15,tg = 1,keyAppoint = "HeroTrialSkill2"}
	BuffUtil.setAllBuff(buff)
end

function HeroTrialSkill:initEffect4()
	local atk,target = 0,self.bmap.hero[1]

	for i,v in ipairs(self.bmap.hero) do
		if v.avtInfo.atk>atk then
			atk = v.avtInfo.atk
			target = v
		end
	end
	self.scene.menu.lockTarget = target
	self.teamSkill:showEffect_JiShaLing(target.V.view,0,target.V.animaConfig.Ymove,{mode=1})
end

function HeroTrialSkill:initEffect5()
	local ct,target = 100,self.bmap.hero[1]

	for i,v in ipairs(self.bmap.hero) do
		if v.coldTime2 and v.coldTime2<ct then
			ct = v.coldTime2
			target = v
		end
	end
	for i,v in ipairs(self.bmap2.hero) do
		self.scene.menu.lockTarget = target
	end
	self.teamSkill:showEffect_JiShaLing(target.V.view,0,target.V.animaConfig.Ymove,{mode=2})
end

function HeroTrialSkill:update(diff)
	self.allTime = self.allTime+diff
	if self.allTime>=10 then
		self.deleted = true
        self.scene.replay:removeUpdateObj(self)
		return
	end
	self.utime = self.utime+diff
	if self.utime>=1 then
		self.utime = self.utime-1
		if self.stype == 3 then
			for k,v in pairs(self.scene.battleMap.hero) do
				if not v.deleted then
					v:damage(v.avtInfo.maxHp*0.03)

					if not v.addHeroTrialEffect3 then
						v.addHeroTrialEffect3 = true
						self.teamSkill:showEffect_HuoYanDan(v.V.view, 0, v.V.animaConfig.Ymove, {t = 10-self.allTime})
					end
				end
			end
		elseif self.stype == 6 then
			for k,v in pairs(self.scene.battleMap2.hero) do
				if not v.deleted then
					v:damage(-v.avtInfo.maxHp*0.03)
				end

				if not v.addHeroTrialEffect6 then
					v.addHeroTrialEffect6 = true
					self.teamSkill:showEffect_BuJibao(v.V.view,0,v.V.animaConfig.Ymove,{t = 10-self.allTime})
				end
			end
		end
	end

end
