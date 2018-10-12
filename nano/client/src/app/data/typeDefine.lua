local typeDefine = {}

typeDefine.sRoomType = {}
typeDefine.sRoomType.classic = 0
typeDefine.sRoomType.dailyMatch = 1
typeDefine.sRoomType.monthlyMatch = 2
typeDefine.sRoomType.finalMatch = 3

typeDefine.sDailyMatchLevel = {}
typeDefine.sDailyMatchLevel.junior = 0
typeDefine.sDailyMatchLevel.senior = 1
typeDefine.sDailyMatchLevel.master = 2

typeDefine.sClassicLevel = {}
typeDefine.sClassicLevel.junior = 0
typeDefine.sClassicLevel.middle = 1
typeDefine.sClassicLevel.senior = 2
typeDefine.sClassicLevel.elite = 3
typeDefine.sClassicLevel.master = 4

typeDefine.sExitType = {}
typeDefine.sExitType.exitDeskUI = -1
typeDefine.sExitType.selfRequest = 0
typeDefine.sExitType.classicCoinNotEnough = 1
typeDefine.sExitType.dailyMatchEnd = 2
typeDefine.sExitType.notReadyForStart = 3
typeDefine.sExitType.changeDesk = 4
typeDefine.sExitType.repeatLogin = 5
typeDefine.sExitType.exitTypeDissolve = 6

typeDefine.sDeskStatus = {}
typeDefine.sDeskStatus.create = 0
typeDefine.sDeskStatus.duanpai = 1
typeDefine.sDeskStatus.qipai = 2
typeDefine.sDeskStatus.playing = 3
typeDefine.sDeskStatus.ended = 4
typeDefine.sDeskStatus.lookback = -1

typeDefine.sHuType = {}
typeDefine.sHuType.dianPao = 0
typeDefine.sHuType.ziMo = 1
typeDefine.sHuType.gangShangHua = 2
typeDefine.sHuType.gangShangPao = 3
typeDefine.sHuType.qiangGao = 4

typeDefine.sSexType = {}
typeDefine.sSexType.unknown = 1
typeDefine.sSexType.male = 1
typeDefine.sSexType.female = 2

typeDefine.sUserType = {}
typeDefine.sUserType.guest = 0
typeDefine.sUserType.laoBaShi = 1

typeDefine.sFanPaiStep = {}
typeDefine.sFanPaiStep.k91 = 0
typeDefine.sFanPaiStep.k61 = 1
typeDefine.sFanPaiStep.k41 = 2
typeDefine.sFanPaiStep.k31 = 3
typeDefine.sFanPaiStep.k21 = 4

typeDefine.sFanPaiStatus = {}
typeDefine.sFanPaiStatus.kNotOpen1 = 0
typeDefine.sFanPaiStatus.kOpenFailed1 = 1
typeDefine.sFanPaiStatus.kOpenSuccessY1 = 2
typeDefine.sFanPaiStatus.kOpenSuccessN1 = 3
typeDefine.sFanPaiStatus.kNotOpen2 = 4
typeDefine.sFanPaiStatus.kOpenFailed2 = 5
typeDefine.sFanPaiStatus.kOpenSuccessY2 = 6
typeDefine.sFanPaiStatus.kOpenSuccessN2 = 7

typeDefine.sPiaoType = {}
typeDefine.sPiaoType.None = 1
typeDefine.sPiaoType.Freedom = 2

typeDefine.sPiaoMultple = {}
typeDefine.sPiaoMultple.NoChange = -1
typeDefine.sPiaoMultple.None = 0
typeDefine.sPiaoMultple.One = 1
typeDefine.sPiaoMultple.Two = 2

return typeDefine
