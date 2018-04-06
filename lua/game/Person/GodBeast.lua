local AvtControler = GMethod.loadScript("game.Person.AvtControler")
local Aoe = GMethod.loadScript('game.GameLogic.Aoe')
local SkillPlugin = GMethod.loadScript("game.Person.SkillPlugin")
local GodBeast = class(AvtControler)

function GodBeast:updateForGodBeast(diff)
	
	if self.deleted then
		return
	end
	if not self.coldTime3 then
		return
	end
	self.coldTime3 = self.coldTime3-diff
	if self.coldTime3<0 then
		self.coldTime3 = 0
	end

	if not self.enterTime then
		self.enterTime = 0
	end

	self.enterTime = self.enterTime+diff		--入场时间
	if self.avtInfo.gtype == 1 then		--助战神兽1
		local t = 5
		if self.enterTime>t then
			self:damage(self.avtInfo.nowHp2)
		end
	end

	if self.avtInfo.gtype == 6 then			--助战神兽6
		if not self.enterTime6 then
			self.enterTime6 = 0
		end
		self.enterTime6 = self.enterTime6+diff		--入场时间
		if self.enterTime6>=6 then
			local a = 20
			self.enterTime6 = self.enterTime6-6
			self:damage(-self.avtInfo.nowHp*a/100)
		end
	end
	if self.bskillData then
	    self:updatePassive1(diff)
	    self:updatePassive3(diff)
	    self:updatePassive4(diff)    
	end
end
--1, 神兽附加的所有防御建筑攻击力加[c]%，攻速加[d]%，
function GodBeast:updatePassive1(diff)
	if self.group == 2 and self.bskillData[1] then
		local ps = self.bskillData[1]
		if not self.defenceBuilds then
			self.defenceBuilds = {}
			for i,v in ipairs(self.battleMap2.build) do
				if v.canAttack then
					table.insert(self.defenceBuilds,v)
				end
			end
		end
		self.passive1Time = self.passive1Time or 0
		self.passive1Time = self.passive1Time+diff
		if self.passive1Time>1 then
			self.passive1Time = self.passive1Time-1
			for k,v in pairs(self.defenceBuilds) do
				BuffUtil.setBuff(v,{bfAtkPct=ps.c, bfAtkSpeedPct=ps.d, lastedTime=1})
			end
		end
	end
end
--3, 神兽在场时，全体英雄的攻击力增加[c]%
function GodBeast:updatePassive3(diff)
	if self.bskillData[3] then
		self.passive3Time = self.passive3Time or 0
		self.passive3Time = self.passive3Time+diff
		if self.passive3Time>1 then
			self.passive3Time = 0
			for k,v in pairs(self.battleMap2.hero) do
				if not v.cantAddBuff.GBpassive3 then
					local buff = {bfAtkPct = self.bskillData[3].c,cantKey = "GBpassive3"}
					BuffUtil.setBuff(v,buff)
					table.insert(self.buffTab,buff)
				end
			end
		end
	end
end
--4, 神兽在场时，全体英雄的每10秒可恢复[c]%的自身生命。
function GodBeast:updatePassive4(diff)
	if self.bskillData[4] then
		if not self.ps4Time then
			self.ps4Time = 0
		end
		self.ps4Time = self.ps4Time+diff
		if self.ps4Time>=10 then
			self.ps4Time = self.ps4Time-10
			for k,v in pairs(self.battleMap2.hero) do
				SkillPlugin.exe7(self,v,v.avtInfo.base_hp*self.bskillData[4].c/100)
			end
		end
	end
end

--2, 神兽在场时，怒气槽增长速度提升[c]%
function GodBeast:initForGodBeast()
	self.buffTab = {}
	if self.actSkillParams then
		self.allColdTime3 = self.actSkillParams.z
		self.coldTime3 = self.allColdTime3
	end
	if self.bskillData and self.bskillData[2] then
		self.groupData.speedScale = 1+self.bskillData[2].c/100
	end
end

--1, 神兽死亡时对自身4格范围内的敌人造成[e]%攻击力的伤害，并将他们炸飞5格
function GodBeast:dieForGodBeast()
	if not self.bskillData then
		return
	end
	--将加成buff去掉
	for k,v in pairs(self.buffTab) do
		v.lastedTime = 0
	end
	--死亡对敌人造成伤害和击飞
	

	local result = self:getCircleTarget(self,self.battleMap.battlerAll,4)
	for k,v in ipairs(result) do
		SkillPlugin.exe2(self,v,0,self.bskillData[1].e)
		if v.beRepel then
			v:beRepel(self,5)
		end
	end

	--去掉怒气速度加成
	self.groupData.speedScale = nil
end

return GodBeast
