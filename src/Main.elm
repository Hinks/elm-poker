module Main exposing (main)

import Browser exposing (UrlRequest)
import Element
import Url exposing (Url)


type alias Model =
    { value : String }


type Msg
    = NoOp


init : Model
init =
    { value = "Hello, World cool" }


view : Model -> Browser.Document Msg
view model =
    { title = "My App"
    , body = [ Element.layout [] (Element.text model.value) ]
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


onUrlRequest : UrlRequest -> Msg
onUrlRequest urlRequest =
    NoOp


onUrlChange : Url -> Msg
onUrlChange url =
    NoOp


main : Program () Model Msg
main =
    Browser.application
        { init = \flags url key -> ( init, Cmd.none )
        , onUrlRequest = onUrlRequest
        , onUrlChange = onUrlChange
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
