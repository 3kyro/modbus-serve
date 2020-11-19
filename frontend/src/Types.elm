module Types exposing
    ( ActiveTab(..)
    , BaudRate(..)
    , ConnectActiveTab(..)
    , ConnectStatus(..)
    , ConnectionInfo(..)
    , HeartBeat
    , HeartBeatType(..)
    , InitInfo
    , KeepAliveResponse(..)
    , Model
    , Msg(..)
    , OS(..)
    , Parity(..)
    , SettingsOptions(..)
    , StopBits(..)
    , WordOrder(..)
    , decodeConnInfo
    , decodeHeartBeat
    , decodeInitInfo
    , decodeKeepAliveResponse
    , decodeWordOrder
    , deleteListElem
    , diffList
    , encodeHeartBeat
    , encodeKeepAlive
    , encodeRTUConnectionRequest
    , encodeTCPConnectionInfo
    , encodeTCPConnectionRequest
    , encodeWordOrder
    , fromIdList
    , getHbTypeLabel
    , getSelectedIds
    , replaceHeartBeatSelected
    , retractDropdowns
    , showConnInfo
    , showConnectStatus
    , showFailedHeartBeat
    , showKeepAliveResponse
    , showOs
    , showWordOrderResponse
    , toWordOrder
    )

import Dropdown exposing (..)
import File exposing (File)
import Http
import Json.Decode as D
import Json.Encode as E exposing (Value)
import ModData
    exposing
        ( ModData
        , ModDataUpdate
        , ModValue(..)
        , RegType(..)
        )
import Notifications
    exposing
        ( Notification
        , StatusBarState(..)
        )
import ReadWrite
    exposing
        ( ReadWrite(..)
        , decodeRW
        , encodeRW
        )
import Settings exposing (Setting)
import String exposing (fromFloat)
import Time
import Types.IpAddress
    exposing
        ( IpAddress
        , IpAddressByte
        , decodeIpAddress
        , showIp
        , unsafeShowIp
        )



----------------------------------------------------------------------------------------------------------------------------------
-- Msg
-----------------------------------------------------------------------------------------------------------------------------------


type Msg
    = ReadRegisters (Result Http.Error (List ModDataUpdate))
    | ReceivedConnectionInfo (Result Http.Error (Maybe ConnectionInfo))
    | RefreshRequest (List ModDataUpdate)
    | ConnectRequest
    | ConnectedResponse (Result Http.Error ())
    | ChangeIpAddress IpAddressByte String
    | ChangePort String
    | ChangeTimeout String
    | DisconnectRequest
    | DisconnectedResponse (Result Http.Error ())
    | ChangeActiveTab ActiveTab
    | CsvRequested
    | CsvSelected File
    | CsvLoaded String
    | ReceivedModData (Result Http.Error (List ModData))
    | SelectAllChecked Bool
    | ModDataChecked Int Bool
    | ToggleWriteAll ReadWrite
    | ModDataWrite Int ReadWrite
    | ChangeModDataValue Int String
    | ExpandStatus
    | TimeZone Time.Zone
    | InitTime Time.Posix
    | NewTime Time.Posix
    | ExpandNotification Notification
    | SetActiveSetting (Setting SettingsOptions Msg)
    | KeepAliveMsg Int Int Bool
    | KeepAliveIdleMsg Int Int String
    | KeepAliveIntervalMsg Int Int String
    | KeepAliveResponseMsg (Result Http.Error KeepAliveResponse)
    | ChangeWordOrderMsg Int Int SettingsOptions
    | ChangeWordOrderResponse (Result Http.Error WordOrder)
    | RegRegTypeDrop (Option RegType Msg)
    | RegValueTypeDrop (Option ModValue Msg)
    | RegAddress String
    | RegUid String
    | RegToggleRW ReadWrite
    | RegNumber String
    | RegModValue String
    | UpdateRegMdu
    | UpdateRegMduResponse (Result Http.Error (List ModDataUpdate))
    | ReceivedInitInfo (Result Http.Error InitInfo)
    | ChangeActiveConnectTab ConnectActiveTab
    | ChangeSerialPort String
    | BaudRateDrop (Option BaudRate Msg)
    | StopBitsDrop (Option StopBits Msg)
    | ParityDrop (Option Parity Msg)
      -- HeartBeat
    | HeartUid String
    | HeartAddress String
    | HeartInterval String
    | StartHeartBeat
    | StopHeartBeat
    | UpdateActiveHeartBeats (Result Http.Error (List Int))
    | HeartBeatChecked Int Bool
    | InitHeartBeat (Result Http.Error (List HeartBeat))
    | HeartBeatTypeDrop (Option HeartBeatType Msg)
    | HBLow String
    | HBHigh String
      -- Noop
    | NoOp



