local MainScene = class("MainScene", function()
    return display.newScene("MainScene")--class本身是一个table
end)--父类为一个场景，通过函数来返回


local scheduler = require(cc.PACKAGE_NAME..".scheduler")--导入包文件，PACKAGE_NAME是framework
--导入时间调度文件，里面是封装好的模板

function MainScene:ctor()
    cc.ui.UILabel.new({
            UILabelType = 2, text = "Hello, World", size = 64})
        :align(display.CENTER, display.cx, display.cy)
        :addTo(self)

		self:testTouch()


		self:scheduleDemo()
		--self:onInterval(dt)--不需要



		--加密crypto
		--[[
		local a = "spring"
		-- local str = crypto.encryptAES256("hello", key)
		local str = crypto.encodeBase64(a)--编码
		print(str)
		local text = crypto.decodeBase64(str)--解码
		print(text)
		--]]


		-- json.encode(var)
		-- 将表格数据编码为 JSON 字符串
		-- json.decode(text)
		-- 将 JSON 字符串解码为表格对象
		--[[
		local a = {x=3,y=4}
		local m = json.encode(a)
		print(m)
		local e = json.decode(m)
		print(e.x)
		--]]

		--添加button实现页面跳转
		local btn1=cc.ui.UIPushButton.new({normal="playbutton.png",pressed="playbutton-hd.png"}, {scale9=true})
		btn1:onButtonClicked(function(event)
			dump(event)
			print("onButtonClicked")
			--切换场景
			local scene=require("app.scenes.Another").new(8)--.new自动调用ctor函数
			--local scene=require("app.scenes.Another"):new(8)--第一个为self,第二个参数为8
			local transition = display.wrapSceneWithTransition(scene,"fade",0.5)
			--cc.Director:getInstance():replaceScene(scene)
			cc.Director:getInstance():replaceScene(transition)
			--display.replaceScene(transition)
			end)
		btn1:onButtonPressed(function(event)
			print("onButtonPressed")
			end)
		btn1:setButtonSize(150, 60)
		btn1:pos(400, 160)
		btn1:setTag(20)
		btn1:setButtonEnabled(true)
		self:addChild(btn1)

end


--测试单点触摸
function MainScene:testTouch()--写法一，写了冒号默认自动传参self
--function MainScene.testTouch(self)--写法二
	local sp = cc.Sprite:create("m.png")
	self:addChild(sp)
	sp:setTouchEnabled(true)--self为当前的层
	sp:setTouchSwallowEnabled(true)
	sp:addNodeEventListener(
		cc.NODE_TOUCH_EVENT,
		function(event)
			dump(event)
			if event.name=="ended" then
				print("ended...")
			elseif event.name=="began" then
				print("began...")
			end
			return true
		end
		)
end

--测试时间调度
function MainScene:scheduleDemo()
	---[[
	--方法一
	local scheduID ;
	sharedScheduler=cc.Director:getInstance():getScheduler()
	scheduID=sharedScheduler:scheduleScriptFunc(
		function()
			print("schedule")
			cc.Director:getInstance()
			:getScheduler()
			:unscheduleScriptEntry(scheduID)--停止调度
			end,1,false)--时间可以是0，表示每帧都调用	
	print(scheduID.."======")--1
	--]]


	--方法二
	--[[
	local function onInterval(dt)
	dump(dt)
	print("aaaa")
	end
	--每0.5秒执行一次onInterval()
	local handle= scheduler.scheduleGlobal(onInterval,0.5)
	--scheduler.unscheduleGlobal(handle)--停止调度
	--]]
end

--MyAPP在加载场景MainScene时会直接运行这段代码
--[[也可以实现
local function onInterval(dt)
dump(dt)
print("aaaa")
end
--每0.5秒执行一次onInterval()
local handle= scheduler.scheduleGlobal(onInterval,0.5)
--]]




function MainScene:onEnter()
end

function MainScene:onExit()
end

return MainScene
