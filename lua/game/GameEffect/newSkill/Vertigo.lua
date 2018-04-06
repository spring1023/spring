Vertigo=class()
function Vertigo:ctor(bg,x,y,lastedTime)
    self.effectManager=GameEffect.new("Vertigo.json","game/GameEffect/newSkill/")
    self.views=self.effectManager.views
    self.viewsNode=bg
    self.initPos={0,0,0}
    self.lastedTime = lastedTime
    self.Xmove = x
    self.Ymove = y
    self:initEffect()
end
function Vertigo:initEffect()
    self:createViews_1()
    self:createViews_2()
end
function Vertigo:createViews_1()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos={}
   initPos[1]=self.initPos[1]+(self.Xmove or 0)
   initPos[2]=self.initPos[2]+(self.Ymove or 0)
   initPos[3]=self.initPos[3]

   local total=self.lastedTime
   local temp

  local downNode=ui.node()
   downNode:setPosition(initPos[1],initPos[2])
   bg:addChild(downNode,initPos[3]-100)
   downNode:setScaleY(0.8)
   downNode:runAction(ui.action.sequence({{"delay",total+90/60},"remove"}))

  local function delayFrameIndex_0()
     effectManager:addEffect("views1_delay0",downNode)
      temp=views.Glow_16_2
      temp:runAction(ui.action.sequence({{"fadeTo",20/60,255},{"delay",total-30/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Sprite_4_1
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",30/60,0.8,0.8},{"scaleTo",70/60,0.1,0.1}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",20/60,255},{"fadeTo",10/60,0},{"delay",70/60}})))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_0}}))

   local function delayFrameIndex_20()
     effectManager:addEffect("views1_delay20",downNode)
      temp=views.Sprite_4_0_1
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",30/60,0.8,0.8},{"scaleTo",70/60,0.1,0.1}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",20/60,255},{"fadeTo",10/60,0},{"delay",70/60}})))
      temp:runAction(ui.action.sequence({{"delay",total-20/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",20/60},{"call",delayFrameIndex_20}}))

   local function delayFrameIndex_40()
     effectManager:addEffect("views1_delay40",downNode)
      temp=views.Sprite_4_0_0_1
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",30/60,0.8,0.8},{"scaleTo",70/60,0.1,0.1}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",20/60,255},{"fadeTo",10/60,0},{"delay",70/60}})))
      temp:runAction(ui.action.sequence({{"delay",total-40/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",40/60},{"call",delayFrameIndex_40}}))

   local function delayFrameIndex_60()
     effectManager:addEffect("views1_delay60",downNode)
      temp=views.Sprite_4_0_0_0_1
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",20/60,0.5,0.5},{"scaleTo",10/60,0.8,0.8},{"scaleTo",70/60,0.1,0.1}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",20/60,255},{"fadeTo",10/60,0},{"delay",70/60}})))
      temp:runAction(ui.action.sequence({{"delay",total-60/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",60/60},{"call",delayFrameIndex_60}}))

   local function delayFrameIndex_80()
     effectManager:addEffect("views1_delay80",downNode)
      temp=views.Sprite_4_0_0_0_0_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",30/60,0.8,0.8},{"scaleTo",70/60,0.1,0.1},{"scaleTo",30/60,0.8,0.8},{"scaleTo",70/60,0.1,0.1}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",20/60,255},{"fadeTo",10/60,0},{"delay",70/60}})))
      temp:runAction(ui.action.sequence({{"delay",total-80/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",80/60},{"call",delayFrameIndex_80}}))

end

function Vertigo:createViews_2()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]+(self.Xmove or 0)
   initPos[2]=self.initPos[2]+40+(self.Ymove or 0)
   initPos[3]=self.initPos[3]

   local total=self.lastedTime

   local temp

  local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2]+40)
   bg:addChild(upNode,initPos[3]+10)
   upNode:runAction(ui.action.sequence({{"delay",total},"remove"}))

   local function delayFrameIndex_0()
     effectManager:addEffect("views2_delay0",upNode)
      temp=views.Vertigo_00000_3
      temp:runAction(ui.action.sequence({{"delay",total-1/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Glow_16_1
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",10/60,4.8,4.8},{"scaleTo",10/60,5.44,5.44},{"scaleTo",15/60,6.4,6.4},{"scaleTo",85/60,1.6,1.6}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",10/60,255},{"fadeTo",25/60,0},{"delay",85/60}})))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_0}}))

   local function delayFrameIndex_30()
     effectManager:addEffect("views2_delay30",upNode)
      temp=views.Glow_16_1_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",10/60,4.8,4.8},{"scaleTo",10/60,5.44,5.44},{"scaleTo",15/60,6.4,6.4},{"scaleTo",85/60,1.6,1.6}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",10/60,255},{"fadeTo",25/60,0},{"delay",85/60}})))
      temp:runAction(ui.action.sequence({{"delay",total-30/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",30/60},{"call",delayFrameIndex_30}}))

   local function delayFrameIndex_60()
     effectManager:addEffect("views2_delay60",upNode)
      temp=views.Glow_16_1_0_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",10/60,4.8,4.8},{"scaleTo",10/60,5.44,5.44},{"scaleTo",15/60,6.4,6.4},{"scaleTo",85/60,1.6,1.6}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",10/60,255},{"fadeTo",25/60,0},{"delay",85/60}})))
      temp:runAction(ui.action.sequence({{"delay",total-60/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",60/60},{"call",delayFrameIndex_60}}))

   local function delayFrameIndex_90()
     effectManager:addEffect("views2_delay90",upNode)
      temp=views.Glow_16_1_0_0_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",10/60,4.8,4.8},{"scaleTo",10/60,5.44,5.44},{"scaleTo",15/60,6.4,6.4},{"scaleTo",85/60,1.6,1.6}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",10/60,255},{"fadeTo",25/60,0},{"delay",85/60}})))
      temp:runAction(ui.action.sequence({{"delay",total-90/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",90/60},{"call",delayFrameIndex_90}}))

end

