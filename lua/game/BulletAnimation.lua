BulletAnimation = class()

function BulletAnimation:ctor(mode,object,skillmode, movetime, pos1,pos2,zorder,r)	--mode表示,1:建筑,2:英雄

	self.mode=mode
	self.movetime=movetime
	self.initPos=pos1
	self.targetPos=pos2
	self.zorder=zorder
	self.r=r
	self.rotation=r
	self.object=object
	self.skillmode=skillmode
	self.stateTime=0
	if self.mode==1 then
		self.id=object.bid
		self.scene=object.vstate.scene
	elseif self.mode==2 then
		self.id=object.avtInfo.id
		self.scene=object.scene
	end
	self:getConfig()
end
--20 机器猫 27女剑仙  33EVA  35蜘蛛侠
function BulletAnimation:getConfig()
	if self.id == 2004 then
		self.id = 27
	elseif self.id == 4001 then
		self.id = 20
	elseif self.id == 4003 then
		self.id = 33
	elseif self.id == 3004 then
		self.id = 35	
	end

	if self.mode==1 then
		self.config = GMethod.loadConfig("game/BulletAnimationJson/" .. "build_" .. self.id .. ".json")
		self.skillconfig=self.config.levels[self.object.level].amode	--建筑攻击配置
	elseif self.mode==2 then
		self.config = GMethod.loadConfig("game/BulletAnimationJson/" .. "soldier_" .. self.id .. ".json")
		if not self.skillmode then
			self.skillconfig=self.config.amode		--英雄普通攻击配置
		else
			self.skillconfig=self.config.smode		--英雄技能攻击配置
		end
	end
end

function BulletAnimation:runAnimation()
		if self.skillconfig then
			local anode

			for _, item in ipairs(self.skillconfig) do
				local act=false
				local act2=false
				local n=0
				if	item[1]==1 then
					anode = ui.sprite(item[2])
					anode:setAnchorPoint(item[3],item[4])
					anode:setScaleX(item[5])
					anode:setScaleY(item[6])
					anode:setRotation(self.r)
					anode:setPosition(self.initPos[1],self.initPos[2])
					self.scene.objs:addChild(anode, self.zorder)
					n=7
				elseif item[1]==2 then
					anode = ui.particle(item[2])
					anode:setScaleX(item[3])
					anode:setScaleY(item[4])
					anode:setPosition(self.initPos[1],self.initPos[2])
					anode:setPositionType(cc.POSITION_TYPE_RELATIVE)
					self.scene.objs:addChild(anode, self.zorder)
					--anode:runAction(ui.action.moveTo(self.movetime,self.targetPos[1],self.targetPos[2]))
					--anode:setDuration(self.movetime)
					--anode:setAutoRemoveOnFinish(true)

				elseif item[1]==3 then
					anode = ui.animateSprite(item[2],item[3],item[4],{beginNum=item[5],plist=item[6],isRepeat=item[7]})
					anode:setAnchorPoint(item[8],item[9])
					anode:setScaleX(item[10])
					anode:setScaleY(item[11])
					anode:setRotation(self.r)
					anode:setPosition(self.initPos[1],self.initPos[2])
					self.scene.objs:addChild(anode,self.zorder)
					--anode:runAction(ui.action.moveTo(self.movetime,self.targetPos[1],self.targetPos[2]))
					n=12
				elseif item[1]==4 then
					anode= ui.node()
					display.adapt(anode, self.initPos[1], self.initPos[2])
					anode:setRotation(self.r)
					self.scene.objs:addChild(anode,self.zorder)
					 local ox, oy = self.targetPos[1]-self.initPos[1], self.targetPos[2]-self.initPos[2]
					local g=self.scene.map.getGridDistance(self.targetPos[1]-self.initPos[1], self.targetPos[2]-self.initPos[2])/self.scene.map.getGridDistance(92,69)
					g=math.floor(g)
					local p=ui.particle(item[2],{max=4*g,rate=13*g})
					p:setScaleX(item[3])
					p:setScaleY(item[4])
					p:setPosition(0,0)
					p:setPositionType(cc.POSITION_TYPE_RELATIVE)
					anode:addChild(p)
					--p:runAction(CCMoveBy:create(self.movetime, cc.p(0, math.sqrt(ox*ox+oy*oy))))
					p:runAction(ui.action.moveBy(self.movetime,0,math.sqrt(ox*ox+oy*oy)))
					act=true
					act2=true
				end

				if item[n] then
					if item[n].color then
						anode:setColor(cc.c3b(item[n].color[1],item[n].color[2],item[n].color[3]))
					end
					if item[n].Opacity then
						anode:setOpacity(item[7].Opacity)
					end
					if item[n].blend then
						local blend={}
						blend.src=item[n].blend[1]
						blend.dst=item[n].blend[1]
						anode:setBlendFunc(blend)
					end
					if item[n].action1 then			--与子弹移动时间无关的动作
						anode:runAction(ui.action.action(item[n].action1))
					end
					if item[n].action2 then			--子弹移动的时间内动作
						item[n].action2[2]=self.movetime
						anode:runAction(ui.action.action(item[n].action2))
					end
					if item[n].action3 then		--子弹移动前的动作
						anode:runAction(ui.action.sequence({item[n].action3,{"moveTo",self.movetime,self.targetPos[1],self.targetPos[2]},"remove"}))
						act=true
					end
					if item[n].action4 then		--子弹移动到目标后的动作
						anode:runAction(ui.action.sequence({{"moveTo",self.movetime,self.targetPos[1],self.targetPos[2]},item[n].action4,"remove"}))
						act=true
					end
				end
				if not act then
						anode:runAction(ui.action.moveTo(self.movetime,self.targetPos[1],self.targetPos[2]))
						anode:runAction(ui.action.sequence({{"delay",self.movetime},"remove"}))
				end
				if act2 then
					anode:runAction(ui.action.sequence({{"delay",self.movetime},"remove"}))
				end
			end
		end
