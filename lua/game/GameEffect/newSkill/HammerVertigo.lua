HammerVertigo=class()
function HammerVertigo:ctor(bg,x,y,attackMode,direction)
    self.effectManager=GameEffect.new("HammerVertigo.json","game/GameEffect/newSkill/")
    self.views=self.effectManager.views
    self.viewsNode=bg
    self.initPos={x,y,0}
    self.targetPos={x+400,y-400,0}
    self.attackMode=attackMode
    self.direction=direction
    self:initEffect()
end
function HammerVertigo:initEffect()
    self:createViews_1()
end
function HammerVertigo:createViews_1()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]
   initPos[2]=self.initPos[2]
   initPos[3]=self.initPos[3]

   local total=3
   local temp

  local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:runAction(ui.action.sequence({{"delay",80/60},"remove"}))

  local upNode2=ui.node()
   upNode2:setPosition(initPos[1]-60,initPos[2])
   bg:addChild(upNode2,initPos[3]+10)
   upNode2:runAction(ui.action.sequence({{"delay",80/60},"remove"}))


     local upNode3=ui.node()
   upNode3:setPosition(initPos[1]-60,initPos[2])
   bg:addChild(upNode3,initPos[3]+10)
   upNode3:runAction(ui.action.sequence({{"delay",total+60/60},"remove"}))

   local function delayFrameIndex_0()
     effectManager:addEffect("views1_delay0",upNode)
      temp=views.Sprite_21
      temp:runAction(ui.action.sequence({{"delay",65/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",75/60},"remove"}))
      temp=views.Sprite_21_1
      temp:runAction(ui.action.sequence({{"fadeTo",20/60,204},{"fadeTo",20/60,51},{"fadeTo",20/60,204},{"fadeTo",5/60,255},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",75/60},"remove"}))
      temp=views.Sprite_21_0
      temp:runAction(ui.action.sequence({{"scaleTo",10/60,1.0,1.0},{"scaleTo",20/60,1.2,1.2}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,127},{"fadeTo",20/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
      temp=views.Sprite_25
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,0.1,0.05},{"scaleTo",5/60,0.4,0.35},{"scaleTo",15/60,0.5,0.45}}))
      temp:runAction(ui.action.sequence({{"delay",5/60},{"fadeTo",5/60,127},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_0}}))

   local function delayFrameIndex_5()
     effectManager:addEffect("views1_delay5",upNode)
      temp=views.Glow_01_24
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,1.0,1.0},{"scaleTo",15/60,0.1,0.1}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,127},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",5/60},{"call",delayFrameIndex_5}}))

   local function delayFrameIndex_10()
     effectManager:addEffect("views1_delay10",upNode)
      temp=views.Sprite_21_0_0
      temp:runAction(ui.action.sequence({{"scaleTo",10/60,1.0,1.0},{"scaleTo",20/60,1.2,1.2}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,127},{"fadeTo",20/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",10/60},{"call",delayFrameIndex_10}}))

   local function delayFrameIndex_45()
    upNode:runAction(ui.action.sequence({{"rotateBy",10/60,60},{"rotateBy",10/60,-90}}))

     effectManager:addEffect("views1_delay45",upNode)
      temp=views.Particle_1
      temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",45/60},{"call",delayFrameIndex_45}}))

   local function delayFrameIndex_58()
     effectManager:addEffect("views1_delay58",upNode2)
      temp=views.Sparkless_00000_1
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",13/60},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
      temp=views.Sparkless_00000_1_0
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",13/60},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
   end
   upNode2:runAction(ui.action.sequence({{"delay",58/60},{"call",delayFrameIndex_58}}))

   local function delayFrameIndex_59()
     effectManager:addEffect("views1_delay59",upNode)
      temp=views.Glow_01_2
      temp:runAction(ui.action.sequence({{"scaleTo",4/60,0.3,0.3},{"scaleTo",10/60,0.5,0.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",4/60,255},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",14/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",59/60},{"call",delayFrameIndex_59}}))

  local function delayFrameIndex_60()
     effectManager:addEffect("views1_delay60",upNode3)
      temp=views.Vertigo_00000_26
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
  end
  upNode3:runAction(ui.action.sequence({{"delay",60/60},{"call",delayFrameIndex_60}}))
end

