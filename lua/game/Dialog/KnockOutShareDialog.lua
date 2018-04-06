local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")
local KnockOutShareDialog = class(DialogViewLayout)
function KnockOutShareDialog:onInitDialog()
	self.canClickBtn = false
    self:initUI()
    self:initData()
end

function KnockOutShareDialog:initUI()
	self:setLayout("KnockOutShareDialog.json")
    self:loadViewsTo()
    local textBox = ui.textBox({1280, 140}, Localize("labelInputPlaceHolder"), General.font6, 46, {align=cc.TEXT_ALIGNMENT_LEFT, back="images/inputBack.png"})
    display.adapt(textBox, 0, -70, GConst.Anchor.Bottom)
    self.textBox = textBox

    local sdkVersion = GEngine.rawConfig.sdkVersion or 0
    if (sdkVersion <= 1) and (sdkVersion >= 2 ) then
        self.nd_input:addChild(textBox)
    end

    self.btn_share.view:setScale(0.8)
    self.btn_share:setScriptCallback(ButtonHandler(self.onClickShare, self))
    self.questionBut:setVisible(false)
end

function KnockOutShareDialog:initData()
    self.unionFlag = false
    self:updateData()
end

function KnockOutShareDialog:updateData()
    -- dump(self.cont)
    self.stage = self.cont[1]
    local ucontext = GameLogic.getUserContext()
    self.head = ucontext:getInfoItem(const.InfoHead)
    self.name = ucontext:getInfoItem(const.InfoName)
    self.lv = ucontext:getInfoItem(const.InfoLevel)
    local unionInfo = ucontext.union
    self.unionFlag = (not GameLogic.isEmptyTable(unionInfo))
    if self.unionFlag then
        self.unionName = unionInfo.name
        self.unionId = unionInfo.id
        self.lpic = unionInfo.flag
        self.ps1 = math.floor(self.lpic/10000)
        self.ps2 = math.floor((self.lpic%10000)/100)
        self.ps3 = self.lpic%10000%100
    end
    self:updateUI()
end

function KnockOutShareDialog:updateUI()
    GameUI.addPlayHead(self.nd_ownHead, {id=self.head, scale = 1.1, x=0,y=0,z=0,blackBack=true, noBlackBack = false})

    local spriteName
    local platform = GEngine.getPlatform()
    if platform == cc.PLATFORM_OS_ANDROID then
        spriteName = "images/pvz/imgPvzAndroid.png"
    elseif platform == cc.PLATFORM_OS_WINDOWS then
        spriteName = "images/pvz/imgPvzAndroid.png"
    else
        spriteName = "images/pvz/imgPvzIos.png"
    end
    self.img_download:setImage(spriteName)

    if self.unionFlag then
        local nd_flag = GameUI.addUnionFlag(self.ps1, self.ps2, self.ps3)
        nd_flag:setScale(0.2)
        self.nd_union:addChild(nd_flag)
    end

    self.lb_unionDes:setVisible(self.unionFlag)
    self.lb_unionIDDes:setVisible(self.unionFlag)

    self.lb_ownName:setString(self.name)
    self.lb_ownLv:setString(self.lv)
    self.lb_unionName:setString(self.unionName)
    self.lb_unionID:setString(self.unionId)

    spriteName = "images/pvz/imgPvzShare"..self.stage.."_EN.png"
    local language = General.language
    if language == "CN" then
        spriteName = "images/pvz/imgPvzShare" .. self.stage .. ".png"
    elseif language == "HK" then
        spriteName = "images/pvz/imgPvzShare" .. self.stage .. "_HK" .. ".png"
    end
    if not cc.FileUtils:getInstance():isFileExist(spriteName) then
        spriteName = "images/pvz/imgPvzShare"..self.stage.."_EN.png"
    end
    if not cc.FileUtils:getInstance():isFileExist(spriteName) then
        spriteName = "images/pvz/imgPvzShare"..self.stage.."_En.png"
    end
    local sprite = ui.sprite(spriteName, self.img_stage.size)
    display.adapt(sprite, self.img_stage.size[1]/2, self.img_stage.size[2]/2, GConst.Anchor.Center)
    self.img_stage:addChild(sprite)
end


function KnockOutShareDialog:onClickShare()
    GameLogic.doShare("knock", self.stage)
    self:closeDialog()
end

function KnockOutShareDialog:closeDialog()
    display.closeDialog(self.priority)
end

return KnockOutShareDialog
