
--做一个node的壳  统一把用node的class改了
--如果有发现没有加的方法  出错了 就自己加上
local ShellNode = class2("ShellNode")

function ShellNode:ctor(view)
    self.view = view
end

function ShellNode:addChild(c,z)
    return self.view:addChild(c,z or 0)
end

function ShellNode:setPosition(x,y)
    return self.view:setPosition(x,y)
end

function ShellNode:setPositionX(x)
    return self.view:setPositionY(x)
end

function ShellNode:setPositionY(y)
    return self.view:setPositionY(y)
end

function ShellNode:getPositionX()
    return self.view:getPositionX()
end

function ShellNode:getPositionY()
    return self.view:getPositionY()
end

function ShellNode:getPosition()
    return self.view:getPosition()
end

function ShellNode:setLocalZOrder(z)
    return self.view:setLocalZOrder(z)
end

function ShellNode:setEnable(b)
    return self.view:setEnable(b)
end

function ShellNode:removeFromParent(b)
    return self.view:removeFromParent(b)
end

function ShellNode:setScale(s)
    return self.view:setScale(s)
end

function ShellNode:setScaleX(s)
    return self.view:setScaleX(s)
end

function ShellNode:setScaleY(s)
    return self.view:setScaleY(s)
end

function ShellNode:getScale()
    return self.view:getScale()
end

function ShellNode:getScaleX()
    return self.view:getScaleX()
end

function ShellNode:getScaleY()
    return self.view:getScaleY()
end

function ShellNode:setContentSize(x,y)
    if y then
        return self.view:setContentSize(x,y)
    else
        return self.view:setContentSize(x)
    end
end

function ShellNode:getContentSize()
    return self.view:getContentSize()
end

function ShellNode:setSValue(v)
    return self.view:setSValue(v)
end

function ShellNode:setHValue(v)
    return self.view:setSValue(v)
end

function ShellNode:setLValue(v)
    return self.view:setSValue(v)
end

function ShellNode:setScrollEnable(b)
    return self.view:setScrollEnable(b)
end

function ShellNode:getParent()
    return self.view:getParent()
end

function ShellNode:stopAllActions()
    return self.view:stopAllActions()
end

function ShellNode:stopActionByTag(t)
    return self.view:stopActionByTag(t)
end

function ShellNode:runAction(a)
    return self.view:runAction(a)
end

function ShellNode:removeAllChildren(b)
    return self.view:removeAllChildren(b)
end

function ShellNode:setColor(r,g,b)
    return self.view:setColor(cc.c3b(r,g,b))
end

function ShellNode:setOpacity(o)
    return self.view:setOpacity(o)
end

function ShellNode:setVisible(v)
    return self.view:setVisible(v)
end

function ShellNode:setAnchorPoint(x,y)
    return self.view:setAnchorPoint(x,y)
end

function ShellNode:setCascadeOpacityEnabled(b)
    return self.view:setCascadeOpacityEnabled(b)
end

function ShellNode:retain()
    return self.view:retain()
end

function ShellNode:release()
    return self.view:release()
end

return ShellNode


