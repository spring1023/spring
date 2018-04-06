--放一些c++的宏定义函数
function INT2STR(v)
	return v..""
end

function STR2INT(v)
	return tonumber(v)
end

RAND_MAX = 0x7fff
function rand()
	return math.floor(math.random() * RAND_MAX)
end

function cast(instance,typename)
	instance = tolua.cast(instance,typename)
	return instance
end

function strlen(instance)
	return instance:len()
end

function sprintf(buf,fmt,...)
	return string.format(fmt,...)
end

function CCPOINT_OFFSET(p,offsetX,offsetY)
	return ccp(p.x + (offsetX), p.y + (offsetY) )
end

function CSEQ(...) return cc.Sequence:create(...) end

function CFUNC_N(f)	return cc.CallFunc:create(f) end

function CCNODE_REMOVE(p)
	if p then
		p:removeFromParentAndCleanup(true)
	end
	p = nil
	return nil
end

function CCNODE_PT_OFFSET(n,x,y)
	return ccp(n:getPositionX()+(x), n:getPositionY()+(y))
end

function CCNODE_PT_CENTER(n)
	return ccp(n:getContentSize().width/2, n:getContentSize().height/2)
end

function CCNODE_PT_CENTER_OFF(n,x,y)
	return ccp(n:getContentSize().width/2+x, n:getContentSize().height/2+y)
end

function AC_DL(...) return cc.DelayTime:create(...) end
function AC_F2(...) return cc.FadeTo:create(...) end
function AC_M2(...) return cc.MoveTo:create(...) end
function AC_MY(...) return cc.MoveBy:create(...) end
function AC_S2(...) return cc.ScaleTo:create(...) end
function AC_R2(...) return cc.RotateTo:create(...) end
function AC_RY(...) return cc.RotateBy:create(...) end
function AC_FOUT(...) return cc.FadeOut:create(...) end
function AC_ESIO(...) return cc.EaseSineInOut:create(...) end

function GC(n,t) return (n:getChildByTag(t)) end

SystemHelper = {}
function SystemHelper:DelayRunAction(pSender,  delaySecs,  pSelectorTarget,  selector)
    if(delaySecs <= 0.0) then
        pSender:runAction(CSEQ(CFUNC_N(selector)))
    else
        pSender:runAction(CSEQ(AC_DL(delaySecs), CFUNC_N(selector)))
	end
end

function SystemHelper:AddChild(node,  parent,  anchor,  point)
    node:setAnchorPoint(anchor[1],anchor[2])
    node:setPosition(point)
    parent:addChild(node)
    return node
end

--[[
	字符串辅助函数
]]
StringHelper = {}
function StringHelper:ReadBeforeCharStr( s,  tagChar,  offset,  str)
	--print("ReadBeforeCharStr")
    -- local pos = s.find(tagChar, offset);
    -- if(pos != -1)
        -- str = s.substr(offset, pos - offset);
	local pos = s.find(s, tagChar,offset + 1); --与std:string.find(tag,pos) 返回不同，下标是1开始
	if pos ~= nil then
		pos = pos - 1
	end --匹配cpp
	local temp = ""
	--offset和pos都是0开始，为了匹配c++代码
	if(pos ~= nil and pos > offset) then
		temp = string.sub(s,offset + 1,pos - 1 + 1) --s.substr(offset, pos - offset);
		return pos,temp
	else
		return -1,""
	end
   return -1,""
end

function StringHelper:ReadBeforeCharInt(s,  tagChar,  offset,  intv)
    local str = ""
    local pos,temp = self:ReadBeforeCharStr(s, tagChar, offset, str);
    if(pos ~= -1) then
        temp = tonumber(temp) --intv = atoi(str.c_str());
	end
    return pos,temp
end

function StringHelper:ReadBeforeCharFloat( s, tagChar, offset, v)
    local str = ""
    local pos,temp = self:ReadBeforeCharStr(s, tagChar, offset, str);
    if(pos ~= -1) then
        temp = tonumber(temp) --intv = atoi(str.c_str());
	end
    return pos,temp
end

--[[
	平台判断
]]

