-- | Module for the core result type, and related functions
--
module Text.Digestive.Result
    ( Result (..)
    , FormId (..)
    , FormRange (..)
    , incrementFormId
    , isInRange
    , isSubRange
    , retainErrors
    , retainChildErrors
    ) where

import Control.Applicative (Applicative (..))

-- | Type for failing computations
--
data Result e ok = Error [(FormRange, e)]
                 | Ok ok
                 deriving (Show, Eq)

instance Functor (Result e) where
    fmap _ (Error x) = Error x
    fmap f (Ok x) = Ok (f x)

instance Monad (Result e) where
    return = Ok
    Error x >>= _ = Error x
    Ok x >>= f = f x

instance Applicative (Result e) where
    pure = Ok
    Error x <*> Error y = Error $ x ++ y
    Error x <*> Ok _ = Error x
    Ok _ <*> Error y = Error y
    Ok x <*> Ok y = Ok $ x y

-- | An ID used to identify forms
--
data FormId = FormId
    { formPrefix :: String
    , formId     :: Integer
    } deriving (Eq, Ord)

instance Show FormId where
    show (FormId p x) = p ++ "-f" ++ show x

-- | A range of ID's to specify a group of forms
--
data FormRange = FormRange FormId FormId
               deriving (Eq, Show)

-- | Increment a form ID
--
incrementFormId :: FormId -> FormId
incrementFormId (FormId p x) = FormId p $ x + 1

-- | Check if a 'FormId' is contained in a 'FormRange'
--
isInRange :: FormId     -- ^ Id to check for
          -> FormRange  -- ^ Range
          -> Bool       -- ^ If the range contains the id
isInRange (FormId _ a) (FormRange b c) = a >= formId b && a < formId c

-- | Check if a 'FormRange' is contained in another 'FormRange'
--
isSubRange :: FormRange  -- ^ Sub-range
           -> FormRange  -- ^ Larger range
           -> Bool       -- ^ If the sub-range is contained in the larger range
isSubRange (FormRange a b) (FormRange c d) =  formId a >= formId c
                                           && formId b <= formId d

-- | Select the errors for a certain range
--
retainErrors :: FormRange -> [(FormRange, e)] -> [e]
retainErrors range = map snd . filter ((== range) . fst)

-- | Select the errors originating from this form or from any of the children of
-- this form
--
retainChildErrors :: FormRange -> [(FormRange, e)] -> [e]
retainChildErrors range = map snd . filter ((`isSubRange` range) . fst)
