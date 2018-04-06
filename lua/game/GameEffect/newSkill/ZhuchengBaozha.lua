ZhuchengBaozha=class()
function ZhuchengBaozha:ctor(bg,x,y,lastedTime)
    self.effectManager=GameEffect.new("ZhuchengBaozha.json","game/GameEffect/newSkill/")
    self.views=self.effectManager.views
    self.viewsNode=bg
    self.lastedTime = lastedTime
    self.initPos={x,y,0}
    self:initEffect()
end
function ZhuchengBaozha:initEffect()
    self:createViews_1()
end
function ZhuchengBaozha:createViews_1()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]
   initPos[2]=self.initPos[2]
   initPos[3]=self.initPos[3]

   local total=self.lastedTime or 10000
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2]+70)
   bg:addChild(upNode,initPos[3]+10)
   upNode:setScale(1.5)
   upNode:runAction(ui.action.sequence({{"delay",total+30/60+20/60},"remove"}))
   self.forBaoZaEffect = upNode
   local function delayFrameIndex_34()
     effectManager:addEffect("views1_delay34",upNode)
      temp=views.Glow_01_14
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,207},{"fadeTo",total-2/60,204},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Particle_1
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Shield_Glow_00000_3_0
      temp:runAction(ui.action.sequence({{"fadeTo",31/60,127},{"delay",total-32/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Shield_Glow_00000_3
      temp:runAction(ui.action.sequence({{"fadeTo",31/60,127},{"delay",total-32/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Gundam_Shield_1_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",10/60,255},{"fadeTo",10/60,51}})))
      temp:runAction(ui.action.sequence({{"delay",total-13/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",34/60},{"call",delayFrameIndex_34}}))

   local function delayFrameIndex_35()
     effectManager:addEffect("views1_delay35",upNode)
      temp=views.Glow_01_13_0
      temp:runAction(ui.action.sequence({{"delay",total-4/60},{"scaleTo",15/60,5.0,5.0},{"scaleTo",15/60,5.0,5.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",30/60,255},{"delay",total-19/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total+26/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",35/60},{"call",delayFrameIndex_35}}))

   local function delayFrameIndex_139()
     effectManager:addEffect("views1_delay139",upNode)
      temp=views.Gundam_Shield_Glow_00000_5_0_0
      temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"delay",17/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",24/60},"remove"}))
      temp=views.Gundam_Shield_Glow_00000_5_0
      temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"delay",17/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",24/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",total+10/60},{"call",delayFrameIndex_139}}))

   local function delayFrameIndex_159()
     effectManager:addEffect("views1_delay159",upNode)
      temp=views.Shield_Breaking_00000_10_0
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,128},{"fadeTo",6/60,127},{"fadeTo",21/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",28/60},"remove"}))
      temp=views.Shield_Breaking_00000_10
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",6/60},{"fadeTo",21/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",28/60},"remove"}))
      temp=views.Circle_Hue130_14
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,1.5,1.125},{"scaleTo",5/60,1.8,1.35}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"fadeTo",5/60,128},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
      temp=views.Circle_Hue130_14_0
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,1.5,1.125},{"scaleTo",5/60,1.8,1.35}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",5/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
      temp=views.Glow_01_13
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,3.0,3.0},{"scaleTo",5/60,1.0,1.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",12/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",total+30/60},{"call",delayFrameIndex_159}}))

end

