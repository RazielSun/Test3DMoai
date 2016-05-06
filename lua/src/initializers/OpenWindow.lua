--------------------------------------------------------------------------------
-- Open window
--
--
--------------------------------------------------------------------------------

local Layer = require("core.Layer")

local width, height = MOAIEnvironment.horizontalResolution or 640, MOAIEnvironment.verticalResolution or 960
local ratio = height / width


-- use 384 width and iPad resources for big screens
-- use 320 and iPhone resources for smaller
-- height is dynamically adjusted to fit
-- 4/3 devices are always treated big (for layouts to work properly)
local BIG_SCREEN_WIDTH = 3.5 -- inches
local isBig = math.abs(ratio - 4/3) < 0.1

if MOAIEnvironment.screenDpi then
    isBig = isBig or (width / MOAIEnvironment.screenDpi > BIG_SCREEN_WIDTH)
else
    isBig = isBig or (width > 900)
end

local viewWidth, viewHeight
if isBig then
    viewWidth = 384
else
    viewWidth = 320
end
viewHeight = ratio * viewWidth

local windowParams = {
    screenWidth = width,
    screenHeight = height,
    viewWidth = viewWidth,
    viewHeight = viewHeight,
    scaleMode = "manual",
    viewOffset = {0, 0},
}

App:openWindow("FruityMap", windowParams)
App.LAYOUT = isBig and "ipad" or "iphone"
App.DEBUG = DEBUG

-- Default effect is DARKEN
-- Shader linking is not needed (was used for DESATURATE)
Layer.ENABLE_SHADER_OVERRIDES = false
Gui.Dialog.DEFAULT_EFFECT = SceneMgr.DARKEN

MOAISim.setStep(1 / 60)
MOAISim.clearLoopFlags()
MOAISim.setLoopFlags(MOAISim.SIM_LOOP_ALLOW_BOOST)
MOAISim.setLoopFlags(MOAISim.SIM_LOOP_LONG_DELAY)
MOAISim.setBoostThreshold(0)
MOAISim.setLongDelayThreshold(5)

RenderMgr:setClearColor( 220.0/255.0, 178.0/255.0, 92.0/255.0, 1 )




