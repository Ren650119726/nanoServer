local appConfig = {}

appConfig.deviceId = "test1"
appConfig.channelId = "test"
appConfig.appId = "test"

-- 生效配置
appConfig.webService = "http://127.0.0.1:12307" -- 内网测试
appConfig.loginQuery = appConfig.webService .. "/v1/user/login/query"
appConfig.guestLogin = appConfig.webService .. "/v1/user/login/guest"
appConfig.thirdLogin = appConfig.webService .. "/v1/user/login/3rd"
appConfig.paymentWeb = appConfig.webService .. "/v1/order/?action=pay&"
appConfig.revinfoURL = appConfig.webService .. "/static/update/version.json"

appConfig.isShowAllShouPai = false

FRAME_WIDTH = 1280 --game frame width
FRAME_HEIGHT = 720 --game frame height
--916496107Qq
-- 0 - disable debug info, 1 - less debug info, 2 - verbose debug info
DEBUG = 2
-- show FPS on screen
CC_SHOW_FPS = false
FPS = 30

appConfig.version = "1.9.3"
appConfig.prefix = "[血战到底]"
return appConfig
