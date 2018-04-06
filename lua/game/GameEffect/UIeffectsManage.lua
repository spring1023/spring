local UIeffectsManage = class()
local _effectManager = EffectMaker:getInstance()

function UIeffectsManage:ctor()
    self.path="game/GameEffect/effectsConfig/"
end
--装备巨龙之心
function UIeffectsManage:showEffect_julongzhixin(bg,x,y,scal)--装备中心坐标
	local baseEffect=GameEffect.new("ui_julongzhixin.json",self.path)
	local viewsNode=ui.node()
	display.adapt(viewsNode, x, y)
  bg:addChild(viewsNode)
  if scal then
      viewsNode:setScale(scal)
  end
    local views=baseEffect.views
    baseEffect:addEffect("allViews",viewsNode)

    return viewsNode
end
--装备雷霆之刃
function UIeffectsManage:showEffect_leiting(bg,x,y,scal)--装备中心坐标
	local baseEffect=GameEffect.new("ui_leiting.json",self.path)
	local viewsNode=ui.node()
	display.adapt(viewsNode, x, y)
  bg:addChild(viewsNode)
  if scal then
      viewsNode:setScale(scal)
  end
    local views=baseEffect.views
    baseEffect:addEffect("allViews",viewsNode)
  local temp
    temp=views.base_jian_13
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",30/60,92},{"fadeTo",35/60,204}})))
    temp=views.Sprite_7
    temp:setVisible(false)
	temp:runAction(ui.action.arepeat(ui.action.sequence({"show",{"delay",0.33},"hide",{"delay",0.33*2}})))
    temp=views.Sprite_7_0
    temp:setVisible(false)
	temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",0.33},"show",{"delay",0.33},"hide",{"delay",0.33}})))
    temp=views.Sprite_7_0_0
    temp:setVisible(false)
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",0.33*2},"show",{"delay",0.33},"hide"})))

    return viewsNode
end
--装备血光之书
function UIeffectsManage:showEffect_xueguangzhishu(bg,x,y,scal)--装备中心坐标
	local baseEffect=GameEffect.new("ui_xueguangzhishu.json",self.path)
	local viewsNode=ui.node()
	display.adapt(viewsNode, x, y)
  bg:addChild(viewsNode)
  if scal then
      viewsNode:setScale(scal)
  end
    local views=baseEffect.views
    baseEffect:addEffect("allViews",viewsNode)

    return viewsNode
end
--装备荆棘之弓
function UIeffectsManage:showEffect_jinji(bg,x,y,scal)--装备中心坐标
	local baseEffect=GameEffect.new("ui_jinji.json",self.path)
	local viewsNode=ui.node()
	display.adapt(viewsNode, x, y)
  bg:addChild(viewsNode)
  if scal then
      viewsNode:setScale(scal)
  end
    local views=baseEffect.views
    baseEffect:addEffect("allViews",viewsNode)
    local temp
    temp=views.jinji_1
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",25/60,1.2,1.2},{"delay",25/60},{"scaleTo",10/60,1.0,1.0}})))
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",25/60,0},{"delay",30/60},{"fadeTo",5/60,90}})))
    temp=views.Sprite_6
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",30/60,25},{"fadeTo",30/60,179}})))

    return viewsNode
end

--声望达成特效
function UIeffectsManage:showEffect_prestigeReach(bg,x,y,z,scal)
  local node = ui.csbNode("UICsb/prestigereach.csb")
  display.adapt(node,x,y,GConst.Anchor.Center)
  bg:addChild(node,z)
  node:setScaleX(scal or 1)
  node:setScaleY(scal or 1)
  local function callRomeve()
    node:removeFromParent(true)
  end
  node:runAction(ui.action.sequence({{"delay",3.0},{"call",callRomeve}}))

  local action = ui.csbTimeLine("UICsb/prestigereach.csb")
  node:runAction(action)
  action:gotoFrameAndPlay(0,true)

end

--竞技场进度条特效
function UIeffectsManage:showEffect_arenaprogress(bg,x,y,z,scal)
  local node = ui.csbNode("UICsb/arenaprogress.csb")
  display.adapt(node,x,y,GConst.Anchor.LeftBottom)
  bg:addChild(node,z)
  bg.view:setScaleX(scal or 1)
  local action = ui.csbTimeLine("UICsb/arenaprogress.csb")
  node:runAction(action)
  action:gotoFrameAndPlay(0,true)
end


--竞技场宝箱特效
function UIeffectsManage:showEffect_arenabox(bg,x,y,z,scal)
  local node = ui.csbNode("UICsb/arenabox.csb")
  display.adapt(node,2*715+x,y,GConst.Anchor.Center)
  bg:addChild(node,z)
  node:setScaleX(scal or 1)
  node:setScaleY(scal*1.1 or 1)
  local action = ui.csbTimeLine("UICsb/arenabox.csb")
  node:runAction(action)
  action:gotoFrameAndPlay(0,false)
end


--不死之心复活特效
function UIeffectsManage:showEffect_busizhixinfuhuo(bg,x,y,z,scal)
  local node = ui.csbNode("UICsb/equip2005resur.csb")
  display.adapt(node,x,y,GConst.Anchor.Center)
  bg:addChild(node,1)
  node:setScale(scal or 1)
  local action = ui.csbTimeLine("UICsb/equip2005resur.csb")
  node:runAction(action)
  action:gotoFrameAndPlay(0,false)
end



--不死之心
function UIeffectsManage:showEffect_busizhixin(bg,x,y,z,scal)
  local node = ui.csbNode("UICsb/equip2005_1.csb")
  display.adapt(node,x,y,GConst.Anchor.Center)
  bg:addChild(node,1)
  node:setScale(scal or 1)
  local action = ui.csbTimeLine("UICsb/equip2005_1.csb")
  node:runAction(action)
  action:gotoFrameAndPlay(0,true)

  local node = ui.csbNode("UICsb/equip2005_2.csb")
  display.adapt(node,x,y-10,GConst.Anchor.Center)
  bg:addChild(node,-1)
  node:setScale(scal or 1)
  local action = ui.csbTimeLine("UICsb/equip2005_2.csb")
  node:runAction(action)
  action:gotoFrameAndPlay(0,true)

end

--战争挽歌
function UIeffectsManage:showEffect_zhanzhengwange(bg,x,y,z,scal)
  local node = ui.csbNode("UICsb/equip2006_1.csb")
  display.adapt(node,x,y,GConst.Anchor.Center)
  bg:addChild(node,1)
  node:setScale(scal or 1)
  local action = ui.csbTimeLine("UICsb/equip2006_1.csb")
  node:runAction(action)
  action:gotoFrameAndPlay(0,true)

  local node = ui.csbNode("UICsb/equip2006_2.csb")
  display.adapt(node,x+25,y-20,GConst.Anchor.Center)
  bg:addChild(node,-1)
  node:setScale(scal or 1)
  local action = ui.csbTimeLine("UICsb/equip2006_2.csb")
  node:runAction(action)
  action:gotoFrameAndPlay(0,true)
end

--装备狂暴
function UIeffectsManage:showEffect_kuangbao(bg,x,y,z,scal)
  local node = ui.csbNode("UICsb/equip2007_1.csb")
  display.adapt(node,x,y,GConst.Anchor.Center)
  bg:addChild(node,1)
  node:setScale(scal or 1)
  local action = ui.csbTimeLine("UICsb/equip2007_1.csb")
  node:runAction(action)
  action:gotoFrameAndPlay(0,true)

  local node = ui.csbNode("UICsb/equip2007_2.csb")
  display.adapt(node,x+10,y-20,GConst.Anchor.Center)
  bg:addChild(node,-1)
  node:setScale(0.9)
  local action = ui.csbTimeLine("UICsb/equip2007_2.csb")
  node:runAction(action)
  action:gotoFrameAndPlay(0,true)
end

