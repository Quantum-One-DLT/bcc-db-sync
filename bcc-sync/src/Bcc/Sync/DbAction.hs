{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}

module Bcc.Sync.DbAction
  ( DbAction (..)
  , DbActionQueue (..)
  , blockingFlushDbActionQueue
  , lengthDbActionQueue
  , mkDbApply
  , newDbActionQueue
  , writeDbActionQueue
  , waitRollback
  ) where

import           Bcc.Prelude

import           Bcc.Sync.Types

import qualified Control.Concurrent.STM as STM
import           Control.Concurrent.STM.TBQueue (TBQueue)
import qualified Control.Concurrent.STM.TBQueue as TBQ

import           Control.Monad.Class.MonadSTM.Strict (StrictTMVar, newEmptyTMVarIO, takeTMVar)

data DbAction
  = DbApplyBlock !BlockDetails
  | DbRollBackToPoint !BccPoint (StrictTMVar IO (Maybe [BccPoint]))
  | DbFinish

newtype DbActionQueue = DbActionQueue
  { dbActQueue :: TBQueue DbAction
  }

mkDbApply :: BccBlock -> SlotDetails -> DbAction
mkDbApply cblk details =
  DbApplyBlock (BlockDetails cblk details)

-- | This simulates a synhronous operations, since the thread waits for the db
-- worker thread to finish the rollback.
waitRollback :: DbActionQueue -> BccPoint -> IO (Maybe [BccPoint])
waitRollback queue point = do
    resultVar <- newEmptyTMVarIO
    atomically $ writeDbActionQueue queue $ DbRollBackToPoint point resultVar
    atomically $ takeTMVar resultVar

lengthDbActionQueue :: DbActionQueue -> STM Natural
lengthDbActionQueue (DbActionQueue q) = STM.lengthTBQueue q

newDbActionQueue :: IO DbActionQueue
newDbActionQueue =
    -- Use an odd number here so that the db_tip_height metric increments by this odd number
    -- when syncing, instead of incrementing by say 2000.
    DbActionQueue <$> TBQ.newTBQueueIO 2117

writeDbActionQueue :: DbActionQueue -> DbAction -> STM ()
writeDbActionQueue (DbActionQueue q) = TBQ.writeTBQueue q

-- | Block if the queue is empty and if its not read/flush everything.
-- Need this because `flushTBQueue` never blocks and we want to block until
-- there is one item or more.
-- Use this instead of STM.check to make sure it blocks if the queue is empty.
blockingFlushDbActionQueue :: DbActionQueue -> IO [DbAction]
blockingFlushDbActionQueue (DbActionQueue queue) = do
  STM.atomically $ do
    x <- TBQ.readTBQueue queue
    xs <- TBQ.flushTBQueue queue
    pure $ x : xs
