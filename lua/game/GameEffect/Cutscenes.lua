--过场动画
local Cutscenes = class2("Cutscenes",function()
    return ui.node({960,640})
end)
function Cutscenes:ctor()
	self.path="game/GameEffect/effectsConfig/"
end
--传送门
function Cutscenes:show_ChuanSongMen()
  local node = ui.csbNode("CsbRes/ChuangSongMen.csb")
  display.adapt(node,480,320+80,GConst.Anchor.Center)
  self:addChild(node)
  node:setScale(2)
  local action = ui.csbTimeLine("CsbRes/ChuangSongMen.csb")
  node:runAction(action)
  action:gotoFrameAndPlay(0,true)
end

--男僵尸追博士
function Cutscenes:show_NanJsZuiBS()
  local node = ui.csbNode("CsbRes/NanJsZuiBS.csb")
  display.adapt(node,480,100,GConst.Anchor.Center)
  self:addChild(node)
  node:setScale(1.2)
  local action = ui.csbTimeLine("CsbRes/NanJsZuiBS.csb")
  node:runAction(action)
  action:gotoFrameAndPlay(0,true)
end

--死神VS雷神
function Cutscenes:show_sishenVSleishen()
  local node = ui.csbNode("CsbRes/ShiShenVSLeiShen.csb")
  display.adapt(node,460,400,GConst.Anchor.Center)
  self:addChild(node)
  node:setScale(1)
  local action = ui.csbTimeLine("CsbRes/ShiShenVSLeiShen.csb")
  node:runAction(action)
  action:gotoFrameAndPlay(0,true)
end

--雷神VS僵尸
function Cutscenes:show_leishenVSjs()
  local node = ui.csbNode("CsbRes/LeiShenVsJS.csb")
  display.adapt(node,480,0,GConst.Anchor.Center)
  self:addChild(node)
  node:setScale(1)
  local action = ui.csbTimeLine("CsbRes/LeiShenVsJS.csb")
  node:runAction(action)
  action:gotoFrameAndPlay(0,true)
end

--绿巨人打僵尸
function Cutscenes:show_hulkVSjs()
    local node = ui.csbNode("CsbRes/hulkVSjs.csb")
    display.adapt(node,480,160,GConst.Anchor.Center)
    self:addChild(node)
    node:setScale(0.8)
    local action = ui.csbTimeLine("CsbRes/hulkVSjs.csb")
    node:runAction(action)
    action:gotoFrameAndPlay(0,true)
end

return Cutscenes