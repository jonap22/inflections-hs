{-# LANGUAGE FlexibleContexts, NoMonomorphismRestriction #-}

module Text.Inflections.Parse.SnakeCase ( parseSnakeCase )
where

import Control.Applicative ((<$>))
import Text.Parsec

import Text.Inflections.Parse.Types (Word(..))
import Text.Inflections.Parse.Acronym (acronym)

import Prelude (Char, String, Either, return)

-- |Parses a snake_case string.
--
-- >>> parseSnakeCase ["bar"] "foo_bar_bazz"
-- Right [Word "foo",Acronym "bar",Word "bazz"]
-- >>> parseSnakeCase [] "fooBarBazz"
-- Left "(unknown)" (line 1, column 4):
-- unexpected 'B'
parseSnakeCase :: [String] -> String -> Either ParseError [Word]
parseSnakeCase acronyms = parse (parser acronyms) "(unknown)"


parser :: Stream s m Char => [String] -> ParsecT s u m [Word]
parser acronyms = do
  ws <- (acronym acronyms <|> word) `sepBy` char '_'
  eof
  return ws

word :: Stream s m Char => ParsecT s u m Word
word = Word <$> (many1 lower <|> many1 digit)
