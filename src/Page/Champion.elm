module Page.Champion exposing (Model, Msg, init, update, view)

import Element
import Element.Font as Font
import Icons
import Theme exposing (Theme)



-- MODEL


type alias Model =
    { pageName : String
    }


init : Model
init =
    { pageName = "Champion"
    }



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

        blindSize =
            150.0

        bigBlindOptions =
            { size = blindSize
            , backgroundColor = colors.primary
            , labelTextColor = colors.chipTextOnDark
            , valueTextColor = colors.chipTextOnDark
            , value = 100
            }

        smallBlindOptions =
            { size = blindSize
            , backgroundColor = colors.accent
            , labelTextColor = colors.chipTextOnDark
            , valueTextColor = colors.chipTextOnDark
            , value = 50
            }
    in
    Element.column
        [ Element.width Element.fill
        , Element.padding 20
        , Element.spacing 30
        , Font.color colors.text
        ]
        [ Element.text ("Champion Content - " ++ model.pageName)
        , Element.row
            [ Element.spacing 40
            , Element.centerX
            , Element.centerY
            ]
            [ Element.column
                [ Element.spacing 10
                , Element.alignTop
                ]
                [ Element.el
                    [ Font.size 18
                    , Font.bold
                    , Font.color colors.text
                    ]
                    (Element.text "Big Blind")
                , Element.html (Icons.bigBlind bigBlindOptions)
                ]
            , Element.column
                [ Element.spacing 10
                , Element.alignTop
                ]
                [ Element.el
                    [ Font.size 18
                    , Font.bold
                    , Font.color colors.text
                    ]
                    (Element.text "Small Blind")
                , Element.html (Icons.smallBlind smallBlindOptions)
                ]
            ]
        ]
