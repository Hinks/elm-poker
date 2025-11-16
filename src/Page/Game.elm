module Page.Game exposing (Model, Msg, init, update, view)

import Element
import Element.Font as Font
import Icons
import Theme exposing (Theme)



-- MODEL


type alias Model =
    { pageName : String
    , chips : List Chip
    }


type ChipColor
    = White
    | Red
    | Blue
    | Green
    | Black


type Chip
    = Chip ChipColor Int


init : Model
init =
    { pageName = "Game"
    , chips = [ Chip White 50, Chip Red 100, Chip Blue 200, Chip Green 250, Chip Black 500 ]
    }


chipColorToElementColor : ChipColor -> Element.Color
chipColorToElementColor chipColor =
    case chipColor of
        White ->
            Element.rgb255 255 255 255

        Red ->
            Element.rgb255 220 20 60

        Blue ->
            Element.rgb255 30 144 255

        Green ->
            Element.rgb255 34 139 34

        Black ->
            Element.rgb255 0 0 0



-- UPDATE


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Theme -> Element.Element Msg
view model theme =
    let
        colors =
            Theme.getColors theme
    in
    Element.el
        [ Element.width Element.fill
        , Element.padding 20
        , Font.color colors.text
        ]
        (Element.column
            [ Element.width Element.fill
            , Element.spacing 20
            ]
            [ Element.text ("Game Content - " ++ model.pageName)
            , viewChips model.chips colors
            ]
        )


viewChips : List Chip -> Theme.ColorPalette -> Element.Element Msg
viewChips chips colors =
    Element.row
        [ Element.width Element.fill
        , Element.spacing 20
        , Element.centerX
        ]
        (List.map (\chip -> viewChip chip colors) chips)


viewChip : Chip -> Theme.ColorPalette -> Element.Element Msg
viewChip chip colors =
    let
        ( chipColor, value ) =
            case chip of
                Chip color val ->
                    ( color, val )

        chipElementColor =
            chipColorToElementColor chipColor

        chipSize =
            80.0

        spinSpeed =
            3.0
    in
    Element.column
        [ Element.spacing 10
        , Element.centerX
        ]
        [ Element.html
            (Icons.pokerChip
                { size = chipSize
                , color = chipElementColor
                , spinSpeed = spinSpeed
                }
            )
        , Element.el
            [ Element.centerX
            , Font.color colors.text
            ]
            (Element.text (String.fromInt value))
        ]
