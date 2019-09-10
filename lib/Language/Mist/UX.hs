-- | This module contains the code for all the user (programmer) facing
--   aspects, i.e. error messages, source-positions, overall results.

{-# LANGUAGE TypeSynonymInstances #-}
{-# LANGUAGE FlexibleInstances    #-}
{-# LANGUAGE DeriveFunctor        #-}
{-# LANGUAGE DeriveAnyClass       #-}
{-# LANGUAGE DeriveGeneric        #-}

module Language.Mist.UX
  (
  -- * Representation
    SourceSpan (..)
  , Located (..)
  , Locate (..)

  -- * Extraction from Source file
  , readFileSpan

  -- * Constructing spans
  , posSpan, junkSpan

  -- * Success and Failure
  , UserError
  , eMsg
  , eSpan
  , Result

  -- * Throwing & Handling Errors
  , mkError
  , abort
  , panic
  , renderErrors
  , renderFixResult

  -- * Pretty Printing
  , Text
  , PPrint (..)
  , pprintMany

  ) where

import           Control.Exception
import           Data.Typeable
import qualified Data.List as L
import           Text.Megaparsec
import           Text.Printf (printf)
import           Language.Mist.Utils
import qualified Language.Fixpoint.Types as F
import qualified Language.Fixpoint.Horn.Types as HC
import           Text.PrettyPrint.HughesPJ
import           Control.DeepSeq
import           GHC.Generics


type Text = String

class PPrint a where
  pprint :: a -> Text

--------------------------------------------------------------------------------
-- | Accessing SourceSpan
--------------------------------------------------------------------------------
class Located a where
  sourceSpan :: a -> SourceSpan

instance Located SourceSpan where
  sourceSpan x = x

data Locate a = Locate a SourceSpan
  deriving (Eq, Show, Read, Functor)

instance Located (Locate a) where
  sourceSpan (Locate _ s) = s

instance (Located a) => Located (HC.Cstr a) where
  sourceSpan = sourceSpan . HC.cLabel

--------------------------------------------------------------------------------
-- | Source Span Representation
--------------------------------------------------------------------------------
data SourceSpan = SS
  { ssBegin :: !SourcePos
  , ssEnd   :: !SourcePos
  }
  deriving (Eq, Show, Read, Generic, NFData)

instance Semigroup SourceSpan where
  s1 <> s2 = mappendSpan s1 s2

instance Monoid SourceSpan where
  mempty  = junkSpan
  -- mappend x y = x <> y

mappendSpan :: SourceSpan -> SourceSpan -> SourceSpan
mappendSpan s1 s2
  | s1 == junkSpan = s2
  | s2 == junkSpan = s1
  | otherwise      = SS (ssBegin s1) (ssEnd s2)

instance F.Loc SourceSpan where
instance F.Fixpoint SourceSpan where

instance F.PPrint SourceSpan where
  pprintTidy _ = text . pprint

instance PPrint SourceSpan where
  pprint = ppSourceSpan

ppSourceSpan :: SourceSpan -> String
ppSourceSpan s
  | l1 == l2  = printf "%s:%d:%d-%d"        f l1 c1 c2
  | otherwise = printf "%s:(%d:%d)-(%d:%d)" f l1 c1 l2 c2
  where
    (f, l1, c1, l2, c2) = spanInfo s

spanInfo :: SourceSpan -> (FilePath, Int, Int, Int, Int)
spanInfo s = (f s, l1 s, c1 s, l2 s, c2 s)
  where
    f      = spanFile
    l1     = unPos . sourceLine   . ssBegin
    c1     = unPos . sourceColumn . ssBegin
    l2     = unPos . sourceLine   . ssEnd
    c2     = unPos . sourceColumn . ssEnd

--------------------------------------------------------------------------------
-- | Source Span Extraction
--------------------------------------------------------------------------------
readFileSpan :: SourceSpan -> IO String
--------------------------------------------------------------------------------
readFileSpan sp = getSpan sp <$> readFile (spanFile sp)


spanFile :: SourceSpan -> FilePath
spanFile = sourceName . ssBegin

getSpan :: SourceSpan -> String -> String
getSpan sp
  | sameLine    = getSpanSingle l1 c1 c2
  | sameLineEnd = getSpanSingleEnd l1 c1
  | otherwise   = getSpanMulti  l1 l2
  where
    sameLine            = l1 == l2
    sameLineEnd         = l1 + 1 == l2 && c2 == 1
    (_, l1, c1, l2, c2) = spanInfo sp


getSpanSingleEnd :: Int -> Int -> String -> String
getSpanSingleEnd l c1
  = highlightEnd l c1
  . safeHead ""
  . getRange l l
  . lines

getSpanSingle :: Int -> Int -> Int -> String -> String
getSpanSingle l c1 c2
  = highlight l c1 c2
  . safeHead ""
  . getRange l l
  . lines

getSpanMulti :: Int -> Int -> String -> String
getSpanMulti l1 l2
  = highlights l1
  . getRange l1 l2
  . lines

highlight :: Int -> Int -> Int -> String -> String
highlight l c1 c2 s = unlines
  [ cursorLine l s
  , replicate (12 + c1) ' ' ++ replicate (1 + c2 - c1) '^'
  ]

highlightEnd :: Int -> Int -> String -> String
highlightEnd l c1 s = highlight l c1 (1 + length s') s'
  where
    s'              = trimEnd s

highlights :: Int -> [String] -> String
highlights i ls = unlines $ zipWith cursorLine [i..] ls

cursorLine :: Int -> String -> String
cursorLine l s = printf "%s|  %s" (lineString l) s

lineString :: Int -> String
lineString n = replicate (10 - nD) ' ' ++ nS
  where
    nS       = show n
    nD       = length nS

--------------------------------------------------------------------------------
-- | Source Span Construction
--------------------------------------------------------------------------------
posSpan :: SourcePos -> SourceSpan
--------------------------------------------------------------------------------
posSpan p = SS p p

junkSpan :: SourceSpan
junkSpan = posSpan (initialPos "unknown")

--------------------------------------------------------------------------------
-- | Representing overall failure / success
--------------------------------------------------------------------------------
type Result a = Either [UserError] a

--------------------------------------------------------------------------------
-- | Representing (unrecoverable) failures
--------------------------------------------------------------------------------
data UserError = Error
  { eMsg  :: !Text
  , eSpan :: !SourceSpan
  }
  deriving (Show, Typeable)

instance Located UserError where
  sourceSpan = eSpan

instance Exception UserError

instance Exception [UserError]

--------------------------------------------------------------------------------
panic :: String -> SourceSpan -> a
--------------------------------------------------------------------------------
panic msg sp = abort (Error msg sp)

--------------------------------------------------------------------------------
abort :: UserError -> b
--------------------------------------------------------------------------------
abort e = throw [e]

--------------------------------------------------------------------------------
mkError :: Text -> SourceSpan -> UserError
--------------------------------------------------------------------------------
mkError = Error

--------------------------------------------------------------------------------
renderErrors :: [UserError] -> IO Text
--------------------------------------------------------------------------------
renderErrors es = do
  errs  <- mapM renderError es
  return $ L.intercalate "\n" ("Errors found!" : errs)

renderError :: UserError -> IO Text
renderError e = do
  let sp   = sourceSpan e
  snippet <- readFileSpan sp
  return   $ printf "%s: %s\n\n%s" (pprint sp) (eMsg e) snippet


pprintMany :: (PPrint a) => [a] -> Text
pprintMany xs = L.intercalate ", " (map pprint xs)


renderFixResult :: (Show a) => F.FixResult a -> Text
renderFixResult (F.Crash _ str) = str
renderFixResult F.Safe = "Safe"
renderFixResult (F.Unsafe as) = "Unsafe: " ++ show as
