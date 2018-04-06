local Const =
{
    ResGold = 1,
    ResBuilder = 3,
    ResCrystal = 4,
    ResSpecial = 5,
    ResExp = 6,
    ResScore = 7,
    ResZhanhun = 8,
    ResMagic = 9,
    ResMedicine = 10,
    ResMedicineStore=-10,   --在商店购买基因药水
    ResBeercup = 11,
    ResEventMoney = 15,
    ResMicCrystal = 26,
    ResTrials = 27,
    ResPBead = 28,
    ResGXun = 32,
    ResGaStone = 52,
    ResCustom = 15,  --自定义类型

    InfoName = 0,
    InfoSynTime = 1,
    InfoScore = 2,
    InfoPurchase = 3,
    InfoUglv = 4,
    InfoLevel = 5,     --领主等级
    InfoExp = 6,
    InfoFlag = 7,
    InfoLayout = 8,
    InfoRandom = 9,
    InfoTownLv = 10,
    InfoWeaponLv = 11,
    InfoHead = 12,
    InfoVIPlv = 13,
    InfoVIPexp = 14,
    InfoNewer = 15,
    InfoPush = 16,
    InfoSVid = 17,
    InfoPopCode = 18,
    InfoCryNum = 19,
    InfoRegTime = 20,

    ItemEquipPart = 1,
    ItemEquipStone = 2,
    ItemResBox = 3,
    ItemAccObj = 4,
    ItemHWater = 5,
    ItemOther = 6,
    ItemFragment = 7,
    ItemEquipFrag = 8,
    ItemHero = 9,
    ItemRes = 10,
    ItemEquip = 11,
    ItemPvtSkill = 12,
    ItemNewBox = 14,
    ItemSpringBox = 15,

    --新的芯片物品
    ItemChip = 16,
    ItemPopValue = 17, -- 声望解锁英雄
    ItemWelfare =18,--福利月卡
    ItemRefreshStone = 19,   --刷新石
    ItemWashsStone = 20,   --洗练石
    ItemTicket = 23,    --代币
    ItemBuild = 24,     --建筑
    ItemExchange = 25,  --活动兑换物

    ProShield = 0,
    ProGold = 1,
    ProGoldMax = 2,
    ProBuilder = 3,
    ProCrystal = 4,
    ProSpecial = 5,
    ProRegTime = 6,
    ProGuide = 7,
    ProZhanhun = 8,
    ProMagic = 9,
    ProMedicine = 10,
    ProBeercup = 11,
    ProBuilderMax = 12,
    ProFreeTime = 13,
    ProHeroNum = 14,
    ProEventMoney = 15,
    ProLuck = 20,
    ProLuckCount = 21,
    ProLuckReward = 22,
    ProMicCrystal = 26,
    ProTrials = 27,
    ProPBead = 28,
    ProPetTime = 30,
    ProPetNum = 31,
    ProGXun = 32,
    ProLBox = 33,
    ProDJCount = 34,
    ProDJTime = 35,
    ProObsTime = 36,
    ProRenameCount = 41,
    ProDutyTime = 42,        --#每日任务刷新时间
    ProDutyRefresh = 44,     --#每日任务刷新数
    ProDutyNum = 45,         --#每日任务完成数
    ProMonthCard = 50,       --联盟月卡
    ProGaEnery = 51,         --炼金能量
    ProGaStone = 52,         --炼金石
    ProGaTime = 53,          --炼金时间
    ProOnlineTime = 54,       --在线时间
    ProOnlineCount = 55,      --在线领取次数
    ProVisitTime = 56,    --膜拜时间
    ProUseLayout = 70,       --是否启用阵容
    ProFBFollow=60,    --关注Facebook
    ProCmdIdx = 71,          --批量接口追踪用IDX

    ProDJCount2 = 73,
    ProDJTime2 = 74,

    ProBuyedCrystal_gem0 = 80,  --购买宝石的次数
    ProBuyedCrystal_gem1 = 81,
    ProBuyedCrystal_gem2 = 82,
    ProBuyedCrystal_gem3 = 83,
    ProBuyedCrystal_gem4 = 84,
    ProBuyedCrystal_gem5 = 85,
    ProBuyedCrystal_gem6 = 86,
    ProBuyedCrystal_gem7 = 87,

    ProFollowTime = 97, --评分时间
    ProPvpChanceTime = 98, --上次pvp花费时间
    ProPvpChanceNum = 99, --每日攻击次数数量

    ProLTNum = 1001,--十连抽的累计次数
    ProLTCurNum = 1005, --十连抽SSR保底计数
    ProLTBoxTime = 1006, --累计暴击时间
    ProLTBoxRate = 1007, --累计暴击值

    ProPvpBuyCount = 1008,--pvp购买过的次数
    ProPvpBuyNum = 1009,--pvp购买的挑战次数
    ProCombat = 1010, --队伍战斗力
    ProLTUrCurNum=1011,  --十连抽UR保底次数
    ProCodeState = 1020, -- 是否填写过邀请码,1021-1040为各个等级礼包的领取数

    ProTalentMatchStage = 1059,       -- 段位
    ProOneRaffleTicket = 1150,        --单抽抽奖券
    ProTenRaffleTicket = 1151,        --十连抽奖券

    ProSpecialNewState = 20001,       -- 各种触发状态；考虑用二进制吧？
    ProSpecialNewAct = 20002,         -- 上次触发的活动ID
    ProSpecialMatchFlag = 20003,      -- 胜利场次
    ProSpecialHeadFlag = 20004,       -- 上次头像进度
    ProGoldExtractChance = 20005,     -- 金币许愿池抽取次数
    ProGoldExtractTimes = 20006,      --金币许愿池上次抽取时间
    TicketOne = 1,       --单抽抽奖券
    TicketTen = 2,       --十连抽奖券
    OneRaffleTicket = 1, --单抽每次消耗抽奖券
    TenRaffleTicket = 1, --十连抽每次消耗抽奖券

    LayoutPvp = 10,     --防守阵容
    LayoutPvc = 20,     --竞技场
    LayoutPvh = 30,     --远征
    LayoutnPvh = 31,    --噩梦远征
    LayoutPvtAtk = 50,  --试炼
    LayoutPvtDef = 60,  --试炼
    LayoutPve = 70,     --剧情战 掠夺战 联盟战
    LayoutUPve = 80,     --联盟副本
    LayoutPvb = 90,   --神兽挑战

    BattleTypePvp = 1, --个人PVP
    BattleTypePve = 2, --个人PVE
    BattleTypePvc = 3, --竞技场
    BattleTypePvh = 4, --英雄远征
    BattleTypePvt = 5, --英雄试炼
    BattleTypePvj = 6, --僵尸来袭
    BattleTypeUPve = 7, --联盟副本
    BattleTypeUPvp = 8, --联盟战
    BattleTypePvz = 9, --淘汰赛
    BattleTypePvb = 10 ,--神兽挑战

    VisitTypeUn = 101, --联盟中参观

    Town = 1,              -- 主城ID
    Union = 2,             -- 联盟
    BuilderRoom = 11,      --
    GoldStorage = 12,
    GoldProducer = 13,
    HeroBase = 3,
    WeaponBase = 4,        -- 遗迹
    ArenaBase = 5,         -- 竞技场
    EquipBase = 6,         -- 装备工厂
    Alchemy = 8,           -- 炼金阵
    Wall = 50,

    MaxPvpChance = 50, -- 最大PVP场次
    PvpBoxRates = {{10, 3}, {30, 2}, {50, 1}},
    InitTime = 1458259200,
    MondayTime = 1488153600,
    RdM = 65536,
    RdA = 12347,
    RdB = 20809,
    MaxHeroLevel = 200,
    InitHeroLevel = 120,
    MaxMainSkillLevel = 20,
    MaxAwakeLevel = 12,
    MaxSoldierLevel = 50,
    MaxSoldierSkillLevel = 5,
    InitHeroNum = 30,
    InitPvhAnger = 8,    -- 远征初始怒气值
    MaxHeroNum = 200,
    PriceHeroNum = 50,
    PriceRename = 1000,
    PriceEquip = 5000,
    PriceEpartRefresh = {20,50,100},
    PriceTrialsRefresh = {10,30,50,50,50,100,100,100,200,200,200,400,400,400,800,800,800,1600},
    BSkillMinHLevel = 10,
    BSkillFirstCost = 300,
    BSkillRefreshCost = 200,
    BSkillRefreshStone = 1,
    BSkillLightCost = {200,300,400,500,600,700,800,900},
    LuckyLotteryCostKey = 1,
    LuckyLotteryBaseKey = 2,
    HelpUnlockLevel = {3, 5, 17},
    MaxWeaponNum = 4,
    PvpCost = {5,25,50,75,100,200,350,550,750,1000},
    ShieldSetting = {{0,7200,86400},{100,86400,86400*5},{150,86400*2,86400*10},{250,86400*7,86400*35}},
    MaxArenaLevel = 24,
    MaxArenaBuy = 3,
    PveTime = 1800,     --体力恢复时间
    MaxPveChance = 20,  -- 最大体力数
    MaxPvjBossNum = 12, --Boss关卡所消耗的行动点数
    MaxPvjCommonNum = 6, --普通关卡消耗的行动点数
    MaxPveBuyChance = 2,
    PveChancePrice = {200,500},
    PriceInspire = 80,
    InspireEffect = 8,
    MaxInspireNum = 5,
    PvhExps = {90,156,214,321,446,578,723,898,1364,1874},
    ProduceBoostTime = 21600,
    ProduceBoostRate = 2,
    HeroStarLevel = 5,
    MaxEquipNum = 100,
    MaxUPMSkillLevel = 20,
    MaxUPBSkillLevel = 12,
    MaxUPTSkillLevel = 8,
    MaxUPGoldChance = 10,
    PriceUPGold = 100000,
    PriceUPCrystal = 200,
    UPGetByGold = 12,
    UPBoxByGold = 1,
    UPGetByCrystal = 400,
    UPBoxByCrystal = 4,
    MaxUPBoxExp = 20,
    MaxUPBoxNum = 100,
    MaxPvjPoint = 240,
    PvjPointTime = 360,
    EquipFragMerge = 50,
    BaseDJSpecial = 10,
    BaseDJZhanhun = 500,
    PriceDJCrystal = 50,
    RatesDJBeercup = {2000,1000,500,200,50},
    RatesDJCrystal = {0,15000,10000,5000,2000,1800,1600,1400,1000,600,500,400,300,200,100,60,40,20,10,5},
    RatesGroupDJCrystal = {{5,2,10},{10,4,12},{15,6,14},{20,8,16},{0,10,20}},
    GXunByPBead = 20,

    UnionPvlData = {
        {10000,450,1000,30},
        {6000,350,700,10},{6000,350,700,10},{6000,350,700,10},{6000,350,700,10},
        {4000,300,500,0},{4000,300,500,0},{4000,300,500,0},{4000,300,500,0},{4000,300,500,0},
        {2000,200,400,0},{2000,200,400,0},{2000,200,400,0},{2000,200,400,0},{2000,200,400,0},{2000,200,400,0},{2000,200,400,0},{2000,200,400,0},{2000,200,400,0},{2000,200,400,0},
        {1000,175,300,0},{1000,175,300,0},{1000,175,300,0},{1000,175,300,0},{1000,175,300,0},{1000,175,300,0},{1000,175,300,0},{1000,175,300,0},{1000,175,300,0},{1000,175,300,0}
    },

    CmdUpgradeUlv = 1,
    CmdChangeLayout = 2,
    CmdBuyHeroPlace = 3,
    CmdBuyRes = 4,
    CmdTestBuyCrystal = 5,
    CmdAddGuideStep = 6,

    CmdStat = 8,


    CmdUpgradeWeapon = 11,
    CmdProduceWeapon = 12,
    CmdCancelWeapon = 13,
    CmdAccWeapon = 14,
    CmdFinishWeapon = 15,

    CmdBatchLayouts = 101,
    CmdBatchExts = 102,
    CmdBuyBuild = 103,
    CmdUpgradeBuild = 104,
    CmdUpgradeBuildOver = 105,
    CmdCancelBuild = 106,
    CmdAccBuild = 107,
    CmdCollectRes = 108,
    CmdUpgradeArmor = 109,


    CmdAccBuildItem = 110,
    CmdBoostBuild = 111,
    CmdBoostOver = 112,
    CmdRemoveBuild = 113,
    CmdSellBuild = 114,
    CmdRemoveObstacle = 115,
    CmdFinishRemove = 116,
    CmdInitObstacle = 117,
    CmdBuyPvp = 120, -- 购买次数，目前仅用于PVP

    CmdLuckyLottery = 151,
    CmdLuckyReward = 152,
    CmdUseOrSellItem = 153,
    CmdBeerGet = 154,

    CmdHeroLock = 200,
    CmdHeroUpgrade = 201,
    CmdHeroExplain = 202,
    CmdHeroMerge = 203,
    CmdHeroAwake = 204,
    CmdHeroUpgradeMain = 205,
    CmdHeroChangeBSkill = 206,
    CmdHeroUpgradeSoldier = 208,
    CmdHeroUpgradeSSkill = 209,
    CmdHeroPveGuide = 224, --Pve引导送英雄
    ProGuideHero = 1082,

    CmdHeroDelete = 210,
    CmdHeroLayout = 211,
    CmdHeroMic = 212,
    CmdHeroBuy = 213,
    CmdHeroHeal = 214,
    CmdUseLayout = 215,
    CmdFollowUs= 217,
    CmdAllCombat=218,
    CmdTallSeverChangeChip=219,

    CmdSetNewBoxHot = 220, --设置热点的批量接口
    CmdRefreshNewBoxHot = 221, --刷新日热点
    CmdExchangePop = 222, --兑换解锁项（每项限1次）
    CmdUpgradePopLevel = 223, --声望升级

    CmdEquipBuy = 250,
    CmdEquipChange = 251,
    CmdEquipUpgrade = 252,
    CmdEquipInstall = 253,
    CmdEquipLvup = 254,
    CmdEquipMerge = 255,
    CmdEquipSell = 256,
    CmdEquipAnalysis = 257,

    CmdShopEpart = 300,

    CmdPveReset = 310,
    CmdPveBBat = 311,

    CmdPvjGift = 320,
    CmdPvjBShop = 321,
    CmdPvjReset = 322,

    CmdPvhHSet = 330,
    CmdPvhInspire = 331,
    CmdnPvhHset=332,
    CmdnPvhInspire=333,
    CmdClanJion = 340,
    CmdClanInvite = 341,
    CmdClanMMember = 342,
    CmdClanMClan = 343,

    CmdPvbABat = 350,
    CmdPvbBTimes = 351,
    CmdPvbReset = 352,

    CmdPvlSSet = 360,
    CmdPvlBBat = 361,
    CmdPvlLInto = 362,
    CmdPvlLSet = 363,
    CmdPvlAtker = 364,
    CmdPvlInspire = 365,

    CmdPvtSkill = 370,
    CmdPvtBTimes = 371,
    CmdPvtBShop = 372,
    CmdPvtBBat = 373,
    CmdPvtHSet = 374,

    CmdEmailDel = 380,
    CmdHeadChange = 381,
    CmdSetChange = 382,
    CmdMobaiReward = 383,
    CmdGiveMCard = 384,

    CmdActSHelp = 390,
    CmdActFHelp = 391,
    CmdActQNum = 392,
    CmdActExchange = 393,
    CmdActMoney = 394,
    CmdActOther = 395,
    CmdActFollow = 396,
    CmdActLogin = 397,
    CmdActStat = 398,
    CmdActTriggle=399,


    CmdBShield = 400,
    CmdDTRefresh = 401,
    CmdActTriggleInit=402,

    CmdPvcBTimes = 410,

    CmdAlchemyBegin = 420,
    CmdAlchemyChance = 421,
    CmdShareAction = 422, --分享成功
    CmdTMGiftInit = 426,

    CmdCostNotice= 7,

    ASkillHp = 1,
    ASkillAtk = 2,
    ASkillGuard = 3,
    ASkillDef = 4,
    ASkillGod = 5,

    EmailRequestTime=5,    --邮件请求时间5分钟一次
    LogPlaybackTime=3,      --日志回放时间3天内
    LogMaxLength=99,

    PvhMaxTimes = 1,     --远征次数
    PvbHurtAddSet = {1,1,1,0.5,0.5,0.5,0.5,0.5}, --pvb好友助战
    NoticeCost = 100,    --联盟公告
    PvjStoreCost = {1680,5980,5980,5980,5980,5980,5980},
    DailyRobSet = {5000,10000,30000,50000,80000,120000,160000,200000,240000,280000,320000,360000,400000,440000,480000,520000},
    Qgiftset = {3000,10000,24000,50000,80000,120000,180000,250000},
    ChatCold = 20,
    ChatNum = 6,
    FacebookBoxSet = {2,6,8,12,16,20,24,28,32},
    HeroTrialLimit = 8,
    UPvpTimes = 3,                      --联盟战次数
    TrialCGTimes = 3,                   --试炼挑战次数
    TrialBuyTimes = 3,                  --购买次数


    ActTypeLogin = 1000,                --登录次数
    -- ActTypeCrystal = 1001,              --花费水晶
    -- ActTypeLeagueMC = 1002,             --购买联盟月卡
    -- ActTypePVC = 1003,                  --竞技场
    -- ActTypePVP = 1004,                  --PVP掠夺战
    -- ActTypePVE = 1005,                  --PVE剧情闯关
    -- ActTypePVT = 1006,                  --英雄试炼胜利
    -- ActTypePVH = 1007,                -- 远征
    -- ActTypePurchase = 1008,             --购买水晶
    -- ActTypePVJ = 1009,               -- 僵尸来袭
    -- ActTypePVLE = 1010,                 --联盟副本胜利
    -- ActTypeMC = 1011,                   --购买月卡
    -- ActTypeSignIn = 1012,               --每日签到
    -- ActTypeHeroGet = 1013,                  --英雄获得
    -- ActTypeHeroLevelUp = 1014,              --英雄升级
    -- ActTypeHeroStarUp = 1015,               --英雄升星
    -- ActTypeHeroAwake = 1016,                --英雄觉醒
    -- ActTypeHeroAuto = 1017,                 --英雄主动技能
    -- ActTypeHeroPassive = 1018,              --英雄被动技能
    -- ActTypeHeroInten = 1019,                 --英雄强化
    -- ActTypeMercenarySkills = 1020,           --佣兵技能强化


    -- ActTypeHeroEqLevelUp = 1021,             --装备升级/进阶
    -- ActTypeSuperWeapons = 1022,              --超级武器研究
    -- ActTypeMercenaryLevels = 1023,           --佣兵升级
    -- ActTypeGoldChange = 1050,                --炼金
    -- ActTypeBuildLevelUp = 1051,              --建筑升级
    ActTypeWishGet = 1052,                   --许愿池召唤
    ActTypeFeedPet = 1053,                   --喂养神兽
    ActTypeHuanSpecial = 1054,               --黑晶对酒
    ActTypeHuanZhanhun = 1055,               --勋章对酒
    -- ActTypePVPGold = 1056,                   --pvp金币获取

    ActTypeMobai = 1057,                --声望膜拜
    ActTypeHunXia = 1058,               -- 魂匣抽取（前两个不算）
    -- ActTypeShareInfo = 1059,            --分享游戏内容(推广码)
    -- ActTypeKnockDivide = 1060,              --小组赛每日任务
    ActTypeBuyAll = 1061,               --累计充值(任何付费行为)
    FirstFlushGiftBag = 1062,           --首冲礼包
    ActTypeHeroInfoNew = 1063,          --英雄信息界面(图鉴)
    ActTypeInviteCode = 11063,              --邀请码成功邀请活动
    ActTypeOpenUrlAndGetReward = 11064,     --打开链接后领取奖励的活动
    

    ActTypeBuildLevelUp = 1001,             -- 建筑升级
    ActTypeHeroLevelUp = 1002,              -- 英雄升级
    ActTypeHeroAuto = 1003,                 -- 英雄技能升级
    ActTypeHeroStarUp = 1004,               -- 英雄升星
    ActTypeHeroAwake = 1005,                -- 英雄觉醒技能升级
    ActTypeMercenaryLevels = 1006,          -- 佣兵升级
    ActTypeMercenarySkills = 1007,          -- 佣兵天赋升级
    ActTypePveGK =1008,                             --通关普通关卡
    ActTypePVPGold = 1009,                   -- 掠夺金币
    ActTypePVPCup = 1010,                  -- 掠夺奖杯
    ActTypeShareInfo = 1011,                 -- 分享游戏
    ActTypeSRHeroGet = 1012,                 -- 获得SR英雄
    ActTypeSSRHeroGet = 1013,                -- 获得SSR英雄
    ActTypeRename = 1014,                    -- 修改昵称
    ActTypeRmBlock = 1015,                     -- 移除障碍物
    ActTypeSignIn = 1016,                    -- 累计签到
    ActTypePurchase = 1017,                  -- 累计充值宝石
    ActTypeCrystal = 1018,                   -- 累计消耗宝石
    ActTypeWishGet = 1019,                   -- 召唤（抽卡）
    ActTypeGoldChange = 1020,                -- 炼金
    ActTypeSuperWeapons = 1021,              -- 制造超级武器
    ActTypePVP= 1022,                        -- 掠夺胜利
    ActTypePVE = 1023,                       -- 普通关卡胜利
    ActTypePVC = 1024,                       -- 竞技场胜利
    ActTypePVH = 1025,                       -- 英雄远征胜利
    ActTypeKnockDivide = 1026,               -- 英雄角逐胜利
    ActTypePVLE = 1027,                      -- 挑战联盟副本
    ActTypeFeedPet = 1028,                   -- 喂养联盟神兽
    ActTypePveEliteGK = 1029,          -- 通关精英关卡
    ActTypePveElite = 1030,            -- 精英关卡胜利
    

    ActTypeLeagueMC = 1031,             --购买联盟月卡
    ActTypePVJ = 1032,               -- 僵尸来袭
    ActTypeMC = 1033,                   --购买月卡
    ActTypeHeroGet = 1034,                  --英雄获得
    ActTypeHeroPassive = 1035,              --英雄被动技能
    ActTypeHeroInten = 1036,                 --英雄强化
    ActTypeHeroEqLevelUp = 1037,             --装备升级/进阶
    


    JumpTypeHeroInfo = 1024, --英雄信息
    JumpTypeWish = 1025,--许愿池
    JumpTypeStore = 1026,--商店
    JumpTypeChip = 1027,--碎片
    JumpTypePass = 1028,--被动
    JumpTypeWake = 1029,--觉醒
    JumpTypeInten = 1030,--强化
    JumpTypeEquipDeve = 1031,--装备升级
    JumpTypeSuperWeapons = 1032,--超级武器
    JumpTypeGoldOre = 1033, --金矿
    JumpTypeBarSpecial = 1034, --酒吧黑晶
    JumpTypeList = 1035, --掠夺战排行榜
    JumpTypeEquipStore = 1036, --装备商店
    JumpTypeMater = 1037,--材料商店
    JumpTypeAccp = 1038, --成就
    JumpTypeTask = 1039, --任务
    JumpTypeGodBaest = 1040, --神兽喂养
    JumpTypeOrb = 1041, --宝珠捐献
    JumpTypeHeroStore = 1042, -- 英雄商店
    JumpTypeMain = 1043, -- 主动
    JumpTypeMercenary = 1044, -- 佣兵
    JumpTypeGoldStore = 1045, --金币商店
    JumpTypeDiamondStore = 1046, -- 宝石商店
    JumpTypeBlackStore = 1047, -- 黑晶商店
    JumpTypeExpStore = 1048, -- 经验商店
    JumpTypeGeneStore = 1049, -- 基因药水
    JumpTypeBarZhanhun = 1050, --酒吧功勋
    JumpTypeArenaBox = 1051, --竞技场宝箱商店
    JumTypeTalentMatch = 1052, --达人赛



    ActTypeBuffPVC = 1103,              --竞技场免费次数增加
    ActTypeBuffPVE = 1105,              --PVE剧情闯关最大次数增加
    ActTypeBuffPVT = 1106,              --英雄试炼免费次数增加
    ActTypeBuffTask = 1107,             --每日任务活动动态buff增加
    ActTypeBuffWelfare = 1108,          --联盟月卡活动动态buff增加
    ActTypeBuffAreneBox = 1109,         --竞技场宝箱活动动态buff增加
    ActTypeBuffHuiGui = 1111,           --老玩家回归buff
    ActTypeBuffImmortal = 1113,         --英雄不死buff
    ActTypeBuffDoublePvj=1114 ,         --pvj掉落翻倍buff
    ActTypeBuffPvjCostReduce= 1115,     --僵尸来袭消耗减半buf
    ActTypeBuffAlchemyCrit = 1116,      --特定英雄炼金翻倍活动
    ActTypeBuffFillVault =1117,          --填满金库
    ActTypeBuffObstacle = 1118,         -- 障碍物活动
    ActTypeBuffWishDiscount = 1119,
    ActTypeBuffTalentMatch = 1120,      --达人赛奖励活动
    ActTypeBuffKnockMatch = 1121,       --英雄角逐开启

    ActStatPrestigeValue = 1196,        --(触发型活动)声望值

    ActStatCityLevel = 1198,            --主城等级
    ActStatUserLevel = 1199,            --指挥官等级(含历史)
    ActStatUserVip = 1195,            --VIP等级
    ActStatHeroStar = 1201,          --R+级英雄星级；ID格式为1[rating]0[star]，原则上不支持0星
    ActTypeLoginDay = 10001,            --登录指定天
    ActTypeLoginContinue = 10002,       --连续登录
    ActTypeCrystalSingle = 10012,       --单笔花费水晶
    ActTypePurchaseSingle = 10082,      --单笔充值宝石
    ActTypeGiveMC = 10021,              --赠送联盟月卡
    ActTypeScratch = 4001,              --刮刮卡
    ActTypeNewKing = 10022,             --新人王:ID格式为[start,end] 区间,end为0时表示当个等级start
    ActTypeContinuousBuy = 10003,       --连续充值
    ActStatLeaveDays = 1194,             --未上线天数

    ActTypeRankCombat = 5001,

    ActActionNormal = 1,
    ActActionBuy = 2,
    ActActionExchange = 3,              --交换获得
    ActActionAuto = 4,
    ActActionSpecial = 5,
    ActActionShare = 6,                 --分享
    ActActionContinuous = 8,            --连续型的

    TalentMatchPvp = 101,               --达人赛PVP
    TalentMatchPvj = 102,               --达人赛PVJ
    TalentMatchPvh = 103,               --达人赛PVH

    DTDayMax = 30,
    DTVersion = 2,
    pushNum = 8,

    ProPopular = 1040, --声望值
    ProPopLevel = 1041, --声望等级，冗余用
    ProPopUnlockMask1 = 1042, --声望解锁标识，二进制格式
    ProPopUnlockMask2 = 1043, --声望解锁标识，二进制格式
    ProNewBoxTime = 1050, --每日热点上次刷新时间
    ProNewBoxHot = 1051, --每日热点设定的热点英雄
    ProNewBoxItems = 1052, --每日热点物品，格式为 周热点id+日热点1*100+日热点2*10000+日热点3*1000000，其中热点id为物品解锁序号idx
    ProHficNum = 1053, --#膜拜次数
    ProHficTime = 1054, --#膜拜时间
    ProTriggleNum = 1055,
    ProPrestigeAct = 1056, --触发型声望活动
    ProCityLevelAct = 1057, --触发型主城等级活动
    ProTwoFirstFlushAct = 1058, --触发型二次首冲活动

    ProPvjSwpTime=1061,    --扫荡时间
    ProPvjSwpNum=1062,    --每日免费扫荡次数

    ProBuyYouthDayStatue = 1071,
    FreePopIdx = 12, --无需解锁的英雄/声望个数
    DefaultHotPopIdx = 12, --默认的初始热点
    MaxArenaBox = 12, --最大宝箱ID

    MaxRewardTimes = 10,                -- 领取每日任务最大次数
    PricePveSweep = 1,                 -- pve扫荡的花费
    MaxVipLV = 10,                       -- 最大VIP等级

    ArenaBoxPresitageTag = 11,     --开启宝箱等级的标记

    MinWorshipEarnings = 50, --膜拜声望的最小收益值
    MaxPreWorshipTime = 10, --最大声望膜拜次数

    HeroInfoNewTry = 10001,--英雄试玩
    PvjSwpBuyNeed = 5,  --扫荡不足花费的宝石
    GodSkillWaitTime = 3, --天神技等待时间
    KnockRollTime = 7,
    KnockRoundTime = 30,  --小组赛开赛时间距离零点的间隔
    KnockDivideMaxReborn = 2,  --小组赛最大重生值

    ProPvzACrystalTime = 1063, --淘汰赛押注时间
    ProPvzACrystalNum = 1064,  --淘汰赛押注额
    ProPvzGambleNum = 100,      --淘汰赛每次押注的金额
    ProPvzGambleMaxCount = 4,  --淘汰赛最高押注次数
    KnockDivideRank = 64,      --小组赛进阶到淘汰赛的名额
    ActsConditionTime = 86400,   --活动条件里有时间限制的

    ProBuyVipPkg1 = 1072,    --礼包1购买次数（跟时间绑定）
    ProBuyVipPkg2 = 1073,
    ProBuyVipPkg3 = 1074,
    ProBuyVipPkgTime1 = 1075, --礼包1最后购买时间
    ProBuyVipPkgTime2 = 1076,
    ProBuyVipPkgTime3 = 1077,

    DfDistanceNum = 121,        --防守方进攻的格子数(正方形)
    ProCombatPvc = 1078,    --竞技场战斗力
    ProCombatPvt = 1079,        --试炼防守阵容战斗力
    CmdGetAchNumReward = 424,    --活跃度宝箱
    CmdGetWeekPackReward = 425,  --联盟周礼包奖励
    OpenTrigglesBagDialog = 10000001,  --打开神秘活动界面次数
    HeroSoldierSkillTalent1 = 1,
    HeroSoldierSkillTalent2 = 2,
    GoldExtractLimit = 20,
    ProRmBlock = 1083   --移除障碍数量 
}

return Const