function CC_PLATFORM_WIN32()
	local app = cc.Application:getInstance()
	local target = app:getTargetPlatform()
	return target == cc.PLATFORM_OS_WINDOWS
	--return CCApplication:sharedApplication():getTargetPlatform() == kTargetWindows
end

function CC_PLATFORM_ANDROID()
	local app = cc.Application:getInstance()
	local target = app:getTargetPlatform()
	return target == cc.PLATFORM_OS_ANDROID
	--return CCApplication:sharedApplication():getTargetPlatform() == kTargetAndroid
end

function CC_PLATFORM_IOS()
	local app = cc.Application:getInstance()
	local target = app:getTargetPlatform()
	return target == cc.PLATFORM_OS_IPHONE or target == cc.PLATFORM_OS_IPAD
	--return CCApplication:sharedApplication():getTargetPlatform() == kTargetIphone or CCApplication:sharedApplication():getTargetPlatform() == kTargetIpad
end

function CC_PLATFORM_WP()
	local app = cc.Application:getInstance()
	local target = app:getTargetPlatform()
	return target == cc.PLATFORM_OS_WP8 --PLATFORM_OS_WP8 PLATFORM_OS_WINRT
	--return CCApplication:sharedApplication():getTargetPlatform() == kTargetWinRT or CCApplication:sharedApplication():getTargetPlatform() == kTargetWP8
end

function ARRAY_INIT(t,v)
	t = {}
end

function CCNODE_HALF_W(n)
	return n:getContentSize().width/2
end

function CCNODE_HALF_H(n)
	return n:getContentSize().height/2
end

function PosEqual(p1, p2)
    return (math.floor(p1[1]) == math.floor(p2[1])  and  math.floor(p1[2]) == math.floor(p2[2]))
end
--------------------------------------------------------
--GFunc_ 开头的部分
--表示常用的静态函数。类似c++ static
--------------------------------------------------------
function GFunc_calcDistance(srcPos,destPos)
	local xlen = srcPos[1]-destPos[1]
	local ylen = srcPos[2]-destPos[2]
	return math.sqrt(math.pow(xlen,2)+math.pow(ylen,2))
end
function GFunc_setMoneyLabelColor(label,notEnough)
	notEnough = notEnough or false
	if notEnough then
		label:setColor(UICOLOR_RED)
	else
		label:setColor(UICOLOR_BROWNL)
	end
end

function GFunc_GetBinaryTable(num)
	local reTab = {0,0,0,0,0,0,0,0}

	local idx = 8
	num = tonumber(num)
	while(num > 0)do
		local i = num %2
		if(i == 1)then
			reTab[idx] = 1
		else
			reTab[idx] = 0
		end
		idx = idx - 1
		num = math.floor(num/2)
		if(num <= 0)then
			for j=1, idx do
				reTab[j] = 0
			end
			break;
		end
	end

	return reTab
end

