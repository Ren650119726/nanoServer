stack = class("stack")

function stack:ctor()
    self.t = {}
    self.topIdx = 0
end

function stack:push(value)
    self.topIdx = self.topIdx + 1
    self.t[self.topIdx] = value
end
function stack:pop()
    assert(self.topIdx > 0)
    local topIdx = self.topIdx
    self.topIdx = topIdx - 1
    local top = self.t[topIdx]
    self.t[topIdx] = nil
    return top
end
function stack:top()
    assert(self.topIdx > 0)
    return self.t[self.topIdx]
end
function stack:isEmpty()
    return not (self.topIdx > 0)
end