----------------------------------------------------------------------------------------------------------------------------------
-- Model
-----------------------------------------------------------------------------------------------------------------------------------


type alias Model =
    { -- register table
      modDataUpdate : List ModDataUpdate
    , selectAllCheckbox : Bool
    , selectSome : Bool
    , readWriteAll : ReadWrite

    -- register tab
    , regTypeDd : Dropdown RegType Msg
    , regModValueDd : Dropdown ModValue Msg
    , regAddress : Maybe Int
    , regUid : Maybe Int
    , regNumReg : Maybe Int
    , regMdu : ModDataUpdate
    , regResponse : List ModDataUpdate

    -- notifications
    , statusBarState : StatusBarState
    , notifications : List Notification
    , connectStatus : ConnectStatus

    -- tabs
    , activeTab : ActiveTab

    -- connect tab
    , connActiveTab : ConnectActiveTab
    , timeout : Maybe Int -- in seconds

    -- TCP Connections
    , ipAddress : IpAddress
    , serialPort : Maybe String

    -- RTU connections
    , socketPort : Maybe Int
    , os : OS
    , baudrate : BaudRate
    , baudrateDd : Dropdown BaudRate Msg
    , stopBits : StopBits
    , stopBitsDd : Dropdown StopBits Msg
    , parity : Parity
    , parityDd : Dropdown Parity Msg

    -- CSV
    , csvFileName : Maybe String
    , csvContent : Maybe String
    , csvLoaded : Bool

    -- time
    , timePosix : Time.Posix
    , timeZone : Time.Zone

    -- heartbeats
    , heartbeats : List HeartBeat
    , heartUid : Maybe Int
    , heartAddr : Maybe Int
    , heartIntv : Maybe Int
    , heartSelectAll : Bool
    , heartSelectSome : Bool
    , hbTypeDd : Dropdown HeartBeatType Msg
    , heartId : Int
    , hbLow : Maybe Int
    , hbHigh : Maybe Int

    -- settings
    , settings : List (Setting SettingsOptions Msg)
    , keepAlive : Bool
    , keepAliveIdle : Maybe Int -- in seconds
    , keepAliveInterval : Maybe Int -- in seconds
    , wordOrder : WordOrder
    }


retractDropdowns : Model -> Model
retractDropdowns model =
    { model
        | regModValueDd = retract model.regModValueDd
        , regTypeDd = retract model.regTypeDd
        , baudrateDd = retract model.baudrateDd
        , stopBitsDd = retract model.stopBitsDd
        , parityDd = retract model.parityDd
    }



----------------------------------------------------------------------------------------------------------------------------------
-- SettingsOptions
-----------------------------------------------------------------------------------------------------------------------------------


type SettingsOptions
    = SetLE
    | SetBE



----------------------------------------------------------------------------------------------------------------------------------
-- Connect Status
-----------------------------------------------------------------------------------------------------------------------------------


type ConnectStatus
    = Connect
    | Connecting
    | Connected
    | Disconnecting


showConnectStatus : ConnectStatus -> String
showConnectStatus st =
    case st of
        Connect ->
            "Connect"

        Connecting ->
            "Connecting"

        Connected ->
            "Connected"

        Disconnecting ->
            "Disconnecting"



