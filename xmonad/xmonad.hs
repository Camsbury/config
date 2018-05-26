import Control.Monad
import Data.Bool
import Data.Traversable
import System.IO
import XMonad
import XMonad.Actions.WindowBringer
import XMonad.Layout
import XMonad.Layout.NoBorders
import XMonad.Util.EZConfig

import qualified XMonad.StackSet as W

main = do
  xmonad $ defaultConfig
         { terminal = "konsole"
         , layoutHook = smartBorders $ noBorders Full ||| Tall 1 (3/100) (1/2)
         , focusFollowsMouse = False
         } `additionalKeysP` myKeys

myKeys = [ ("M1-M4-S-C-c", grabApp "chromium")
         , ("M1-M4-S-C-e", grabApp "emacs")
         ]

-- .StackSet -> W.allWindows :: Eq a => StackSet i l a s sd -> [a]
-- .Core -> withWindowSet :: (WindowSet -> X a) -> X a
-- .Core -> withDisplay :: (Display -> X a) -> X a
-- resClass/getClassHint?
findAppWindows :: String -> X [Window]
findAppWindows queriedName = withWindowSet $ \windowSet -> do
  let windowsV = W.allWindows windowSet
  filterM (hasWindowName queriedName) windowsV
      -- (\window -> do
      --   windowName <- withDisplay $ \display -> fmap resClass . liftIO $ getClassHint display window
      --   pure $ bool [] [window] (windowName == name) :: X [Window]
      -- ) >>= pure . join

hasWindowName :: String -> Window -> X Bool
hasWindowName queriedName window = do
  windowName <- withDisplay $ \display -> fmap resClass . liftIO $ getClassHint display window
  pure $ windowName == queriedName

grabApp :: String -> X ()
grabApp app = do
  winV <- findAppWindows app
  if length winV > 0 then
    windows . W.focusWindow $ head winV
    else spawn app
