local TimeCount = class("TimeCount")

function TimeCount:ctor(tag)
    assert(tag, "time count must has a tag.")
    self.m_t1 = nil
    self.m_t2 = nil
    self.m_tag = tag
    self.m_table = {"year", "month", "day", "hour", "min", "sec"}
end

function TimeCount:start()
    self.m_t1 = customtime.gettime()
end
function TimeCount:stop()
    self.m_t2 = customtime.gettime()
    printInfo(self.m_tag .. " used time:".. customtime.difftime(self.m_t1 ,self.m_t2) .. "ms")
end
return TimeCount
