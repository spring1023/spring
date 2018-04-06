YonBingDun=class()
function YonBingDun:ctor(bg,x,y,lastedTime)
    self.effectManager=GameEffect.new("YonBingDun.json","game/GameEffect/newSkill/")
    self.views=self.effectManager.views
    self.viewsNode=bg
    self.initPos={x,y,0}
    self.targetPos={x+400,y-400,0}
    self.lastedTime = lastedTime
    self:initEffect()
end
function YonBingDun:initEffect()
    self:createViews_1()
end
function YonBingDun:createViews_1()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos={}
   initPos[1]=self.initPos[1]
   initPos[2]=self.initPos[2]
   initPos[3]=self.initPos[3]

   local total=self.lastedTime

   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2]+80)
   bg:addChild(upNode,initPos[3]+10)
   upNode:runAction(ui.action.sequence({{"delay",60000/60},"remove"}))

   local function delayFrameIndex_0()
     effectManager:addEffect("views1_delay0",upNode)
      temp=views.DunPai01_3
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",total},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.DunPai01_3_0
      temp:runAction(ui.action.sequence({{"scaleTo",10/60,0.7,0.7},{"scaleTo",15/60,0.8,0.8}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,76},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
      temp=views.DunPai01_3_0_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",30/60,127},{"fadeTo",30/60,25}})))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Sprite_11
      temp:runAction(ui.action.sequence({{"scaleTo",10/60,0.4,0.4},{"scaleTo",20/60,0.6,0.6}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,127},{"fadeTo",20/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_0}}))

   local function delayFrameIndex_5()
     effectManager:addEffect("views1_delay5",upNode)
      temp=views.DunPai01_3_0_1
      temp:runAction(ui.action.sequence({{"scaleTo",10/60,0.7,0.7},{"scaleTo",15/60,0.8,0.8}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,76},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
      temp=views.Glow_01_10
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,1.0,1.0},{"scaleTo",10/60,0.1,0.1}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",15/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",5/60},{"call",delayFrameIndex_5}}))

   local function delayFrameIndex_10()
     effectManager:addEffect("views1_delay10",upNode)
      temp=views.DunPai01_3_0_1_0
      temp:runAction(ui.action.sequence({{"scaleTo",10/60,0.7,0.7},{"scaleTo",15/60,0.8,0.8}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,76},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",10/60},{"call",delayFrameIndex_10}}))

end

