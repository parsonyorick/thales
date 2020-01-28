{-# LANGUAGE StrictData #-}
module Syntax where

import Data.Functor.Classes
import Data.Functor.Foldable
import Data.Scientific
import Text.Show

import Value

data Syntax
  = VerbatimS Verbatim
  | StatementS Statement
  deriving Show

data PartialStatement
  = BlockS ([Syntax] -> Statement)
  | StandaloneS Statement

data Statement
  = EmptyS
  | ExprS Expr
  | ForS Name Expr [Syntax]
  | Optional Expr
  | Optionally Expr [Syntax]
  deriving Show

data ExprF a
  = LiteralE Literal
  | ArrayE [a]
  | ApplyE a a
  | FieldAccessE Name a
  | NameE Name

instance Show1 ExprF where
  liftShowsPrec showsPrecA showsListA prec = \case
    LiteralE l ->
      showsPrec prec l
    ArrayE a ->
      showsListA a
    ApplyE f z ->
      ('(' :)
      . showsPrecA prec f
      . (' ' :)
      . showsPrecA prec z
      . (')' :)
    FieldAccessE n a ->
      ('(' :)
      . showsPrecA prec a
      . (')' :)
      . ('.' :)
      . showsPrec prec n
    NameE n ->
      showsPrec prec n

instance Show a => Show (ExprF a) where
  showsPrec prec = showsPrec1 prec

type Expr = Fix ExprF

data Literal
  = NumberL Scientific
  | StringL Text
  | BooleanL Bool
  deriving Show

literalToValue :: Literal -> Value f
literalToValue = \case
  NumberL  n -> Number n
  StringL  s -> String s
  BooleanL b -> Boolean b
