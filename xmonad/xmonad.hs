import Control.Monad
import Data.Bool
import Data.Foldable
import Data.Traversable
import System.IO
import XMonad
-- import XMonad.Hooks.Script
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
         -- , startupHook = execScriptHook "" -- permission denied...
         } `additionalKeysP` myKeys

myKeys = [ ("M1-M4-S-C-c", grabApp "chromium" "Chromium-browser")
         , ("M1-M4-S-C-d", grabApp "dota2" "dota2")
         , ("M1-M4-S-C-e", grabApp "emacs" "Emacs")
         , ("M1-M4-S-C-s", grabApp "spotify" "Spotify")
         , ("M1-M4-S-C-t", grabApp "xterm" "XTerm")
         , ("M1-M4-S-C-v", grabApp "vlc" "Vlc")
         ]

findAppWindows :: String -> X [Window]
findAppWindows queriedName = withWindowSet $ \windowSet -> do
  let windowsV = W.allWindows windowSet
  filterM (hasWindowName queriedName) windowsV

hasWindowName :: String -> Window -> X Bool
hasWindowName queriedName window = do
  windowName <- runQuery className window
  pure $ windowName == queriedName

grabApp :: String -> String -> X ()
grabApp spawnName matchName = do
  winV <- findAppWindows matchName
  if length winV > 0 then
    windows . W.focusWindow $ head winV
    else spawn spawnName
