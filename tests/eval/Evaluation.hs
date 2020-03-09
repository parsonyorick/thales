{-# LANGUAGE OverloadedLists #-}
{-# OPTIONS_GHC -Wno-missing-signatures #-}
import Test.Hspec

import qualified Data.ByteString.Builder as Builder
import qualified Data.HashMap.Strict as Map
import Text.Megaparsec (SourcePos(..), mkPos)

import qualified Bindings
import Eval
import qualified List
import qualified Output
import Syntax
import Value

main = hspec $
  describe "Evaluation" $ do
    it "evaluates names to their bindings" $ do
      let expr = NameE "potato"
          bindings = Bindings.singleton "potato" (Number 3)
      result <- runExprM (evalTopExpr expr) bindings
      result `shouldBe` Right (Number 3)
    it "evaluates field accesses" $ do
      let expr = FieldAccessE "potato" (Id (NameE "vegetables"))
          bindings =
            Bindings.singleton "vegetables"
            (Record (Map.singleton "potato" (Number 7)))
      result <- runExprM (evalTopExpr expr) bindings
      result `shouldBe` Right (Number 7)
    it "evaluates for statements" $ do
      let sp = SourcePos "tests-e/Evaluation.hs" (mkPos 1) (mkPos 1)
          stmt =
            ForS sp "vegetable"
              (ArrayE (List.map (Id . LiteralE . StringL)
                ["leek", "potato", "turnip", "acorn squash"]))
              [ExprS sp (NameE "vegetable"), VerbatimS ", "]
      result <- runStmtM (evalStatement stmt) Bindings.empty
      fmap (Builder.toLazyByteString . Output.toBuilder . snd) result `shouldBe` Right "leek, potato, turnip, acorn squash, "
