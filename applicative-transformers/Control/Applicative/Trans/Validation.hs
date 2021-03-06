module Control.Applicative.Trans.Validation
  ( ValidationT(..)
  , Validation
  , success
  , failure
  , mapFailures
  )
where

import Control.Applicative
import Control.Applicative.Trans.Class
import Control.Monad
import Control.Monad.IO.Class
import Control.Monad.Trans.Class
import Data.Bifunctor
import Data.Functor.Identity

newtype ValidationT e f a = ValidationT
  { runValidationT :: f (Either e a) }

type Validation e = ValidationT e Identity

instance ApplicativeTrans (ValidationT e) where
  liftApplicative = ValidationT . fmap Right
  {-# INLINE liftApplicative #-}

instance MonadTrans (ValidationT e) where
  lift = liftApplicative

-- | The same as 'pure'; provided for symmetry with 'failure'.
success :: Applicative f => a -> ValidationT e f a
success a = ValidationT (pure (Right a))
{-# INLINE success #-}

-- | Inject a 'Left'.
failure :: Applicative f => e -> ValidationT e f a
failure e = ValidationT (pure (Left e))
{-# INLINE failure #-}

-- | Map a function over all the 'Left's. (This is like 'first', but
-- 'ValidationT' is not a 'Bifunctor', because the type parameters are not in
-- the right order.)
mapFailures :: Functor f => (e -> e') -> ValidationT e f a -> ValidationT e' f a
mapFailures f (ValidationT v) =
  ValidationT $ fmap (first f) v
{-# INLINE mapFailures #-}

instance Functor f => Functor (ValidationT e f) where
  fmap f (ValidationT v) =
    ValidationT $ fmap (fmap f) v
  {-# INLINE fmap #-}

-- TODO: what to do about a Bifunctor instance??

instance (Applicative f, Monoid e) => Applicative (ValidationT e f) where
  vf <*> va =
    ValidationT $ liftA2 apply (runValidationT vf) (runValidationT va)
    where
      apply (Left e1) (Left e2) =
        Left (e1 <> e2)
      apply (Right f) (Right a) =
        Right (f a)
      apply (Left e) (Right _) =
        Left e
      apply (Right _) (Left e) =
        Left e
  pure a =
    ValidationT (pure (Right a))
  {-# INLINE pure #-}

instance (Applicative f, Monoid e) => Alternative (ValidationT e f) where
  empty =
    ValidationT (pure (Left mempty))
  {-# INLINE empty #-}

  v1 <|> v2 =
    ValidationT $ liftA2 alt (runValidationT v1) (runValidationT v2)
    where
      alt (Left e1) (Left e2) =
        Left (e1 <> e2)
      alt a1@(Right _) _ =
        a1
      alt _ a2 =
        a2
  {-# INLINE (<|>) #-}

instance (Monad m, Monoid e) => MonadPlus (ValidationT e m) where
  mzero = empty
  mplus = (<|>)
  {-# INLINE mzero #-}
  {-# INLINE mplus #-}

instance (Monad m, Monoid e) => Monad (ValidationT e m) where
  mva >>= f =
    ValidationT $
      runValidationT mva >>= \va ->
        case va of
          Right a ->
            runValidationT (f a)
          Left e ->
            return (Left e)
  {-# INLINE (>>=) #-}

instance (Functor m, MonadIO m, Monoid e) => MonadIO (ValidationT e m) where
  liftIO a = ValidationT (fmap Right (liftIO a))
