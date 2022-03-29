{-# LANGUAGE OverloadedStrings #-}

import           Prelude

import           Control.Monad (when)

import           Data.Maybe (isNothing)

import           Test.Tasty (defaultMain, testGroup)

import qualified Test.IO.Bcc.Db.Insert
import qualified Test.IO.Bcc.Db.Migration
import qualified Test.IO.Bcc.Db.Rollback
import qualified Test.IO.Bcc.Db.TotalSupply

import           System.Directory (getCurrentDirectory)
import           System.Environment (lookupEnv, setEnv)
import           System.FilePath ((</>))

main :: IO ()
main = do
  -- If the env is not set, set it to default.
  mPgPassFile <- lookupEnv "PGPASSFILE"
  when (isNothing mPgPassFile) $ do
    currentDir <- getCurrentDirectory
    setEnv "PGPASSFILE" (currentDir </> "../config/pgpass-mainnet")

  defaultMain $
    testGroup "Database"
      [ Test.IO.Bcc.Db.Migration.tests
      , Test.IO.Bcc.Db.Insert.tests
      , Test.IO.Bcc.Db.TotalSupply.tests
      , Test.IO.Bcc.Db.Rollback.tests
      ]

