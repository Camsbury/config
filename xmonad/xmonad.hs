import Control.Monad
import Data.Bool
import Data.Foldable
import Data.Traversable
import System.IO
import XMonad
import XMonad.Layout
import XMonad.Layout.ThreeColumns
import XMonad.Layout.NoBorders
import XMonad.Util.EZConfig

import qualified XMonad.StackSet as W

main = do
  xmonad $ defaultConfig
         { layoutHook = smartBorders $
           ThreeCol 1 (3/100) (1/4) ||| noBorders Full ||| Tall 1 (3/100) (1/2)
         , focusFollowsMouse = False
         , startupHook = spawn "sh ~/.scripts/startup.sh"
         } `additionalKeysP` myKeys

myKeys = [ ("M1-M4-S-C-c", grabApp "chromium" "Chromium-browser")
         , ("M1-M4-S-C-e", grabApp "emacs" "Emacs")
         , ("M1-M4-S-C-k", grabApp "slack" "Slack")
         , ("M1-M4-S-C-s", grabApp "spotify" "Spotify")
         , ("M1-M4-S-C-t", grabApp "xterm" "XTerm")
         , ("M1-M4-S-C-v", grabApp "vlc" "Vlc")
         , ("M1-c",        spawn   "sh ~/.scripts/check-time.sh")
         , ("M1-b",        spawn   "sh ~/.scripts/check-battery.sh")
         , ("M1-m",        spawn   "sh ~/.scripts/pomodoro.sh")
         , ( "<XF86AudioRaiseVolume>"
           , spawn   "pactl set-sink-volume @DEFAULT_SINK@ +1000"
           )
         , ( "<XF86AudioLowerVolume>"
           , spawn   "pactl set-sink-volume @DEFAULT_SINK@ -1000"
           )
         , ( "<XF86AudioMute>"
           , spawn   "pactl set-sink-mute @DEFAULT_SINK@ toggle"
           )
         ]

findAppWindows :: String -> X [Window]
findAppWindows queriedName = withWindowSet filterQueried
  where
    filterQueried windowSet
      = filterM (hasWindowName queriedName)
      $ W.allWindows windowSet

hasWindowName :: String -> Window -> X Bool
hasWindowName queriedName window
  =   (== queriedName)
  <$> runQuery className window

grabApp :: String -> String -> X ()
grabApp spawnName matchName = do
  winV <- findAppWindows matchName
  case winV of
    (headWin:_) -> windows . W.focusWindow $ head winV
    _           -> spawn spawnName
