module HeartBeat exposing
    ( hbTypeDropDown
    , heartBeatInfoModule
    , heartBeatNav
    , updateSelectedHbType
    )

import Dropdown exposing (Dropdown, Option, getOption)
import Element
    exposing
        ( Attribute
        , Color
        , Element
        , IndexedColumn
        , alignLeft
        , centerX
        , centerY
        , column
        , el
        , fill
        , fillPortion
        , height
        , indexedTable
        , none
        , paddingXY
        , px
        , spacing
        , text
        , width
        )
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import Json.Encode exposing (Value)
import NavigationModule
    exposing
        ( navButton
        , navDd
        , navInput
        )
import Palette exposing (background, grey, greyWhite, lightGrey)
import Types
    exposing
        ( HeartBeat
        , HeartBeatType(..)
        , Model
        , Msg(..)
        , getHbTypeLabel
        )


heartBeatNav : Model -> Element Msg
heartBeatNav model =
    column
        [ Background.color background
        , width fill
        , height fill
        , spacing 10
        ]
        [ navUid model
        , navAddress model
        , navInterval model
        , navDd "Type" model.hbTypeDd
        , navLow model
        , navHigh model
        , startButton
        , stopButton
        ]


navUid : Model -> Element Msg
navUid model =
    navInput "Unit id" HeartUid <| Maybe.map String.fromInt model.heartUid


navAddress : Model -> Element Msg
navAddress model =
    navInput "Address" HeartAddress <| Maybe.map String.fromInt model.heartAddr


navInterval : Model -> Element Msg
navInterval model =
    navInput "Interval" HeartInterval <| Maybe.map String.fromInt model.heartIntv


navLow : Model -> Element Msg
navLow model =
    case model.hbTypeDd.selected.value of
        Increment ->
            none

        Pulse _ ->
            navInput "Value" HBLow <| Maybe.map String.fromInt model.hbLow

        Alternate _ _ ->
            navInput "First" HBLow <| Maybe.map String.fromInt model.hbLow

        Range _ _ ->
            navInput "Low" HBLow <| Maybe.map String.fromInt model.hbLow


navHigh : Model -> Element Msg
navHigh model =
    case model.hbTypeDd.selected.value of
        Increment ->
            none

        Pulse _ ->
            none

        Alternate _ _ ->
            navInput "Second" HBHigh <| Maybe.map String.fromInt model.hbHigh

        Range _ _ ->
            navInput "High" HBHigh <| Maybe.map String.fromInt model.hbHigh


startButton : Element Msg
startButton =
    navButton "Start" (Just StartHeartBeat)


stopButton : Element Msg
stopButton =
    navButton "Stop" (Just StopHeartBeat)


heartBeatInfoModule : Model -> Element Msg
heartBeatInfoModule model =
    indexedTable
        []
        { data = model.heartbeats
        , columns = heartbeatColumns model
        }


heartbeatColumns : Model -> List (IndexedColumn HeartBeat Msg)
heartbeatColumns model =
    [ selectColumn model
    , uidColumn
    , addressColumn
    , intervalColumn
    , typeColumn
    ]


uidColumn : IndexedColumn HeartBeat Msg
uidColumn =
    { header = el [ height <| px 38 ] <| el headerTextAttr <| text "Unit Id"
    , width = fillPortion 1
    , view = \i hb -> viewCell i <| String.fromInt hb.uid
    }


addressColumn : IndexedColumn HeartBeat Msg
addressColumn =
    { header = el [ height <| px 38 ] <| el headerTextAttr <| text "Address"
    , width = fillPortion 1
    , view = \i hb -> viewCell i <| String.fromInt hb.address
    }


intervalColumn : IndexedColumn HeartBeat Msg
intervalColumn =
    { header = el [ height <| px 38 ] <| el headerTextAttr <| text "Interval"
    , width = fillPortion 1
    , view = \i hb -> viewCell i <| String.fromInt hb.interval
    }

typeColumn : IndexedColumn HeartBeat Msg
typeColumn =
    { header = el [ height <| px 38 ] <| el headerTextAttr <| text "Type"
    , width = fillPortion 1
    , view = \i hb -> viewCell i <| getHbTypeLabel hb.hbType
    }


headerTextAttr : List (Attribute msg)
headerTextAttr =
    [ centerX, centerY ]


viewCell : Int -> String -> Element msg
viewCell idx str =
    el
        [ Background.color <| tableCellColor idx
        , Font.color greyWhite
        , height <| px 38
        , Font.center
        ]
        (el [ centerX, centerY ] <| text str)


tableCellColor : Int -> Color
tableCellColor idx =
    if modBy 2 idx == 0 then
        lightGrey

    else
        grey


selectColumn : Model -> IndexedColumn HeartBeat Msg
selectColumn model =
    { header =
        el
            [ height <| px 38
            , paddingXY 10 0
            ]
        <|
            selectCheckbox SelectAllChecked model.heartSelectAll
    , width = px 30
    , view = \i hb -> viewCheckedCell i hb.selected
    }


selectCheckbox : (Bool -> Msg) -> Bool -> Element Msg
selectCheckbox msg flag =
    Input.checkbox
        [ alignLeft
        , centerY
        ]
        { onChange = msg
        , icon = Input.defaultCheckbox
        , checked = flag
        , label = Input.labelHidden "Select Checkbox"
        }


viewCheckedCell : Int -> Bool -> Element Msg
viewCheckedCell idx selected =
    el
        [ Background.color <| tableCellColor idx
        , Font.color greyWhite
        , height <| px 38
        , Font.center
        , paddingXY 10 0
        ]
    <|
        selectCheckbox (HeartBeatChecked idx) selected



----------------------------------------------------------------------------------------------------------------------------------
-- HeartBeatType Dropdowns
----------------------------------------------------------------------------------------------------------------------------------


hbTypeDropDown : Int -> Int -> Bool -> Dropdown HeartBeatType Msg
hbTypeDropDown low high flag =
    { onClick = HeartBeatTypeDrop
    , options = [ increment, pulse low, alternate low high, range low high ]
    , selected = increment
    , expanded = flag
    , label = ""
    }



-- update selected option on a heartbeattype dropdown


updateSelectedHbType : Maybe Int -> Maybe Int -> Option HeartBeatType Msg -> Option HeartBeatType Msg
updateSelectedHbType mlow mhigh opt =
    let
        mpair =
            Maybe.map2 Tuple.pair
                mlow
                mhigh
    in
    case opt.value of
        Increment ->
            opt

        -- only check low value
        Pulse _ ->
            case mlow of
                Nothing ->
                    opt

                Just low ->
                    pulse low

        Alternate _ _ ->
            case mpair of
                Nothing ->
                    opt

                Just ( low, high ) ->
                    alternate low high

        Range _ _ ->
            case mpair of
                Nothing ->
                    opt

                Just ( low, high ) ->
                    range low high


increment : Option HeartBeatType Msg
increment =
    getOption Increment (text "Increment")


pulse : Int -> Option HeartBeatType Msg
pulse value =
    getOption (Pulse value) (text "Pulse")


alternate : Int -> Int -> Option HeartBeatType Msg
alternate low high =
    getOption (Alternate low high) (text "Alternate")


range : Int -> Int -> Option HeartBeatType Msg
range low high =
    getOption (Range low high) (text "Range")
