local TimerScheduler = class("TimerScheduler")
local TimerClass = require "app.core.Timer"

function TimerScheduler:ctor()
    self.m_timers = {}
    self.m_needRemoveTimers = {}
end

function TimerScheduler:scheduler(key, handler, interval, times, delay)
    local timer = TimerClass:create(key, handler, interval, times, delay)
    local realKey = string.upper(tostring(key))
    if self.m_timers[realKey] then
        printInfo("timer [%s] is existed, it will be replace by new.", realKey)
    end
    self.m_timers[realKey] = timer
    return timer
end

function TimerScheduler:unScheduler(key)
    local realKey = string.upper(tostring(key))
    local timer = self.m_timers[realKey]
    if timer == nil then
        printInfo("unScheduler: timer [%s] is not existed", realKey)
        return
    end
    timer:cancel()
    self.m_timers[realKey] = nil
    table.push(self.m_needRemoveTimers, realKey)
end

function TimerScheduler:unSchedulerAll()
    local keys = {}
    for k, v in self.m_timers do
        keys[#keys + 1] = k
    end
    for i = 1, #keys do
        local key = keys[i]
        self:unScheduler(key)
    end
end

function TimerScheduler:update(dt)
    local len = #self.m_needRemoveTimers
    if len > 0 then
        for i = 1, len do
            local key = self.m_needRemoveTimers[i]
            self.m_timers[key] = nil
            self.m_needRemoveTimers[i] = nil
        end
    end
    for k, timer in pairs(self.m_timers) do
        timer:update(dt)

        if timer:isCancel() then
            self:unScheduler(k)
        end
    end
end

return TimerScheduler
