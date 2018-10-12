--init simple screen and design resolution size
local director = cc.Director:getInstance()
local view = director:getOpenGLView()

if not view then
    local width = 1136
    local height = 640
    view = cc.GLViewImpl:createWithRect("bullfight", cc.rect(0, 0, width, height))
    director:setOpenGLView(view)
end

local app = cc.Application:getInstance()
local target = app:getTargetPlatform()
if target == 0 then
    if FRAME_WIDTH ~= nil and FRAME_HEIGHT ~= nil then
        view:setFrameSize(FRAME_WIDTH, FRAME_HEIGHT)
    end
end

if FPS ~= nil then
    director:setAnimationInterval(1 / FPS)
end

local frameSize = view:getFrameSize()

local ResolutionPolicy =
{
    EXACT_FIT = 0,
    NO_BORDER = 1,
    SHOW_ALL  = 2,
    FIXED_HEIGHT  = 3,
    FIXED_WIDTH  = 4,
    UNKNOWN  = 5,
}
-- auto scale

local function checknumber(value, base)
    return tonumber(value, base) or 0
end

local function checkResolution(r)
    r.width = checknumber(r.width)
    r.height = checknumber(r.height)
    r.autoscale = string.upper(r.autoscale)
    assert(r.width > 0 and r.height > 0,
        string.format("display - invalid design resolution size %d, %d", r.width, r.height))
end

local framesize = view:getFrameSize()
local function setDesignResolution(r, framesize)
    local xRatio = frameSize.width / r.width
    local yRatio = frameSize.height / r.height
    local width, height = r.width, r.height
    if (xRatio > yRatio) then
        width = r.height * frameSize.width / frameSize.height
    else 
        height = r.width * frameSize.height / frameSize.width;
    end
	view:setDesignResolutionSize(width, height, ResolutionPolicy.SHOW_ALL);
    globalScale = r.height / height

--    local scaleX, scaleY = framesize.width / r.width, framesize.height / r.height
--    local width, height = r.width, framesize.height
--    r.autoscale = "NO_BORDER"
--    globalScale = scaleX
--    if scaleX < scaleY then
--        r.autoscale = "FIXED_WIDTH"
--        globalScale = scaleX
--    elseif scaleX > scaleY then
--        r.autoscale = "FIXED_HEIGHT"
--        globalScale = scaleY
--    end
--    if r.autoscale == "FIXED_WIDTH" then
--        width = framesize.width / scaleX
--        height = framesize.height / scaleX
--        view:setDesignResolutionSize(width, height, ResolutionPolicy.NO_BORDER)
--    elseif r.autoscale == "FIXED_HEIGHT" then
--        width = framesize.width / scaleY
--        height = framesize.height / scaleY
--        view:setDesignResolutionSize(width, height, ResolutionPolicy.NO_BORDER)
--    elseif r.autoscale == "NO_BORDER" then
--        view:setDesignResolutionSize(r.width, r.height, ResolutionPolicy.NO_BORDER)
--    end
end

local function setAutoScale(configs)
    if type(configs) ~= "table" then return end
    checkResolution(configs)
    if type(configs.callback) == "function" then
        local c = configs.callback(framesize)
        for k, v in pairs(c or {}) do
            configs[k] = v
        end
        checkResolution(configs)
    end
    setDesignResolution(configs, framesize)
    print(string.format("# design resolution size       = {width = %0.2f, height = %0.2f}", configs.width, configs.height))
    print(string.format("# design resolution autoscale  = %s", configs.autoscale))
end

if type(CC_DESIGN_RESOLUTION) == "table" then
    setAutoScale(CC_DESIGN_RESOLUTION)
end

if CC_SHOW_FPS then
    director:setDisplayStats(true)
end

director:getConsole():listenOnTCP(60000)
