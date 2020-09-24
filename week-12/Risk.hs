{-# LANGUAGE GeneralizedNewtypeDeriving #-}

module Risk where

import Control.Monad.Random
import Control.Applicative
import Data.List
import Debug.Trace

------------------------------------------------------------
-- Die values

newtype DieValue = DV { unDV :: Int } 
  deriving (Eq, Ord, Show, Num)

first :: (a -> b) -> (a, c) -> (b, c)
first f (a, c) = (f a, c)

instance Random DieValue where
  random           = first DV . randomR (1,6)
  randomR (low,hi) = first DV . randomR (max 1 (unDV low), min 6 (unDV hi))

die :: Rand StdGen DieValue
die = getRandom

testDie = evalRandIO (die)
------------------------------------------------------------
-- Risk

type Army = Int

data Battlefield = Battlefield { attackers :: Army, defenders :: Army } deriving Show

-- 1

battle :: Battlefield -> Rand StdGen Battlefield
battle (Battlefield a d) = do
  aRolls <- return (attackerRolls a)
  dRolls <- return (defenderRolls d)
  rollResults <- return $ zipWith compare <$> aRolls <*> dRolls
  (aLosses, dLosses) <- summedResults <$> rollResults
  return (Battlefield (a - aLosses) (d - dLosses))

summedResults :: [Ordering] -> (Int, Int)
summedResults rolls =
  foldr (\roll (a, d) -> 
    if roll == GT then 
      (a, (d + 1))
    else 
      (a + 1, d)) (0,0) rolls

attackerRolls :: Army -> Rand StdGen [DieValue]
attackerRolls size
  | size < 2 = return []
  | otherwise  = reverse . sort <$> sequence rolls
      where rolls = replicate (min 3 (size - 1)) die

defenderRolls :: Army -> Rand StdGen [DieValue]
defenderRolls size
  | size < 1 = return []
  | otherwise  = reverse . sort <$> sequence rolls
      where rolls = replicate (min 2 size) die

testBattle = evalRandIO (battle (Battlefield 3 2))