module RegisterTab exposing (renderRegistersTab)

import Dropdown exposing (dropdown)
import Element
    exposing
        ( Element
        , alignTop
        , fill
        , paddingXY
        , px
        , row
        , spacing
        , text
        , width
        , fill
        , indexedTable
        , IndexedColumn
        , column
        )
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import ModData exposing (getModValueUpdate)
import Palette exposing (blueSapphire, fireBrick, greyWhite, lightGrey)
import ReadWrite
    exposing
        ( ReadWrite(..)
        , flipRW
        , readWriteButton
        )
import Types
    exposing
        ( Model
        , Msg(..)
        )
import ModData exposing
    ( ModDataUpdate
    , modRegTypeColumn
    , modAddressColumn
    , modValueTypeColumn
    , modValueColumn
    , modUidColumn
    )

import Palette exposing (lightGrey, greyWhite)

renderRegistersTab : Model -> Element Msg
renderRegistersTab model =
    column
        [ alignTop

        ]
        [ renderInputBar model
        , renderOutput model.regResponse
        ]
renderInputBar : Model -> Element Msg
renderInputBar model =
    row
        [ spacing 20
        , paddingXY 20 20
        ]
    <|
        [ text "Register type: "
        , dropdown
            []
            model.regTypeDd
        , text "Address"
        , Input.text
            [ width <| px 100 ]
            { onChange = RegAddress
            , text = Maybe.withDefault "" <| Maybe.map String.fromInt model.regAddress
            , placeholder = Nothing
            , label = Input.labelHidden "Register Address"
            }
        , text "Value Type"
        , dropdown
            []
            model.valueTypeDd
        , text "Unit id"
        , Input.text
            [ width <| px 100 ]
            { onChange = RegUid
            , text = Maybe.withDefault "" <| Maybe.map String.fromInt model.regUid
            , placeholder = Nothing
            , label = Input.labelHidden "Unit Id"
            }
        , readWriteButton
            model.regMdu.mduRW
            blueSapphire
            fireBrick
          <|
            Just <|
                RegToggleRW <|
                    flipRW model.regMdu.mduRW
        , regNumInput model
        , Input.button
            [ Background.color lightGrey
            , width fill
            , Font.center
            , Font.color greyWhite
            , paddingXY 0 10
            ]
            { onPress = Just UpdateRegMdu
            , label = text "Update"
            }
        ]


regNumInput : Model -> Element Msg
regNumInput model =
    case model.regMdu.mduRW of
        Read ->
            Input.text
                [ width <| px 100 ]
                { onChange = RegNumber
                , text = Maybe.withDefault "" <| Maybe.map String.fromInt model.regNumReg
                , placeholder = Nothing
                , label = Input.labelLeft [] <| text "Number of registers"
                }

        Write ->
            Input.text
                [ width <| px 100 ]
                { onChange = RegModValue
                , text = Maybe.withDefault "" <| getModValueUpdate model.regMdu
                , placeholder = Nothing
                , label = Input.labelLeft [] <| text "Value"
                }

renderOutput : List ModDataUpdate -> Element Msg
renderOutput mdus =
    indexedTable
        []
        { data = mdus
        , columns = responseColumns mdus
        }

responseColumns : List ModDataUpdate -> List (IndexedColumn ModDataUpdate Msg)
responseColumns mdus =
    [ modRegTypeColumn
    , modAddressColumn
    , modValueTypeColumn
    , modValueColumn Nothing
    , modUidColumn
    ]

