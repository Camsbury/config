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

myKeys = [ ("M1-M4-S-C-a", grabApp "anki" "Anki")
         , ("M1-M4-S-C-c", grabApp "brave" "Brave-browser")
         , ("M1-M4-S-C-e", grabApp "emacs" "Emacs")
         , ("M1-M4-S-C-g", grabApp "signal-desktop" "Signal")
         , ("M1-M4-S-C-k", grabApp "slack" "Slack")
         , ("M1-M4-S-C-s", grabApp "spotify" "Spotify")
         , ("M1-M4-S-C-t", grabApp "xterm" "XTerm")
         , ("M1-M4-S-C-v", grabApp "vlc" "Vlc")
         , ("M1-c",        spawn   "sh ~/.scripts/check-time.sh")
         , ("M1-b",        spawn   "sh ~/.scripts/check-battery.sh")
         , ("M1-m",        spawn   "sh ~/.scripts/pomodoro.sh")
         , ("C-<Space>",   spawn   "xkb-switch -n")
         , ( "<XF86MonBrightnessUp>"
           , spawn "sh ~/.scripts/brightness.sh +2"
           )
         , ( "<XF86MonBrightnessDown>"
           , spawn "sh ~/.scripts/brightness.sh -2"
           )
         , ( "<XF86AudioRaiseVolume>"
           , spawn "pactl set-sink-volume @DEFAULT_SINK@ +1000"
           )
         , ( "<XF86AudioLowerVolume>"
           , spawn "pactl set-sink-volume @DEFAULT_SINK@ -1000"
           )
         , ( "<XF86AudioMute>"
           , spawn "pactl set-sink-mute @DEFAULT_SINK@ toggle"
           )
         , ( "<XF86AudioPlay>" -- default to spotify until intelligent process stuff
           , spawn "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause"
           )
         , ( "<XF86AudioPrev>" -- default to spotify until intelligent process stuff
           , spawn "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous"
           )
         , ( "<XF86AudioNext>" -- default to spotify until intelligent process stuff
           , spawn "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next"
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
