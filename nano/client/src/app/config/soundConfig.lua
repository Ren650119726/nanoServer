local soundConfig = {}

--pre path
soundConfig.soundPathEffect = "sound/effect/"
soundConfig.soundPathMusic = "sound/bg/"
soundConfig.soundPathVoice = "sound/yuyin/"

--fang yan path
soundConfig.language = {
    ["chengdu"] = "",
}

--background music
soundConfig.backgroundMusic = {
    ["lobby"] = {"bg_lobby"},
    ["table"] = {"bg_table"},
}

--sound effect

soundConfig.effect = {
    [1] = {"dapai/tiao_1"},
    [2] = {"dapai/tiao_2"},
    [3] = {"dapai/tiao_3"},
    [4] = {"dapai/tiao_4"},
    [5] = {"dapai/tiao_5"},
    [6] = {"dapai/tiao_6"},
    [7] = {"dapai/tiao_7"},
    [8] = {"dapai/tiao_8"},
    [9] = {"dapai/tiao_9"},
    [11] = {"dapai/tong_1"},
    [12] = {"dapai/tong_2"},
    [13] = {"dapai/tong_3"},
    [14] = {"dapai/tong_4"},
    [15] = {"dapai/tong_5"},
    [16] = {"dapai/tong_6"},
    [17] = {"dapai/tong_7"},
    [18] = {"dapai/tong_8"},
    [19] = {"dapai/tong_9"},
    [21] = {"dapai/wan_1"},
    [22] = {"dapai/wan_2"},
    [23] = {"dapai/wan_3"},
    [24] = {"dapai/wan_4"},
    [25] = {"dapai/wan_5"},
    [26] = {"dapai/wan_6"},
    [27] = {"dapai/wan_7"},
    [28] = {"dapai/wan_8"},
    [29] = {"dapai/wan_9"},
    ["peng"] = {"dapai/peng"},
    ["gang"] = {"dapai/gang"},
    ["hu"] = {"dapai/hu"},
    ["qianggang"] = {"qianggang"},
    ["zimo"] = {"dapai/zimo"},

    ["click"] = {"btn_0"},
    ["closeWindow"] = {"btn_close"},
    ["switchui"] = {"btn_switch_0"},
    ["switchtab"] = {"btn_tab"},
    ["error"] = {"error"},
    ["dice"] = {"dice"},
}

function soundConfig.effectFilePath(name, sex)
    if nil == name then
        return ""
    end
    local rets = soundConfig.effect[name]
    if nil == rets then
        return ""
    end
    local size = #rets
    if size == 0 then
        return ""
    end
    local idx = math.random(size)
    local filename = rets[idx]
    local sexAdd = ""
    if nil ~= sex then
        if 1 == sex then
            sexAdd = "male_"
        else
            sexAdd = "female_"
        end
    end
    return soundConfig.soundPathEffect .. sexAdd .. filename .. ".mp3"
end

function soundConfig.musicFilePath(name)
    if nil == name then name = "lobby" end
    local rets = soundConfig.backgroundMusic[name]
    if nil == rets then
        return ""
    end
    local size = #rets
    if size == 0 then
        return ""
    end 
    local idx = math.random(size)
    local filename = rets[idx]
    return soundConfig.soundPathMusic .. filename .. ".mp3"
end

function soundConfig.voiceFilePath(sex, index)
    local sexAdd = ""
    if nil ~= sex then
        if 1 == sex then
            sexAdd = "male"
        else
            sexAdd = "female"
        end
    end
    local filename = string.format("%s/quyu_%d", sexAdd, index)
    return soundConfig.soundPathVoice .. filename .. ".mp3"
end

return soundConfig
