
local ScrollLabel = class2("ScrollLabel",function(scrollNode)
    local scrollNode = ScrollNode:create(cc.size(0,0), 0, false, true)
    scrollNode:setScrollEnable(true)
    scrollNode:setInertia(true)
    scrollNode:setClip(true)
    scrollNode:setElastic(true)
    scrollNode:setScaleEnable(true,1,1,1,1)
    scrollNode:setScrollContentRect(cc.rect(0,0,0,0))
    return scrollNode
end)

function ScrollLabel:ctor(text, fontName, fontSize, setting)
    self.fontName=fontName
    self.fontSize=fontSize
    self.setting=setting
    self:init(text, fontName, fontSize, setting)
    self:setAnchorPoint2(0,0)--默认锚点
end

function ScrollLabel:init(text, fontName, fontSize, setting)
    local label = ui.label(text, fontName, fontSize, setting)
    self.label=label

    local labelW = label:getContentSize().width
    local labelH = label:getContentSize().height
    local width = setting.width or label:getContentSize().width
    local height = setting.height or label:getContentSize().height
    self.labelW=labelW
    self.labelH=labelH
    self.width=width
    self.height=height
    self.offx=setting.offx or 0
    self.offy=setting.offy or 0
    self.scrollEnable=true
    if (labelH+self.offy)<=height then
        --self:setScrollEnable(false)
        self.scrollEnable=false
        self:addChild(label)--不可拖动
    else
        self:getScrollNode():addChild(label)--可拖动
    end
    self:setContentSize(cc.size(width,height))

    -- local color=ui.colorNode({width,height},{255,0,0})
    -- color:setPosition(0,0)
    -- color:setOpacity(0.5*255)
    -- self:addChild(color)
end

function ScrollLabel:setAnchorPoint2(x,y)
    self:setAnchorPoint(cc.p(x,y))
    self.label:setAnchorPoint(cc.p(x,y))
    
    if self.scrollEnable then
        self.label:setPosition(self.width*x+self.offx,self.height*y-self.offy-(self.labelH-self.height)*(1-y))
        self:setScrollContentRect(cc.rect(0,(-self.labelH+self.height)*y-(self.labelH-self.height)*(1-y)-self.offy,0,self.labelH+self.offy))
    else
        self.label:setPosition(self.width*x+self.offx,self.height*y-self.offy)
        self:setScrollContentRect(cc.rect(0,(-self.labelH+self.height)*y,0,self.labelH))
    end
end

function ScrollLabel:setString(text)
    local anchor=self.label:getAnchorPoint()
    self.label:removeFromParent(true)
    self:init(text,self.fontName,self.fontSize,self.setting)
    self:setAnchorPoint2(anchor.x,anchor.y)
end

function ScrollLabel:getString()
   return self.label:getString()
end

return ScrollLabel
