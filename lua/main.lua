package.path = "src/?.lua;framework/?.lua;" .. package.path

-- framework
require("include")

-- MOAILuaRuntime.setTrackingFlags(MOAILuaRuntime.TRACK_OBJECTS_STACK_TRACE)

-- initializers
require("initializers.Flags")
require("initializers.OpenWindow")
require("initializers.ResourceRules")

-- for squish: require( "scenes.TestScene" )
SceneManager:pushScene("scenes.TestScene")
