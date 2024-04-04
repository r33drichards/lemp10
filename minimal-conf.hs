import XMonad
import XMonad.Util.EZConfig
import XMonad.Util.Ungrab
import XMonad.Hooks.ManageDocks
import XMonad.Layout.Spacing
import XMonad.Hooks.EwmhDesktops

main = do
  xmonad $ ewmh def
    { terminal    = myTerminal
    , modMask     = myModMask
    , borderWidth = myBorderWidth
    , layoutHook  = myLayoutHook
    , handleEventHook = handleEventHook def <+> fullscreenEventHook
    }
    `additionalKeysP`
    [
      -- enable and disable touchpad
      ("M-t", spawn "xinput disable 13"),
      ("M-S-t", spawn "xinput enable 13")
    ]

myTerminal    = "sakura"
myModMask     = mod4Mask -- Win key or Super_L
myBorderWidth = 2

-- Define a layout hook with spacing and avoidStruts
myLayoutHook = avoidStruts $ spacingRaw True (Border 10 10 10 10) True (Border 10 10 10 10) True $ layoutHook def
