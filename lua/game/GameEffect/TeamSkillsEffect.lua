--战队技
local TeamSkillsEffect=class()
function TeamSkillsEffect:ctor()
	self.path="game/GameEffect/effectsConfig/"
end
--补给包
function TeamSkillsEffect:showEffect_BuJibao(bg,x,y,setting)
    local params=setting or {}
	local baseEffect=GameEffect.new("TeamSkills_BuJibao.json",self.path)
	local viewsNode=ui.node()
	display.adapt(viewsNode, x, y)
    bg:addChild(viewsNode)
    local views=baseEffect.views
    baseEffect:addEffect("allViews",viewsNode)
    if params.scale then
        viewsNode:setScale(params.scale)
    end
    if params.t then
        viewsNode:runAction(ui.action.sequence({{"delay",params.t},"remove"}))
    end
    return viewsNode
end
--火焰弹
function TeamSkillsEffect:showEffect_HuoYanDan(bg,x,y,setting)
    local params=setting or {}
    local baseEffect=GameEffect.new("TeamSkills_HuoYanDan.json",self.path)
    local viewsNode=ui.node()
    display.adapt(viewsNode, x, y)
    bg:addChild(viewsNode)
    local views=baseEffect.views
    baseEffect:addEffect("allViews",viewsNode)
    if params.scale then
        viewsNode:setScale(params.scale)
    end
    if params.t then
        viewsNode:runAction(ui.action.sequence({{"delay",params.t},"remove"}))
    end
    return viewsNode
end

--超重力网
function TeamSkillsEffect:showEffect_JinKong(bg,x,y,setting)
    local params=setting or {}
    local baseEffect=GameEffect.new("TeamSkills_JinKong.json",self.path)
    local viewsNode=ui.node()
    display.adapt(viewsNode, x, y)
    bg:addChild(viewsNode)
    local views=baseEffect.views
    baseEffect:addEffect("allViews",viewsNode)
    if params.scale then
        viewsNode:setScale(params.scale)
    end
    if params.t then
        viewsNode:runAction(ui.action.sequence({{"delay",params.t},"remove"}))
    end

      temp=views.base_Glow_01_4
      temp:runAction(ui.action.sequence({{"scaleTo",8/60,1.2,1.2},{"scaleTo",27/60,1.4,1.4}}))
      temp:runAction(ui.action.sequence({{"fadeTo",8/60,255},{"fadeTo",27/60,0}}))
      temp=views.CiBang02_5
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",5/60,0.4,0.4}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255}}))
      temp=views.Qiu01_6
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255}}))
      temp=views.CiBang01_7
      temp:runAction(ui.action.sequence({{"scaleTo",10/60,0.8,0.8},{"scaleTo",15/60,1.2,1.2}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,204},{"fadeTo",15/60,0}}))

      temp=views.Glow_01_12
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",10/60,1.0,1.0}}))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",20/60,178},{"fadeTo",20/60,89}})))
      temp=views.CiBang01_7_0
      temp:runAction(ui.action.sequence({{"scaleTo",10/60,0.7,0.7},{"scaleTo",15/60,1.2,1.2}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,204},{"fadeTo",15/60,0}}))
      temp=views.HongQuan_9
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",6/60,0.5,0.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",4/60,76},{"fadeTo",2/60,255}}))

      temp=views.HongQuan_9_0
      temp:runAction(ui.action.sequence({{"scaleTo",21/60,0.5,0.5},{"scaleTo",14/60,1.0,1.0}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},{"fadeTo",1/60,255},{"fadeTo",14/60,0}}))
      temp=views.HongGang_10
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",6/60,0.5,0.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",4/60,76},{"fadeTo",2/60,255}}))
      temp=views.Circle_R_00001_15
      temp:runAction(ui.action.sequence({{"scaleTo",6/60,0.4,0.4},{"scaleTo",15/60,0.6,0.6}}))
      temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
      temp=views.Circle_R_00001_15_0
      temp:runAction(ui.action.sequence({{"scaleTo",6/60,0.4,0.4},{"scaleTo",15/60,0.6,0.6}}))
      temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
      temp=views.Circle_R_00001_15_0_0
      temp:runAction(ui.action.sequence({{"scaleTo",6/60,0.4,0.4},{"scaleTo",15/60,0.6,0.6}}))
      temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))

    return viewsNode
