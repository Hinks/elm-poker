module Page.Home exposing (Model, Msg, init, update, view)

import Element exposing (rgb255)
import Element.Font as Font
import Icons
import Theme exposing (Theme)



-- MODEL


type alias Model =
    { pageName : String
    }


init : Model
init =
    { pageName = "Home"
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
    in
    Element.column
        [ Font.color colors.text ]
        [ Element.text ("Home Content - " ++ model.pageName)
        , Element.html (Icons.pokerChip { size = 256, color = rgb255 0 170 0, spinSpeed = 3 })
        ]
