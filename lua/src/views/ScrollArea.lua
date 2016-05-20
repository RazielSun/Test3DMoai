
local Component = require("entity.Component")
local InputEvent = require("input.InputEvent")

local abs = math.abs
local max = math.max
local min = math.min
local atan = math.atan
local ceil = math.ceil
local clamp = math.clamp
local round = math.round
local distance = math.distance

---------------------------------------------------------------------------------
--
-- @type ScrollArea
--
---------------------------------------------------------------------------------

local ScrollArea = Class( Component, "ScrollArea" ):FIELDS {
}

ScrollArea.EVENTS = _ENUM_S {
	"SCROLL_BEGIN",
	"SCROLL",
	"SCROLL_END",
}

ScrollArea.DIRECTIONS = _ENUM_S {
	"BOTH",
	"VERTICAL",
	"HORIZONTAL",
}


--------------------------------------------------------------------------------
-- private 
--------------------------------------------------------------------------------
local CIRCULAR_ARRAY_DEFAULT_CAPACITY = 4

local CircularArray = Class( "CircularArray" ) -- class for managing circular array to accumulate user touch updates and compute average velocity

function CircularArray:init(cap)
    self._innerTable = {}
    self._cap = cap or CIRCULAR_ARRAY_DEFAULT_CAPACITY
    self:clear()
end

function CircularArray:startTracking()
    self:stopTracking()
    self._updateThread = Executors.callLoop(function()
        for k, v in pairs(self._innerTable) do
            v.elapsedFrames = v.elapsedFrames + 1
            if v.elapsedFrames > self._cap then
                self._innerTable[k].x = 0
                self._innerTable[k].y = 0
            end
        end
    end)
end

function CircularArray:stopTracking()
    if self._updateThread then
        self._updateThread:stop()
        self._updateThread = nil
    end
end

function CircularArray:add(x, y)
    local index = self._lastIndex
    self._innerTable[index] = {
        x = x,
        y = y,
        elapsedFrames = 0,
    }
    self._lastIndex = 1 + (index + 1) % self._cap
end

function CircularArray:clear()
    for i = 1, self._cap do
        self._innerTable[i] = {x = 0, y = 0, elapsedFrames = 0}
    end
    self._lastIndex = 1
end

function CircularArray:average()
    local totalX = 0
    local totalY = 0
    local count = 0
    
    for k, v in pairs(self._innerTable) do
        if v.elapsedFrames <= self._cap then
            totalX = totalX + v.x
            totalY = totalY + v.y
            count = count + 1
        end
    end

    if count > 0 then
        return totalX / count, totalY / count
    else
        return 0, 0
    end
end

--------------------------------------------------------------------------------
-- attenuation 
--------------------------------------------------------------------------------

local function attenuation(distance)
    return 4 * atan(0.25 * distance) / distance
end

--------------------------------------------------------------------------------
-- ScrollArea 
--------------------------------------------------------------------------------

function ScrollArea:init( option )
	local option = option or {}
	option.name = option.name or "ScrollArea"

	self.direction = option.direction or ScrollArea.DIRECTIONS.BOTH
	self.contentRect = option.contentRect or { 0, 0, 0, 0 }
	self.boundRect = option.boundRect or { 0, 0, 0, 0 }
	self.target = option.target
	self.camera = option.camera
	self.xScrollEnabled = true
    self.yScrollEnabled = true
    self.touchDistanceToSlide = 15
    self.rubberEffect = false
    
    self:updatePossibleDirections()

    self.layer = MOAILayer.new()
    self.layer:setViewport( App.viewport )

    self._velocityAccumulator = CircularArray()
    self._scrollPositionX = 0
    self._scrollPositionY = 0
	
	Component.init( self, option )
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
function ScrollArea:setTarget( target )
	self.target = target
end

function ScrollArea:setCamera( camera )
	self.camera = camera
end

function ScrollArea:setContentRect( xMin, yMin, xMax, yMax )
	self.contentRect[1] = xMin
	self.contentRect[2] = yMin
	self.contentRect[3] = xMax
	self.contentRect[4] = yMax
	self:updatePossibleDirections()
end

function ScrollArea:updatePossibleDirections()
	local xMin, yMin, xMax, yMax = unpack(self.boundRect)
	local xMinContent, yMinContent, xMaxContent, yMaxContent = unpack(self.contentRect)
	local xPossible = xMax - xMin < xMaxContent - xMinContent
	local yPossible = yMax - yMin < yMaxContent - yMinContent

    self.xScrollEnabled = false
    self.yScrollEnabled = false

    if self.direction == ScrollArea.DIRECTIONS.HORIZONTAL then
        self.xScrollEnabled = xPossible
        self.yScrollEnabled = false
    end
    
    if self.direction == ScrollArea.DIRECTIONS.VERTICAL then
        self.xScrollEnabled = false
        self.yScrollEnabled = yPossible
    end

    if self.direction == ScrollArea.DIRECTIONS.BOTH then
        self.xScrollEnabled = xPossible
        self.yScrollEnabled = yPossible
    end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
