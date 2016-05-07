
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
	-- default basic shader
	-- require("tests.test1"):setup( self.defaultLayer )

	-- test 2 - Simple RED
	-- require("tests.test2"):setup( self.defaultLayer )

	-- test 3 - Simple Blue only XY coords
	-- require("tests.test3"):setup( self.defaultLayer )

	-- test 4 - Invert texture
	-- require("tests.test4"):setup( self.defaultLayer )

	-- test 5 - Sepia
	require("tests.test5"):setup( self.defaultLayer )
end



--------------------------------------------------------------------------------

return TestScene