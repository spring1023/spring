local ComicEffect1=class()
function ComicEffect1:ctor(bg,x,y)
    self.effectManager=GameEffect.new("ComicEffect1.json")
    self.views=self.effectManager.views
    self.viewsNode=bg
    self.initPos={x,y,0}
    self.targetPos={x+400,y,0}
    self:initEffect()
end
function ComicEffect1:initEffect()
    self:createViews_1()
end
function ComicEffect1:createViews_1()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos=self.initPos
   local temp

     effectManager:addEffect("views1_delay0",bg)

      temp=views.base_GuangYun01_2
      temp:runAction(ui.action.sequence({{"scaleTo",10/60,2.0,1.5},{"scaleTo",20/60,2.5,2.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",5/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
      temp:setPosition(initPos[1],initPos[2])
      temp=views.GuangYun01_2_0
      temp:runAction(ui.action.sequence({{"scaleTo",10/60,2.5,2.0},{"scaleTo",20/60,3.0,2.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",5/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
      temp:setPosition(initPos[1],initPos[2])
end

return ComicEffect1
