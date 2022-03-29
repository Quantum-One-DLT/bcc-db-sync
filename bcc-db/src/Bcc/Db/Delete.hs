module Bcc.Db.Delete
  ( deleteCascadeBlock
  , deleteCascadeAfter
  , deleteCascadeBlockNo
  , deleteCascadeSlotNo
  ) where

import           Bcc.Slotting.Slot (SlotNo (..))

import           Control.Monad.IO.Class (MonadIO)
import           Control.Monad.Trans.Reader (ReaderT)

import           Database.Persist.Sql (SqlBackend, delete, selectKeysList, (==.))

import           Bcc.Db.Schema

import           Shardagnostic.Network.Block (BlockNo (..))


-- | Delete a block if it exists. Returns 'True' if it did exist and has been
-- deleted and 'False' if it did not exist.
deleteCascadeBlock :: MonadIO m => Block -> ReaderT SqlBackend m Bool
deleteCascadeBlock block = do
  keys <- selectKeysList [ BlockHash ==. blockHash block ] []
  mapM_ delete keys
  pure $ not (null keys)

-- | Delete a block after the specified 'BlockId'. Returns 'True' if it did exist and has been
-- deleted and 'False' if it did not exist.
deleteCascadeAfter :: MonadIO m => BlockId -> ReaderT SqlBackend m Bool
deleteCascadeAfter bid = do
  keys <- selectKeysList [ BlockPreviousId ==. Just bid ] []
  mapM_ delete keys
  pure $ not (null keys)

-- | Delete a block if it exists. Returns 'True' if it did exist and has been
-- deleted and 'False' if it did not exist.
deleteCascadeBlockNo :: MonadIO m => BlockNo -> ReaderT SqlBackend m Bool
deleteCascadeBlockNo (BlockNo blockNo) = do
  keys <- selectKeysList [ BlockBlockNo ==. Just blockNo ] []
  mapM_ delete keys
  pure $ not (null keys)

-- | Delete a block if it exists. Returns 'True' if it did exist and has been
-- deleted and 'False' if it did not exist.
deleteCascadeSlotNo :: MonadIO m => SlotNo -> ReaderT SqlBackend m Bool
deleteCascadeSlotNo (SlotNo slotNo) = do
  keys <- selectKeysList [ BlockSlotNo ==. Just slotNo ] []
  mapM_ delete keys
  pure $ not (null keys)

