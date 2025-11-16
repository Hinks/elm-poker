module Page.Players exposing (Model, Msg, init, update, view)

import Element
import Element.Background
import Element.Font
import Element.Input
import Html.Events
import Json.Decode as Decode
import Theme exposing (Theme)



-- MODEL


type alias Model =
    { pageName : String
    , players : List Player
    , newPlayerName : String
    }


type Player
    = Player String


init : Model
init =
    { pageName = "Players"
    , players = []
    , newPlayerName = ""
    }



-- UPDATE


type Msg
    = PlayerNameChanged String
    | AddPlayer
    | RemovePlayer Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PlayerNameChanged name ->
            ( { model | newPlayerName = name }, Cmd.none )

        AddPlayer ->
            if String.trim model.newPlayerName == "" then
                ( model, Cmd.none )

            else
                ( { model
                    | players = model.players ++ [ Player (String.trim model.newPlayerName) ]
                    , newPlayerName = ""
                  }
                , Cmd.none
                )

        RemovePlayer index ->
            ( { model
                | players =
                    model.players
                        |> List.indexedMap Tuple.pair
                        |> List.filter (\( i, _ ) -> i /= index)
                        |> List.map Tuple.second
              }
            , Cmd.none
            )



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
        , Element.Font.color colors.text
        ]
        (Element.column
            [ Element.width Element.fill
            , Element.spacing 20
            ]
            [ viewAddPlayerSection model colors
            , viewDivider colors
            , viewCurrentPlayersSection model colors
            ]
        )


viewAddPlayerSection : Model -> Theme.ColorPalette -> Element.Element Msg
viewAddPlayerSection model colors =
    Element.column
        [ Element.width Element.fill
        , Element.spacing 10
        ]
        [ Element.text "Add a player:"
        , Element.row
            [ Element.width Element.fill
            , Element.spacing 10
            ]
            [ Element.Input.text
                [ Element.width (Element.fillPortion 3)
                , Element.padding 8
                , Element.Background.color colors.surface
                , Element.Font.color colors.text
                , onEnterPress AddPlayer
                ]
                { onChange = PlayerNameChanged
                , text = model.newPlayerName
                , placeholder = Just (Element.Input.placeholder [] (Element.text "Enter player name"))
                , label = Element.Input.labelHidden "Player name"
                }
            , Element.Input.button
                [ Element.padding 8
                , Element.width (Element.fillPortion 1)
                , Element.Background.color colors.primary
                , Element.Font.color colors.text
                ]
                { onPress = Just AddPlayer
                , label = Element.text "Add"
                }
            ]
        ]


viewDivider : Theme.ColorPalette -> Element.Element Msg
viewDivider colors =
    Element.el
        [ Element.width Element.fill
        , Element.height (Element.px 1)
        , Element.Background.color colors.border
        ]
        Element.none


viewCurrentPlayersSection : Model -> Theme.ColorPalette -> Element.Element Msg
viewCurrentPlayersSection model colors =
    Element.column
        [ Element.width Element.fill
        , Element.spacing 10
        ]
        [ Element.text "Current Players:"
        , if List.isEmpty model.players then
            Element.el
                [ Element.Font.color colors.textSecondary
                , Element.Font.italic
                ]
                (Element.text "No players added yet.")

          else
            Element.column
                [ Element.width Element.fill
                , Element.spacing 8
                ]
                (List.indexedMap (\index player -> viewPlayerRow index player colors) model.players)
        ]


viewPlayerRow : Int -> Player -> Theme.ColorPalette -> Element.Element Msg
viewPlayerRow index player colors =
    let
        playerName =
            case player of
                Player name ->
                    name
    in
    Element.row
        [ Element.width Element.fill
        , Element.spacing 10
        ]
        [ Element.el
            [ Element.width Element.fill
            ]
            (Element.text ("- " ++ playerName))
        , Element.Input.button
            [ Element.padding 8
            , Element.Background.color colors.accent
            , Element.Font.color colors.text
            ]
            { onPress = Just (RemovePlayer index)
            , label = Element.text "Remove"
            }
        ]



-- Helper functions (general utilities)


onEnterPress : Msg -> Element.Attribute Msg
onEnterPress msg =
    Element.htmlAttribute
        (Html.Events.on "keydown"
            (Decode.field "key" Decode.string
                |> Decode.andThen
                    (\key ->
                        if key == "Enter" then
                            Decode.succeed msg

                        else
                            Decode.fail "Not Enter key"
                    )
            )
        )
