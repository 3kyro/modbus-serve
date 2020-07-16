-- |
-- Module : CsvParser.Spec
-- Description: Specifications for the csv files parsed by modbus-serve
--
-- Modbus-serve can use input in the form of a csv file. This module defines the specifications of this csv file.
-- - The first line of the document contains field descriptions and will be ignored by the parser
-- - Cells are delimited by a semicolon
-- - Decimal nummbers are dot seperated (eg 1.5)
-- - Text fields cannot contain newline characters
-- - Register addresses above 65535 are truncated
-- - Order of fields is the following:
--     Description;Register Type;Register Address;Data Type; Value;Comments
module CsvParser.Spec
       ( 
         ModData (..)
       , RegType (..)
       , ModType (..)
       , ByteOrder (..)
       , modData
       )
       where

import Data.Word (Word16)
import System.Modbus.TCP (RegAddress)

import qualified Data.Text as T

-- Modbus Register type:
-- Discrete Input, single bit, read only
-- Coil Single bit, read / write
-- Input Register, 16-bit word, read only
-- Holding Register, 16-bit word, read / write
data RegType 
    = DiscreteInput 
    | Coil 
    | InputRegister 
    | HoldingRegister
    deriving (Show, Eq)

data ModData = ModData
    { description   :: !T.Text
    , regType       :: !RegType
    ,  register     :: !RegAddress
    ,  value        :: !ModType
    ,  comments     :: !T.Text
    }
    deriving (Show, Eq)

-- Modbus uses a 'big-Endian' encoding for addresses and data items.
-- This means that when a numerical quantity larger than a single byte is 
-- transmitted, th most significant byte is sent first.
-- In order to transmit a 32 bit float value, two consecutive registers
-- will be used. 
data ModType 
    = ModWord   (Maybe Word16) 
    | ModFloat  (Maybe Float)
    deriving (Show, Eq)

-- Byte order of data types
-- Eg: when receiving two words MSW and LSW
-- LE - MSW LSW
-- BE - LSW MSW 
data ByteOrder
    = LE    -- Little Endian
    | BE    -- Big Endian
    deriving (Show, Read, Eq)

-- ModData constructor
modData :: T.Text -> RegType -> RegAddress -> ModType -> T.Text -> ModData
modData d rt r v c = 
    ModData
    { description = d
    , regType = rt
    , register = r
    , value = v
    , comments = c
    }
