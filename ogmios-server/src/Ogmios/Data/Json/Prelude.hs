--  This Source Code Form is subject to the terms of the Mozilla Public
--  License, v. 2.0. If a copy of the MPL was not distributed with this
--  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-- This is used to define the 'keepRedundantContraint' helper here where it is
-- safe to define, and use it in other Json modules where we do not want to turn
-- -fno-warn-redundant-constraints for the entire module, but still want some
-- redundant constraints in order to enforce some restriction at the type-level
-- to not shoot ourselves in the foot by accident.
{-# OPTIONS_GHC -fno-warn-redundant-constraints #-}

module Ogmios.Data.Json.Prelude
    ( -- * Prelude
      module Relude
    , Json
    , FromJSON
    , jsonToByteString
    , decodeWith
    , humanReadablePart
    , keepRedundantConstraint
    , choice

      -- * Basic Types
    , encodeBlockNo
    , encodeBool
    , encodeByteArray
    , encodeByteStringBase16
    , encodeByteStringBase64
    , encodeByteStringBech32
    , encodeDnsName
    , encodeDouble
    , encodeEpochNo
    , encodeIPv4
    , encodeIPv6
    , encodeInteger
    , encodeNatural
    , encodeNull
    , encodePort
    , encodeRational
    , encodeScientific
    , encodeShortByteString
    , encodeSlotNo
    , encodeString
    , encodeText
    , encodeUnitInterval
    , encodeUrl
    , encodeWord
    , encodeWord16
    , encodeWord32
    , encodeWord64
    , encodeWord8

      -- * Data-Structures
    , encodeAnnotated
    , encodeIdentity
    , encodeFoldable
    , encodeList
    , encodeMap
    , encodeMaybe
    , encodeObject
    , encode2Tuple
    , encode3Tuple
    , encode4Tuple
    , encodeStrictMaybe

      -- * Queries
    , SomeQuery (..)
    ) where

import Relude

import Cardano.Binary
    ( Annotated (..) )
import Cardano.Slotting.Block
    ( BlockNo (..) )
import Cardano.Slotting.Slot
    ( EpochNo (..), SlotNo (..) )
import Codec.Binary.Bech32
    ( HumanReadablePart )
import Codec.Binary.Bech32.TH
    ( humanReadablePart )
import Data.Aeson
    ( FromJSON )
import Data.ByteArray
    ( ByteArrayAccess )
import Data.ByteString.Base16
    ( encodeBase16 )
import Data.ByteString.Base64
    ( encodeBase64 )
import Data.ByteString.Short
    ( ShortByteString, fromShort )
import Data.IP
    ( IPv4, IPv6 )
import Data.Scientific
    ( Scientific )
import Data.Sequence.Strict
    ( StrictSeq )
import Data.Vector
    ( Vector )
import Jsonifier
    ( Json )
import Ouroboros.Consensus.Shelley.Ledger.Query
    ( Query (..) )
import Shelley.Spec.Ledger.BaseTypes
    ( DnsName
    , Port
    , StrictMaybe (..)
    , UnitInterval
    , Url
    , dnsToText
    , portToWord16
    , unitIntervalToRational
    , urlToText
    )

import qualified Codec.Binary.Bech32 as Bech32
import qualified Data.ByteArray as BA
import qualified Data.Map.Strict as Map
import qualified Jsonifier as Json

import qualified Data.Aeson.Parser.Internal as Aeson
import qualified Data.Aeson.Types as Aeson

--
-- Prelude
--

jsonToByteString :: Json -> ByteString
jsonToByteString = Json.toByteString

decodeWith :: (Aeson.Value -> Aeson.Parser a) -> ByteString -> Maybe a
decodeWith decoder =
    Aeson.decodeStrictWith Aeson.jsonEOF (Aeson.parse decoder)

--
-- Basic Types
--

encodeBlockNo :: BlockNo -> Json
encodeBlockNo =
    encodeWord64 . unBlockNo

encodeBool :: Bool -> Json
encodeBool = Json.bool

encodeByteArray :: ByteArrayAccess ba => (ByteString -> Json) -> ba -> Json
encodeByteArray encodeByteString =
    encodeByteString . BA.convert

encodeByteStringBase16 :: ByteString -> Json
encodeByteStringBase16 =
    encodeText . encodeBase16

encodeByteStringBech32 :: HumanReadablePart -> ByteString -> Json
encodeByteStringBech32 hrp =
    encodeText . Bech32.encodeLenient hrp . Bech32.dataPartFromBytes

encodeByteStringBase64 :: ByteString -> Json
encodeByteStringBase64 =
    encodeText . encodeBase64

encodeDnsName :: DnsName -> Json
encodeDnsName =
    encodeText . dnsToText


encodeDouble :: Double -> Json
encodeDouble =
    Json.doubleNumber

encodeEpochNo :: EpochNo -> Json
encodeEpochNo =
    encodeWord64 . unEpochNo

encodeIPv4 :: IPv4 -> Json
encodeIPv4 =
    encodeString . show

encodeIPv6 :: IPv6 -> Json
encodeIPv6 =
    encodeString . show

encodeInteger :: Integer -> Json
encodeInteger =
    Json.scientificNumber . fromInteger

encodeNatural :: Natural -> Json
encodeNatural =
    encodeInteger . toInteger

encodeNull :: Json
encodeNull =
    Json.null

encodePort :: Port -> Json
encodePort =
    encodeWord16 . portToWord16

encodeRational :: Rational -> Json
encodeRational r =
    encodeText (show (numerator r) <> "/" <> show (denominator r))

encodeScientific :: Scientific -> Json
encodeScientific =
    Json.scientificNumber

encodeShortByteString :: (ByteString -> Json) -> ShortByteString -> Json
encodeShortByteString encodeByteString =
    encodeByteString . fromShort

encodeSlotNo :: SlotNo -> Json
encodeSlotNo =
    encodeWord64 . unSlotNo

encodeString :: String -> Json
encodeString =
    encodeText . toText

encodeText :: Text -> Json
encodeText =
    Json.textString

encodeUnitInterval :: UnitInterval -> Json
encodeUnitInterval =
    encodeRational . unitIntervalToRational

encodeUrl :: Url -> Json
encodeUrl =
    encodeText . urlToText

encodeWord :: Word -> Json
encodeWord =
    Json.wordNumber

encodeWord8 :: Word8 -> Json
encodeWord8 =
    encodeWord . fromIntegral

encodeWord16 :: Word16 -> Json
encodeWord16 =
    encodeWord . fromIntegral

encodeWord32 :: Word32 -> Json
encodeWord32 =
    encodeWord . fromIntegral

encodeWord64 :: Word64 -> Json
encodeWord64 =
    encodeInteger . toInteger

--
-- Data-Structures
--

encodeAnnotated :: (a -> Json) -> Annotated a any -> Json
encodeAnnotated encodeElem =
    encodeElem . unAnnotated

encodeIdentity :: (a -> Json) -> Identity a -> Json
encodeIdentity encodeElem =
    encodeElem . runIdentity

encodeFoldable :: Foldable f => (a -> Json) -> f a -> Json
encodeFoldable encodeElem =
    Json.array . foldr ((:) . encodeElem) []
{-# SPECIALIZE encodeFoldable :: (a -> Json) -> [a] -> Json #-}
{-# SPECIALIZE encodeFoldable :: (a -> Json) -> NonEmpty a -> Json #-}
{-# SPECIALIZE encodeFoldable :: (a -> Json) -> Vector a -> Json #-}
{-# SPECIALIZE encodeFoldable :: (a -> Json) -> Set a -> Json #-}
{-# SPECIALIZE encodeFoldable :: (a -> Json) -> StrictSeq a -> Json #-}

encodeList :: (a -> Json) -> [a] -> Json
encodeList encodeElem =
    Json.array . fmap encodeElem

encodeMap :: (k -> Text) -> (v -> Json) -> Map k v -> Json
encodeMap encodeKey encodeValue =
    Json.object . Map.foldrWithKey (\k v -> (:) (encodeKey k, encodeValue v)) []

encodeMaybe :: (a -> Json) -> Maybe a -> Json
encodeMaybe =
    maybe Json.null

encodeObject :: Foldable f => f (Text, Json) -> Json
encodeObject =
    Json.object
{-# SPECIALIZE encodeObject :: [(Text, Json)] -> Json #-}

encode2Tuple
    :: (a -> Json)
    -> (b -> Json)
    -> (a, b)
    -> Json
encode2Tuple encodeA encodeB (a,b) =
    Json.array [encodeA a, encodeB b]

encode3Tuple
    :: (a -> Json)
    -> (b -> Json)
    -> (c -> Json)
    -> (a, b, c)
    -> Json
encode3Tuple encodeA encodeB encodeC (a, b, c) =
    Json.array [encodeA a, encodeB b, encodeC c]

encode4Tuple
    :: (a -> Json)
    -> (b -> Json)
    -> (c -> Json)
    -> (d -> Json)
    -> (a, b, c, d)
    -> Json
encode4Tuple encodeA encodeB encodeC encodeD (a, b, c, d) =
    Json.array [encodeA a, encodeB b, encodeC c, encodeD d]

encodeStrictMaybe :: (a -> Json) -> StrictMaybe a -> Json
encodeStrictMaybe encodeElem = \case
    SNothing -> Json.null
    SJust a  -> encodeElem a

--
-- Queries
--

data SomeQuery (f :: * -> *) block = forall result. SomeQuery
    { query :: Query block result
    , encodeResult :: result -> Json
    , genResult :: Proxy result -> f result
    }

choice :: (Alternative f, MonadFail f) => String -> [a -> f b] -> a -> f b
choice entity xs a =
    asum (xs <*> pure a) <|> fail ("invalid " <> entity)

--
-- Redundant Constraints
--

keepRedundantConstraint :: c => Proxy c -> ()
keepRedundantConstraint _ = ()