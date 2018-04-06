HeroDun=class()
function HeroDun:ctor(bg,x,y,lastedTime)
    self.effectManager=GameEffect.new("HeroDun.json","game/GameEffect/newSkill/")
    self.views=self.effectManager.views
    self.viewsNode=bg
    self.initPos={x,y,0}
    self.lastedTime = lastedTime
    self:initEffect()
end
function HeroDun:initEffect()
    self:createViews_1()
end
function HeroDun:createViews_1()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos={}
   initPos[1]=self.initPos[1]
   initPos[2]=self.initPos[2]
   initPos[3]=self.initPos[3]
   local temp

   local total=self.lastedTime

    local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:runAction(ui.action.sequence({{"delay",total+5/60},"remove"}))
   self.viewNode = upNode
   local function delayFrameIndex_4()
     effectManager:addEffect("views1_delay4",upNode)
      temp=views.Particle_3_0
      temp:runAction(ui.action.sequence({{"delay",total-5/60},"remove"}))
      temp=views.Particle_3
      temp:runAction(ui.action.sequence({{"delay",total-5/60},"remove"}))
      temp=views.Gundam_Shield_15_1
      temp:runAction(ui.action.sequence({{"fadeTo",11/60,204},{"delay",total-31/60},{"fadeTo",20/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Gundam_Shield_15
      temp:runAction(ui.action.sequence({{"fadeTo",11/60,255},{"delay",total-31/60},{"fadeTo",20/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Shield_Glow_00000_16
      temp:runAction(ui.action.sequence({{"fadeTo",11/60,76},{"delay",total-31/60},{"fadeTo",20/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_4}}))

   local function delayFrameIndex_10()
     effectManager:addEffect("views1_delay10",upNode)
      temp=views.Glow_01_1
      temp:runAction(ui.action.sequence({{"scaleTo",7/60,1.3,1.3},{"scaleTo",13/60,0.01,0.01}}))
      temp:runAction(ui.action.sequence({{"fadeTo",7/60,255},{"fadeTo",13/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
      temp=views.Gundam_Shield_15_0
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,1.0,1.0},{"scaleTo",15/60,1.1,1.1}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,102},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",10/60},{"call",delayFrameIndex_10}}))

   local function delayFrameIndex_14()
     effectManager:addEffect("views1_delay14",upNode)
      temp=views.Gundam_Shield_15_0_0
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,1.0,1.0},{"scaleTo",10/60,1.1,1.1}}))
      temp:runAction(ui.action.sequence({{"delay",1/60},{"fadeTo",10/60,76},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",14/60},{"call",delayFrameIndex_14}}))

   local function delayFrameIndex_19()
     effectManager:addEffect("views1_delay19",upNode)
      temp=views.Gundam_Shield_15_0_0_0
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,1.0,1.0},{"scaleTo",10/60,1.1,1.1}}))
      temp:runAction(ui.action.sequence({{"delay",1/60},{"fadeTo",10/60,76},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",19/60},{"call",delayFrameIndex_19}}))

end