end

function BulletAnimation:runAnimation2()
	local htpos=self:JShtpoint(true)
	local anode
	if self.skillconfig then
			for _, item in ipairs(self.skillconfig) do
				local Rota=false
				local n=0
				if	item[1]==1 then
					anode = ui.sprite(item[2])
					anode:setAnchorPoint(item[3],item[4])
					anode:setScaleX(item[5])
					anode:setScaleY(item[6])
					anode:setRotation(self.r)
					anode:setPosition(self.initPos[1],self.initPos[2])
					self.scene.objs:addChild(anode, self.zorder)
					Rota=true
				elseif item[1]==2 then
					anode = ui.particle(item[2])
					anode:setScaleX(item[3])
					anode:setScaleY(item[4])
					anode:setPosition(self.initPos[1],self.initPos[2])
					anode:setPositionType(cc.POSITION_TYPE_RELATIVE)
					self.scene.objs:addChild(anode, self.zorder+item[5])
				end
				local moveX=ui.action.moveBy(self.movetime,self.targetPos[1]-self.initPos[1],0)
				local moveY1=ui.action.moveBy(self.movetime/2,0,htpos[2]-self.initPos[2])
				local moveY2=ui.action.moveBy(self.movetime/2,0,self.targetPos[2]-htpos[2])
				anode:runAction(moveX)
				anode:runAction(ui.action.sequence({ui.action.easeSineOut(moveY1),ui.action.easeSineIn(moveY2),"remove"}))
			if Rota then
				self.view=anode
				if self.targetPos[1]-self.initPos[1]>=0 then
					self.fuhao=1
					self.view:setRotation(45)
				else
					self.fuhao=-1
					self.view:setRotation(-45)
				end
				self.number=math.floor(self.movetime/0.1)
				self.view:runAction(ui.action.sequence({{"rotateBy",self.movetime/2,self.fuhao*45},{"rotateBy",self.movetime/2,self.fuhao*85}}))
			end
		end
	end
end


