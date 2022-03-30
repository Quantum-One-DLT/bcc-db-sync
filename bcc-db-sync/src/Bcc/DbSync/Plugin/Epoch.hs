{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE MultiWayIf #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}

module Bcc.DbSync.Plugin.Epoch
  ( epochPluginOnStartup
  , epochPluginInsertBlock
  , epochPluginRollbackBlock
  ) where

import           Bcc.Prelude hiding (from, on, replace)

import           Bcc.BM.Trace (Trace, logError, logInfo)

import qualified Bcc.Chain.Block as Cole
import           Bcc.Slotting.Slot (EpochNo (..))

import           Control.Monad.Logger (LoggingT)
import           Control.Monad.Trans.Control (MonadBaseControl)

import           Data.IORef (IORef, atomicWriteIORef, newIORef, readIORef)

import           Database.Esqueleto.Legacy (Value (..), desc, from, limit, orderBy, select, val,
                   where_, (==.), (^.))

import           Database.Persist.Class (replace)
import           Database.Persist.Sql (SqlBackend)

import           Bcc.Db (EntityField (..), EpochId, SyncState (..))
import qualified Bcc.Db as DB

import           Bcc.Sync.Api
import           Bcc.Sync.Error
import           Bcc.Sync.Types
import           Bcc.Sync.Util

import           Shardagnostic.Consensus.Cole.Ledger (ColeBlock (..))
import           Shardagnostic.Consensus.Bcc.Block (HardForkBlock (..))

import           System.IO.Unsafe (unsafePerformIO)

-- Populating the Epoch table has two mode:
--  * SyncLagging: when the node is far behind the chain tip and is just updating the DB. In this
--    mode, the row for an epoch is only calculated and inserted when at the end of the epoch.
--  * Following: When the node is at or close to the chain tip, the row for a given epoch is
--    updated on each new block.
--
-- When in syncing mode, the row for the current epoch being synced may be incorrect.


epochPluginOnStartup :: SqlBackend -> Trace IO Text -> IO (Either a ())
epochPluginOnStartup backend trce =
  Right <<$>> DB.runDbtbcoLogging backend trce $ do
    liftIO . logInfo trce $ "epochPluginOnStartup: Checking"
    mlbe <- queryLatestEpochNo
    case mlbe of
      Nothing ->
        pure ()
      Just lbe -> do
        let backOne = if lbe == 0 then 0 else lbe - 1
        liftIO $ atomicWriteIORef latestCachedEpochVar (Just backOne)

epochPluginInsertBlock
    :: SqlBackend -> Trace IO Text -> SyncEnv -> [BlockDetails]
    -> IO (Either SyncNodeError ())
epochPluginInsertBlock backend trce _dbSyncEnv blockDetails =
    DB.runDbtbcoLogging backend trce $ traverseMEither insert blockDetails
  where
    insert :: BlockDetails -> ReaderT SqlBackend (LoggingT IO) (Either SyncNodeError ())
    insert (BlockDetails cblk details) = do
      case cblk of
        BlockCole bblk ->
          case coleBlockRaw bblk of
            Cole.ABOBBoundary {} ->
              -- For the OBFT era there are no boundary blocks so we ignore them even in
              -- the Shardagnostic Classic era.
              pure $ Right ()

            Cole.ABOBBlock _blk ->
              insertBlock trce details
        BlockSophie {} -> epochUpdate details
        BlockAllegra {} -> epochUpdate details
        BlockJen {} -> epochUpdate details
        BlockAurum {} -> epochUpdate details

    -- What we do here is completely independent of Sophie/Evie/Jen eras.
    epochUpdate :: SlotDetails -> ReaderT SqlBackend (LoggingT IO) (Either SyncNodeError ())
    epochUpdate details = do
      when (sdSlotTime details > sdCurrentTime details) $
        liftIO . logError trce $ mconcat
          [ "Slot time '", textShow (sdSlotTime details) ,  "' is in the future" ]
      insertBlock trce details

-- Nothing to be done here.
-- Rollback will take place in the Default plugin and the epoch table will just be recalculated.
epochPluginRollbackBlock :: Trace IO Text -> BccPoint -> IO (Either SyncNodeError ())
epochPluginRollbackBlock _ _ = pure $ Right ()

-- -------------------------------------------------------------------------------------------------

insertBlock
    :: Trace IO Text -> SlotDetails
    -> ReaderT SqlBackend (LoggingT IO) (Either SyncNodeError ())
insertBlock trce details = do
  mLatestCachedEpoch <- liftIO $ readIORef latestCachedEpochVar
  let lastCachedEpoch = fromMaybe 0 mLatestCachedEpoch
      epochNum = unEpochNo (sdEpochNo details)

  -- These cases are listed from the least likey to occur to the most
  -- likley to keep the logic sane.

  if  | epochNum > 0 && isNothing mLatestCachedEpoch ->
          updateEpochNum 0 trce
      | epochNum >= lastCachedEpoch + 2 ->
          updateEpochNum (lastCachedEpoch + 1) trce
      | getSyncStatus details == SyncFollowing ->
          -- Following the chain very closely.
          updateEpochNum epochNum trce
      | otherwise ->
          pure $ Right ()

-- -------------------------------------------------------------------------------------------------

{-# NOINLINE latestCachedEpochVar #-}
latestCachedEpochVar :: IORef (Maybe Word64)
latestCachedEpochVar = unsafePerformIO $ newIORef Nothing -- Gets updated later.

updateEpochNum :: (MonadBaseControl IO m, MonadIO m) => Word64 -> Trace IO Text -> ReaderT SqlBackend m (Either SyncNodeError ())
updateEpochNum epochNum trce = do
    mid <- queryEpochId epochNum
    res <- maybe insertEpoch updateEpoch mid
    liftIO $ atomicWriteIORef latestCachedEpochVar (Just epochNum)
    pure res
  where
    updateEpoch :: MonadIO m => EpochId -> ReaderT SqlBackend m (Either SyncNodeError ())
    updateEpoch epochId = do
      epoch <- DB.queryCalcEpochEntry epochNum
      Right <$> replace epochId epoch

    insertEpoch :: (MonadBaseControl IO m, MonadIO m) => ReaderT SqlBackend m (Either SyncNodeError ())
    insertEpoch = do
      epoch <- DB.queryCalcEpochEntry epochNum
      liftIO . logInfo trce $ "epochPluginInsertBlock: epoch " <> textShow epochNum
      void $ DB.insertEpoch epoch
      pure $ Right ()

-- -------------------------------------------------------------------------------------------------

-- | Get the PostgreSQL row index (EpochId) that matches the given epoch number.
queryEpochId :: MonadIO m => Word64 -> ReaderT SqlBackend m (Maybe EpochId)
queryEpochId epochNum = do
  res <- select . from $ \ epoch -> do
            where_ (epoch ^. DB.EpochNo ==. val epochNum)
            pure (epoch ^. EpochId)
  pure $ unValue <$> listToMaybe res

-- | Get the epoch number of the most recent epoch in the Epoch table.
queryLatestEpochNo :: MonadIO m => ReaderT SqlBackend m (Maybe Word64)
queryLatestEpochNo = do
  res <- select . from $ \ epoch -> do
            orderBy [desc (epoch ^. DB.EpochNo)]
            limit 1
            pure (epoch ^. DB.EpochNo)
  pure $ unValue <$> listToMaybe res
