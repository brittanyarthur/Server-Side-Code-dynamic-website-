-- Author: Ian Gudger (igudger@ucsc.edu)
-- CMPS 112 Final Project, Haskell Snap implementation
-- March 21, 2014

{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE DoAndIfThenElse #-}

------------------------------------------------------------------------------
-- | This module is where all the routes and handlers are defined for your
-- site. The 'app' function is the initializer that combines everything
-- together and is exported by this module.
module Site
	( app
	) where

------------------------------------------------------------------------------
import				Control.Applicative
import				Data.ByteString (ByteString)
import qualified	Data.ByteString as B
import qualified	Data.Text as T
import				Data.Maybe
import				Snap.Core
import				Snap.Snaplet
import				Snap.Snaplet.Auth
import				Snap.Snaplet.Auth.Backends.JsonFile
import				Snap.Snaplet.Heist
import				Snap.Snaplet.Session.Backends.CookieSession
import				Snap.Util.FileServe
import				Snap.Snaplet.PostgresqlSimple
import				Heist
import qualified	Data.Text as T
import qualified	Heist.Interpreted as I
import				Snap.Util.Readable
import				Data.ByteString.Char8 as C8 (pack)
import				Data.Char (chr)
import qualified	Control.RMonad as RM
import				Data.Suitable
import				Data.Time.Clock
------------------------------------------------------------------------------
import				Application
import				Control.Applicative
import				Database.PostgreSQL.Simple.FromRow
import				Control.Monad.IO.Class

data FormData = FormData
	{ user_starter_id			:: Int
	, user_entry				:: ByteString
	, user_error_message		:: ByteString
	, user_id_val				:: Int
	}

data FullEntry = FullEntry
	{ starter		:: T.Text
	, entry		:: T.Text
	, user_id		:: Int
	}

instance FromRow StarterOnly where
	fromRow = StarterOnly <$> field <*> field

instance Show StarterOnly where
	show (StarterOnly starterID starterText) =
		"<option value=\"" ++ show starterID ++ "\">" ++ T.unpack starterText ++ "</option>\n"

data StarterOnly = StarterOnly
	{ starterID			:: Int
	, starterText		:: T.Text
	}

instance FromRow FullEntry where
	fromRow = FullEntry <$> field <*> field <*> field

instance Show FullEntry where
	show (FullEntry starter entry _) =
		"<tr><td>" ++ T.unpack starter ++ "</td<td>" ++ T.unpack entry ++ "</td></tr>\n"

data RowInt = RowInt
	{ rowInt	:: Int
	}

instance FromRow RowInt where
	fromRow = RowInt <$> field

------------------------------------------------------------------------------
-- | The application's routes.
routes :: [(ByteString, Handler App App ())]
routes = [ ("/haskell", method GET processNonForm),
	("/haskell", method POST processForm),
	("", serveDirectory "static")
	]

showColor :: Int -> FullEntry -> String
showColor user_id (FullEntry starter entry entry_user_id) =
	"<tr><td class=\"" ++ (if user_id == entry_user_id then "your_entry" else "other_entry") ++ "\">" ++ T.unpack starter ++ "</td<td>" ++ T.unpack (encodeHtml entry) ++ "</td></tr>\n"

showSelected :: Int -> StarterOnly -> String
showSelected selected (StarterOnly starterID starterText) =
	"<option value=\"" ++ show starterID ++ "\"" ++ (if starterID == selected then " selected=\"\"" else "") ++ ">" ++ T.unpack starterText ++ "</option>\n"

-------------------------------------------------
strToBS :: String -> B.ByteString
strToBS = C8.pack

bsToStr :: B.ByteString -> String
bsToStr = map (chr . fromEnum) . B.unpack

-- From http://stackoverflow.com/questions/9838232/haskell-reading-bytestring
-------------------------------------------------

-------------------------------------------------
-- | Escape special HTML characters.
encodeHtml :: T.Text -> T.Text
encodeHtml = T.concatMap (T.pack . encodeHtmlChar)

encodeHtmlChar :: Char -> String
encodeHtmlChar '<' = "&lt;"
encodeHtmlChar '>' = "&gt;"
encodeHtmlChar '&' = "&amp;"
encodeHtmlChar '"' = "&quot;"
encodeHtmlChar '\'' = "&#39;"
encodeHtmlChar c = [c]
-- Adapted from http://hackage.haskell.org/package/web-encodings-0.3.0.2/docs/src/Web-Encodings.html#encodeHtml
-------------------------------------------------

safeMaybeInt :: Maybe Int -> Int
safeMaybeInt maybeNum = case maybeNum of
	Nothing -> 0
	Just num -> num

safeMaybeBool :: Maybe Bool -> Bool
safeMaybeBool maybeVal = case maybeVal of
	Nothing -> False
	Just val -> val

getIDFromCookie :: Maybe Cookie -> Maybe Int
getIDFromCookie maybeCookie = do
	cookie <- maybeCookie
	maybeRead $ bsToStr $ cookieValue cookie

safeGetIDFromCookie :: Maybe Cookie -> Int
safeGetIDFromCookie = safeMaybeInt . getIDFromCookie

-------------------------------------------------
maybeRead :: Read a => String -> Maybe a
maybeRead = fmap fst . listToMaybe . reads
-- From http://hackage.haskell.org/package/cgi-3001.1.8.5/docs/src/Network-CGI-Protocol.html#maybeRead
-------------------------------------------------

------------------------------------------------------------------------------
-- | The application initializer.

app :: SnapletInit App App
app = makeSnaplet "app" "My stunningly advanced Snap application." Nothing $ do
	pg <- nestSnaplet "pg" pg pgsInit
	addRoutes routes
	return $ App pg

processNonForm :: Handler App App ()
processNonForm = do
	cookie <- getCookie "user"
	let userID = safeGetIDFromCookie cookie
	result <- query_ ("select id from starters offset floor(random() * (select count(*) from starters)) limit 1")
	let randomID = rowInt $ head result
	getAllHTML (FormData randomID B.empty B.empty userID)

processForm :: Handler App App ()
processForm = do
	cookie <- getCookie "user"
	let userID = safeGetIDFromCookie cookie
	receivedStarter <- getPostParam "starter"
	receivedEntry <- getPostParam "entry"
	remoteIp <- return . rqRemoteAddr =<< getRequest
	let starter_id = safeMaybeInt $ maybeRead $ bsToStr $ fromJust receivedStarter
	let error_message = if starter_id <= 0 then strToBS "Invalid Starter" else (if B.null (fromJust receivedEntry) then strToBS "Entry cannot be left blank" else B.empty)
	new_user_id <- if B.null error_message then do
		if userID < 1 then do
			result <- query "WITH user_row AS ( INSERT INTO \"users\" (ip_address) VALUES (?) RETURNING id ) INSERT INTO entries (user_id, starter_id, entry) VALUES ((SELECT id FROM user_row), ?, ?) RETURNING (SELECT id FROM user_row)" (remoteIp, receivedStarter, receivedEntry)
			let new_user_id = rowInt $ head result
			--setCookie (newCookie "user" (show new_user_id))
			time <- liftIO getCurrentTime
			let expires = Just $ addUTCTime (60*60*24*365*10) time
			modifyResponse $ addResponseCookie $ Cookie (strToBS "user") (strToBS $ show new_user_id) expires Nothing (Just "/") False True
			--(Cookie (Just "user") (Just (show new_user_id)) Nothing Nothing False False)
			return (new_user_id)
		else do
			_ <- execute "INSERT INTO entries (user_id, starter_id, entry) VALUES (?, ?, ?)" (userID, receivedStarter, receivedEntry)
			--let new_user_id = userID
			return (userID)
	else do
		return (userID)
	let old_entry = if B.null error_message then B.empty else fromJust receivedEntry
	getAllHTML (FormData starter_id old_entry error_message new_user_id)

getAllEntries :: Bool -> Int -> Handler App App ()
getAllEntries showAll userID = do
	allEntries <- if showAll then query_ "SELECT starter, entry, user_id FROM starters, entries WHERE starters.id = entries.starter_id ORDER BY entries.id DESC"
	else query_ "SELECT starter, entry, user_id FROM starters, entries WHERE starters.id = entries.starter_id ORDER BY entries.id DESC LIMIT 10"
	writeText $ T.pack $ ("<table>" ++ concat ( map (showColor userID) (allEntries :: [FullEntry])) ++ "</table>\n")

getForm :: ByteString -> Int -> Handler App App ()
getForm oldEntry oldStarterID = do
	writeBS "<form action=\"haskell\" method=\"POST\">\n"
	starterOnlys <- query_ "SELECT id, starter FROM starters ORDER BY id ASC"
	writeText $ T.pack $ ("<select name=\"starter\">\n" ++ concat ( map (showSelected oldStarterID) (starterOnlys :: [StarterOnly])) ++ "</select>\n")
	writeBS $ B.concat ["<input type=\"text\" value=\"", oldEntry, "\" name=\"entry\"></input>\n"]
	writeBS "<input type=\"submit\" value=\"Submit\"></input>\n"
	writeBS "</form>\n"

getAllHTML :: FormData -> Handler App App ()
getAllHTML form_data = do
	maybeShowAll <- getQueryParam "showall"
	let showAll = case maybeShowAll of
		Nothing -> False
		Just sall -> sall == (strToBS "True")
	writeBS "<!DOCTYPE html>\n"
	writeBS "<html>\n"
	writeBS "<head>\n"
	writeBS "<title>Gratitude Journal</title>\n"
	writeBS "<style type=\"text/css\" media=\"all\">\n"
	writeBS "<!--\n"
	writeBS ".your_entry { background: yellow; }\n"
	writeBS ".other_entry { background: #00FFFF; }\n"
	writeBS "body { font-family: Helvetica, Arial, Sans-Serif; }\n"
	writeBS "-->\n"
	writeBS "</style>\n"
	writeBS "</head>\n"
	writeBS "<body>\n"
	writeBS "<h1>Gratitude Journal</h1>\n"
	getForm (user_entry form_data) (user_starter_id form_data)
	writeBS $ user_error_message form_data
	writeBS "<br />\n"
	getAllEntries showAll (user_id_val form_data)
	writeBS "<form action=\"haskell\" method=\"GET\">\n"
	writeBS "<input type=\"hidden\" value=\""
	writeBS $ strToBS $ show $ not showAll
	writeBS "\" name=\"showall\"></input>\n"
	writeBS "<input type=\"submit\" value=\"Show "
	writeBS (if showAll then "Fewer" else "All")
	writeBS "\"></input>\n"
	writeBS "</form>\n"
	writeBS "<p>This web page was served with Haskell Snap!<p>\n"
	writeBS "</body>\n"
	writeBS "</html>\n"

