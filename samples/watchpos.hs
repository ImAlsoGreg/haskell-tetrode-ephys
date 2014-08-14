{-# LANGUAGE NoMonomorphismRestriction #-}

module Main where

------------------------------------------------------------------------------
import           Control.Lens
import qualified Data.Map as Map
import qualified Data.Vector as V
------------------------------------------------------------------------------
import           Graphics.Gloss
import           Graphics.Gloss.Interface.IO.Game
------------------------------------------------------------------------------
import           Data.Ephys.GlossPictures
import           Data.Ephys.OldMWL.ParsePFile
import           Data.Ephys.Position
import           Data.Ephys.TrackPosition

------------------------------------------------------------------------------
-- Current time, current pos, track segs, occupancy)
type World = (Float, Position, Track, Field)


------------------------------------------------------------------------------
-- The default track for caillou's Nov 28 sample data.
myTrack :: Track
myTrack = circularTrack (0,0) 0.75 0 0.2 0.25


------------------------------------------------------------------------------
gScale :: Float
gScale = 200


------------------------------------------------------------------------------
main :: IO ()
main = playIO (InWindow "My Window" (400,400) (10,10))
       white
       60
       (0,p0,t0,f0)
       (drawWorld :: World -> IO Picture)
       (eventUpdateWorld :: Event -> World -> IO World)
       (timeUpdateWorld)
  where p0 = Position 0 (Location 0 0 0)
             (Angle 0 0 0) 0 0 ConfSure someZeros someZeros
             (-1/0) (Location 0 0 0):: Position
        t0 = myTrack
        f0 = V.replicate (length $ allTrackPos t0) 0 :: Field
        someZeros = take 20 . repeat $ 0

eventUpdateWorld :: Event -> World -> IO World
eventUpdateWorld (EventMotion (x',y')) (now, p,t,occ) =
  let --p' = Position 0 (Location ((r2 x')/ r2 gScale) ((r2 y') / r2 gScale) (p^.location.z))
      --     (Angle 0 0 0) 0 0 ConfSure
      p' = stepPos p (realToFrac now)
           (Location ((realToFrac x')/realToFrac gScale)
            ((realToFrac y') / realToFrac gScale)
            (p^.location.z))
           (Angle 0 0 0) ConfSure
      occ' = updateField (+) occ (posToField t p (PosGaussian 0.4))
  in return (now, p',t,occ')
eventUpdateWorld (EventKey _ _ _ _) w = return w
eventUpdateWorld (EventResize _) w = return w 

timeUpdateWorld :: Float -> World -> IO World
timeUpdateWorld t (now,p,track,occ) = return (now+t,p,track,occ)

drawWorld :: World -> IO Picture
drawWorld (now,p,t,occ) =
  do print p
     return . Scale gScale gScale $
       pictures [drawTrack t, drawNormalizedField occ, drawPos p]