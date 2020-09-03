module Types exposing
    ( Msg (..)
    , Model
    , RegType (..)
    , ModValue (..)
    , ModData
    , getRegType
    , Status (..)
    , showStatus
    , IpAddress
    , IpAddressByte (..)
    , changeIpAddressByte
    , showIpAddressByte
    , insertIpAddressByte
    , ConnectStatus (..)
    , showConnectStatus
    , ipFromString
    , ConnectionInfo
    , decodeIpAddress
    , decodeConnInfo
    , encodeIpPort
    , encodeRegister
    , decodeModData
    )

import Http
import Array
import Json.Decode as D
import Json.Encode as E

type Msg
    = ReadRegisters (Result Http.Error (List ModData))
    | ReceivedConnectionInfo ( Result Http.Error (Maybe ConnectionInfo))
    | RefreshRequest (List ModData)
    | ConnectRequest
    | ConnectedResponse (Result Http.Error () )
    | ChangeIpAddressByte IpAddressByte
    | ChangePort String
    | ChangeTimeout String
    | DisconnectRequest
    | DisconnectedResponse (Result Http.Error () )

type alias Model =
    { modData : List ModData
    , status : Status
    , connectStatus : ConnectStatus
    , ipAddress : IpAddress
    , socketPort : Int
    , timeout : Int
    }
type ConnectStatus
    = Connect
    | Connecting
    | Connected
    | Disconnecting

showConnectStatus : ConnectStatus -> String
showConnectStatus st =
    case st of
        Connect -> "connect"
        Connecting -> "connecting"
        Connected -> "connected"
        Disconnecting -> "disconnecting"

-- IpAddress
------------------------------------------------------------------------------------------
type alias IpAddress =
    { b1 : Int
    , b2 : Int
    , b3 : Int
    , b4 : Int
    }

decodeIpAddress : D.Decoder IpAddress
decodeIpAddress =
    D.string |> D.andThen (\str ->
        case ipFromString str of
            Nothing -> D.fail "Not an Ip Address"
            Just ip -> D.succeed ip
        )

showIp : IpAddress -> String
showIp ip =
    String.fromInt ip.b1
    ++ "."
    ++ String.fromInt ip.b2
    ++ "."
    ++ String.fromInt ip.b3
    ++ "."
    ++ String.fromInt ip.b4

ipFromString : String -> Maybe IpAddress
ipFromString s =
    let
        splits = Array.fromList <| String.split "." s
        mip = Maybe.map4 getIpAddress
                ( Array.get 0 splits )
                ( Array.get 1 splits )
                ( Array.get 2 splits )
                ( Array.get 3 splits )
    in mip |> Maybe.andThen (\m -> m)

getIpAddress : String -> String -> String -> String -> Maybe IpAddress
getIpAddress byte1 byte2 byte3 byte4 =
    Maybe.map4 IpAddress
        ( String.toInt byte1 )
        ( String.toInt byte2 )
        ( String.toInt byte3 )
        ( String.toInt byte4 )
showIpAddressByte : IpAddressByte -> String
showIpAddressByte byte =
    case byte of
        Byte1 x -> String.fromInt x
        Byte2 x -> String.fromInt x
        Byte3 x -> String.fromInt x
        Byte4 x -> String.fromInt x
        NoByte -> "No Byte"

changeIpAddressByte : IpAddress -> IpAddressByte -> IpAddress
changeIpAddressByte ip byte =
    case byte of
        Byte1 x -> { ip | b1 = x }
        Byte2 x -> { ip | b2 = x }
        Byte3 x -> { ip | b3 = x }
        Byte4 x -> { ip | b4 = x }
        NoByte -> ip

insertIpAddressByte : IpAddressByte -> Int -> IpAddressByte
insertIpAddressByte b i =
    case b of
        Byte1 _ -> Byte1 i
        Byte2 _ -> Byte2 i
        Byte3 _ -> Byte3 i
        Byte4 _ -> Byte4 i
        NoByte -> NoByte

type IpAddressByte
    = Byte1 Int
    | Byte2 Int
    | Byte3 Int
    | Byte4 Int
    | NoByte


type Status
    = AllGood
    | Loading
    | Bad String
    | BadIpAddress
    | BadPort
    | BadTimeout

showStatus : Status -> String
showStatus status =
    case status of
        AllGood -> "all good"
        Loading -> "getting stuff from the server"
        Bad err -> err
        BadIpAddress -> "Invalid ip address"
        BadPort -> "Bad Port"
        BadTimeout -> "Bad Timeout"

type alias ConnectionInfo =
    { ipAddress : IpAddress
    , socketPort : Int
    , timeout : Int
    }


decodeConnInfo : D.Decoder ConnectionInfo
decodeConnInfo =
    D.map3 ConnectionInfo
        ( D.field "ip address" decodeIpAddress )
        ( D.field "port" D.int )
        ( D.field "timeout" D.int)

encodeIpPort : Model -> E.Value
encodeIpPort model =
    E.object
        [ ( "ip address", E.string <| showIp model.ipAddress)
        , ( "port", E.int model.socketPort )
        , ( "timeout", E.int  model.timeout)
        ]


-- ModData
--------------------------------------------------------------------------------------------------

type alias ModData =
    { modName : String
    , modRegType : RegType
    , modAddress : Int
    , modValue : ModValue
    , modUid : Int
    , modDescription : String
    }

type RegType
    = InputRegister
    | HoldingRegister

type ModValue
    = ModWord (Maybe Int)
    | ModFloat (Maybe Float)
getRegType : RegType -> String
getRegType rt =
    case rt of
        InputRegister -> "input register"
        HoldingRegister -> "holding register"

encodeRegister : ModData -> E.Value
encodeRegister md =
    E.object
        [ ( "name" , E.string md.modName)
        , ( "register type" , E.string <| getRegType md.modRegType )
        , ( "address", E.int md.modAddress )
        , ( "register value" , encodeModValue md.modValue )
        , ( "uid", E.int md.modUid )
        , ( "description", E.string md.modDescription )
        ]

encodeModValue : ModValue -> E.Value
encodeModValue mv =
    case mv of
        ModWord (Just x) -> E.object
            [ ( "type", E.string "word" )
            , ( "value", E.int x)
            ]
        ModWord Nothing -> E.object
            [ ( "type", E.string "word" )
            ]
        ModFloat (Just x) -> E.object
            [ ( "type", E.string "float" )
            , ( "value", E.float x)
            ]
        ModFloat Nothing -> E.object
            [ ( "type", E.string "float" )
            ]

decodeModData : D.Decoder ModData
decodeModData =
    D.map6 ModData
        ( D.field "name" D.string )
        ( D.field "register type" decodeRegType )
        ( D.field "address" D.int )
        ( D.field "register value" decodeModValue )
        ( D.field "uid" D.int )
        ( D.field "description" D.string )

decodeModValue : D.Decoder ModValue
decodeModValue =
    D.field "type" D.string |> D.andThen (\s ->
        case s of
            "word" -> D.map ModWord <| D.field "value" (D.nullable D.int)
            "float" -> D.map ModFloat <| D.field "value" (D.nullable D.float)
            _ -> D.fail "Not a valid ModValue"
    )

-- find a way to fail on non valid input
decodeRegType : D.Decoder RegType
decodeRegType =
    D.map (\s ->
        case s of
            "input register" -> InputRegister
            "holding register" -> HoldingRegister
            _ -> InputRegister
    ) D.string