end
--兴奋剂
function TeamSkillsEffect:showEffect_XingFengJi(bg,x,y,setting)
    local params=setting or {}
    local baseEffect=GameEffect.new("TeamSkills_XingFengJi.json",self.path)
    local viewsNode=ui.node()
    display.adapt(viewsNode, x, y)
    bg:addChild(viewsNode)
    local views=baseEffect.views
    baseEffect:addEffect("allViews",viewsNode)
    if params.scale then
        viewsNode:setScale(params.scale)
    end
    if params.t then
        viewsNode:runAction(ui.action.sequence({{"delay",params.t},"remove"}))
    end
    local temp
      temp=views.base_Glow_01_9_1
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",5/60,0.6,0.6}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,153}}))
      temp=views.Attack_00000_6_0_0
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255}}))
      temp=views.Attack_00000_6_0_0_0
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255}}))
      temp=views.Attack_00000_6_0
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255}}))
      temp=views.Attack_00000_6
      temp:runAction(ui.action.sequence({{"delay",5/60},{"scaleTo",5/60,1.5,1.5},{"scaleTo",15/60,1.75,1.75}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",5/60,76},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
      temp=views.Attack_00000_6_1
      temp:runAction(ui.action.sequence({{"delay",5/60},{"scaleTo",5/60,1.5,1.5},{"scaleTo",15/60,1.75,1.75}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,127},{"fadeTo",5/60,76},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
      temp=views.Glow_01_9
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,0.6,0.6},{"scaleTo",25/60,1.2,1.2}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",25/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
      temp=views.Glow_01_9_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",20/60,0.5,0.5},{"scaleTo",20/60,0.7,0.7}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",20/60,204},{"fadeTo",20/60,76}})))
      temp=views.Sprite_15
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",25/60,0.3,0.3}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
      temp=views.Sprite_15_0
      temp:runAction(ui.action.sequence({{"delay",10/60},{"scaleTo",25/60,0.3,0.3}}))
      temp:runAction(ui.action.sequence({{"delay",10/60},{"fadeTo",10/60,255},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
      temp=views.Sprite_15_0_0
      temp:runAction(ui.action.sequence({{"delay",20/60},{"scaleTo",25/60,0.3,0.3}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},{"fadeTo",10/60,255},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",45/60},"remove"}))

    return viewsNode
end
--击杀令,mode,1集火令，2屠魔令，3击杀令
function TeamSkillsEffect:showEffect_JiShaLing(bg,x,y,setting)
    local params=setting or {t=1.5,mode=1}
    local baseEffect=GameEffect.new("TeamSkills_JiShaLing.json",self.path)
    local viewsNode=ui.node()
    display.adapt(viewsNode, x, y)
    bg:addChild(viewsNode)
    local views=baseEffect.views
   
    if params.scale then
        viewsNode:setScale(params.scale)
    end
    if params.t then
        viewsNode:runAction(ui.action.sequence({{"delay",params.t},"remove"}))
    end
    local hvs={{0,0},{178,0},{-68,6}}
    local mode=params.mode

    local rNode=ui.node()
    display.adapt(rNode, 0, 0)
    viewsNode:addChild(rNode)
    rNode:setScaleX(0.5)
    rNode:setScaleY(0.42)
    baseEffect:addEffect("allViews",rNode)
    local temp
    views.base_Quan01_3_0:setHValue(hvs[mode][1])
    views.base_Quan01_3_0:setSValue(hvs[mode][2])
    views.Quan01_3:setHValue(hvs[mode][1])
    views.Quan01_3:setSValue(hvs[mode][2])
    views.Sprite_5_0:setHValue(hvs[mode][1])
    views.Sprite_5_0:setSValue(hvs[mode][2])
    views.Sprite_5:setHValue(hvs[mode][1])
    views.Sprite_5:setSValue(hvs[mode][2])


      temp=views.base_Quan01_3_0
      temp:runAction(ui.action.sequence({{"delay",25/60},{"scaleTo",30/60,1.0,1.0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},{"fadeTo",30/60,255},{"delay",25/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},{"rotateBy",30/60,-180}}))
      temp:runAction(ui.action.sequence({{"delay",95/60},"remove"}))
      temp=views.Quan01_3
      temp:runAction(ui.action.sequence({{"scaleTo",40/60,1.0,1.0},{"scaleTo",15/60,1.0,1.0},{"scaleTo",25/60,0.5,0.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",40/60,255},{"delay",14/60},{"fadeTo",1/60,178},{"fadeTo",10/60,255},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"rotateBy",40/60,-180}}))
      temp:runAction(ui.action.sequence({{"delay",80/60},"remove"}))
      temp=views.Sprite_5_0
      temp:runAction(ui.action.sequence({{"delay",25/60},{"scaleTo",25/60,1.2,1.2},{"scaleTo",15/60,0.5,0.5}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},{"delay",24/60},{"fadeTo",1/60,255},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},{"rotateBy",25/60,180}}))
      temp:runAction(ui.action.sequence({{"delay",65/60},"remove"}))
      temp=views.Sprite_5
      temp:runAction(ui.action.sequence({{"delay",25/60},{"scaleTo",25/60,1.2,1.2},{"scaleTo",10/60,0.8,0.8},{"scaleTo",10/60,1.2,1.2}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},{"fadeTo",25/60,255},{"delay",25/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},{"rotateBy",25/60,180}}))
      temp:runAction(ui.action.sequence({{"delay",90/60},"remove"}))

    return viewsNode
end
return TeamSkillsEffect