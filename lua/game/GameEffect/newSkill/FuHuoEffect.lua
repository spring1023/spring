FuHuoEffect=class()
function FuHuoEffect:ctor(bg,x,y)
    self.effectManager=GameEffect.new("FuHuoEffect.json","game/GameEffect/newSkill/")
    self.views=self.effectManager.views
    self.viewsNode=bg
    self.initPos={x,y,0}
    self:initEffect()
end

function FuHuoEffect:initEffect()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos=self.initPos
   local temp

    local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:setScale(1.5)
   upNode:runAction(ui.action.sequence({{"delay",230/60},"remove"}))

   local upNode2=ui.node()
   upNode2:setPosition(initPos[1],initPos[2]+200)
   bg:addChild(upNode2,initPos[3]+10)
   upNode2:setScale(1.5)

   local function delayFrameIndex_54()
     effectManager:addEffect("views4_delay54",upNode)
      temp=views.Siwang0000_1
      temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"delay",34/60},{"fadeTo",7/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",47/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_54}}))

   local function delayFrameIndex_65()
     effectManager:addEffect("views4_delay65",upNode)
      temp=views.Glow_01_2_0_d
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,177},{"delay",110/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",125/60},"remove"}))
      temp=views.Glow_01_2_d
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",110/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",125/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",11/60},{"call",delayFrameIndex_65}}))

   -- local function delayFrameIndex_84()
   --   effectManager:addEffect("views4_delay84",upNode)
   --    temp=views.Relive_00000_18
   --    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",36/60},{"fadeTo",1/60,0}}))
   --    temp:runAction(ui.action.sequence({{"delay",38/60},"remove"}))
   -- end
   -- upNode:runAction(ui.action.sequence({{"delay",30/60},{"call",delayFrameIndex_84}}))

   local function delayFrameIndex_90()
     effectManager:addEffect("views4_delay90",upNode)
      temp=views.Circle_Hue130_1
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",10/60,0.5,0.375}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",10/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",36/60},{"call",delayFrameIndex_90}}))

   local function delayFrameIndex_124()
     effectManager:addEffect("views4_delay124",upNode)
      temp=views.Line_00000_19_0
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",63/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",65/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",70/60},{"call",delayFrameIndex_124}}))


   --魂图标
  local function delayFrameIndex_50()
     effectManager:addEffect("views1_delay50",upNode2)
      temp=views.Sprite_2
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",7/60,255}}))
      
      temp=views.Sprite_2_0
      temp:runAction(ui.action.sequence({{"delay",5/60},{"scaleTo",2/60,0.25,0.25},{"scaleTo",18/60,0.45,0.45}}))
      temp:runAction(ui.action.sequence({{"fadeTo",7/60,255},{"fadeTo",18/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
      temp=views.Glow_01_3
      temp:runAction(ui.action.sequence({{"scaleTo",7/60,0.5,0.5},{"scaleTo",13/60,0.8,0.8}}))
      temp:runAction(ui.action.sequence({{"fadeTo",7/60,151},{"fadeTo",13/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",50/60},{"call",delayFrameIndex_50}}))

   local function delayFrameIndex_56()
     effectManager:addEffect("views1_delay56",upNode2)
      temp=views.Sprite_2_0_0
      temp:runAction(ui.action.sequence({{"delay",5/60},{"scaleTo",2/60,0.25,0.25},{"scaleTo",18/60,0.45,0.45}}))
      temp:runAction(ui.action.sequence({{"fadeTo",7/60,255},{"fadeTo",18/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
   end
   upNode2:runAction(ui.action.sequence({{"delay",56/60},{"call",delayFrameIndex_56}}))

   local function delayFrameIndex_60()
     effectManager:addEffect("views1_delay60",upNode2)
      temp=views.Glow_01_3_0
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",10/60,0.5,0.5}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,76}}))
      
   end
   upNode2:runAction(ui.action.sequence({{"delay",60/60},{"call",delayFrameIndex_60}}))

   local function delayFrameIndex_63()
     effectManager:addEffect("views1_delay63",upNode2)
      temp=views.Sprite_2_0_0_0
      temp:runAction(ui.action.sequence({{"delay",5/60},{"scaleTo",2/60,0.25,0.25},{"scaleTo",18/60,0.45,0.45}}))
      temp:runAction(ui.action.sequence({{"fadeTo",7/60,255},{"fadeTo",18/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
   end
   upNode2:runAction(ui.action.sequence({{"delay",63/60},{"call",delayFrameIndex_63}}))

end