function BulletAnimation:runAnimation3()
	local htpos=self:JShtpoint(false)
	local anode
	if self.skillconfig then
			for _, item in ipairs(self.skillconfig) do
				local Rota=false
				local n=0
				if	item[1]==1 then
					anode = ui.sprite(item[2])
					anode:setAnchorPoint(item[3],item[4])
					anode:setScaleX(item[5])
					anode:setScaleY(item[6])
				if item[7] and item[7].set then
					anode:setPosition(self.initPos[1]+item[7].set[1],self.initPos[2]+item[7].set[2])
					anode:setRotation(self.r+item[7].set[3])
					self.scene.objs:addChild(anode, self.zorder+item[7].set[4])
				 else
					anode:setPosition(self.initPos[1],self.initPos[2])
					anode:setRotation(self.r)
					self.scene.objs:addChild(anode, self.zorder)
				 end

					if item[7] and item[7].node then
						local view= ui.sprite(item[7].node[2])
						view:setAnchorPoint(item[7].node[3],item[7].node[4])
						view:setScaleX(item[7].node[5])
						view:setScaleY(item[7].node[6])
						if item[7].node[7] and item[7].node[7].set then
							view:setPosition(item[7].node[7].set[1],item[7].node[7].set[2])
							view:setRotation(item[7].node[7].set[3])
							anode:addChild(view, item[7].node[7].set[4])
						 else
							view:setPosition(0,0)
							view:setRotation(0)
							anode:addChild(view)
						 end
					end

				elseif item[1]==2 then
					anode = ui.particle(item[2])
					anode:setScaleX(item[3])
					anode:setScaleY(item[4])
					anode:setPosition(self.initPos[1],self.initPos[2])
					anode:setPositionType(cc.POSITION_TYPE_RELATIVE)
					self.scene.objs:addChild(anode, self.zorder)
				end

				self.view=anode
				self:runMove()
		end
	end
end

function BulletAnimation:JShtpoint(HS)
	local ox,oy=math.abs(self.targetPos[1]-self.initPos[1]),math.abs(self.targetPos[2]-self.initPos[2])
	local r=math.atan2(oy, ox)
	local Lenth=math.sqrt((self.targetPos[1]-self.initPos[1])^2+(self.targetPos[2]-self.initPos[2])^2)
	local Cpoint={(self.targetPos[1]+self.initPos[1])/2,(self.targetPos[2]+self.initPos[2])/2}
	local pos=Cpoint
	if HS then
		pos[2]=pos[2]+Lenth/2*math.sin(r)+Lenth/2*math.cos(r)
	else
		pos[2]=pos[2]-(1/2)*Lenth/2*math.cos(r)
	end
	return pos
end

function BulletAnimation:updatesetRotion(diff)
    local stateTime = self.stateTime + diff
	self.stateTime=stateTime
	if stateTime>=0.1 then
		self.view:runAction(ui.action.rotateBy(0.1,self.fuhao*(180-30)/self.number))
		self.stateTime=0
	end
end

function BulletAnimation:runMove()

		local ox, oy = self.targetPos[1] - self.initPos[1], self.targetPos[2] - self.initPos[2]
        local dir = 0
        local temp = math.deg(math.atan2(oy, ox))
			dir = -temp

        local dirDis = (dir-self.rotation+3600)%360
        if dirDis>180 then
            dirDis = dirDis-360
        end
        local length = math.sqrt(ox*ox+oy*oy)
        local ra = math.rad(self.rotation)
        local rb = math.rad(dir)
        if dirDis<60 and dirDis>-60 then
            self.view:runAction(cc.RotateBy:create(self.movetime, dirDis*2))
            local config = ccBezierConfig:new_local()
            config.controlPoint_1 = cc.p(length/3*math.cos(ra), length/3*math.sin(-ra))
            config.controlPoint_2 = cc.p(length/3*math.cos(ra) + length/3*math.cos(rb), length/3*math.sin(-ra)+length/3*math.sin(-rb))
            config.endPosition = cc.p(ox, oy)
            self.view:runAction(cc.BezierBy:create(self.movetime, config))
        else
            local llen = length
            if llen>450 then
                llen = 450
            end
            rb = math.rad(self.rotation+dirDis/2)
            local tdir = math.deg(math.atan2(oy-(llen+length)/2*math.sin(-rb), ox-(llen+length)/2*math.cos(rb)))
            tdir = (tdir-self.rotation+720)%360
            self.view:runAction(cc.RotateBy:create(self.movetime, dirDis*2))
            local config = ccBezierConfig:new_local()
            config.controlPoint_1 = cc.p(llen*math.cos(ra), llen*math.sin(-ra))
            config.controlPoint_2 = cc.p((llen+length)/2*math.cos(rb), (llen+length)/2*math.sin(-rb))
            config.endPosition = cc.p(ox, oy)
            self.view:runAction(cc.BezierBy:create(self.movetime, config))
        end
		self.view:runAction(ui.action.sequence({{"delay",self.movetime},"remove"}))
end
