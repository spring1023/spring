ShaiYaRen=class()
function ShaiYaRen:ctor(bg,x,y,z,tx,ty,tz)
    self.effectManager=GameEffect.new("ShaiYaRen.json","game/GameEffect/newSkill/")
    self.views=self.effectManager.views
    self.viewsNode=bg
    self.initPos={x,y,10000}
    self.targetPos={tx,ty,tz}
    self:initEffect()
end
function ShaiYaRen:initEffect()
    self:createViews_1()
    --self:createViews_2()
end
--飞行光球
function ShaiYaRen:createViews_1()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos={}
   initPos[1]=self.initPos[1]
   initPos[2]=self.initPos[2]
   initPos[3]=self.initPos[3]

   local moveTime=1

   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:runAction(ui.action.sequence({{"delay",moveTime+20/60},{"call",function()
     self:createViews_2()
   end},"remove"}))
   upNode:runAction(ui.action.action({"moveTo",moveTime,self.targetPos[1],self.targetPos[2]}))
   local function delayFrameIndex_0()
     effectManager:addEffect("views1_delay0",upNode)
      temp=views.GF_472_1
      temp:runAction(ui.action.sequence({{"delay",moveTime-3/60},{"scaleTo",3/60,1.3,1.3},{"scaleTo",12/60,2.0,2.0}}))
      temp:runAction(ui.action.sequence({{"delay",moveTime-3/60},{"fadeTo",3/60,255},{"fadeTo",12/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",moveTime+12/60},"remove"}))
      temp=views.GF_472_1_0
      temp:runAction(ui.action.sequence({{"delay",moveTime-3/60},{"scaleTo",3/60,1.0,1.0},{"scaleTo",12/60,2.0,2.0}}))
      temp:runAction(ui.action.sequence({{"delay",moveTime-3/60},{"fadeTo",3/60,255},{"fadeTo",12/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",moveTime+12/60},"remove"}))
      temp=views.Glow_16_5
      temp=views.Qiu_00001_3
      temp=views.FengQiu_2
      temp:runAction(ui.action.arepeat(ui.action.rotateBy(40/60,-360)))
      temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
      temp=views.Glow_16_5_0
      upNode:runAction(ui.action.sequence({{"delay",moveTime},{"fadeTo",3/60,0}}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_0}}))
end

--赛亚人图标
function ShaiYaRen:createViews_2()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos={}
   initPos[1]=self.targetPos[1]
   initPos[2]=self.targetPos[2]
   initPos[3]=self.targetPos[3]

   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2]+140)
   bg:addChild(upNode,initPos[3]+10)
   upNode:runAction(ui.action.sequence({{"delay",50/60},"remove"}))

   local function delayFrameIndex_0()
     effectManager:addEffect("views2_delay0",upNode)
      temp=views.Uif_2
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",7/60,0.85,0.85},{"scaleTo",5/60,0.7,0.7}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",7/60,255}}))
      temp:runAction(ui.action.sequence({{"delay",50/60},"remove"}))
      temp=views.GF_472_3
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",7/60,1.5,1.5},{"scaleTo",20/60,2.0,2.0}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",7/60,255},{"fadeTo",20/60,51},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",28/60},"remove"}))
      temp=views.Circle00205_7
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",7/60,0.2,0.2},{"scaleTo",7/60,0.7,0.7},{"scaleTo",13/60,1.0,1.0}}))
      temp:runAction(ui.action.sequence({{"delay",7/60},{"fadeTo",7/60,127},{"fadeTo",13/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",27/60},"remove"}))
   end  
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_0}}))

   local function delayFrameIndex_20()
     effectManager:addEffect("views2_delay20",upNode)
      temp=views.GF_472_3_0
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",15/60,1.5,1.5},{"scaleTo",15/60,2.0,2.0}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",15/60,178},{"fadeTo",15/60,51},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",31/60},"remove"}))
      temp=views.Circle00205_7_0
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",15/60,0.7,0.7},{"scaleTo",15/60,1.0,1.0}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",15/60,127},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",20/60},{"call",delayFrameIndex_20}}))

end