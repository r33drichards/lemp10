import XMonad
import XMonad.Util.EZConfig
import XMonad.Util.Ungrab
import XMonad.Hooks.ManageDocks
import XMonad.Layout.Spacing

main = do
  xmonad $ def
    { terminal    = myTerminal
    , modMask     = myModMask
    , borderWidth = myBorderWidth
    , layoutHook  = myLayoutHook
    }

myTerminal    = "sakura"
myModMask     = mod4Mask -- Win key or Super_L
myBorderWidth = 3

-- Define a layout hook with spacing and avoidStruts
myLayoutHook = avoidStruts $ spacingRaw True (Border 10 10 10 10) True (Border 10 10 10 10) True $ layoutHook def
