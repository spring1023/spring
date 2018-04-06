local ComicEffect3=class()
function ComicEffect3:ctor(bg,x,y,total)
    self.total = total
    self.effectManager=GameEffect.new("ComicEffect3.json")
    self.views=self.effectManager.views
    self.viewsNode=bg
    self.initPos={x,y,0}
    self.targetPos={x+400,y,0}
    self:initEffect()
end
function ComicEffect3:initEffect()
    self:createViews_1()
end
function ComicEffect3:createViews_1()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos=self.initPos
   local temp

  local total=self.total or 2

    effectManager:addEffect("views2",bg)
      temp=views.Sprite_2
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"scaleTo",10/60,4.0,4.0},{"scaleTo",30/60,5.0,5.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",total},{"fadeTo",30/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",40/60+total},"remove"}))
      temp=views.arcane_hydra_spiral_4
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.arepeat(ui.action.rotateBy(65/60,360)))
      temp:runAction(ui.action.sequence({{"delay",10/60},{"fadeTo",7/60,255}}))
      temp:runAction(ui.action.sequence({{"delay",75/60+total},"remove"}))
      temp=views.arcane_orb_spiral_5
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.arepeat(ui.action.rotateBy(65/60,460)))
      temp:runAction(ui.action.sequence({{"delay",10/60},{"fadeTo",7/60,255}}))
      temp:runAction(ui.action.sequence({{"delay",75/60+total},"remove"}))
      temp=views.arcane_orb_spiral_5_0
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.arepeat(ui.action.rotateBy(65/60,540)))
      temp:runAction(ui.action.sequence({{"delay",10/60},{"fadeTo",7/60,255}}))
      temp:runAction(ui.action.sequence({{"delay",75/60+total},"remove"}))
end
return ComicEffect3