function ScrollArea:checkBounds( dx, dy )
    dx = dx or 0
    dy = dy or 0
    
    local newX = -(self._scrollPositionX + dx)
    local newY = -(self._scrollPositionY + dy)
    local xMin, yMin, xMax, yMax = unpack(self.boundRect)
    local xMinContent, yMinContent, xMaxContent, yMaxContent = unpack(self.contentRect)

    -- this prevents scrolling when content area is smaller than scroll view size
    if xMaxContent - xMinContent < xMax - xMin then
        xMinContent = xMaxContent - xMax + xMin
    end
    if yMaxContent - yMinContent < yMax - yMin then
        yMinContent = yMaxContent - yMax + yMin
    end

    local xOffset, yOffset = 0, 0
    if newX + xMax > xMaxContent then
        xOffset = newX + xMax - xMaxContent
    end
    if newX + xMin < xMinContent then
        xOffset = newX + xMin - xMinContent
    end

    if newY + yMin < yMinContent then
        yOffset = newY + yMin - yMinContent
    end
    if newY + yMax > yMaxContent then
        yOffset = newY + yMax - yMaxContent
    end

    return xOffset == 0, yOffset == 0, xOffset, yOffset
end

function ScrollArea:updatePosition()
	if self.target then
		self.target:setLoc( self._scrollPositionX, self._scrollPositionY )
	elseif self.camera then
		self.camera:setLoc( -self._scrollPositionX, -self._scrollPositionY )
	end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
function ScrollArea:startScroll( event )
	self._trackingTouch = true

	self._velocityAccumulator:clear()
    self._velocityAccumulator:startTracking()

	self:dispatchEvent( { eventType = ScrollArea.EVENTS.SCROLL_BEGIN } )
end

function ScrollArea:scroll( dx, dy )
	local xOk, yOk, xOffset, yOffset = self:checkBounds(dx, dy)

	if self._touchIdx and not xOk then 
        dx = self.rubberEffect and attenuation(abs(xOffset)) * dx or (dx + xOffset)
    end
    if self._touchIdx and not yOk then 
        dy = self.rubberEffect and attenuation(abs(yOffset)) * dy or (dy + yOffset)
    end

	if self.xScrollEnabled then
		self._scrollPositionX = self._scrollPositionX + dx
	end
    if self.yScrollEnabled then
    	self._scrollPositionY = self._scrollPositionY + dy
    end

	self._velocityAccumulator:add(dx, dy)

	self:dispatchEvent( { eventType = ScrollArea.EVENTS.SCROLL, delta = { dx, dy } } )

	self:updatePosition()
end

function ScrollArea:stopScroll( event )
	self._touchIdx = nil
	self._trackingTouch = false

	self._velocityAccumulator:stopTracking()

	self:dispatchEvent( { eventType = ScrollArea.EVENTS.SCROLL_END } )
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
function ScrollArea:touchOffset( event )
	local x1, y1 = self.layer:wndToWorld( event.wx, event.wy, 0 )
	local x0, y0 = self.layer:wndToWorld( event.x_b, event.y_b, 0 )
	return x1 - x0, y1 - y0
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
function ScrollArea:startKineticScroll()
	--
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
function ScrollArea:handleInputEvent( event )
	local handled = false

	if InputEvent.isPointed( event ) then
		local evtype = event.eventName

		if evtype == InputEvent.DOWN then
			self._touchIdx = event.idx
		    self._trackingTouch = false
	    elseif evtype == InputEvent.MOVE then
	    	if self._touchIdx == event.idx then
	    		if self._trackingTouch then
	    			local dx, dy = self:touchOffset( event )
	    			self:scroll( dx, dy )
	    		end
	    		
			    if not self._trackingTouch then
			    	local dx, dy = event:getDelta()
			    	if (self.xScrollEnabled and math.abs(dx) > self.touchDistanceToSlide
		    			or self.yScrollEnabled and math.abs(dy) > self.touchDistanceToSlide) then
				    	self:startScroll( event )
				    end
			    end
	    	end
	    elseif evtype == InputEvent.UP or evtype == InputEvent.TOUCH_CANCEL then
	    	if self._touchIdx == event.idx then
	    		self:stopScroll( event )
	    	end
	    end

		handled = self._trackingTouch
	end

	return handled
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

return ScrollArea
