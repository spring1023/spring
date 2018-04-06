Explosion=class()
function Explosion:ctor(bg,x,y)
    self.effectManager=GameEffect.new("Explosion.json","game/GameEffect/newSkill/")
    self.views=self.effectManager.views
    self.viewsNode=bg
    self.initPos={x,y,10000}
    self.targetPos={x+400,y-400,0}
    self:initEffect()
end
function Explosion:initEffect()
    self:createViews_1()
end
function Explosion:createViews_1()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos={}
   initPos[1]=self.initPos[1]
   initPos[2]=self.initPos[2]
   initPos[3]=self.initPos[3]
   local temp

     local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2]+40)
   upNode:setScale(1.5)
   bg:addChild(upNode,initPos[3]+10)
   upNode:runAction(ui.action.sequence({{"delay",80/60},"remove"}))

   local function delayFrameIndex_0()
     effectManager:addEffect("views1_delay0",upNode)
      temp=views.RTD0_00_30
      temp:runAction(ui.action.sequence({{"delay",30/60},{"fadeTo",6/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",36/60},"remove"}))
      temp=views.Fire_Impact_00001_32
      temp:runAction(ui.action.sequence({{"delay",30/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",40/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_0}}))

   local function delayFrameIndex_5()
     effectManager:addEffect("views1_delay5",upNode)
      temp=views.Sparkless_00000_33
      temp:runAction(ui.action.sequence({{"fadeTo",4/60,255},{"delay",15/60},{"fadeTo",2/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",5/60},{"call",delayFrameIndex_5}}))

end

