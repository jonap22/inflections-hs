-- |
-- Module      :  Text.Inflections
-- Description :  Rails-like inflections library for common String transformations.
-- Copyright   :  (c) Justin Leitgeb
-- License     :  MIT
--
-- Maintainer  :  justin@stackbuilders.com
-- Stability   :  unstable
-- Portability :  portable
--
-- This module provides methods for common String transformations, similar
-- to the Inflections library found in Rails:
--
-- <http://api.rubyonrails.org/classes/ActiveSupport/Inflector.html>
--
-- While many of the functions in this library are the same as in
-- implementations in Rails' ActiveSupport, the philosophy of this library
-- is fundamentally different. Where Rails tries to be as permissive as
-- possible, and return a String when given any input, this library tries to
-- output strings that make sense according to the function that is called.
--
-- When you look closely at many of the functions in Rails' inflections
-- library, you will notice that many of them are partial. That is, they
-- only have well-defined output for some of the possible inputs to the
-- function allowed by the type system. As an example, let's take the
-- @underscore@ function. In Rails, it works like this:
--
-- >>> "fooBar".underscore
-- "foo_bar"
--
-- Looks OK so far. However, it's also easy to produce less expected results:
--
-- >>> "foo bar".underscore
-- "foo bar"
--
-- The output isn't underscored - it contains a space! It turns out that
-- some of the functions from Inflections in ActiveSupport are /partial/.
-- I.e., the outputs are really only specified for a certain range of the
-- inputs allowed by the String type.
--
-- In the Haskell inflections library, we aim to deliver more predictable
-- results by separating the parsing of strings into tokens from the
-- application of transformations. Let's see an example.
--
-- First, we tokenize an underscored String using 'parseSnakeCase':
--
-- >>> parseSnakeCase [] "foo_bar"
-- Right [Word "foo",Word "bar"]
--
-- We can chain together the tokenization of the input String and the
-- transformation to CamelCase by using 'Control.Monad.LiftM':
--
-- >>> import Control.Monad (liftM)
-- >>> liftM camelize $ parseSnakeCase "foo_bar"
-- Right "FooBar"
--
-- By separating out the tokenization from the application of inflections,
-- we also end up with useful libraries for validating input which can be
-- used independently:
--
-- >>> parseSnakeCase [] "fooBar"
-- 1:4:
-- unexpected 'B'
-- expecting '_', end of input, or lowercase letter
--
-- As of version 0.3.0.0, we don't permit creation of invalid 'Word's by
-- using of the smart constructors 'mkWord' and 'mkAcronym'. This is done
-- because not every 'Text' value is a valid 'Word', as it should not
-- contain whitespace, for example. Normal words have the type @'Word'
-- 'Normal'@, while acronyms have the type @'Word' 'Acronym'@. If you need
-- to have several words\/acronyms in a single list, use the existential
-- wrapper 'SomeWord'. Parsing functions now produce 'SomeWord's.
--
-- This library is still a work-in-progress, and contributions are welcome
-- for missing pieces and to fix bugs. Please see the Github page to
-- contribute with code or bug reports:
--
-- <https://github.com/stackbuilders/inflections-hs>

{-# LANGUAGE CPP #-}

module Text.Inflections
  ( -- * Parsing
    parseSnakeCase
  , parseCamelCase
    -- * Rendering
  , camelize
  , camelizeCustom
  , dasherize
  , humanize
  , underscore
  , titleize
  , Transliterations
  , defaultTransliterations
  , parameterize
  , parameterizeCustom
  , transliterate
  , transliterateCustom
  , ordinalize
  , ordinal
    -- * Types and helpers
  , Word
  , WordType (..)
  , mkWord
  , mkAcronym
  , unWord
  , SomeWord (..)
  , unSomeWord
  , InflectionException (..)
    -- * Often used combinators
  , toUnderscore
  , toDashed
  , toCamelCased )
where

import Control.Monad (liftM)
import Control.Monad.Catch (MonadThrow (..))
import Data.Text (Text)
import Text.Inflections.Camelize (camelize, camelizeCustom)
import Text.Inflections.Dasherize (dasherize)
import Text.Inflections.Data (Transliterations, defaultTransliterations)
import Text.Inflections.Humanize (humanize)
import Text.Inflections.Ordinal (ordinal, ordinalize)
import Text.Inflections.Parameterize (parameterize, parameterizeCustom)
import Text.Inflections.Parse.CamelCase (parseCamelCase)
import Text.Inflections.Parse.SnakeCase (parseSnakeCase)
import Text.Inflections.Titleize (titleize)
import Text.Inflections.Transliterate (transliterate, transliterateCustom)
import Text.Inflections.Types
import Text.Inflections.Underscore (underscore)
import Text.Megaparsec

#if MIN_VERSION_base(4,8,0)
import Prelude hiding (Word)
#endif

-- | Transforms CamelCasedString to snake_cased_string_with_underscores. In
-- case of failed parsing 'InflectionException' is thrown.
--
-- >>> toUnderscore "FooBarBazz"
-- "foo_bar_bazz"
toUnderscore :: MonadThrow m => Text -> m Text
toUnderscore = liftM underscore . handleEither . parseCamelCase []
{-# INLINE toUnderscore #-}

-- | Transforms CamelCasedString to snake-cased-string-with-dashes. In case
-- of failed parsing 'InflectionException' is thrown.
--
-- >>> toDashed "FooBarBazz"
-- "foo-bar-bazz"
toDashed :: MonadThrow m => Text -> m Text
toDashed = liftM dasherize . handleEither . parseCamelCase []
{-# INLINE toDashed #-}

-- | Transforms underscored_text to CamelCasedText. If first argument is
-- 'True' then FirstCharacter in result string will be in upper case. If
-- 'False' then firstCharacter will be in lower case. In case of failed
-- parsing 'InflectionException' is thrown.
--
-- >>> toCamelCased True "foo_bar_bazz"
-- "FooBarBazz"
-- >>> toCamelCased False "foo_bar_bazz"
-- "fooBarBazz"
toCamelCased :: MonadThrow m
  => Bool              -- ^ Capitalize the first character
  -> Text              -- ^ Input
  -> m Text            -- ^ Ouput
toCamelCased t = liftM (camelizeCustom t) . handleEither . parseSnakeCase []
{-# INLINE toCamelCased #-}

-- | Take an 'Either' that can contain a parser error and throw it if
-- necessary. If everything is OK, just return 'Right' value.
handleEither :: MonadThrow m => Either (ParseError Char Dec) a -> m a
handleEither (Left err) = throwM (InflectionParsingFailed err)
handleEither (Right  x) = return x
{-# INLINE handleEither #-}
