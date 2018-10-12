local fxIconConfig = {}
--fxString[1] = "清一色"
--fxString[2] = "清七对"
--fxString[3] = "清大对"
--fxString[4] = "清带幺"
--fxString[5] = "清将对"
--fxString[6] = "素番"
--fxString[7] = "七对"
--fxString[8] = "大对子"
--fxString[9] = "全带幺"
--fxString[10] = "将对"
--fxString[11] = "幺九七对"
--fxString[12] = "清龙七对"
--fxString[13] = "龙七对"

fxIconConfig[1] = "result_font_qingyise"
fxIconConfig[2] = "result_font_qingqidui"
fxIconConfig[3] = "result_font_qingdadui"
fxIconConfig[4] = "result_font_qingdaiyao"
fxIconConfig[5] = nil
fxIconConfig[6] = "result_font_sufan"
fxIconConfig[7] = "result_font_qidui"
fxIconConfig[8] = "result_font_daduizi"
fxIconConfig[9] = "result_font_quandaiyao"
fxIconConfig[10] = "result_font_jiangdadui"
fxIconConfig[11] = "result_font_yaojiuqidui"
fxIconConfig[12] = "result_font_qinglongqidui"
fxIconConfig[13] = "result_font_longqidui"

function fxIconConfig.getFXIcon(fx)
    return "result/" .. fxIconConfig[fx] .. ".png"
end
return fxIconConfig
