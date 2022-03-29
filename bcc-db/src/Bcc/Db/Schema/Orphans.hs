{-# LANGUAGE OverloadedStrings #-}

{-# OPTIONS_GHC -Wno-orphans #-}

module Bcc.Db.Schema.Orphans where

import           Bcc.Db.Types (DbInt65 (..), DbEntropic (..), DbWord64 (..), ScriptPurpose,
                   ScriptType (..), SyncState, readDbInt65, readScriptPurpose, readScriptType,
                   readSyncState, renderScriptPurpose, renderScriptType, renderSyncState,
                   showDbInt65)

import qualified Data.ByteString.Char8 as BS
import           Data.Ratio (denominator, numerator)
import qualified Data.Text as Text
import           Data.WideWord.Word128 (Word128)

import           Database.Persist.Class (PersistField (..))
import           Database.Persist.Types (PersistValue (..))

instance PersistField DbInt65 where
  toPersistValue = PersistText . Text.pack . showDbInt65
  fromPersistValue (PersistInt64 i) = Right $ if i >= 0
                                                then PosInt65 (fromIntegral i)
                                                else NegInt65 (fromIntegral $ negate i)
  fromPersistValue (PersistText bs) = Right $ readDbInt65 (Text.unpack bs)
  fromPersistValue x@(PersistRational r) =
    if denominator r == 1
      then Right $ if numerator r >= 0
                    then PosInt65 (fromIntegral $ numerator r)
                    else NegInt65 (fromIntegral . numerator $ negate r)
      else Left $ mconcat [ "Failed to parse Haskell type DbInt65: ", Text.pack (show x) ]
  fromPersistValue x =
    Left $ mconcat [ "Failed to parse Haskell type DbInt65: ", Text.pack (show x) ]

instance PersistField DbEntropic where
  toPersistValue = PersistText . Text.pack . show . unDbEntropic
  fromPersistValue (PersistInt64 i) = Right $ DbEntropic (fromIntegral i)
  fromPersistValue (PersistText bs) = Right $ DbEntropic (read $ Text.unpack bs)
  fromPersistValue x@(PersistRational r) =
    -- If the value is greater than MAX_INT64, it comes back as a PersistRational (wat??).
    if denominator r == 1
      then Right $ DbEntropic (fromIntegral $ numerator r)
      else Left $ mconcat [ "Failed to parse Haskell type DbEntropic: ", Text.pack (show x) ]
  fromPersistValue x =
    Left $ mconcat [ "Failed to parse Haskell type DbEntropic: ", Text.pack (show x) ]

instance PersistField DbWord64 where
  toPersistValue = PersistText . Text.pack . show . unDbWord64
  fromPersistValue (PersistInt64 i) = Right $ DbWord64 (fromIntegral i)
  fromPersistValue (PersistText bs) = Right $ DbWord64 (read $ Text.unpack bs)
  fromPersistValue x@(PersistRational r) =
    -- If the value is greater than MAX_INT64, it comes back as a PersistRational (wat??).
    if denominator r == 1
      then Right $ DbWord64 (fromIntegral $ numerator r)
      else Left $ mconcat [ "Failed to parse Haskell type DbWord64: ", Text.pack (show x) ]
  fromPersistValue x =
    Left $ mconcat [ "Failed to parse Haskell type DbWord64: ", Text.pack (show x) ]

instance PersistField SyncState where
  toPersistValue = PersistText . renderSyncState
  fromPersistValue (PersistLiteral bs) = Right $ readSyncState (BS.unpack bs)
  fromPersistValue x =
    Left $ mconcat [ "Failed to parse Haskell type SyncState: ", Text.pack (show x) ]

instance PersistField ScriptPurpose where
  toPersistValue = PersistText . renderScriptPurpose
  fromPersistValue (PersistLiteral bs) = Right $ readScriptPurpose (BS.unpack bs)
  fromPersistValue x =
    Left $ mconcat [ "Failed to parse Haskell type ScriptPurpose: ", Text.pack (show x) ]

instance PersistField ScriptType where
  toPersistValue = PersistText . renderScriptType
  fromPersistValue (PersistLiteral bs) = Right $ readScriptType (BS.unpack bs)
  fromPersistValue x =
    Left $ mconcat [ "Failed to parse Haskell type ScriptType: ", Text.pack (show x) ]

instance PersistField Word128 where
  toPersistValue = PersistText . Text.pack . show
  fromPersistValue (PersistText bs) = Right $ read (Text.unpack bs)
  fromPersistValue x@(PersistRational r) =
    if denominator r == 1
      then Right $ fromIntegral (numerator r)
      else Left $ mconcat [ "Failed to parse Haskell type Word128: ", Text.pack (show x) ]
  fromPersistValue x =
    Left $ mconcat [ "Failed to parse Haskell type Word128: ", Text.pack (show x) ]
