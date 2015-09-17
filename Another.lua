--
-- Author: answer
-- Date: 2015-08-27 10:55:35
--
local AnotherScene = class("AnotherScene",function()
	return display.newScene()
end)


function AnotherScene:ctor(num,num2)--传参
	cc.ui.UILabel.new({
            UILabelType = 2, text = "Second Scene", size = 64})
        :align(display.CENTER, display.cx, display.cy)
        :addTo(self)


        print(num,num2)




        --添加slider滑动条
        local barHeight = 40
        local barWidth = 400
        cc.ui.UISlider.new(display.LEFT_TO_RIGHT,{
        	bar ="SliderBar.png",
        	button="SliderButton.png"},
        	{scale9=true})

        :onSliderValueChanged(function(event)
        	--dump(event)
        	print(string.format("value=%0.2f",event.value))
        end)
        :setSliderSize(barWidth, barHeight)
        :setSliderValue(75)--设置初始的滑动条的位置
        :align(display.LEFT_BOTTOM, display.left+40, display.top-80)
        :addTo(self)

end



function AnotherScene:onEnter(...)
end

function AnotherScene:onExit(...)

end

return AnotherScene