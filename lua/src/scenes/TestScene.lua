
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

	-- test 5 - Vignette Sepia
	-- require("tests.test5"):setup( self.defaultLayer )

	-- test 6 - Multi Texture
	-- require("tests.test6"):setup( self.defaultLayer )

	-- test 7 - Blur
	-- require("tests.test7"):setup( self.defaultLayer )

	-- test 8 - Normal Map
	-- require("tests.test8"):setup( self.defaultLayer )

	-- test 9 - Test curve
	require("tests.test9"):setup( self.defaultLayer )

end



--------------------------------------------------------------------------------

return TestScene