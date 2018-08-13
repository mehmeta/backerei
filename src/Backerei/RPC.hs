module Backerei.RPC where

import qualified Data.Aeson         as A
import           Data.Default.Class
import qualified Data.Text          as T
import qualified Data.Time.Clock    as C
import           Foundation
import qualified Network.HTTP.Req   as R
import qualified Prelude            as P

import           Backerei.Types

data Config = Config {
  configHost :: T.Text,
  configPort :: Int
}

defaultConfig :: Config
defaultConfig = Config "127.0.0.1" 8732

currentLevel :: Config -> T.Text -> IO CurrentLevel
currentLevel config hash = get config ["chains", "main", "blocks", hash, "helpers", "current_level"] mempty

header :: Config -> T.Text -> IO BlockHeader
header config hash = get config ["chains", "main", "blocks", hash, "header"] mempty

metadata :: Config -> T.Text -> IO BlockMetadata
metadata config hash = get config ["chains", "main", "blocks", hash, "metadata"] mempty

operations :: Config -> T.Text -> IO [Operation]
operations config hash = P.head `fmap` get config ["chains", "main", "blocks", hash, "operations"] mempty

cycleInfo :: Config -> T.Text -> Int -> IO CycleInfo
cycleInfo config hash cycle = get config ["chains", "main", "blocks", hash, "context", "raw", "json", "cycle", T.pack (P.show cycle)] mempty

delegatedContracts :: Config -> T.Text -> T.Text -> IO [T.Text]
delegatedContracts config hash delegate = get config ["chains", "main", "blocks", hash, "context", "delegates", delegate, "delegated_contracts"] mempty

delegatedBalance :: Config -> T.Text -> T.Text -> IO Tezzies
delegatedBalance config hash delegate = get config ["chains", "main", "blocks", hash, "context", "delegates", delegate, "delegated_balance"] mempty

frozenBalance :: Config -> T.Text -> T.Text -> IO Tezzies
frozenBalance config hash delegate = get config ["chains", "main", "blocks", hash, "context", "delegates", delegate, "frozen_balance"] mempty

stakingBalance :: Config -> T.Text -> T.Text -> IO Tezzies
stakingBalance config hash delegate = get config ["chains", "main", "blocks", hash, "context", "delegates", delegate, "staking_balance"] mempty

balanceAt :: Config -> T.Text -> T.Text -> IO Tezzies
balanceAt config hash contract = get config ["chains", "main", "blocks", hash, "context", "contracts", contract, "balance"] mempty

bakingRightsFor :: Config -> T.Text -> T.Text -> Int -> IO [BakingRight]
bakingRightsFor config hash delegate cycle = get config ["chains", "main", "blocks", hash, "helpers", "baking_rights"]
  ("delegate" R.=: delegate <> "cycle" R.=: cycle)

endorsingRightsFor :: Config -> T.Text -> T.Text -> Int -> IO [EndorsingRight]
endorsingRightsFor config hash delegate cycle = get config ["chains", "main", "blocks", hash, "helpers", "endorsing_rights"]
  ("delegate" R.=: delegate <> "cycle" R.=: cycle)

block :: Config -> T.Text -> IO A.Value
block config hash = get config ["chains", "main", "blocks", hash] mempty

blocks :: Config -> IO [[T.Text]]
blocks config = get config ["chains", "main", "blocks"] mempty

protocols :: Config -> IO [T.Text]
protocols config = get config ["protocols"] mempty

get :: (A.FromJSON a) => Config -> [T.Text] -> R.Option 'R.Http -> IO a
get config path options = R.runReq def $ do
  r <- R.req R.GET
    (foldl' ((R./:)) (R.http (configHost config)) path)
    R.NoReqBody
    R.jsonResponse
    (R.port (configPort config) <> R.responseTimeout 600000000 <> options)
  return (R.responseBody r)