-- Author: Ian Gudger (igudger@ucsc.edu)
-- CMPS 112 Final Project, Haskell Snap implementation
-- March 21, 2014

{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE FlexibleInstances #-}

------------------------------------------------------------------------------
-- | This module defines our application's state type and an alias for its
-- handler monad.
module Application where

------------------------------------------------------------------------------
import Control.Lens
import Snap (get)
import Snap.Snaplet
import Snap.Snaplet.Heist
import Snap.Snaplet.Auth
import Snap.Snaplet.Session
import Snap.Snaplet.PostgresqlSimple
------------------------------------------------------------------------------
data App = App
    { _pg :: Snaplet Postgres }

makeLenses ''App

--instance HasHeist App where
--    heistLens = subSnaplet heist

instance HasPostgres (Handler b App) where
    getPostgresState = with pg get

