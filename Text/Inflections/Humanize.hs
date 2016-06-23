-- |
-- Module      :  Text.Inflections.Humanize
-- Copyright   :  © 2016 Justin Leitgeb
-- License     :  MIT
--
-- Maintainer  :  Justin Leitgeb <justin@stackbuilders.com>
-- Stability   :  experimental
-- Portability :  portable
--
-- Conversion to “humanized” phrases.

module Text.Inflections.Humanize (humanize) where

import Text.Inflections.Parse.Types (Word(..))

import Data.Char (toUpper)

import Prelude (String, Bool(..), (.), map, zip, ($), unwords, repeat)

-- |Capitalizes the first word and turns underscores into spaces. Like titleize,
-- this is meant for creating pretty output.
--
-- >>> humanize [ Word "foo", Acronym "bar", Word "bazz" ]
-- "Foo bar bazz"
humanize
  :: [Word] -- ^ List of Words, first of which will be capitalized
  -> String -- ^ The humanized output
humanize = unwords . map caseForWord . isFirstList

-- |Returns list with Bool indicating if an element is first.
isFirstList :: [a] -> [(a, Bool)]
isFirstList xs = zip xs $ True : repeat False

-- | Convert given 'Word' to capitalized 'String' when associated Boolean
-- value is 'True'.
caseForWord :: (Word, Bool) -> String
caseForWord (Word (c:cs), True)  = toUpper c : cs
caseForWord (Word s, False)      = s
caseForWord (Word [], _)         = []
caseForWord (Acronym s, _)       = s  -- Acronyms are left intact
