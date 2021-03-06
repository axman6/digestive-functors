{-# LANGUAGE OverloadedStrings #-}
module Text.Digestive.Blaze.Html5
    ( BlazeFormHtml
    , inputText
    , inputTextArea
    , inputTextRead
    , inputPassword
    , inputCheckBox
    , inputRadio
    , inputFile
    , submit
    , label
    , errors
    , childErrors
    , module Text.Digestive.Forms.Html
    ) where

import Control.Monad (forM_, unless, when)
import Data.Maybe (fromMaybe)
import Data.Monoid (mempty)

import Text.Blaze.Html5 (Html, (!))
import qualified Text.Blaze.Html5 as H
import qualified Text.Blaze.Html5.Attributes as A

import Text.Digestive.Types
import Text.Digestive.Forms (FormInput (..))
import qualified Text.Digestive.Forms as Forms
import qualified Text.Digestive.Common as Common
import Text.Digestive.Forms.Html

-- | Form HTML generated by blaze
--
type BlazeFormHtml = FormHtml Html

-- | 'applyClasses' instantiated for blaze
--
applyClasses' :: [FormHtmlConfig -> [String]]  -- ^ Labels to apply
              -> FormHtmlConfig                -- ^ Label configuration
              -> Html                          -- ^ HTML element
              -> Html                          -- ^ Resulting element
applyClasses' = applyClasses $ \element value ->
    element ! A.class_ (H.stringValue value)

-- | Checks the input element when the argument is true
--
checked :: Bool -> Html -> Html
checked False x = x
checked True  x = x ! A.checked "checked"

inputText :: (Monad m, Functor m, FormInput i f)
          => Maybe String
          -> Form m i e BlazeFormHtml String
inputText = Forms.inputString $ \id' inp -> createFormHtml $ \cfg ->
    applyClasses' [htmlInputClasses] cfg $
        H.input ! A.type_ "text"
                ! A.name (H.stringValue $ show id')
                ! A.id (H.stringValue $ show id')
                ! A.value (H.stringValue $ fromMaybe "" inp)

inputTextArea :: (Monad m, Functor m, FormInput i f)
              => Maybe Int                        -- ^ Rows
              -> Maybe Int                        -- ^ Columns
              -> Maybe String                     -- ^ Default input
              -> Form m i e BlazeFormHtml String  -- ^ Result
inputTextArea r c = Forms.inputString $ \id' inp -> createFormHtml $ \cfg ->
    applyClasses' [htmlInputClasses] cfg $ rows r $ cols c $
        H.textarea ! A.name (H.stringValue $ show id')
                   ! A.id (H.stringValue $ show id')
                   $ H.string $ fromMaybe "" inp
  where
    rows Nothing = id
    rows (Just x) = (! A.rows (H.stringValue $ show x))
    cols Nothing = id
    cols (Just x) = (! A.cols (H.stringValue $ show x))

inputTextRead :: (Monad m, Functor m, FormInput i f, Show a, Read a)
              => e
              -> Maybe a
              -> Form m i e BlazeFormHtml a
inputTextRead error' = flip Forms.inputRead error' $ \id' inp ->
    createFormHtml $ \cfg -> applyClasses' [htmlInputClasses] cfg $
        H.input ! A.type_ "text"
                ! A.name (H.stringValue $ show id')
                ! A.id (H.stringValue $ show id')
                ! A.value (H.stringValue $ fromMaybe "" inp)

inputPassword :: (Monad m, Functor m, FormInput i f)
              => Form m i e BlazeFormHtml String
inputPassword = flip Forms.inputString Nothing $ \id' inp ->
    createFormHtml $ \cfg -> applyClasses' [htmlInputClasses] cfg $
        H.input ! A.type_ "password"
                ! A.name (H.stringValue $ show id')
                ! A.id (H.stringValue $ show id')
                ! A.value (H.stringValue $ fromMaybe "" inp)

inputCheckBox :: (Monad m, Functor m, FormInput i f)
              => Bool
              -> Form m i e BlazeFormHtml Bool
inputCheckBox inp = flip Forms.inputBool inp $ \id' inp' ->
    createFormHtml $ \cfg -> applyClasses' [htmlInputClasses] cfg $
        checked inp' $ H.input ! A.type_ "checkbox"
                               ! A.name (H.stringValue $ show id')
                               ! A.id (H.stringValue $ show id')

inputRadio :: (Monad m, Functor m, FormInput i f, Eq a)
           => Bool                        -- ^ Use @<br>@ tags
           -> a                           -- ^ Default option
           -> [(a, Html)]                 -- ^ Choices with their names
           -> Form m i e BlazeFormHtml a  -- ^ Resulting form
inputRadio br def choices = Forms.inputChoice toView def (map fst choices)
  where
    toView group id' sel val = createFormHtml $ \cfg -> do
        applyClasses' [htmlInputClasses] cfg $ checked sel $
            H.input ! A.type_ "radio"
                    ! A.name (H.stringValue $ show group)
                    ! A.value (H.stringValue id')
                    ! A.id (H.stringValue id')
        H.label ! A.for (H.stringValue id')
                $ fromMaybe mempty $ lookup val choices
        when br H.br

inputFile :: (Monad m, Functor m, FormInput i f)
          => Form m i e BlazeFormHtml (Maybe f)  -- ^ Form
inputFile = Forms.inputFile toView
  where
    toView id' = createFormHtmlWith MultiPart $ \cfg -> do
        applyClasses' [htmlInputClasses] cfg $
            H.input ! A.type_ "file"
                    ! A.name (H.stringValue $ show id')
                    ! A.id (H.stringValue $ show id')

submit :: Monad m
       => String                            -- ^ Text on the submit button
       -> Form m String e BlazeFormHtml ()  -- ^ Submit button
submit text = view $ createFormHtml $ \cfg ->
    applyClasses' [htmlInputClasses, htmlSubmitClasses] cfg $
        H.input ! A.type_ "submit"
                ! A.value (H.stringValue text)

label :: Monad m
      => String
      -> Form m i e BlazeFormHtml ()
label string = Common.label $ \id' -> createFormHtml $ \cfg ->
    applyClasses' [htmlLabelClasses] cfg $
        H.label ! A.for (H.stringValue $ show id')
                $ H.string string

errorList :: [Html] -> BlazeFormHtml
errorList errors' = createFormHtml $ \cfg -> unless (null errors') $
    applyClasses' [htmlErrorListClasses] cfg $
        H.ul $ forM_ errors' $ applyClasses' [htmlErrorClasses] cfg . H.li

errors :: Monad m
       => Form m i Html BlazeFormHtml ()
errors = Common.errors errorList

childErrors :: Monad m
            => Form m i Html BlazeFormHtml ()
childErrors = Common.childErrors errorList