function GFunc_BinaryAnd(num1, num2)   --8位二进制
	--print("GFunc_BinaryAnd(), num1: ", num1, "; num2: ", num2)
	local tab1 = GFunc_GetBinaryTable(num1)
	local tab2 = GFunc_GetBinaryTable(num2)
	if(#tab1 >8 or #tab2 >8)then
		return nil;
	end

	local reTab = {0,0,0,0,0,0,0,0}
	local retCount = 0
	for i=1, 8 do
		if(tab1[i] ==1 and tab2[i] == 1)then
			reTab[i] = 1
			retCount = retCount + 2^(8-i)
		else
			reTab[i] = 0
		end
	end

	return retCount;
end

--设置纹理进度条
--progress: 0-1
function GFunc_setSpriteProgress(spr,progress,isHorizontal)
	if type(isHorizontal) ~= "boolean" then isHorizontal  = true end
	if progress > 1 then
		progress = 1
		--llog("error progress in GFunc_setSpriteProgress , is big than 1!:",progress)
	end
	if progress == 0 then
		progress = 0.001
		--llog("error progress in GFunc_setSpriteProgress , is big than 1!:",progress)
	end
	--local texSize = spr:getTexture():getContentSize()
	--local rect = CCRectMake(0,0, texSize.width , texSize.height)
	local rect = spr:getTextureRect();
	--llog("GFunc_setSpriteProgress rect",rect.width,rect.height)
	if isHorizontal then
		rect.width = rect.width * progress;
		--rect = CCRectMake(0,0, texSize.width * progress, texSize.height)
	else
		rect.height = rect.height * progress;
		--rect = CCRectMake(0,0, texSize.width , texSize.height* progress)
	end
    spr:setTextureRect(rect);

end

--延迟删除对象
function GFunc_DelayRemoveSelf(target,sec)
	if type(sec) ~= "number" then sec = 0.1 end
	target:runAction(CSEQ(AC_DL(sec),cc.RemoveSelf:create()))
end

--延迟触发回调
function GFunc_DelayCallFunc(target,func,sec)
	if type(sec) ~= "number" then sec = 0.1 end
	target:runAction(CSEQ(AC_DL(sec),cc.CallFunc:create(func)))
end

function GFunc_lsround( data,digits)
    local tmp = data * math.pow( 10,digits);
    tmp  =  (tmp > 0.0) and math.floor(tmp + 0.5) or math.ceil(tmp - 0.5);
    tmp = tmp / math.pow( 10,digits);
    return tmp;
end

function GFunc_unschedule(v )
	if v then
		scheduler:unscheduleScriptEntry(v)
	end
	return nil
end

--OnAutoClearUpdateL,0,false
--func,seconds
function GFunc_schedule(...)
	local a = {...}
	--print("GFunc_schedule",#a)
	return scheduler:scheduleScriptFunc(a[1],a[2],false)
end

function GFunc_unregisterScriptHandler(target,tp)
	if type(tp) ~= "number" then tp =  cc.Handler.EVENT_CUSTOM_COMMON end
	ScriptHandlerMgr:getInstance():unregisterScriptHandler(target,tp)
end

function GFunc_registerScriptHandler(target,callback,tp)
	if type(tp) ~= "number" then tp =  cc.Handler.EVENT_CUSTOM_COMMON end
	ScriptHandlerMgr:getInstance():registerScriptHandler(target,callback,tp)
end

--获取加号+数字资源
function GFunc_LabelAtlas_PreAdd(texImgFile,num) -- 资源是+0123456789
	--local texImgFile = "ImageNum/image_num_duanzao_yellow.mydp"
	local texSize = CCTextureCache:sharedTextureCache():addImage(texImgFile):getContentSize();
	local _labelNum = CCLabelAtlas:create("", texImgFile, texSize.width/11, texSize.height, 47);
	_labelNum:setString(CCSTR_FMT1("/%d", num )); --从0开始要减去
	return _labelNum
end

-- +号在后面
function GFunc_LabelAtlas(texImgFile,num) -- 资源是0123456789+
	--local texImgFile = "ImageNum/image_num_duanzao_yellow.mydp"
	local texSize = CCTextureCache:sharedTextureCache():addImage(texImgFile):getContentSize();
	local _labelNum = CCLabelAtlas:create("", texImgFile, texSize.width/11, texSize.height, 48);
	_labelNum:setString(CCSTR_FMT1(":%d", num ));
	return _labelNum
end

---------------------------------
--lua utils
--lua语法相关的 table string os ...
---------------------------------
function GetPreciseDecimal(nNum, n)
    if type(nNum) ~= "number" then
        return nNum;
    end

    n = n or 0;
    n = math.floor(n)
    local fmt = '%.' .. n .. 'f'
    local nRet = tonumber(string.format(fmt, nNum))

    return nRet
end

function table_contains(t,v)
	if not t then return false end;
	for _,value in pairs(t) do
		--llog("***table_contains",value , v,type(value), type(v))
		if value == v then
			return true
		end
	end
	return false
end

function table_print(t)
	print("----------------table_print begin:----------------")
	table_printCore(t)
	print("----------------table_print end----------------")
end

--table每个元素与常量相乘
function table_mul(t,val)
	for k,v in pairs(t) do
		t[k] = v*val
	end
	return t
end
--两个table对应元素相加
function table_add(t1,t2)
	local t = {}
	local table_len = math.min(#t1,#t2)
	for i=1,table_len do
		table.insert(t,t1[i]+t2[i])
	end
	return t
end
--传入值table和pos table，返回对应新table的所有元素
function table_item(t_val,t_pos,t_radio, t_radio2)
	t_radio = t_radio or 1
	--print("table_item",t_val,#t_val,t_pos,#t_pos)
	if not t_pos then
		t_pos = {}
		local i=1
		for k,v in pairs(t_val) do
			t_pos[i] = k
			i = i+1
		end
	end

	--table_print(t_val)
	--table_print(t_pos)

	local a = {}
	for i=1,#t_pos do
		local j = tonumber(t_pos[i])
		local value = t_val[j]
		if j == 1 or j == 3 then
			value = value/100
		elseif j == 5 then
			value = value/t_radio
		elseif j == 6 then
			value = value/t_radio2
		end
		table.insert(a,value)
	end

	return unpack(a)
end
--删除无序table中的某一项
function tabel_remove(t,key)
	t[key] = nil
end

function table_printCore(t,prefix)
	if type(t) ~= "table" then return end
	if type(prefix) ~= "string" then prefix = "" end
	for k,v in pairs(t) do
		local name = nil
		if type(t.__cname) == "string" then name = t.__cname end --type(t.__cname) == "string"
		if name then
			print(prefix..t.__cname..":",k,v)
		else
			print(prefix.."no name:",k,v)
		end

		if type(v) == "table" and v ~= t then
			local newprefix = prefix
			if type(t.__cname) == "string" then newprefix = newprefix..t.__cname.."|" end
			table_printCore(v,newprefix)
		else
		end

	end
	local mt = getmetatable(t)
	if mt and type(mt) == "table" and mt ~= t then
		local newprefix = prefix
		if type(t.__cname) == "string" then newprefix = newprefix..t.__cname.." mt|" end
		table_printCore(mt,newprefix)
	end
end

function table_clear(t)
	--这个要注意，#只针对连续数字下标的table
	while(t and #t > 0)
	do
		table.remove(t,1)
	end
	--非连续数字下标的key
	for k,v in pairs(t) do
		t[k] = nil
	end
end

--将表t2插到表t1
function table_insert(t1,t2)
	if not t1 or not t2 then return false end
	for _,value in pairs(t2) do
			table.insert(t1 , value)
	end
	return true
end

--order 默认false 从开始1截取到pos为止   osder为true 则反向截取到pos+1
function table_cut(t , pos , order)
	order = order or false

	if not t then return
		false
	end

	if (pos < 1 and not order) or (pos > #t and order) then
		table_clear(t)
	end

	if order == true then
		pos = #t - pos
	end

	while #t > pos
	do
		table.remove(t , not order and #t or 1)
	end
end

-- t 要排序的表  pos1 起始位置 pos2 结束位置（1.2.pos1..pos2 ..#t) func 要排序的函数依据
function sort(t , pos1 , pos2 , func)
	if not t then
		return false
	end
	if pos1 < 1 or pos2 < 1 or pos1 > #t or pos2 > #t  then
		return false
	end

	local function funcTmp(a , b)
		return a < b
	end

	func = func or funcTmp

	local tmpT1 = clone(t)
	table_cut(tmpT1 , pos1 - 1)

	local tmpT2 = clone(t)
	table_cut(tmpT2 , pos2)
	table_cut(tmpT2 , pos1 - 1 , true)

	local tmpT3 = clone(t)
	table_cut(tmpT3 , pos2 , true)

	table_clear(t)

	if #tmpT1 > 0 then
		table_insert(t , tmpT1)
	end

	if #tmpT2 > 0 then
		table.sort(tmpT2 , func)
		table_insert(t , tmpT2)
	end

	if #tmpT3 > 0 then
		table_insert(t , tmpT3)
	end

	return t
end

function partial_sort(t , pos1 , pos2 , pos3 , func)
	if not t then
		return false
	end
	if pos1 < 1 or pos2 < 1 or pos1 > #t or pos2 > #t  then
		return false
	end

	local function funcTmp(a , b)
		return a < b
	end

	func = func or funcTmp


	local tmpT1 = clone(t)
	table_cut(tmpT1 , pos1 - 1)

	local tmpT2 = clone(t)
	table_cut(tmpT2 , pos3)
	table_cut(tmpT2 , pos1 - 1 , true)
	local tmpT2t = clone(tmpT2)

	local tmpT3 = clone(t)
	table_cut(tmpT3 , pos3 , true)

	table_clear(t)

	if #tmpT1 > 0 then
		table_insert(t , tmpT1)
	end

	if #tmpT2 > 0 then
		table.sort(tmpT2 , func)
		table_cut(tmpT2 , pos2 - pos1 + 1)
		table_insert(t , tmpT2)
		for _ , v in pairs(tmpT2t) do
			if not table_contains(tmpT2 , v) then
				table.insert(t , v)
			end
		end
	end

	if #tmpT3 > 0 then
		table_insert(t , tmpT3)
	end

	return true
end

function string_split(str, delimiter)
	if str==nil or str=='' or delimiter==nil then
		return nil
	end

    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

function string_at(str, idx)
    return string.sub(str,idx,idx)
end

function ccpMult(p,s)
	return ccp(p.x*s,p.y*s)
end

function getPosI(n)
	return math.floor(n:getPositionX()),math.floor(n:getPositionY())
end

function getccpPos(n)
	return cc.p(n:getPosition())
end

function getccpPosI(n)
	return cc.p(getPosI(n))
end

function gettabPos(n)
	return {n:getPosition()}
end

function gettabPosI(n)
	return {getPosI(n)}
end

function tab2ccp(n)
	return cc.p(n[1],n[2])
end

function ccp2tab(n)
	return {n.x,n.y}
end

--一些数字接口
-- cc.pDot(p1, p2)         -- 点积
-- cc.pCross(p1, p2)       -- 叉积
-- cc.pProject(p1, p2)     -- 投影: 前point在后point上的投影


-- cc.pIsLineIntersect(pA, pB, pC, pD,float,float)-- 直线AB与直线CD是否相交

-- cc.pIsSegmentIntersect(pA, pB, pC, pD)-- 线段AB与线段CD是否相交
-- cc.pGetLength(p)        -- 向量长度
-- cc.pLengthSQ(p)         -- 向量长度平方

-- cc.pGetDistance(p1, p2) -- 坐标距离
-- cc.pDistanceSQ(p1, p2)  -- 坐标距离平方

-- cc.pGetAngle(p1, p2)    -- 向量夹角：弧度

-- cc.p(x, y)                       -- 构造坐标point
-- cc.pAdd(p1, p2)                  -- 相加
-- cc.pSub(p1, p2)                  -- 相减
-- cc.pMidpoint(p1, p2)             -- 两向量的中点
-- cc.pNormalize(p1)                -- 标准化向量
-- cc.pGetClampPoint(minp, maxp, p) -- 将p值限制在[minp,maxp]区间内
-- cc.pForAngle(float)              -- 返回坐标 x=cos(a) , y=sin(a)

-- cc.pPerp(p)                      -- 逆时针旋转90度(-y, x)
-- cc.RPerp(p)                      -- 顺时针旋转90度(y, -x)

-- -- 绕p1向量旋转
-- -- 返回向量: 角度 this.getAngle() +other.getAngle()
-- --           长度 this.getLength()*other.getLength()
-- cc.pRotate(p1, p2)

-- -- 绕p1向量旋转前的向量值
-- -- 返回向量: 角度 this.getAngle() -other.getAngle();
-- --           长度 this.getLength()*other.getLength();
-- cc.pUnrotate(p1, p2)

-- cc.pGetIntersectPoint(pA, pB, pC, pD)-- 直线AB与直线CD的交点

-- cc.rectContainsPoint(rect, point)-- 判断point是否包含在矩形内

-- cc.rectIntersectsRect(rect1, rect2)-- 判断矩形是否相交. 常常用作碰撞检测.


-- cc.rectUnion(rect1, rect2)-- 两矩形合并
