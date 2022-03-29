{-# LANGUAGE OverloadedStrings #-}
module Test.IO.Bcc.Db.Migration where

import           Bcc.Db (LogFileDir (..), MigrationDir (..), MigrationValidate (..),
                   MigrationValidateError (..), MigrationVersion (..), SchemaVersion (..),
                   getMigrationScripts, querySchemaVersion, readPGPassFileEnv, runDbNoLogging,
                   runMigrations, validateMigrations)
import           Control.Monad (unless)
import           Control.Monad.Trans.Except (runExceptT)

import qualified Data.List as List
import           Data.Maybe (fromMaybe)
import           Data.Text (Text)

import           Test.Tasty (TestTree, testGroup)
import           Test.Tasty.HUnit (testCase)


tests :: TestTree
tests =
  testGroup "Migration"
    [ testCase "Migration is idempotent" migrationTest
    , testCase "Migration validation - unknown migration found" unknownMigrationValidate
    , testCase "Migration validation - mismatched hash for migration" invalidHashMigrationValidate
    , testCase "Migration validation - mismatched hash for migration 2" invalidHashMigrationValidate'
    ]

unknownMigrationValidate :: IO ()
unknownMigrationValidate = do
  result <- runExceptT $ validateMigrations testSchemaDir knownTestMigrations
  unless (result == expected) $
    error $ mconcat
            [ "Schema version mismatch. Expected "
            , show expected
            , " but got "
            , show result
            , "."
            ]
  where
    expected :: Either MigrationValidateError ()
    expected =
      Left $ UnknownMigrationsFound
                { missingMigrations =
                    [ MigrationValidate
                      { mvHash = "hash"
                      , mvFilepath = "migration-1-0000-20190730.sql"
                      }
                    ]
                , extraMigrations =
                    [ MigrationValidate
                      { mvHash = "395187b4157ef5307b7d95e0150542e09bb19679055eee8017a34bcca89a691d"
                      , mvFilepath = "migration-1-0000-20190730.sql"
                      }
                    ]
                }


invalidHashMigrationValidate :: IO ()
invalidHashMigrationValidate = do
  result <- runExceptT $ validateMigrations testSchemaDir knownTestMigrations
  unless (result == expected) $
    error $ mconcat
            [ "Schema version mismatch. Expected "
            , show expected
            , " but got "
            , show result
            , "."
            ]
  where
    expected  :: Either MigrationValidateError ()
    expected =
      Left $ UnknownMigrationsFound
                { missingMigrations =
                    [ MigrationValidate
                      { mvHash = "hash"
                      , mvFilepath = "migration-1-0000-20190730.sql"
                      }
                    ]
                , extraMigrations =
                    [ MigrationValidate
                      { mvHash = "395187b4157ef5307b7d95e0150542e09bb19679055eee8017a34bcca89a691d"
                      , mvFilepath = "migration-1-0000-20190730.sql"
                      }
                    ]
                }

invalidHashMigrationValidate' :: IO ()
invalidHashMigrationValidate' = do
  let emptyMigrations = []                   -- No known migrations from compiling
  result <- runExceptT $ validateMigrations testSchemaDir emptyMigrations
  unless (result == expected) $
    error $ mconcat
            [ "Schema version mismatch. Expected "
            , show expected
            , " but got "
            , show result
            , "."
            ]
  where
    expected  :: Either MigrationValidateError ()
    expected =
      Left $ UnknownMigrationsFound
                { missingMigrations = []
                , extraMigrations =
                    [ MigrationValidate
                      { mvHash = "395187b4157ef5307b7d95e0150542e09bb19679055eee8017a34bcca89a691d"
                      , mvFilepath = "migration-1-0000-20190730.sql"
                      }
                    ]
                }

-- Really just make sure that the migrations do actually run correctly.
-- If they fail the file path of the log file (in /tmp) will be printed.
migrationTest :: IO ()
migrationTest = do
  let schemaDir = MigrationDir "../schema"
  pgConfig <- readPGPassFileEnv Nothing
  runMigrations pgConfig True schemaDir (Just $ LogFileDir "/tmp")
  expected <- readSchemaVersion schemaDir
  actual <- getDbSchemaVersion
  unless (expected == actual) $
    error $ mconcat
            [ "Schema version mismatch. Expected "
            , showSchemaVersion expected
            , " but got "
            , showSchemaVersion actual
            , "."
            ]

getDbSchemaVersion :: IO SchemaVersion
getDbSchemaVersion =
  runDbNoLogging $
    fromMaybe (error "getDbSchemaVersion: Nothing") <$> querySchemaVersion

readSchemaVersion :: MigrationDir -> IO SchemaVersion
readSchemaVersion migrationDir = do
    xs <- filter ignoreVersion . fmap fst <$> getMigrationScripts migrationDir
    pure $ List.foldl' func (SchemaVersion 0 0 0) xs
  where
    func :: SchemaVersion -> MigrationVersion -> SchemaVersion
    func (SchemaVersion a b c) mv =
      case mvStage mv of
        1 -> SchemaVersion (max (mvVersion mv) a) b c
        2 -> SchemaVersion a (max (mvVersion mv) b) c
        3 -> SchemaVersion a b (max (mvVersion mv) c)
        _otherwise -> SchemaVersion a b c

    -- Ignore all migrations with version numbers of 9000 or above.
    ignoreVersion :: MigrationVersion -> Bool
    ignoreVersion mv = mvVersion mv < 9000

showSchemaVersion :: SchemaVersion -> String
showSchemaVersion (SchemaVersion a b c) =
  List.intercalate "." [show a, show b, show c]

testSchemaDir :: MigrationDir
testSchemaDir = MigrationDir "test/schema" -- Migration directory with single migration

knownTestMigrations :: [(Text, Text)]
knownTestMigrations = [("hash", "migration-1-0000-20190730.sql")]
