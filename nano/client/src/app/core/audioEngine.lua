audioEngine = {}

audioEngine.effectCache = {}
audioEngine.backgroundId = nil

audioEngine.effectVolume = 1
audioEngine.effect = true
audioEngine.backgroundVolume = 0.8

function audioEngine.playEffect(filepath, loop)
    if not audioEngine.effect then
        return
    end
    if nil == filepath then return end
    if nil == loop then loop = false end

    local id = ccexp.AudioEngine:play2d(filepath, loop, audioEngine.effectVolume)
    audioEngine.effectCache[id] = true
    ccexp.AudioEngine:setFinishCallback(id, function(id, filePath)
        audioEngine.effectCache.id = nil
    end)
end

function audioEngine.playBackgroundMusic(filepath, loop)
    if nil == filepath then return end
    if nil == loop then loop = true end
    if audioEngine.curBackgroundFile == filepath then return end
    audioEngine.curBackgroundFile = filepath
    audioEngine.stopBackgroundMusic()
    audioEngine.backgroundId = ccexp.AudioEngine:play2d(filepath, loop, audioEngine.backgroundVolume)
end

function audioEngine.stopBackgroundMusic()
    if audioEngine.backgroundId then
        ccexp.AudioEngine:stop(audioEngine.backgroundId)
        audioEngine.backgroundId = nil
        audioEngine.curBackgroundFile = nil
    end
end

function audioEngine.pause()
    ccexp.AudioEngine:pauseAll()
end

function audioEngine.resume()
    ccexp.AudioEngine:resumeAll()
end

function audioEngine.enableBackgroundMusic(isenable)
    if not isenable then
        audioEngine.backgroundVolume = 0
    else
        audioEngine.backgroundVolume = 0.8
    end
    if audioEngine.backgroundId then
        ccexp.AudioEngine:setVolume(audioEngine.backgroundId, audioEngine.backgroundVolume)
    end
end

function audioEngine.enableEffect(isenable)
    if not isenable then
        for id, v in pairs(audioEngine.effectCache) do
            ccexp.AudioEngine:stop(id)
        end
        audioEngine.effectCache = {}
        audioEngine.effectVolume = 0
        audioEngine.effect = false
    else
        audioEngine.effectVolume = 1
        audioEngine.effect = true
    end
end