----------------------------------------------------------------------------------------------------------------------------------
-- Connection Info
-----------------------------------------------------------------------------------------------------------------------------------


type ConnectionInfo
    = TCPConnectionInfo
        { ipAddress : IpAddress
        , socketPort : Int
        , timeout : Int -- in seconds
        }
    | RTUConnectionInfo
        { rtuAddress : String
        , serialSettings : SerialSettings
        }


decodeConnInfo : D.Decoder ConnectionInfo
decodeConnInfo =
    D.field "connection type" D.string
        |> D.andThen
            (\s ->
                case s of
                    "tcp" ->
                        D.map3 getTCPConnectionInfo
                            (D.field "ip address" decodeIpAddress)
                            (D.field "port" D.int)
                            (D.field "timeout" D.int)

                    "rtu" ->
                        D.map2 getRTUConnectionInfo
                            (D.field "serial port" D.string)
                            (D.field "settings" decodeSerialSettings)

                    _ ->
                        D.fail "Not a connection info"
            )


encodeTCPConnectionRequest : Model -> E.Value
encodeTCPConnectionRequest model =
    E.object
        [ ( "connection info", encodeTCPConnectionInfo model )
        , ( "keep alive", encodeKeepAlive model model.keepAlive )
        ]


encodeRTUConnectionRequest : Model -> E.Value
encodeRTUConnectionRequest model =
    E.object
        [ ( "connection info", encodeRTUConnectionInfo model )
        , ( "keep alive", encodeKeepAlive model model.keepAlive )
        ]


encodeTCPConnectionInfo : Model -> E.Value
encodeTCPConnectionInfo model =
    E.object
        [ ( "connection type", E.string "tcp" )
        , ( "ip address", E.string <| unsafeShowIp model.ipAddress )
        , ( "port", E.int <| Maybe.withDefault 0 model.socketPort )
        , ( "timeout", E.int <| Maybe.withDefault 0 model.timeout )
        ]


encodeRTUConnectionInfo : Model -> E.Value
encodeRTUConnectionInfo model =
    E.object
        [ ( "connection type", E.string "rtu" )
        , ( "serial port", E.string <| Maybe.withDefault "" model.serialPort )
        , ( "settings"
          , encodeSerialSettings <|
                SerialSettings
                    model.baudrate
                    model.stopBits
                    model.parity
                <|
                    Maybe.withDefault 1 model.timeout
          )
        ]


getTCPConnectionInfo : IpAddress -> Int -> Int -> ConnectionInfo
getTCPConnectionInfo ip portNum tm =
    TCPConnectionInfo
        { ipAddress = ip
        , socketPort = portNum
        , timeout = tm
        }


getRTUConnectionInfo : String -> SerialSettings -> ConnectionInfo
getRTUConnectionInfo address settings =
    RTUConnectionInfo
        { rtuAddress = address
        , serialSettings = settings
        }


showConnInfo : ConnectionInfo -> String
showConnInfo connInfo =
    case connInfo of
        TCPConnectionInfo conn ->
            ("IP Address: " ++ Maybe.withDefault "N/A" (showIp conn.ipAddress) ++ "\n")
                ++ ("Port: " ++ String.fromInt conn.socketPort ++ "\n")
                ++ ("Timeout: " ++ String.fromInt conn.timeout)

        RTUConnectionInfo conn ->
            "Serial Port: " ++ conn.rtuAddress ++ "\n"



--------------------------------------------------------------------------------------------------
-- InitInfo
--------------------------------------------------------------------------------------------------


type alias InitInfo =
    { initConnInfo : Maybe ConnectionInfo
    , initOS : OS
    }


decodeInitInfo : D.Decoder InitInfo
decodeInitInfo =
    D.map2 InitInfo
        (D.field "connection info" <| D.maybe decodeConnInfo)
        (D.field "os" decodeOS)



--------------------------------------------------------------------------------------------------
-- OS
--------------------------------------------------------------------------------------------------


