{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Bcc.Sync.Config
  ( ConfigFile (..)
  , GenesisConfig (..)
  , GenesisFile (..)
  , LedgerStateDir (..)
  , NetworkName (..)
  , SophieConfig (..)
  , SocketPath (..)
  , SyncCommand (..)
  , SyncProtocol (..)
  , SyncNodeConfig (..)
  , SyncNodeParams (..)
  , bccLedgerConfig
  , genesisProtocolMagicId
  , readBccGenesisConfig
  , readSyncNodeConfig
  , configureLogging
  ) where

import           Bcc.Prelude

import qualified Bcc.BM.Setup as Logging
import           Bcc.BM.Trace (Trace)
import qualified Bcc.BM.Trace as Logging

import qualified Bcc.BM.Configuration.Model as Logging

import           Bcc.Sync.Config.Bcc
import           Bcc.Sync.Config.Node
import           Bcc.Sync.Config.Sophie
import           Bcc.Sync.Config.Types
import           Bcc.Sync.Util

import qualified Data.ByteString.Char8 as BS
import qualified Data.Text as Text
import qualified Data.Yaml as Yaml

import           System.FilePath (takeDirectory, (</>))

configureLogging :: SyncNodeParams -> Text -> IO (Trace IO Text)
configureLogging params loggingName = do
    let configFile = enpConfigFile params
    enc <- readSyncNodeConfig configFile

    if not (dncEnableLogging enc)
       then pure Logging.nullTracer
       else liftIO $ Logging.setupTrace (Right $ dncLoggingConfig enc) loggingName

readSyncNodeConfig :: ConfigFile -> IO SyncNodeConfig
readSyncNodeConfig (ConfigFile fp) = do
    pcfg <- adjustNodeFilePath . parseSyncPreConfig <$> readByteString fp "DbSync"
    ncfg <- parseNodeConfig <$> readByteString (pcNodeConfigFilePath pcfg) "node"
    coalesceConfig pcfg ncfg (mkAdjustPath pcfg)
  where
    parseSyncPreConfig :: ByteString -> SyncPreConfig
    parseSyncPreConfig bs =
      case Yaml.decodeEither' bs of
      Left err -> panic $ "readSyncNodeConfig: Error parsing config: " <> textShow err
      Right res -> res

    adjustNodeFilePath :: SyncPreConfig -> SyncPreConfig
    adjustNodeFilePath cfg =
      cfg { pcNodeConfigFile = adjustNodeConfigFilePath (takeDirectory fp </>) (pcNodeConfigFile cfg) }

coalesceConfig
    :: SyncPreConfig -> NodeConfig -> (FilePath -> FilePath)
    -> IO SyncNodeConfig
coalesceConfig pcfg ncfg adjustGenesisPath = do
  lc <- Logging.setupFromRepresentation $ pcLoggingConfig pcfg
  pure $ SyncNodeConfig
          { dncNetworkName = pcNetworkName pcfg
          , dncLoggingConfig = lc
          , dncNodeConfigFile = pcNodeConfigFile pcfg
          , dncProtocol = ncProtocol ncfg
          , dncRequiresNetworkMagic = ncRequiresNetworkMagic ncfg
          , dncEnableLogging = pcEnableLogging pcfg
          , dncEnableMetrics = pcEnableMetrics pcfg
          , dncPrometheusPort = pcPrometheusPort pcfg
          , dncPBftSignatureThreshold = ncPBftSignatureThreshold ncfg
          , dncColeGenesisFile = adjustGenesisFilePath adjustGenesisPath (ncColeGenesisFile ncfg)
          , dncColeGenesisHash = ncColeGenesisHash ncfg
          , dncSophieGenesisFile = adjustGenesisFilePath adjustGenesisPath (ncSophieGenesisFile ncfg)
          , dncSophieGenesisHash = ncSophieGenesisHash ncfg
          , dncAurumGenesisFile = adjustGenesisFilePath adjustGenesisPath (ncAurumGenesisFile ncfg)
          , dncAurumGenesisHash = ncAurumGenesisHash ncfg
          , dncColeSoftwareVersion = ncColeSotfwareVersion ncfg
          , dncColeProtocolVersion = ncColeProtocolVersion ncfg

          , dncSophieHardFork = ncSophieHardFork ncfg
          , dncAllegraHardFork = ncAllegraHardFork ncfg
          , dncJenHardFork = ncJenHardFork ncfg
          , dncAurumHardFork = ncAurumHardFork ncfg
          }

mkAdjustPath :: SyncPreConfig -> (FilePath -> FilePath)
mkAdjustPath cfg fp = takeDirectory (pcNodeConfigFilePath cfg) </> fp

readByteString :: FilePath -> Text -> IO ByteString
readByteString fp cfgType =
  catch (BS.readFile fp) $ \(_ :: IOException) ->
    panic $ mconcat [ "Cannot find the ", cfgType, " configuration file at : ", Text.pack fp ]