--手链
function UIeffectsManage:showEffect_rock(bg,x,y,z,scal)
  local node = ui.csbNode("UICsb/equip2008.csb")
  display.adapt(node,x,y,GConst.Anchor.Center)
  bg:addChild(node,1)
  node:setScale(scal or 1)
  local action = ui.csbTimeLine("UICsb/equip2008.csb")
  node:runAction(action)
  action:gotoFrameAndPlay(0,true)
end

--权杖
function UIeffectsManage:showEffect_wand(bg,x,y,z,scal)
    local node = ui.csbNode("UICsb/equip2009.csb")
    display.adapt(node,x,y,GConst.Anchor.Center)
    bg:addChild(node,1)
    node:setScale(scal or 1)
    local action = ui.csbTimeLine("UICsb/equip2009.csb")
    node:runAction(action)
    action:gotoFrameAndPlay(0,true)
end

--对酒按钮
function UIeffectsManage:showEffect_duijiuanniu(bg,x,y)--传入按钮中心坐标
	local baseEffect=GameEffect.new("ui_duijiuanniu.json",self.path)
	local viewsNode=ui.node()
	display.adapt(viewsNode, x, y+4)
    bg:addChild(viewsNode)
    --viewsNode:setScale(1.5)
    local views=baseEffect.views
    baseEffect:addEffect("allViews",viewsNode)
    return viewsNode
end

---首充按钮
function UIeffectsManage:showEffect_shouchonganniu(bg,x,y,z,scal)--传入按钮中心坐标
  local baseEffect=GameEffect.new("ui_ShouChongT.json",self.path)
    local viewsNode_up=ui.node()
    display.adapt(viewsNode_up, x, y)
    bg:addChild(viewsNode_up,z or -1)
    viewsNode_up:setScale(scal or 0.5)
    local viewsNode_down=ui.node()
    display.adapt(viewsNode_down, x, y)
    bg:addChild(viewsNode_down,z or -10)
    viewsNode_down:setScale(scal or 0.5)
    local views=baseEffect.views
    local temp
    baseEffect:addEffect("views_up",viewsNode_up)
    temp=views.guangci1025_2
    temp:runAction(ui.action.arepeat(ui.action.rotateBy(140/60,360)))
    temp=views.guangci1025_2_0
    temp:runAction(ui.action.arepeat(ui.action.rotateBy(140/60,360)))
    baseEffect:addEffect("views_down",viewsNode_down)

    return viewsNode_up,viewsNode_down
end

--远征关卡
function UIeffectsManage:showEffect_guangka(bg,x,y,mode)--传入关卡中心坐标,mode,蓝色,橙色
	local baseEffect=GameEffect.new("ui_guangka.json",self.path)
	local viewsNode=ui.node()
	display.adapt(viewsNode, x, y)
    bg:addChild(viewsNode,10)
    local views=baseEffect.views
    local temp
    if mode==1 then
    	baseEffect:addEffect("allViews1",viewsNode)

    elseif mode==2 then
    	baseEffect:addEffect("allViews2",viewsNode)
      temp=views.Sprite_6
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",45/60,255},{"fadeTo",45/60,102}})))
      temp=views.Sprite_6_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",45/60,255},{"fadeTo",45/60,102}})))
    end



    return viewsNode
end
--联盟战
function UIeffectsManage:showEffect_lianmenzhan(bg,x,y)--传入中心坐标
	local baseEffect=GameEffect.new("ui_lianmenzhan.json",self.path)
	local viewsNode=ui.node()
	display.adapt(viewsNode, x, y)
    bg:addChild(viewsNode)
    local views=baseEffect.views

    baseEffect:addEffect("allViews",viewsNode)

    return viewsNode
end
--释放技能时按钮上特效
function UIeffectsManage:showEffect_zhanduiUI(bg,x,y)
    local effectId = _effectManager:registerGameEffect("game/GameEffect/effectsConfig/ui_zhanduiUI.json")
    local viewsNode = ui.node()
    display.adapt(viewsNode, x, y)
    bg:addChild(viewsNode)

    _effectManager:addGameEffect(viewsNode, effectId, "allViews", 0, 0, 0)

    return viewsNode
end