type OS
    = Linux
    | Windows
    | Other


decodeOS : D.Decoder OS
decodeOS =
    D.string
        |> D.andThen
            (\s ->
                case s of
                    "linux" ->
                        D.succeed Linux

                    "windows" ->
                        D.succeed Windows

                    _ ->
                        D.succeed Other
            )


showOs : OS -> String
showOs os =
    case os of
        Linux ->
            "linux"

        Windows ->
            "windows"

        Other ->
            "not detected"



--------------------------------------------------------------------------------------------------
-- ActiveTab
--------------------------------------------------------------------------------------------------


type ActiveTab
    = ConnectMenu
    | RegistersTab
    | ModDataTab
    | HeartbeatTab
    | SettingsTab



--------------------------------------------------------------------------------------------------
-- ConnectActiveTab
--------------------------------------------------------------------------------------------------


type ConnectActiveTab
    = TCPTab
    | RTUTab



--------------------------------------------------------------------------------------------------
-- Keep Alive
--------------------------------------------------------------------------------------------------


encodeKeepAlive : Model -> Bool -> E.Value
encodeKeepAlive model flag =
    E.object
        [ ( "flag", E.bool flag )
        , ( "idle", E.int <| Maybe.withDefault 60 model.keepAliveIdle )
        , ( "interval", E.int <| Maybe.withDefault 10 model.keepAliveInterval )
        ]


type KeepAliveResponse
    = KeepAliveActivated
    | KeepAliveDisactivated


showKeepAliveResponse : KeepAliveResponse -> String
showKeepAliveResponse kar =
    case kar of
        KeepAliveActivated ->
            "Keep alive activated"

        KeepAliveDisactivated ->
            "Keep alive disactivated"


decodeKeepAliveResponse : D.Decoder KeepAliveResponse
decodeKeepAliveResponse =
    D.string
        |> D.andThen
            (\s ->
                case s of
                    "Keep alive activated" ->
                        D.succeed KeepAliveActivated

                    "Keep alive disactivated" ->
                        D.succeed KeepAliveDisactivated

                    _ ->
                        D.fail "Not a KeepAliveResponse"
            )



--------------------------------------------------------------------------------------------------
-- WordOrder
--------------------------------------------------------------------------------------------------


type WordOrder
    = LE
    | BE


encodeWordOrder : WordOrder -> E.Value
encodeWordOrder order =
    case order of
        LE ->
            E.string "le"

        BE ->
            E.string "be"


decodeWordOrder : D.Decoder WordOrder
decodeWordOrder =
    D.string
        |> D.andThen
            (\s ->
                case s of
                    "le" ->
                        D.succeed LE

                    "be" ->
                        D.succeed BE

                    _ ->
                        D.fail "Not a WordOrder"
            )


showWordOrderResponse : WordOrder -> String
showWordOrderResponse order =
    case order of
        LE ->
            "Word order changed to Little Endian"

        BE ->
            "Word order changed to Big Endian"


toWordOrder : SettingsOptions -> WordOrder
toWordOrder option =
    case option of
        SetLE ->
            LE

        SetBE ->
            BE



--------------------------------------------------------------------------------------------------
-- SerialSettings
--------------------------------------------------------------------------------------------------
-- Settings used for serial communication


type alias SerialSettings =
    { baudRate : BaudRate
    , stopBits : StopBits
    , parity : Parity
    , timeout : Int
    }


decodeSerialSettings : D.Decoder SerialSettings
decodeSerialSettings =
    D.map4 SerialSettings
        (D.field "baudrate" decodeBaudRate)
        (D.field "stopbits" decodeStopBits)
        (D.field "parity" decodeParity)
        (D.field "timeout" D.int)


encodeSerialSettings : SerialSettings -> E.Value
encodeSerialSettings ss =
    E.object
        [ ( "baudrate", encodeBaudRate ss.baudRate )
        , ( "stopbits", encodeStopBits ss.stopBits )
        , ( "parity", encodeParity ss.parity )
        , ( "timeout", E.int ss.timeout )
        ]


