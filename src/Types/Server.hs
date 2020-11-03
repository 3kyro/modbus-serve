{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Types.Server
    ( Server
    , ServState (..)
    , ServerActors (..)
    , Connection (..)
    , ConnectionInfo (..)
    , ConnectionRequest (..)
    , getActors
    , setActors
    , KeepAliveServ (..)
    , KeepAliveResponse (..)
    , toKeepAlive
    , OS (..)
    , InitRequest (..)
    ) where

import qualified Network.Socket             as S

import           Data.Aeson                 (FromJSON, ToJSON, object,
                                             parseJSON, toJSON, (.:), (.=))
import           Data.Aeson.Types           (Value (..))
import           Data.IP                    (IPv4)
import           Servant

import           Control.Concurrent         (MVar)
import           Control.Concurrent.STM     (TVar)
import qualified Data.Text                  as T
import           Modbus                     (SerialSettings, rtuBatchWorker, rtuDirectWorker, RTUWorker, ByteOrder, Client, HeartBeat,
                                             ModbusProtocol, TID, TCPWorker(..),
                                             tcpBatchWorker, tcpDirectWorker)
import           Network.Socket.KeepAlive   (KeepAlive (..))
import qualified System.Hardware.Serialport as SP

data ServState = ServState
    { servConnection  :: !Connection
    , servProtocol    :: !ModbusProtocol
    , servOrd         :: !ByteOrder
    , servTID         :: !(TVar TID)
    , servPool        :: ![HeartBeat]
    }


data Connection = TCPConnection
    { tcpSocket         :: !S.Socket
    , tcpConnectionInfo :: !ConnectionInfo
    , tcpActors         :: !ServerActors
    }
    | RTUConnection
    { rtuPort           :: !SP.SerialPort
    , rtuConnectionInfo :: !ConnectionInfo
    , rtuActors         :: !ServerActors
    }
    | NotConnected

data ServerActors = ServerActors
    { sclClient             :: !(MVar Client)
    , sclTCPDirectWorker    :: !(TCPWorker IO)
    , sclTCPBatchWorker     :: !(TCPWorker IO)
    , sclRTUDirectWorker    :: !(RTUWorker IO)
    , sclRTUBatchWorker     :: !(RTUWorker IO)
    }

getActors :: Connection -> Maybe ServerActors
getActors (TCPConnection _ _ actors) = Just actors
getActors (RTUConnection _ _ actors) = Just actors
getActors NotConnected               = Nothing

setActors :: MVar Client -> ServerActors
setActors client =
    ServerActors
        client
        tcpDirectWorker
        tcpBatchWorker
        rtuDirectWorker
        rtuBatchWorker


data ConnectionInfo = TCPConnectionInfo
    { tcpIpAddress :: !IPv4
    , tcpPortNum   :: !Int
    -- in seconds
    , tcpTimeout   :: !Int -- in seconds
    }
    | RTUConnectionInfo
    { rtuAddress :: !String
    , serialSettings :: !SerialSettings
    }

instance FromJSON ConnectionInfo where
    parseJSON (Object o) = do
        (valueType :: T.Text) <- o .: "connection type"
        case valueType of
            "tcp" -> do
                ip <- o .: "ip address"
                port <- o .: "port"
                tm <- o .: "timeout"
                return $ TCPConnectionInfo (read ip) port tm
            "rtu" -> do
                serial <- o .: "serial port"
                settings <- o .: "settings"
                return $ RTUConnectionInfo serial settings
            _ -> fail "Not a valid Connection Info"
    parseJSON _ = fail "Not a valid Connection Info"

instance ToJSON ConnectionInfo where
    toJSON cd =
        case cd of
            TCPConnectionInfo ip port tm-> object
                [ "connection type" .= String "tcp"
                , "ip address" .= show ip
                , "port" .= port
                , "timeout" .= tm
                ]
            RTUConnectionInfo address settings -> object
                [ "connection type" .= String "rtu"
                , "serial port" .= address
                , "settings" .= settings
                ]

data ConnectionRequest = ConnectionRequest
    { requestInfo      :: !ConnectionInfo
    , requestKeepAlive :: !KeepAliveServ
    }

instance FromJSON ConnectionRequest where
    parseJSON (Object o) = do
        jsonInfo <- o .: "connection info"
        jsonKeepAlive <- o .: "keep alive"
        return $ ConnectionRequest jsonInfo jsonKeepAlive
    parseJSON _ = fail "Not a valid ConnectionRequest"

data InitRequest = InitRequest
    { initConnInfo  :: !(Maybe ConnectionInfo)
    , initOs      :: !OS
    }

instance ToJSON InitRequest where
    toJSON ir = object
        [ "connection info" .= initConnInfo ir
        , "os" .= initOs ir
        ]

        
data KeepAliveServ = KeepAliveServ
    { flag     :: Bool
    , idle     :: Int
    , interval :: Int
    } deriving (Show)

instance FromJSON KeepAliveServ where
    parseJSON (Object o) = do
        pflag <- o .: "flag"
        pidle <- o .: "idle"
        pinterval <- o .: "interval"
        return $ KeepAliveServ pflag pidle pinterval
    parseJSON _ = fail "Not a valid KeepAlive"


data KeepAliveResponse = KeepAliveActivated
    | KeepAliveDisactivated

instance ToJSON KeepAliveResponse where
    toJSON KeepAliveActivated    = String "Keep alive activated"
    toJSON KeepAliveDisactivated = String "Keep alive disactivated"

toKeepAlive :: KeepAliveServ -> KeepAlive
toKeepAlive (KeepAliveServ flag' tidle tintv) =
    KeepAlive flag' (fromIntegral tidle) (fromIntegral tintv)


data OS
    = Linux
    | Windows
    | Other

instance ToJSON OS where
    toJSON Linux = String "linux"
    toJSON Windows = String "windows"
    toJSON Other = String "other"