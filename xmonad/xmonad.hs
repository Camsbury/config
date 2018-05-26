import Control.Monad
import Data.Bool
import Data.Foldable
import Data.Traversable
import System.IO
import XMonad
import XMonad.Layout
import XMonad.Layout.NoBorders
import XMonad.Util.EZConfig

import qualified XMonad.StackSet as W

main = do
  xmonad $ defaultConfig
         { layoutHook = smartBorders $ noBorders Full ||| Tall 1 (3/100) (1/2)
         , focusFollowsMouse = False
         } `additionalKeysP` myKeys

myKeys = [ ("M1-M4-S-C-c", grabApp "chromium" "Chromium-browser")
         , ("M1-M4-S-C-e", grabApp "emacs" "Emacs")
         , ("M1-M4-S-C-t", grabApp "xterm" "XTerm")
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
