local SquareMapView = {}
local ui = _G["ui"]

local _view
local _batch
local _size
local _specialBack
local _specialGrid

local _views = {}
local _squTab = {}
local _squTab1 = {}
local _squTab2 = {}
local _xoff = 3
local _yoff = 3
local _snum = 46 
for i=1, _snum*_snum do
    _views[i] = 0
    _squTab[i] = 0
    _squTab1[i] = 0
    _squTab2[i] = 0
end

local _gridSettings = 
{
    {0,-90},{0,180},{1,-90},{0,360},{1,360},
    {0,360},{2,-90},{0,90},{0,-90},{1,180},
    {2,180},{1,90},{2,360},{2,90},{3,360}
}


function SquareMapView.initView(scene, size, sx, sy)
    --memory.loadSpriteSheet("images/grid.plist")
    _batch = ui.node()
    _batch:setCascadeOpacityEnabled(true)
    _batch:setCascadeColorEnabled(true)
    _view = ui.node()
    _size = size
    _view:setScaleY(sy/(_size*1.414))
    _view:setScaleX(-sx/(_size*1.414))
    _batch:setRotation(-45)
    _view:addChild(_batch)
    RegTimeUpdate(_view, SquareMapView.update, 0.05)
    _specialBack = ui.node()
    _specialBack:setRotation(-45)
    _view:addChild(_specialBack)
    _specialBack:setVisible(false)
    _specialGrid = CaeShaderNode:create("egrid", cc.size(0,0))
    _specialGrid:setAnchorPoint(cc.p(0,0))
    _specialGrid:setColor(cc.c3b(255,0,0))
    _specialBack:addChild(_specialGrid)
    return _view
end

function SquareMapView.setSpecialLimitGrids(lg)
    if lg then
        _specialBack:setVisible(true)
        local w, h = _size*(lg[2]-lg[1]+1),_size*(lg[4]-lg[3]+1)
        _specialGrid:setContentSize(cc.size(w, h))
        _specialGrid:setShaderUniform4f(w, h, 10, 5)
        _specialGrid:setPosition(_size*lg[1], _size*lg[3])
    else
        _specialBack:setVisible(false)
    end
end

function SquareMapView.getBatch()
    return _batch
end

function SquareMapView.getView()
    return _view
end

function SquareMapView.setGridUse(gx, gy, size)
    local xs, ys = gx + _xoff, gy + _yoff
    local xe, ye = xs + size - 1, ys + size - 1
    for i = xs, xe do
        for j = ys, ye do
            _squTab[i*_snum + j] = _squTab[i*_snum + j] + 1
        end
    end
    SquareMapView.dirty = true
end

function SquareMapView.clearGridUse(gx, gy, size)
    local xs, ys = gx + _xoff, gy + _yoff
    local xe, ye = xs + size - 1, ys + size - 1
    for i = xs, xe do
        for j = ys, ye do
            _squTab[i*_snum + j] = _squTab[i*_snum + j] - 1
        end
    end
    SquareMapView.dirty = true
end

function SquareMapView.update()
    if SquareMapView.locked then
        return
    end
    if SquareMapView.dirty then
        SquareMapView._initPoint()
        SquareMapView.createPoint()
        SquareMapView.dirty = false
    end
end

function SquareMapView._initPoint()
    for i = 2, _snum-1 do
        for j= 2, _snum-1 do
            local num1, num2, num3, num4=0,0,0,0
            if _squTab[(i-1) * _snum + j-1] > 0 then
                num1 = 1
            end 
            if _squTab[i*_snum + j-1]>0 then
                num2=1
            end 
            if _squTab[(i-1)*_snum +j]>0 then
                num3=1
            end 
            if _squTab[i*_snum+j]>0 then
                num4=1
            end
            local num = num1*8+num2*4+num3*2+num4
            _squTab1[i*_snum+j] = num
        end
    end
end

function SquareMapView.createPoint()
    local pt, k
    for i = 2, _snum-1 do
        for j = 2, _snum-1 do
            k = i * _snum + j 
            if _squTab1[k] ~= _squTab2[k] then
                local num = _squTab1[k]
                _squTab2[k] = _squTab1[k]
                local _gset = _gridSettings[num]
                if _views[k] and _views[k]~=0 then
                    _views[k]:removeFromParent(true)
                    _views[k] = nil
                end
                if _gset and num~=6 and num ~=9 then
                    _views[k] = ui.sprite("grid" .. _gset[1] .. ".png")
                    _views[k]:setRotation(_gset[2])
                    _batch:addChild(_views[k])
                    display.adapt(_views[k], (i-_xoff)*_size, (j-_xoff)*_size, GConst.Anchor.Center)
                elseif num==6 or num ==9 then
                    _views[k] = ui.sprite("grid0.png")
                    _views[k]:setCascadeOpacityEnabled(true)
                    _views[k]:setCascadeColorEnabled(true)      
                    local b = ui.sprite("grid0.png")
                    b:setRotation(180)
                    _views[k]:addChild(b)
                    display.adapt(b, b:getContentSize().width/2, b:getContentSize().height/2, GConst.Anchor.Center)
                    _batch:addChild(_views[k])
                    display.adapt(_views[k], (i-_xoff)*_size, (j-_xoff)*_size, GConst.Anchor.Center)
                    _views[k]:setRotation(_gset[2])
                end
            end
        end
    end
end

function SquareMapView.checkGridEmpty(gx, gy)
    local k = (gx + _xoff)*_snum + gy + _yoff
    if _squTab[k] > 0 then
        return false
    else
        return true
    end
end

return SquareMapView