type BaudRate
    = BR110
    | BR300
    | BR600
    | BR1200
    | BR2400
    | BR4800
    | BR9600
    | BR19200
    | BR38400
    | BR57600
    | BR115200


decodeBaudRate : D.Decoder BaudRate
decodeBaudRate =
    D.string
        |> D.andThen
            (\s ->
                case s of
                    "BR110" ->
                        D.succeed BR110

                    "BR300" ->
                        D.succeed BR300

                    "BR600" ->
                        D.succeed BR600

                    "BR1200" ->
                        D.succeed BR1200

                    "BR2400" ->
                        D.succeed BR2400

                    "BR4800" ->
                        D.succeed BR4800

                    "BR9600" ->
                        D.succeed BR9600

                    "BR19200" ->
                        D.succeed BR19200

                    "BR38400" ->
                        D.succeed BR38400

                    "BR57600" ->
                        D.succeed BR57600

                    "BR115200" ->
                        D.succeed BR115200

                    _ ->
                        D.fail "Not a BaudRate"
            )


encodeBaudRate : BaudRate -> E.Value
encodeBaudRate br =
    case br of
        BR110 ->
            E.string "BR110"

        BR300 ->
            E.string "BR300"

        BR600 ->
            E.string "BR600"

        BR1200 ->
            E.string "BR1200"

        BR2400 ->
            E.string "BR2400"

        BR4800 ->
            E.string "BR4800"

        BR9600 ->
            E.string "BR9600"

        BR19200 ->
            E.string "BR19200"

        BR38400 ->
            E.string "BR38400"

        BR57600 ->
            E.string "BR57600"

        BR115200 ->
            E.string "BR115200"


type StopBits
    = OneStopBit
    | TwoStopBits


decodeStopBits : D.Decoder StopBits
decodeStopBits =
    D.string
        |> D.andThen
            (\s ->
                case s of
                    "one" ->
                        D.succeed OneStopBit

                    "two" ->
                        D.succeed TwoStopBits

                    _ ->
                        D.fail "Not a StopBit"
            )


encodeStopBits : StopBits -> E.Value
encodeStopBits sb =
    case sb of
        OneStopBit ->
            E.string "one"

        TwoStopBits ->
            E.string "two"


type Parity
    = OddParity
    | EvenParity


decodeParity : D.Decoder Parity
decodeParity =
    D.string
        |> D.andThen
            (\s ->
                case s of
                    "odd" ->
                        D.succeed OddParity

                    "even" ->
                        D.succeed EvenParity

                    _ ->
                        D.fail "Not a Parity"
            )


encodeParity : Parity -> E.Value
encodeParity pr =
    case pr of
        OddParity ->
            E.string "odd"

        EvenParity ->
            E.string "even"



--------------------------------------------------------------------------------------------------
-- HeartBeatType
--------------------------------------------------------------------------------------------------


type HeartBeatType
    = Increment
    | Pulse Int
    | Alternate Int Int
    | Range Int Int


encodeHeartBeatType : HeartBeatType -> E.Value
encodeHeartBeatType hbt =
    case hbt of
        Increment ->
            E.object
                [ ( "type", E.string "Increment" ) ]

        Pulse value ->
            E.object
                [ ( "type", E.string "Pulse" )
                , ( "value", E.int value )
                ]

        Alternate low high ->
            E.object
                [ ( "type", E.string "Alternate" )
                , ( "low", E.int low )
                , ( "high", E.int high )
                ]

        Range low high ->
            E.object
                [ ( "type", E.string "Range" )
                , ( "low", E.int low )
                , ( "high", E.int high )
                ]