--技能升级
function UIeffectsManage:showEffect_jinengshenji(bg,x,y,scal)
	local baseEffect=GameEffect.new("ui_jinengshenji.json",self.path)
	local viewsNode=ui.node()
	display.adapt(viewsNode, x, y)
  bg:addChild(viewsNode)
  if scal then
    viewsNode:setScale(scal)
  end
    local views=baseEffect.views

    baseEffect:addEffect("allViews",viewsNode)
    local temp
    temp=views.base_rtert_1
    temp:runAction(ui.action.sequence({{"delay",0/60},{"moveBy",20/60,0,120}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",20/60,0}}))
    temp=views.rtert_1_0
    temp:runAction(ui.action.sequence({{"delay",10/60},{"moveBy",20/60,0,120}}))
    temp:runAction(ui.action.sequence({{"delay",10/60},{"fadeTo",20/60,0}}))
    temp=views.Particle_1
    temp:setAutoRemoveOnFinish(true)

    viewsNode:runAction(ui.action.sequence({{"delay",40/60},"remove"}))
end
--佣兵升级
function UIeffectsManage:showEffect_yonbingshenji(mode,bg,x,y,z,scal)
  local baseEffect=GameEffect.new("ui_yonbingshenji.json",self.path)
  local viewsNode=ui.node()
  display.adapt(viewsNode, x, y)
  bg:addChild(viewsNode,z or 0)
  viewsNode:setScale(scal or 1)
  viewsNode:runAction(ui.action.sequence({{"delay",60/60},"remove"}))

  local views=baseEffect.views

  local temp
  if mode==1 then--头像上的
    baseEffect:addEffect("allViews",viewsNode)
      temp=views.base_JiaoS_8
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,229},{"fadeTo",20/60,51},{"fadeTo",20/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",50/60},"remove"}))
      temp=views.XianTiao_01_00002_2
      temp:runAction(ui.action.sequence({{"delay",40/60},{"fadeTo",12/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",52/60},"remove"}))
      temp=views.XianTiao_01_00002_2_0
      temp:runAction(ui.action.sequence({{"delay",40/60},{"fadeTo",12/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",52/60},"remove"}))
      temp=views.UP_00016_3
      temp:runAction(ui.action.sequence({{"delay",30/60},{"moveBy",20/60,0,85}}))
      temp:runAction(ui.action.sequence({{"scaleTo",20/60,2.0,2.0},{"scaleTo",10/60,1.8,1.8}}))
      temp:runAction(ui.action.sequence({{"fadeTo",20/60,255},{"delay",20/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",50/60},"remove"}))
      temp=views.UP_00016_3_0
      temp:runAction(ui.action.sequence({{"delay",30/60},{"moveBy",20/60,0,85}}))
      temp:runAction(ui.action.sequence({{"scaleTo",20/60,2.0,2.0},{"scaleTo",10/60,1.8,1.8}}))
      temp:runAction(ui.action.sequence({{"fadeTo",20/60,255},{"delay",20/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",50/60},"remove"}))
      temp=views.ish_kapailevelup_4
      temp:runAction(ui.action.sequence({{"delay",30/60},{"moveBy",20/60,0,48}}))
      temp:runAction(ui.action.sequence({{"scaleTo",20/60,1.0,1.0},{"scaleTo",10/60,0.95,0.95},{"scaleTo",20/60,0.95,0.95}}))
      temp:runAction(ui.action.sequence({{"fadeTo",20/60,255},{"delay",10/60},{"fadeTo",20/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",50/60},"remove"}))
      temp=views.ish_kapailevelup_4_0
      temp:runAction(ui.action.sequence({{"delay",30/60},{"moveBy",20/60,0,48}}))
      temp:runAction(ui.action.sequence({{"scaleTo",20/60,1.0,1.0},{"scaleTo",10/60,0.95,0.95},{"scaleTo",20/60,0.95,0.95}}))
      temp:runAction(ui.action.sequence({{"fadeTo",20/60,255},{"delay",10/60},{"fadeTo",20/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",50/60},"remove"}))
  elseif mode==2 then --按钮上的
    baseEffect:addEffect("butViews",viewsNode)
    temp=views.JiaoS_9
    temp:runAction(ui.action.sequence({{"fadeTo",7/60,178},{"fadeTo",18/60,0}}))
  end
end

--觉醒
function UIeffectsManage:showEffect_juexing(bg,x,y)
	local baseEffect=GameEffect.new("ui_juexing.json",self.path)
	local viewsNode=ui.node()
	display.adapt(viewsNode, x, y)
    bg:addChild(viewsNode)
    local views=baseEffect.views

    baseEffect:addEffect("allViews",viewsNode)
    local temp
    temp=views.base_Sprite_2
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",30/60,25},{"fadeTo",30/60,76}})))

    temp=views.guangzhuan_1
	temp:runAction(ui.action.arepeat(ui.action.rotateBy(30/60,-180)))
    return viewsNode
end

--十尾合成
function UIeffectsManage:showEffect_weishouhechen(bg,x,y)--传入中间十尾位置
	x=x or 645
	y=y or 712

	local baseEffect=GameEffect.new("ui_weishouhechen.json",self.path)
	local viewsNode=ui.node()
	display.adapt(viewsNode, x, y)
    bg:addChild(viewsNode)
    local views=baseEffect.views

    baseEffect:addEffect("views_delay0",viewsNode)
    local temp
    temp=views.base_shiwei_1
    temp:runAction(ui.action.sequence({{"delay",70/60},{"scaleTo",10/60,0.6,0.6},{"delay",65/60},{"scaleTo",5/60,1.5,1.5}}))

	local beastPos={{647,1114},{926,1016},{1032,773},{1002,505},{794,323},{503,313},{307,506},{263,771},{378,1021}}

	local circleNode=ui.node()
	display.adapt(circleNode, 0, 0)
    viewsNode:addChild(circleNode,1)
    circleNode:runAction(ui.action.sequence({{"delay",30/60},{"rotateBy",40/60,180},"remove"}))
	for i,pos in ipairs(beastPos) do
		baseEffect:addEffect("views_delay0_par",circleNode)
		temp=views.Particle_1
		temp:setPosition(pos[1]-x,pos[2]-y)
		temp:runAction(ui.action.scaleTo(30/60,2.5,2.5))
		temp:runAction(ui.action.sequence({{"delay",30/60},{"moveTo",40/60,0,0}}))

		temp=views.Particle_2
		temp:setPosition(pos[1]-x,pos[2]-y)
		temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
    end
    local function delay70()
    	baseEffect:addEffect("views_delay70",viewsNode)
    	  temp=views.guangquan1_1_0_0_0
	      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",40/60,1.97,1.97}}))
	      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",40/60,247}}))
	      temp:runAction(ui.action.sequence({{"delay",40/60},"remove"}))
    end
    viewsNode:runAction(ui.action.sequence({{"delay",70/60},{"call",delay70}}))

    local function delay80()
    	baseEffect:addEffect("views_delay80",viewsNode)
    	  temp=views.guangquan1_1_0_0
	      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",40/60,1.97,1.97}}))
	      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",40/60,247}}))
	      temp:runAction(ui.action.sequence({{"delay",40/60},"remove"}))
    end
    viewsNode:runAction(ui.action.sequence({{"delay",80/60},{"call",delay80}}))

    local function delay90()
    	baseEffect:addEffect("views_delay90",viewsNode)
    	  temp=views.guangquan1_1_0
	      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",40/60,1.97,1.97}}))
	      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",40/60,247}}))
	      temp:runAction(ui.action.sequence({{"delay",40/60},"remove"}))
    end
    viewsNode:runAction(ui.action.sequence({{"delay",90/60},{"call",delay90}}))

    local function delay145()
    	baseEffect:addEffect("views_delay145",viewsNode)
    	 temp=views.Particle_34
	     temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",5/60,3.0,3.0}}))
    end
    viewsNode:runAction(ui.action.sequence({{"delay",145/60},{"call",delay145}}))

    local function delay149()
    	baseEffect:addEffect("views_delay149",viewsNode)
    	  temp=views.guangquan1_1
	      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,4.2697,4.2697},{"scaleTo",25/60,13.7772,13.7772}}))
	      temp:runAction(ui.action.sequence({{"delay",1/60},{"fadeTo",30/60,0}}))

    	 temp=views.Sprite_5
	     temp:runAction(ui.action.arepeat(ui.action.rotateBy(80/60,360)))

    end
    viewsNode:runAction(ui.action.sequence({{"delay",149/60},{"call",delay149}}))

    return viewsNode
end
--被动洗炼
function UIeffectsManage:showEffect_beidongxilian(mode,bg,x,y,i)--传入中间位置,点亮哪个
	x=x or 584
	y=y or 715
	local skillPos={{721, 1038},{452, 1038},{265, 849},{265, 586},{452, 401},{721, 401},{904, 586},{904, 849}}

	local baseEffect=GameEffect.new("ui_beidongxilian.json",self.path)
	local viewsNode=ui.node()
	display.adapt(viewsNode, x, y)
  bg:addChild(viewsNode)
  local views=baseEffect.views
  local temp
  if mode==1 then
        baseEffect:addEffect("views_delay80",viewsNode)
        temp=views.Sprite_5
        temp:setPosition(skillPos[i][1]-x,skillPos[i][2]-y)
        temp:runAction(ui.action.sequence({{"delay",15/60},"remove"}))
        temp=views.Sprite_5_0
        temp:setPosition(skillPos[i][1]-x,skillPos[i][2]-y)
        temp:runAction(ui.action.sequence({{"delay",15/60},"remove"}))
        temp=views.Sprite_5_0_0
        temp:setPosition(skillPos[i][1]-x,skillPos[i][2]-y)
        temp:runAction(ui.action.sequence({{"delay",15/60},"remove"}))
  elseif mode==2 then
      baseEffect:addEffect("views_delay0",viewsNode)
      temp=views.Particle_1
      temp:runAction(ui.action.sequence({{"delay",60/60},"remove"}))
      temp=views.base_Sprite_7
      temp:runAction(ui.action.sequence({{"delay",60/60},"remove"}))
  end
  viewsNode:runAction(ui.action.sequence({{"delay",95/60},"remove"}))
end

--僵尸场景特效
function UIeffectsManage:showEffect_jiangshiCJ(bg,x,y)--场景中心位置
    local baseEffect=GameEffect.new("ui_jiangshiCJ.json",self.path)
    local viewsNode=ui.node()
    display.adapt(viewsNode, x, y)
    bg:addChild(viewsNode)
    local views=baseEffect.views
    baseEffect:addEffect("allViews",viewsNode)

    return viewsNode
end

--荒野场景特效
function UIeffectsManage:showEffect_huanyeCJ(bg,x,y,isSceneUmland)--场景中心位置
    local baseEffect=GameEffect.new("ui_huanyeCJ.json",self.path)
    local viewsNode=ui.node()
    display.adapt(viewsNode, x, y)
    bg:addChild(viewsNode)
    local views=baseEffect.views
    local temp
    baseEffect:addEffect("allViews",viewsNode)
      temp=views.guangying_2
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",50/60,17},{"fadeTo",50/60,0}})))
    if not isSceneUmland then
      baseEffect:addEffect("allViews_2",viewsNode)
      temp=views.guangyan_3
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",50/60,120},{"fadeTo",50/60,38}})))
      temp=views.guangyan_3_1
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",50/60,120},{"fadeTo",50/60,38}})))
      temp=views.guangyan_3_1_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",50/60,120},{"fadeTo",50/60,38}})))
      temp=views.guangyan_3_1_0_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",50/60,120},{"fadeTo",50/60,38}})))
      temp=views.guangyan_3_1_1
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",50/60,120},{"fadeTo",50/60,38}})))
      temp=views.guangyan_3_1_1_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",50/60,120},{"fadeTo",50/60,38}})))
      temp=views.guangyan_3_1_1_0_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",50/60,120},{"fadeTo",50/60,38}})))
      temp=views.guangyan_3_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",50/60,120},{"fadeTo",50/60,38}})))
      temp=views.guangyan_3_0_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",50/60,120},{"fadeTo",50/60,38}})))
      temp=views.guangyan_3_0_0_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",50/60,120},{"fadeTo",50/60,38}})))
      temp=views.guangyan_3_0_0_0_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",50/60,120},{"fadeTo",50/60,38}})))
      temp=views.guangyan_3_0_0_0_0_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",50/60,120},{"fadeTo",50/60,38}})))
      temp=views.guangyan_3_0_0_0_0_0_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",50/60,120},{"fadeTo",50/60,38}})))
      temp=views.guangyan_3_0_0_0_0_0_0_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",50/60,120},{"fadeTo",50/60,38}})))
      temp=views.guangyan_3_0_0_0_0_0_0_0_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",50/60,120},{"fadeTo",50/60,38}})))
    end
    return viewsNode
end

--科幻场景特效
function UIeffectsManage:showEffect_kehuanCJ(bg,x,y)--场景中心位置
    local baseEffect=GameEffect.new("ui_kehuanCJ.json",self.path)
    local viewsNode=ui.node()
    display.adapt(viewsNode, x, y)
    bg:addChild(viewsNode)
    local views=baseEffect.views
    baseEffect:addEffect("allViews",viewsNode)
      local temp
    local cT=200/60
      temp=views.jianguang_2
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",15/60},{"fadeTo",30/60,255},{"fadeTo",30/60,0},{"delay",cT-75/60}})))
      temp=views.jianguang_2_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",30/60,255},{"fadeTo",30/60,0},{"delay",cT-60/60}})))
      temp=views.jianguang_2_0_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",30/60},{"fadeTo",30/60,255},{"fadeTo",30/60,0},{"delay",cT-90/60}})))
      --100/60
      temp=views.fanguang_11
      temp:runAction(ui.action.arepeat(ui.action.sequence({"show",{"moveBy",28/60,83,-62},{"moveBy",2/60,14,0},{"moveBy",2/60,15,0},{"moveBy",38/60,202,0},{"moveBy",30/60,91,64},"hide",{"moveTo",0/60,-134,-1263}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",20/60,0.76,0.32},{"scaleTo",8/60,0.36,0.32},{"scaleTo",22/60,1.2,0.32},{"scaleTo",22/60,0.36,0.32},{"scaleTo",13/60,0.7,0.32},{"scaleTo",15/60,0.36,0.32}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",28/60},{"rotateBy",2/60,-34},{"rotateBy",38/60,-7},{"rotateBy",2/60,-39},{"delay",30/60},{"rotateBy",0/60,80}})))
      temp=views.fanguang_12
      temp:runAction(ui.action.arepeat(ui.action.sequence({"show",{"moveBy",40/60,137,-102},{"moveBy",30/60,0,-120},{"moveBy",30/60,-155,-116},"hide",{"moveTo",0/60,1708,142}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",39/60},{"rotateBy",1/60,-38},{"delay",29/60},{"rotateBy",1/60,45},{"delay",30/60},{"rotateBy",0/60,-7}})))
      temp=views.fanguang_13
      temp:setVisible(false)
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",25/60},"show",{"moveBy",20/60,0,68},{"moveBy",2/60,3,11},{"moveBy",3/60,5,7},{"moveBy",50/60,134,103},"hide",{"moveTo",0/60,-1756,-8}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",25/60},{"scaleTo",10/60,0.8,0.35},{"scaleTo",10/60,0.4,0.35},{"scaleTo",30/60,0.8,0.3408},{"scaleTo",25/60,0.4,0.33},{"scaleTo",0/60,0.4,0.35}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",45/60},{"rotateBy",5/60,48},{"delay",50/60},{"rotateBy",0/60,-48}})))
      temp=views.fanguang_1
      temp:runAction(ui.action.arepeat(ui.action.sequence({"show",{"moveBy",20/60,-83,58},{"moveBy",2/60,-9,6},{"moveBy",3/60,-15,2},{"moveBy",50/60,-232,0},{"moveBy",2/60,-11,-2},{"moveBy",3/60,-12,-7},{"moveBy",20/60,-78,-56},"hide",{"moveTo",0/60,236,1235}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",25/60},{"scaleTo",25/60,0.4,0.8},{"scaleTo",25/60,0.4,0.3},{"scaleTo",15/60,0.4,0.6},{"scaleTo",10/60,0.4,0.3}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",20/60},{"rotateBy",5/60,-40},{"delay",50/60},{"rotateBy",5/60,-40},{"delay",20/60},{"rotateBy",0/60,80}})))

      temp=views.jianguang_2_1
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",105/60},{"fadeTo",30/60,255},{"fadeTo",30/60,0},{"delay",cT-165/60}})))
      temp=views.jianguang_2_0_1
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",90/60},{"fadeTo",30/60,255},{"fadeTo",30/60,0},{"delay",cT-150/60}})))
      temp=views.jianguang_2_0_0_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",120/60},{"fadeTo",30/60,255},{"fadeTo",30/60,0},{"delay",cT-180/60}})))

      temp=views.Sprite_8
      temp:runAction(ui.action.arepeat(ui.action.sequence({"show",{"delay",30/60},"hide",{"delay",60/60}})))

    return viewsNode
end

--主界面活动图标特效
function UIeffectsManage:showEffect_huodong(bg,x,y)
    local baseEffect=GameEffect.new("ui_huodong.json",self.path)
    local viewsNode=ui.node()
    display.adapt(viewsNode, x, y)
    bg:addChild(viewsNode)
    local views=baseEffect.views
    baseEffect:addEffect("allViews",viewsNode)

    return viewsNode
end

--好友宝箱特效
function UIeffectsManage:showEffect_haoyoubaoxiang(bg,x,y)--场景中心位置
    local baseEffect=GameEffect.new("ui_haoyoubaoxiang.json",self.path)
    local viewsNode=ui.node()
    display.adapt(viewsNode, x, y)
    bg:addChild(viewsNode)
    local zNode=ui.node()
    display.adapt(zNode, x, y)
    zNode:setScaleY(0.5)
    bg:addChild(zNode)

    local views=baseEffect.views

    baseEffect:addEffect("zViews",zNode)
      local temp
      temp=views.zhuanpan
      temp:runAction(ui.action.arepeat(ui.action.rotateBy(120/60,180)))

    baseEffect:addEffect("allViews",viewsNode)

      temp=views.sdf1_3_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",10/60},{"scaleTo",60/60,1.0,2.2},{"scaleTo",0/60,0.7,1.2}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",10/60},{"fadeTo",30/60,255},{"fadeTo",30/60,0}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",10/60},{"rotateBy",60/60,-32},{"rotateBy",0/60,32}})))
      temp=views.sdf1_3
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",0/60},{"scaleTo",60/60,1.2,-2.0571},{"delay",10/60},{"scaleTo",0/60,0.7,-1.2}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",30/60,255},{"fadeTo",30/60,0},{"delay",10/60}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"rotateBy",60/60,30},{"delay",10/60},{"rotateBy",0/60,-30}})))

      temp=views.sdf1_3_0_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",15/60},{"scaleTo",40/60,1.2,2.0571},{"delay",15/60},{"scaleTo",0/60,0.7,1.2}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",15/60},{"fadeTo",20/60,255},{"fadeTo",20/60,0},{"delay",15/60}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",15/60},{"rotateBy",40/60,-40},{"delay",15/60},{"rotateBy",0/60,40}})))
      temp=views.sdf1_3_1
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",5/60},{"scaleTo",50/60,1.0,-1.7143},{"delay",15/60},{"scaleTo",0/60,0.6,-1.0286}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",5/60},{"fadeTo",25/60,170},{"fadeTo",25/60,0},{"delay",15/60}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",5/60},{"rotateBy",50/60,28},{"delay",15/60},{"rotateBy",0/60,-28}})))

    return viewsNode
end

--炼金阵选中和时钟特效
function UIeffectsManage:showEffect_lianjingzhen(mode,bg,x,y)--mode:1选中，2时钟
    local baseEffect=GameEffect.new("ui_lianjingzhen.json",self.path)
    local viewsNode=ui.node()
    display.adapt(viewsNode, x, y)
    bg:addChild(viewsNode,3)
    local views=baseEffect.views
    local temp
    if mode==1 then
      baseEffect:addEffect("allViews1",viewsNode)
      temp=views.xuanzhong_1_0
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",30/60,1.2,1.2}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",30/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
    elseif mode==2 then
      baseEffect:addEffect("allViews2",viewsNode)
      temp=views.kkk_4
      temp:runAction(ui.action.arepeat(ui.action.rotateBy(90/60,360)))
      temp=views.kkk_4_0
      temp:runAction(ui.action.arepeat(ui.action.rotateBy(90/60,360)))
    end
    return viewsNode
end
--熔炼英雄完成特效
function UIeffectsManage:showEffect_melting(bg,x,y)
  local viewsNode=ui.node()
  display.adapt(viewsNode, x, y)
  bg:addChild(viewsNode)
  viewsNode:runAction(ui.action.sequence({{"delay",0.7},"remove"}))
    local p=ui.animateSprite(0.7,"kapian",7,{beginNum=0,plist="images/dialogs/upgrade_kapianposui.plist",isRepeat=false})
    display.adapt(p, 0, 0, GConst.Anchor.Center)
    viewsNode:addChild(p)
    p:setOpacity(0)
    p:runAction(ui.action.sequence({{"fadeIn",0.4}, {"delay",0.3},"remove"}))
    p = ui.particle("images/dialogs/chibaokai.plist")
    p:setPosition(0, 0)
    p:setPositionType(cc.POSITION_TYPE_GROUPED)
    viewsNode:addChild(p)
end

--经营等级提升
function UIeffectsManage:showEffect_jinyingtishen(bg,x,y,expNum)
  local baseEffect=GameEffect.new("ui_jinyingtishen.json",self.path)
  local viewsNode=ui.node()
  display.adapt(viewsNode, x, y,GConst.Anchor.Center)
  bg:addChild(viewsNode,20)
  viewsNode:setScale(ui.getUIScale2())
  viewsNode:runAction(ui.action.sequence({{"delay",70/60},"remove"}))

  baseEffect:addEffect("allViews",viewsNode)
  local views=baseEffect.views
    local temp
      temp=views.base_jinyan_3
      temp:runAction(ui.action.sequence({{"delay",5/60},{"moveBy",5/60,0,-98},{"moveBy",3/60,0,-20},{"moveBy",2/60,0,20}}))
      temp:runAction(ui.action.sequence({{"delay",10/60},{"scaleTo",3/60,3.0,2.7},{"scaleTo",2/60,3.0,3.0}}))
      temp:runAction(ui.action.sequence({{"delay",5/60},{"fadeTo",10/60,255},{"delay",35/60},{"fadeTo",20/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",70/60},"remove"}))
      temp = ui.label(StringManager.getString(expNum), General.font1, 140, {color={255,255,255}})
      display.adapt(temp, 0, 98, GConst.Anchor.Center)
      viewsNode:addChild(temp,3)
      temp:runAction(ui.action.sequence({{"delay",5/60},{"moveBy",5/60,0,-98},{"moveBy",3/60,0,-20},{"moveBy",2/60,0,20}}))
      temp:runAction(ui.action.sequence({{"delay",5/60},{"fadeTo",10/60,255},{"delay",35/60},{"fadeTo",20/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",70/60},"remove"}))
      temp=views.jinyanguang_4_0
      temp:runAction(ui.action.sequence({{"delay",15/60},{"fadeTo",15/60,255},{"fadeTo",20/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",50/60},"remove"}))
end

--每日登录奖励
function UIeffectsManage:showEffect_meiriqiandao(mode,bg,x,y,z)
    local baseEffect=GameEffect.new("ui_meiriqiandao.json",self.path)
    local viewsNode=ui.node()
    display.adapt(viewsNode, x, y)
    bg:addChild(viewsNode,z or 0)

    local temp
    if mode==1 then
        baseEffect:addEffect("allViews1",viewsNode)
        local back = baseEffect.views.base_yinzhan_2
        temp = ui.label(StringManager.getString("labelAlreadyReceive"),General.font2,65,{color = {252,41,41}})
        display.adapt(temp,138,90,GConst.Anchor.Center)
        temp:setRotation(-15)
        back:addChild(temp)
        temp:setOpacity(0)
        temp:runAction(ui.action.fadeIn(0.5))
    elseif mode==2 then
        baseEffect:addEffect("allViews2", viewsNode)
    end
end

--十连抽特效
function UIeffectsManage:showEffect_ShiLianChou(mode,bg,x,y,z,heroInfo,scale)
  local baseEffect=GameEffect.new("ui_ShiLianChou.json",self.path)
  local viewsNode=ui.node()
  display.adapt(viewsNode, x, y)
  bg:addChild(viewsNode,z or 0)
  local _scale = scale or 1
  local temp
  if mode==0 then
    baseEffect:addEffect("views_0",viewsNode)
    local views=baseEffect.views
    return viewsNode
  elseif mode==1 then
    baseEffect:addEffect("views_1",viewsNode)
    local views=baseEffect.views
    temp=views.JiaoS_4
    temp:runAction(ui.action.sequence({{"scaleTo",7/60,1.6,1.6},{"scaleTo",38/60,1.9,1.9}}))
    temp:runAction(ui.action.sequence({{"fadeTo",7/60,255},{"delay",3/60},{"fadeTo",35/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",45/60},"remove"}))
    temp=views.JiaoS_4_0
    temp:runAction(ui.action.sequence({{"scaleTo",7/60,1.6,1.6},{"scaleTo",38/60,2.3,2.3}}))
    temp:runAction(ui.action.sequence({{"fadeTo",7/60,255},{"fadeTo",38/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",45/60},"remove"}))
    viewsNode:runAction(ui.action.sequence({{"delay",45/60},"remove"}))

  elseif  mode==2 then
    baseEffect:addEffect("views_2",viewsNode)
    local views=baseEffect.views
    temp=views.JiaoS_4_2
    temp:runAction(ui.action.sequence({{"scaleTo",7/60,1.6,1.6},{"scaleTo",38/60,1.9,1.9}}))
    temp:runAction(ui.action.sequence({{"fadeTo",7/60,255},{"delay",3/60},{"fadeTo",35/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",45/60},"remove"}))
    temp=views.JiaoS_4_0_2
    temp:runAction(ui.action.sequence({{"scaleTo",7/60,1.6,1.6},{"scaleTo",38/60,2.3,2.3}}))
    temp:runAction(ui.action.sequence({{"fadeTo",7/60,255},{"fadeTo",38/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",45/60},"remove"}))
    viewsNode:runAction(ui.action.sequence({{"delay",45/60},"remove"}))
  elseif  mode==3 then
    if _scale~=1 then
      viewsNode:setScale(_scale)
    end
    baseEffect:addEffect("views_3",viewsNode)
    local views=baseEffect.views
      temp=views.GF_472_5
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",7/60,4.0,4.0},{"scaleTo",23/60,6.0,6.0}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",7/60,255},{"fadeTo",23/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
      temp=views.GF_472_5_0
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",7/60,3.0,3.0},{"scaleTo",23/60,5.0,5.0}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",7/60,127},{"fadeTo",23/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
      temp=views.JiaoS_4_0_0
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",7/60,1.6,1.6},{"scaleTo",23/60,1.9,1.9}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",7/60,255},{"fadeTo",23/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
      temp=views.Sprite_10
      temp:runAction(ui.action.sequence({{"delay",6/60},{"fadeTo",7/60,255},{"fadeTo",18/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",31/60},"remove"}))
      temp=views.UIguang_00000_12
      temp:runAction(ui.action.sequence({{"delay",24/60},{"fadeTo",6/60,255}}))
  elseif mode==4 then
      baseEffect:addEffect("views_4",viewsNode)
      local views=baseEffect.views
      temp=views.BeiJingGuang_2
      temp:runAction(ui.action.sequence({{"delay",45/60},{"fadeTo",5/60,204},{"fadeTo",32/60,178}}))
      temp:runAction(ui.action.arepeat(ui.action.rotateBy(45/60,180)))
      temp=views.GF_472_12
      temp:runAction(ui.action.sequence({{"delay",50/60},{"scaleTo",8/60,6.0,6.0},{"scaleTo",28/60,10.0,10.0}}))
      temp:runAction(ui.action.sequence({{"delay",50/60},{"fadeTo",8/60,255},{"fadeTo",28/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",86/60},"remove"}))
      temp=views.GF_472_12_0
      temp:runAction(ui.action.sequence({{"delay",50/60},{"scaleTo",8/60,5.0,5.0},{"scaleTo",28/60,8.0,8.0}}))
      temp:runAction(ui.action.sequence({{"delay",50/60},{"fadeTo",8/60,255},{"fadeTo",28/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",86/60},"remove"}))
      temp=views.GF_472_7_0
      temp:runAction(ui.action.sequence({{"delay",27/60},{"scaleTo",8/60,7.0,7.0},{"scaleTo",15/60,10.0,10.0}}))
      temp:runAction(ui.action.sequence({{"delay",27/60},{"fadeTo",8/60,255},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",50/60},"remove"}))
      temp=views.JiaoS_5
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",30/60,3.0,4.2},{"scaleTo",10/60,4.0,5.2}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",30/60,255},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",40/60},"remove"}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"rotateBy",30/60,360}}))

      temp=views.JiaoS_5_0
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",30/60,3.0,4.2},{"scaleTo",20/60,5.0,6.2}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"delay",15/60},{"fadeTo",15/60,255},{"fadeTo",20/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",50/60},"remove"}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"rotateBy",30/60,360}}))
      temp=views.GF_472_7
      temp:runAction(ui.action.sequence({{"delay",27/60},{"scaleTo",8/60,8.0,8.0},{"scaleTo",15/60,12.0,12.0}}))
      temp:runAction(ui.action.sequence({{"delay",27/60},{"fadeTo",8/60,255},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",50/60},"remove"}))

      local featrue=GameUI.addHeroFeature(viewsNode, heroInfo.hid, 1, 0, 351-768, 15, false)
      featrue:setOpacity(0)
      featrue:setScale(0.2)
      featrue:runAction(ui.action.sequence({{"scaleTo",30/60,1.3,1.3},{"delay",20/60},{"scaleTo",10/60,1.0,1.0}}))
      featrue:runAction(ui.action.sequence({{"delay",25/60},{"fadeTo",5/60,255}}))
      featrue:runAction(ui.action.rotateBy(30/60,360))

      temp = ui.label(StringManager.getFormatString("titleGetHeroTips"), General.font1, 60,{color={255,127,0}})
      display.adapt(temp, 0, 1226-768, GConst.Anchor.Center)
      viewsNode:addChild(temp)
      temp:setOpacity(0)
      local ls=temp:getScaleX()
      temp:setScale(ls*0.5)
      temp:runAction(ui.action.sequence({{"delay",30/60},{"fadeTo",20/60,255}}))
      temp:runAction(ui.action.sequence({{"delay",30/60},{"scaleTo",20/60,ls*1.1,ls*1.1},{"scaleTo",10/60,ls*1.0,ls*1.0}}))
      GameUI.addSSR(viewsNode,heroInfo.displayColor and heroInfo.displayColor >= 5 and 5 or heroInfo.rating,1,temp:getContentSize().width/2+50,1226-800,0)

      local nameNode=ui.node()
      display.adapt(nameNode, 0, 277-768, GConst.Anchor.Center)
      viewsNode:addChild(nameNode,30)
      nameNode:setScale(0.5)
      nameNode:runAction(ui.action.sequence({{"delay",30/60},{"scaleTo",20/60,1.05,1.05},{"scaleTo",10/60,1,1}}))

      temp = ui.sprite("images/dialogItemRibbon.png",{428, 145})
      display.adapt(temp, -214, -28, GConst.Anchor.Center)
      nameNode:addChild(temp)
      temp:setFlippedX(true)
      temp:setOpacity(0)
      temp:runAction(ui.action.sequence({{"delay",30/60},{"fadeTo",30/60,255}}))

      temp = ui.sprite("images/dialogItemRibbon.png",{428, 145})
      display.adapt(temp, 214, -28, GConst.Anchor.Center)
      nameNode:addChild(temp)
      temp:setOpacity(0)
      temp:runAction(ui.action.sequence({{"delay",30/60},{"fadeTo",30/60,255}}))
      temp = ui.label(heroInfo.name, General.font1, 45,{color={255,255,255}})
      display.adapt(temp, 0, 0, GConst.Anchor.Center)
      nameNode:addChild(temp)
      temp:setOpacity(0)
      temp:runAction(ui.action.sequence({{"delay",30/60},{"fadeTo",30/60,255}}))
      return viewsNode
  elseif mode==5 then
      baseEffect:addEffect("views_4",viewsNode)
      local views=baseEffect.views
      temp=views.BeiJingGuang_2
      temp:runAction(ui.action.sequence({{"delay",45/60},{"fadeTo",5/60,204},{"fadeTo",32/60,178}}))
      temp:runAction(ui.action.arepeat(ui.action.rotateBy(45/60,180)))
      temp=views.GF_472_12
      temp:runAction(ui.action.sequence({{"delay",50/60},{"scaleTo",8/60,6.0,6.0},{"scaleTo",28/60,10.0,10.0}}))
      temp:runAction(ui.action.sequence({{"delay",50/60},{"fadeTo",8/60,255},{"fadeTo",28/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",86/60},"remove"}))
      temp=views.GF_472_12_0
      temp:runAction(ui.action.sequence({{"delay",50/60},{"scaleTo",8/60,5.0,5.0},{"scaleTo",28/60,8.0,8.0}}))
      temp:runAction(ui.action.sequence({{"delay",50/60},{"fadeTo",8/60,255},{"fadeTo",28/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",86/60},"remove"}))
      temp=views.GF_472_7_0
      temp:runAction(ui.action.sequence({{"delay",27/60},{"scaleTo",8/60,7.0,7.0},{"scaleTo",15/60,10.0,10.0}}))
      temp:runAction(ui.action.sequence({{"delay",27/60},{"fadeTo",8/60,255},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",50/60},"remove"}))
      temp=views.JiaoS_5
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",30/60,3.0,4.2},{"scaleTo",10/60,4.0,5.2}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",30/60,255},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",40/60},"remove"}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"rotateBy",30/60,360}}))

      temp=views.JiaoS_5_0
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",30/60,3.0,4.2},{"scaleTo",20/60,5.0,6.2}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"delay",15/60},{"fadeTo",15/60,255},{"fadeTo",20/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",50/60},"remove"}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"rotateBy",30/60,360}}))
      temp=views.GF_472_7
      temp:runAction(ui.action.sequence({{"delay",27/60},{"scaleTo",8/60,8.0,8.0},{"scaleTo",15/60,12.0,12.0}}))
      temp:runAction(ui.action.sequence({{"delay",27/60},{"fadeTo",8/60,255},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",50/60},"remove"}))

      local featrue=GameUI.addEquipFeature(viewsNode, heroInfo.eid, 1,768-768, 15)
      featrue:setOpacity(0)
      featrue:setScale(0.2)
      featrue:runAction(ui.action.sequence({{"scaleTo",30/60,1.3,1.3},{"delay",20/60},{"scaleTo",10/60,1.0,1.0}}))
      featrue:runAction(ui.action.sequence({{"delay",25/60},{"fadeTo",5/60,255}}))
      featrue:runAction(ui.action.rotateBy(30/60,360))

      temp = ui.label(StringManager.getFormatString("titleGetHeroTips"), General.font1, 60,{color={255,127,0}})
      display.adapt(temp, 0, 1226-768, GConst.Anchor.Center)
      viewsNode:addChild(temp)
      temp:setOpacity(0)

      local nameNode=ui.node()
      display.adapt(nameNode, 0, 277-768, GConst.Anchor.Center)
      viewsNode:addChild(nameNode,30)
      nameNode:setScale(0.5)
      nameNode:runAction(ui.action.sequence({{"delay",30/60},{"scaleTo",20/60,1.05,1.05},{"scaleTo",10/60,1,1}}))

      temp = ui.sprite("images/dialogItemRibbon.png",{428, 145})
      display.adapt(temp, -214, -28, GConst.Anchor.Center)
      nameNode:addChild(temp)
      temp:setFlippedX(true)
      temp:setOpacity(0)
      temp:runAction(ui.action.sequence({{"delay",30/60},{"fadeTo",30/60,255}}))

      temp = ui.sprite("images/dialogItemRibbon.png",{428, 145})
      display.adapt(temp, 214, -28, GConst.Anchor.Center)
      nameNode:addChild(temp)
      temp:setOpacity(0)
      temp:runAction(ui.action.sequence({{"delay",30/60},{"fadeTo",30/60,255}}))
      temp = ui.label(heroInfo.name, General.font1, 45,{color={255,255,255}})
      display.adapt(temp, 0, 0, GConst.Anchor.Center)
      nameNode:addChild(temp)
      temp:setOpacity(0)
      temp:runAction(ui.action.sequence({{"delay",30/60},{"fadeTo",30/60,255}}))
  end

end

--战斗能量条动画
function UIeffectsManage:showEffect_nengLiangTiao(mode,bg,baseScale,node,i)--mode，1能量未满，2满
  if mode==1 then
    if i==10 then
      return
    end
    bg:runAction(ui.action.sequence({{"scaleTo",0.08,(baseScale+0.04),0.393},{"scaleTo",0.08,baseScale,0.393}}))
    local temp=ui.sprite("images/GuangLiang_00000.png")
    display.adapt(temp, 83+160*(i-0.5), 28, GConst.Anchor.LeftBottom)
    node:addChild(temp,3)
    temp:setScaleX(0.9325*0.5)
    temp:setScaleY(0.564)
    local blend={}
    blend.src=1
    blend.dst=1
    temp:setBlendFunc(blend)
    temp:runAction(ui.action.sequence({{"scaleTo",10/60,1.0057*0.5,0.564*1.0},{"scaleTo",5/60,0.9288*0.5,0.564*1.0}}))
    temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",5/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
  elseif mode==2 then
    local effNode2=bg
    local temp1=ui.sprite("images/BaiTiao01.png")
    display.adapt(temp1, 0, 0, GConst.Anchor.Left)
    effNode2:addChild(temp1,3)
    temp1:setColor(cc.c3b(255,248,169))
    local blend={}
    blend.src=1
    blend.dst=1
    temp1:setBlendFunc(blend)
    temp1:setScaleX(0)
    temp1:setScaleY(0.56)
    temp1:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",190/60,4.31,0.56},{"fadeOut",30/60},{"scaleTo",0,0,0.56},{"fadeIn",0},{"delay",50/60}})))
    local temp2=ui.sprite("images/BaiTiao01.png")
    display.adapt(temp2, 0, 0, GConst.Anchor.Left)
    effNode2:addChild(temp2,3)
    local blend={}
    blend.src=1
    blend.dst=1
    temp2:setBlendFunc(blend)
    temp2:setScaleX(0)
    temp2:setScaleY(0.56)
    temp2:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",190/60,4.31,0.56},{"fadeOut",30/60},{"scaleTo",0,0,0.56},{"fadeIn",0},{"delay",50/60}})))
    local function delay135( ... )
        local temp3=ui.sprite("images/BaiTiao01.png")
        display.adapt(temp3, 0, 0, GConst.Anchor.Left)
        effNode2:addChild(temp3,3)
        temp3:setColor(cc.c3b(255,248,169))
        local blend={}
        blend.src=1
        blend.dst=1
        temp3:setBlendFunc(blend)
        temp3:setScaleX(0)
        temp3:setScaleY(0.56)
        temp3:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",190/60,4.31,0.56},{"fadeOut",30/60},{"scaleTo",0,0,0.56},{"fadeIn",0},{"delay",50/60}})))
        local temp4=ui.sprite("images/BaiTiao01.png")
        display.adapt(temp4, 0, 0, GConst.Anchor.Left)
        effNode2:addChild(temp4,3)
        local blend={}
        blend.src=1
        blend.dst=1
        temp4:setBlendFunc(blend)
        temp4:setScaleX(0)
        temp4:setScaleY(0.56)
        temp4:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",190/60,4.31,0.56},{"fadeOut",30/60},{"scaleTo",0,0,0.56},{"fadeIn",0},{"delay",50/60}})))
    end
    effNode2:runAction(ui.action.sequence({{"delay",135/60},{"call",delay135}}))
  end
end
--战斗结束宝箱打开特效
function UIeffectsManage:showEffect_BaoXiangOpen(bg,x,y)
  local baseEffect=GameEffect.new("ui_BaoXiangOpen.json",self.path)
  local viewsNode=ui.node()
  display.adapt(viewsNode, x, y)
  bg:addChild(viewsNode)
  viewsNode:runAction(ui.action.sequence({{"delay",0.8},"remove"}))
  baseEffect:addEffect("allViews",viewsNode)
  local views=baseEffect.views
  local temp

  temp=views.BaoHeGuang02_3
  temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",35/60},{"fadeTo",10/60,0}}))
  temp:runAction(ui.action.sequence({{"delay",55/60},"remove"}))
  temp=views.BaoHeGuang02_3_0
  temp:runAction(ui.action.sequence({{"fadeTo",5/60,127},{"delay",40/60},{"fadeTo",10/60,0}}))
  temp:runAction(ui.action.sequence({{"delay",55/60},"remove"}))
  temp=views.Particle_1
  temp:runAction(ui.action.sequence({{"delay",51/60},"remove"}))
  temp=views.BeiJingGuang_5
  temp:runAction(ui.action.sequence({{"delay",70/60},"remove"}))
end
--wiff
function UIeffectsManage:showEffect_wiff(bg,x,y,z)
  local baseEffect=GameEffect.new("ui_wiff.json",self.path)
  local viewsNode=ui.node()
  display.adapt(viewsNode, x, y)
  bg:addChild(viewsNode,z or 0)

  baseEffect:addEffect("allViews",viewsNode)
  local views=baseEffect.views
  local temp=views.Sprite_2
  temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",10/60,102},{"fadeTo",10/60,255}})))

  return viewsNode
end
--loding
function UIeffectsManage:showEffect_loding(bg,x,y,z)
  local baseEffect=GameEffect.new("ui_loding.json",self.path)
  local viewsNode=ui.node()
  display.adapt(viewsNode, x, y)
  bg:addChild(viewsNode,z or 0)
  local back=ui.colorNode(display.winSize,{0,0,0,178})
  display.adapt(back, 0, 0,GConst.Anchor.Center)
  viewsNode:addChild(back)
  baseEffect:addEffect("allViews",viewsNode)
  local views=baseEffect.views

  return viewsNode
end
--宣传图特效
function UIeffectsManage:showEffect_xuanchuan(id,bg,x,y,z)
  local baseEffect=GameEffect.new("ui_xuanchuan.json",self.path)
  local viewsNode=ui.node({960,640})
  display.adapt(viewsNode, x, y+30)
  bg:addChild(viewsNode,z or 0)
  if id==1 then
    baseEffect:addEffect("allViews_1",viewsNode)
    local views=baseEffect.views
      temp=views.SF4_00000_1
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",4/60},{"fadeTo",1/60,0},{"delay",1/60},{"fadeTo",1/60,128},{"fadeTo",4/60,102},{"fadeTo",1/60,0},{"delay",1/60},{"fadeTo",1/60,102},{"delay",4/60},{"fadeTo",1/60,0},{"delay",1/60},{"fadeTo",1/60,102},{"delay",4/60},{"fadeTo",1/60,0}})))
      temp=views.GuangH02_2
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",20/60,4.0,-0.3008},{"scaleTo",30/60,5.0,-0.376},{"scaleTo",0/60,2.0,-0.1504}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",20/60},{"fadeTo",30/60,0},{"fadeTo",0/60,255}})))
      temp=views.GuangH02_2_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",20/60,4.0,-0.3008},{"scaleTo",30/60,5.0,-0.376},{"scaleTo",0/60,2.0,-0.1504}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",20/60},{"fadeTo",30/60,0}})))
      temp=views.TgaF01_3
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",25/60,127},{"fadeTo",25/60,51}})))
      temp=views.Redsf221_4
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",25/60,114},{"fadeTo",25/60,76}})))


  elseif id==2 then

  elseif id==3 then

  end
  return viewsNode
end

--英雄复活特特效
function UIeffectsManage:showEffect_heroFuhuo(bg,x,y,z)
  local baseEffect=GameEffect.new("ui_heroFuhuo.json",self.path)
  local viewsNode=ui.node()
  display.adapt(viewsNode, x, y)
  bg:addChild(viewsNode,z or 0)
  local views=baseEffect.views
  local initPos={0,0,0}
  local temp

   viewsNode:runAction(ui.action.sequence({{"delay",97/60},"remove"}))

   --  local function delayFrameIndex_59()
   --   baseEffect:addEffect("views2_delay59",viewsNode)
   --    temp=views.Relive_00000_18
   --    temp:setPosition(initPos[1],initPos[2]+40)
   --    temp:setLocalZOrder(initPos[3]+1)
   --    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",36/60},{"fadeTo",1/60,0}}))
   --    temp:runAction(ui.action.sequence({{"delay",38/60},"remove"}))
   -- end
   -- viewsNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_59}}))

   local function delayFrameIndex_65()
     baseEffect:addEffect("views2_delay65",viewsNode)
      temp=views.Circle_Hue130_1
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]-1)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",10/60,1,0.75}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",10/60},"remove"}))
      temp=views.Glow_01_2_0
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+3)
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,177},{"delay",110/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",125/60},"remove"}))
      temp=views.Glow_01_2
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+4)
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",110/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",125/60},"remove"}))
   end
   viewsNode:runAction(ui.action.sequence({{"delay",6/60},{"call",delayFrameIndex_65}}))

   -- local function delayFrameIndex_94()
   --   baseEffect:addEffect("views2_delay94",viewsNode)
   --    temp=views.Line_00000_19_0
   --    temp:setPosition(initPos[1],initPos[2]+40)
   --    temp:setLocalZOrder(initPos[3]+2)
   --    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",95/60},{"fadeTo",1/60,0}}))
   --    temp:runAction(ui.action.sequence({{"delay",97/60},"remove"}))
   -- end
   -- viewsNode:runAction(ui.action.sequence({{"delay",35/60},{"call",delayFrameIndex_94}}))
end
--联盟神兽宝箱奖励
function UIeffectsManage:showEffect_BaoXiangT(bg,x,y)
    local baseEffect=GameEffect.new("ui_BaoXiangT.json",self.path)
    local viewsNode_up=ui.node()
    display.adapt(viewsNode_up, x, y)
    bg:addChild(viewsNode_up,1)
    viewsNode_up:setScale(0.6)
    local viewsNode_down=ui.node()
    display.adapt(viewsNode_down, x, y)
    bg:addChild(viewsNode_down,10)
    viewsNode_down:setScale(0.6)
    local views=baseEffect.views
    local temp
    baseEffect:addEffect("views_up",viewsNode_up)
    temp=views.guangci1025_2
    temp:runAction(ui.action.arepeat(ui.action.rotateBy(140/60,360)))
    temp=views.guangci1025_2_0
    temp:runAction(ui.action.arepeat(ui.action.rotateBy(140/60,360)))
    baseEffect:addEffect("views_down",viewsNode_down)

    return viewsNode_up,viewsNode_down
end

--远征鼓舞
function UIeffectsManage:showEffect_GuWu(bg,x,y,z)
    local baseEffect=GameEffect.new("ui_GuWu.json",self.path)
    local viewsNode=ui.node()
    display.adapt(viewsNode, x, y)
    bg:addChild(viewsNode,z or 0)
    viewsNode:setScale(1.2)
    local views=baseEffect.views
    local temp
    local xTime=45/60
    baseEffect:addEffect("allViews",viewsNode)
    temp=views.LiuBianXing0001_2
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",5/60},{"fadeTo",7/60,255},{"fadeTo",23/60,0},{"delay",xTime-35/60}})))
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",5/60},{"scaleTo",30/60,0.9,0.9},{"scaleTo",0/60,0.6,0.6},{"delay",xTime-35/60}})))
    temp=views.LiuBianXing0001_2_0
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",15/60},{"fadeTo",7/60,255},{"fadeTo",23/60,0},{"delay",xTime-45/60}})))
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",15/60},{"scaleTo",30/60,0.8,0.8},{"scaleTo",0/60,0.6,0.6},{"delay",xTime-45/60}})))
    temp=views.GF_472_4
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",6/60,255},{"fadeTo",14/60,0},{"delay",xTime-20/60}})))
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",20/60,4,4},{"scaleTo",0/60,1,1},{"delay",xTime-20/60}})))
    temp=views.GF_472_4_0
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",6/60,255},{"fadeTo",14/60,0},{"delay",xTime-20/60}})))
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",20/60,3.5,3.5},{"scaleTo",0/60,1,1},{"delay",xTime-20/60}})))

    viewsNode:runAction(ui.action.sequence({{"delay",xTime},{"remove"}}))
end



--竞技场段位提升
function UIeffectsManage:showEffect_upArenaStage(bg,x,y,z,scal)
  local node = ui.csbNode("UICsb/upArenaStage.csb")
  display.adapt(node,x,y,GConst.Anchor.Center)
  bg:addChild(node)
  node:setScale(scal or 1)
  local action = ui.csbTimeLine("UICsb/upArenaStage.csb")
  node:runAction(action)
  action:gotoFrameAndPlay(0,false)
end

--Facebook
function UIeffectsManage:showEffect_facebook(bg,x,y,z,scal)
    local animateSprite = ui.animateSprite(0.833,"effectsGridLight_", 5,{beginNum=0,plist="effects/uiEffects.plist",isRepeat=true})
    display.adapt(animateSprite, x-2, y, GConst.Anchor.Center)
    animateSprite:setOpacity(127)
    bg:addChild(animateSprite)
    animateSprite:setScale((scal or 1)*1.4)
    ui.setBlend(animateSprite, 770, 1)
end
--分享至facebook
function UIeffectsManage:showEffect_share(bg,x,y,z,shareIdx,itemID)
    local shareFacebook = Handler(GameLogic.doShare, "hero", shareIdx, itemID)
    local shareBtn = ui.button({400, 207}, shareFacebook, {image=nil})
    display.adapt(shareBtn, x, y, GConst.Anchor.Center)
    bg:addChild(shareBtn,z or 0)
    local temp = ui.sprite("images/btnGreen.png", {300, 107})
    if temp then
        display.adapt(temp, 200, 103.5, GConst.Anchor.Center)
        shareBtn:getDrawNode():addChild(temp, -1)
    end
    GameLogic.addStatLog(1001, shareIdx, itemID, 1)
    Plugins:onStat({callKey=5,eventId="shareBtnShow",params={["content" .. shareIdx .. "_" .. itemID]=1}})
    local label = ui.label(Localize("btnToShowOff"), General.font1, 47)
    display.adapt(label, 200, 114, GConst.Anchor.Center)
    shareBtn:getDrawNode():addChild(label)
    return shareBtn
end

return UIeffectsManage
