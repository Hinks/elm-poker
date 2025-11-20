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
    Element.text ""
