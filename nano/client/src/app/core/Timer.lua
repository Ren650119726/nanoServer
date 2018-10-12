local Timer = class("Timer")

function Timer:ctor(key, handler, interval, times, delay)
    self.m_key = key
    self.m_handler = handler

    self.m_interval = interval or 0
    self.m_elapse = 0
    self.m_delay = delay or 0
    self.m_useDelay = (self.m_delay > 0)

    self.m_times = times or -1
    self.m_repeatForever = (self.m_times < 0)
    self.m_executeTimes = 0

    self.m_isCancel = false
end

function Timer:update(dt)
    if self.m_isCancel then 
        return
    end
    self.m_elapse = self.m_elapse + dt
    
    --for delay
    if self.m_useDelay then
        if self.m_elapse >= self.m_delay then
            self.m_useDelay = false
            self.m_elapse = self.m_elapse - self.m_delay
        else 
            return
        end
    end
    --for timer, if intervale is zero, use dt
    local interval = (self.m_interval > 0) and self.m_interval or dt
    while self.m_elapse >= interval do
        self:trigger(interval)
        self.m_elapse = self.m_elapse - interval
        self.m_executeTimes = self.m_executeTimes + 1

        if (not self.m_repeatForever) and (self.m_executeTimes >= self.m_times) then
            self:cancel()
            break
        end
    end
end

function Timer:trigger(dt)
    if self.m_handler then
        self.m_handler(dt, self.m_key)
    end
end

function Timer:cancel()
    self.m_isCancel = true
end

function Timer:isCancel()
    return self.m_isCancel
end
return Timer