decodeHeartBeatType : D.Decoder HeartBeatType
decodeHeartBeatType =
    D.field "type" D.string
        |> D.andThen
            (\s ->
                case s of
                    "Increment" ->
                        D.succeed Increment

                    "Pulse" ->
                        D.map Pulse <|
                            D.field "value" D.int

                    "Alternate" ->
                        D.map2 Alternate
                            (D.field "low" D.int)
                            (D.field "high" D.int)

                    "Range" ->
                        D.map2 Range
                            (D.field "low" D.int)
                            (D.field "high" D.int)

                    _ ->
                        D.fail "Not a valid HeartBeatType"
            )


getHbTypeLabel : HeartBeatType -> String
getHbTypeLabel hbt =
    case hbt of
        Increment ->
            "Increment"

        Pulse value ->
            "Pulse (" ++ String.fromInt value ++ ")"

        Alternate low high ->
            "Alternate (" ++ String.fromInt low ++ ", " ++ String.fromInt high ++ ")"

        Range low high ->
            if low <= high then
                "Range (" ++ String.fromInt low ++ ", " ++ String.fromInt high ++ ")"

            else
                "Range (" ++ String.fromInt high ++ ", " ++ String.fromInt low ++ ")"



--------------------------------------------------------------------------------------------------
-- HeartBeat
--------------------------------------------------------------------------------------------------


type alias HeartBeat =
    { uid : Int
    , address : Int
    , interval : Int
    , selected : Bool
    , id : Int
    , hbType : HeartBeatType
    }


encodeHeartBeat : HeartBeat -> E.Value
encodeHeartBeat hb =
    E.object
        [ ( "uid", E.int hb.uid )
        , ( "address", E.int hb.address )
        , ( "interval", E.int hb.interval )
        , ( "id", E.int hb.id )
        , ( "type", encodeHeartBeatType hb.hbType )
        ]


decodeHeartBeat : D.Decoder HeartBeat
decodeHeartBeat =
    D.map6 HeartBeat
        (D.field "uid" D.int)
        (D.field "address" D.int)
        (D.field "interval" D.int)
        (D.succeed False)
        (D.field "id" D.int)
        (D.field "type" decodeHeartBeatType)


showFailedHeartBeat : HeartBeat -> String -> String
showFailedHeartBeat hb str =
    str
        ++ "Heartbeat: Address: "
        ++ String.fromInt hb.address
        ++ ", unit id: "
        ++ String.fromInt hb.uid
        ++ ", interval: "
        ++ String.fromInt hb.interval
        ++ "\n"


replaceHeartBeatSelected : Int -> Bool -> Int -> HeartBeat -> HeartBeat
replaceHeartBeatSelected idx flag =
    \i hb ->
        if i == idx then
            { hb | selected = flag }

        else
            hb



-- Returns the list of heartbeat ids corresponding to those heartbeats that are
-- selected


getSelectedIds : List HeartBeat -> List Int
getSelectedIds hbs =
    let
        getId hb ids =
            hb.id :: ids
    in
    List.foldl getId [] hbs



-- Filters a list of heartbeats based on their ids


fromIdList : List HeartBeat -> List Int -> List HeartBeat
fromIdList hbs ids =
    let
        f heartbeats id acc =
            List.filter (\hb -> hb.id == id) heartbeats ++ acc
    in
    List.foldr (f hbs) [] ids



--------------------------------------------------------------------------------------------------
-- Utils
--------------------------------------------------------------------------------------------------
-- diffList listA listB returns the difference between the two lists, namely all
-- items in listA that are not present in listB
-- Note: Only the first occurence of an item is considered, so
-- diffList [1,1] [1] will return [1]


diffList : List a -> List a -> List a
diffList =
    List.foldl deleteListElem



-- deleteListElem listA a deletes the first occurence of a in listA


deleteListElem : a -> List a -> List a
deleteListElem y xs =
    case List.head xs of
        Nothing ->
            []

        Just x ->
            if x == y then
                case List.tail xs of
                    Nothing ->
                        []

                    Just tail ->
                        tail

            else
                case List.tail xs of
                    Nothing ->
                        [ x ]

                    Just tail ->
                        x :: deleteListElem y tail
