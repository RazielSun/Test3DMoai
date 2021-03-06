
local Scene = require("scenes.Scene")

--------------------------------------------------------------------------------
--
-- TestScene.lua
--
--------------------------------------------------------------------------------

local TestScene = Class( Scene, "TestScene" )

function TestScene:init( option )
	Scene.init(self, option)
	self:initReferences()
end

--------------------------------------------------------------------------------
function TestScene:initReferences()
	MOAIGfxDevice.getFrameBuffer():setClearDepth( true )

	-- default basic shader
	-- require("tests.test1"):setup( self.defaultLayer )

	-- test 2 - Simple RED
	-- require("tests.test2"):setup( self.defaultLayer )

	-- test 3 - Simple Blue only XY coords
	-- require("tests.test3"):setup( self.defaultLayer )

	-- test 4 - Invert texture
	-- require("tests.test4"):setup( self.defaultLayer )

	-- test 5 - Vignette Sepia
	-- require("tests.test5"):setup( self.defaultLayer )

	-- test 6 - Multi Texture
	-- require("tests.test6"):setup( self.defaultLayer )

	-- test 7 - Blur
	-- require("tests.test7"):setup( self.defaultLayer )

	-- test 8 - Normal Map
	-- require("tests.test8"):setup( self.defaultLayer )

	-- test 9 - Test curve
	-- require("tests.test9"):setup( self.defaultLayer )

	-- test 10 - Sample 3d curve
	-- require("tests.test10"):setup( self.defaultLayer )
	self:initMap()
end

function TestScene:initMap()
	local MapView = require("views.MapView")
	local map = self:addEntity( MapView() )
	self.map = map
end

function TestScene:onLoad()
	-- self.inputDevice:addListener( self.jui )
	self.inputDevice:addListener( self.map )

	-- UIMgr:setMainUI( self.jui )
end

function TestScene:onUnload()
	-- self.inputDevice:removeListener( self.jui )
	self.inputDevice:removeListener( self.map )

	-- UIMgr:removeMainUI( self.jui )
end

--------------------------------------------------------------------------------

return TestScene