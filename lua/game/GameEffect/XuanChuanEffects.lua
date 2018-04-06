local XuanChuanEffects=class()

function XuanChuanEffects:ctor()
	self.path="game/GameEffect/effectsConfig/"
end

--宣传图3特效
function XuanChuanEffects:showEffect_xuanchuan3(bg,x,y,z)
  local baseEffect=GameEffect.new("ui_xuanchuan.json",self.path)
  local baseNode=ui.node({960,640})
  display.adapt(baseNode, x, y,GConst.Anchor.Center)
  --baseNode:setScale(0.36)
  local scalePolicy = display.getScalePolicy(2919,1817)
  local scaleBg = scalePolicy[GConst.Scale.Big]
  baseNode:setScale(scaleBg)
  bg:addChild(baseNode,z or 0)

  local viewsNode=ui.node()
  display.adapt(viewsNode, 484, 349,GConst.Anchor.Center)
  baseNode:addChild(viewsNode,z or 0)

  local temp
    baseEffect:addEffect("allViews_3",viewsNode)
    local views=baseEffect.views
      local dt=27/60
      temp=views.linghtingd_00000_5
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",4/60},{"fadeTo",1/60,0},{"delay",1/60},{"delay",4/60},{"delay",1/60},{"fadeTo",1/60,255},{"delay",4/60},{"fadeTo",1/60,0},{"delay",1/60},{"delay",4/60},{"delay",1/60},{"fadeTo",1/60,255},{"delay",4/60},{"fadeTo",1/60,0},{"fadeTo",1/60,255},{"fadeTo",3/60,0},{"delay",dt}})))
      temp=views.linghtingd_00000_5_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",4/60},{"fadeTo",1/60,0},{"fadeTo",1/60,255},{"fadeTo",4/60,0},{"delay",1/60},{"fadeTo",1/60,255},{"delay",4/60},{"fadeTo",1/60,0},{"fadeTo",1/60,255},{"fadeTo",4/60,0},{"delay",1/60},{"fadeTo",1/60,255},{"delay",4/60},{"fadeTo",1/60,0},{"fadeTo",1/60,255},{"fadeTo",3/60,0},{"delay",dt}})))
      temp=views.linghtingd_00000_5_1
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",4/60},{"fadeTo",1/60,0},{"delay",1/60},{"delay",4/60},{"delay",1/60},{"fadeTo",1/60,255},{"delay",4/60},{"fadeTo",1/60,0},{"delay",1/60},{"delay",4/60},{"delay",1/60},{"fadeTo",1/60,255},{"delay",4/60},{"fadeTo",1/60,0},{"fadeTo",1/60,255},{"fadeTo",3/60,0},{"delay",dt}})))
     
  return baseNode
end

return XuanChuanEffects