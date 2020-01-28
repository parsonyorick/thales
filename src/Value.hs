{-# LANGUAGE StrictData #-}
module Value where

import qualified Data.HashMap.Strict as Map
import Data.Scientific
import Data.Text.Lazy.Builder as Text
import Data.Vector as Vec
import Text.Show

type Name = Text

data Value f where
  Number :: Scientific -> Value f
  String :: Text -> Value f
  Verbatim :: Verbatim -> Value f
  Boolean :: Bool -> Value f
  Array :: (Vector (Value f)) -> Value f
  Record :: HashMap Name (Value f) -> Value f
  Function :: ValueType f a -> (a -> f (Value f)) -> Value f

data ValueType f t where
  NumberT :: ValueType f Scientific
  StringT :: ValueType f Text
  BooleanT :: ValueType f Bool
  ArrayT :: ValueType f (Vector (Value f))
  RecordT :: ValueType f (HashMap Name (Value f))
  FunctionT :: ValueType f a -> ValueType f (a -> f (Value f))

data SomeValueType f where
  SomeValueType :: ValueType f t -> SomeValueType f

instance Show (Value f) where
  showsPrec prec = \case
    Number  s -> showsPrec prec s
    String  t -> showsPrec prec t
    Boolean b -> showsPrec prec b
    Record  h ->
        ('{' :)
      . Map.foldrWithKey
        (\k v s -> showsPrec prec k . (':':) . showsPrec prec v . s) id h
      . ('}' :)
    Array   a -> showList (Vec.toList a)
    Verbatim _v -> ("..." <>)
    Function _ _ -> ("<function>" <>)

type Verbatim = Text.Builder
