--召唤绿巨人
Hulk2ZhaoHuan=class()
function Hulk2ZhaoHuan:ctor(bg,x,y)
    self.effectManager=GameEffect.new("Hulk2ZhaoHuan.json","game/GameEffect/newSkill/")
    self.views=self.effectManager.views
    self.viewsNode=bg
    self.initPos={x,y,100000}
    self:initEffect()
end

function Hulk2ZhaoHuan:initEffect()
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

   local function delayFrameIndex_65()
     effectManager:addEffect("views4_delay65",upNode)
      temp=views.Glow_01_2_0_d
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,177},{"delay",110/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",125/60},"remove"}))
      temp=views.Glow_01_2_d
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",110/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",125/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_65}}))

   -- local function delayFrameIndex_84()
   --   effectManager:addEffect("views4_delay84",upNode)
   --    temp=views.Relive_00000_18
   --    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",36/60},{"fadeTo",1/60,0}}))
   --    temp:runAction(ui.action.sequence({{"delay",38/60},"remove"}))
   -- end
   -- upNode:runAction(ui.action.sequence({{"delay",19/60},{"call",delayFrameIndex_84}}))

   local function delayFrameIndex_90()
     effectManager:addEffect("views4_delay90",upNode)
      temp=views.Circle_Hue130_1
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",10/60,0.5,0.375}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",10/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",25/60},{"call",delayFrameIndex_90}}))

   local function delayFrameIndex_124()
     effectManager:addEffect("views4_delay124",upNode)
      temp=views.Line_00000_19_0
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",63/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",65/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",59/60},{"call",delayFrameIndex_124}}))

end

