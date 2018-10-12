local soundManager={}
local audio = cc.SimpleAudioEngine:getInstance()
local stringDefine = require "app.data.stringDefine"
local LocalRecord = require "app.core.LocalRecord"
function soundManager.stopAllEffects()
    audio:stopAllEffects()
end

function soundManager.getMusicVolume()
    return audio:getMusicVolume()
end

function soundManager.isMusicPlaying()
    return audio:isMusicPlaying()
end

function soundManager.getEffectsVolume()
    return audio:getEffectsVolume()
end

function soundManager.setMusicVolume(volume)
    audio:setMusicVolume(volume)
end

function soundManager.stopEffect(handle)
    audio:stopEffect(handle)
end

function soundManager.stopMusic(isReleaseData)
    local releaseDataValue = false
    if nil ~= isReleaseData then
        releaseDataValue = isReleaseData
    end
    audio:stopMusic(releaseDataValue)
end

function soundManager.playMusic(filename, isLoop)
    if not LocalRecord.instance():getProperty(stringDefine.SOUND_BG) then
        return
    end

    local loopValue = false
    if nil ~= isLoop then
        loopValue = isLoop
    end
    audio:playMusic(filename, loopValue)
end

function soundManager.pauseAllEffects()
    audio:pauseAllEffects()
end

function soundManager.preloadMusic(filename)
    audio:preloadMusic(filename)
end

function soundManager.resumeMusic()
    audio:resumeMusic()
end

function soundManager.playEffect(filename, isLoop)
    if not LocalRecord.instance():getProperty(stringDefine.SOUND_EF) then
        return
    end
    local loopValue = false
    if nil ~= isLoop then
        loopValue = isLoop
    end
    return audio:playEffect(filename, loopValue)
end

function soundManager.rewindMusic()
    audio:rewindMusic()
end

function soundManager.willPlayMusic()
    return audio:willPlayMusic()
end

function soundManager.unloadEffect(filename)
    audio:unloadEffect(filename)
end

function soundManager.preloadEffect(filename)
    audio:preloadEffect(filename)
end

function soundManager.setEffectsVolume(volume)
    audio:setEffectsVolume(volume)
end

function soundManager.pauseEffect(handle)
    audio:pauseEffect(handle)
end

function soundManager.resumeAllEffects(handle)
    audio:resumeAllEffects()
end

function soundManager.pauseMusic()
    audio:pauseMusic()
end

function soundManager.resumeEffect(handle)
    audio:resumeEffect(handle)
end

function soundManager.getInstance()
    return audio
end

function soundManager.destroyInstance()
    return cc.SimpleAudioEngine:destroyInstance()
end

return soundManager