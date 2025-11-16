module Page.Players exposing (Model, Msg, init, update, view)

import Element
import Element.Background
import Element.Font
import Element.Input
import Html.Events
import Json.Decode as Decode
import Random
import Theme exposing (Theme)



-- MODEL


type alias Model =
    { pageName : String
    , players : List Player
    , newPlayerName : String
    , seatingArrangement : Maybe (List Table)
    }


type Player
    = Player String


type Table
    = Table (List Player)


init : Model
init =
    { pageName = "Players"
    , players = []
    , newPlayerName = ""
    , seatingArrangement = Nothing
    }



-- UPDATE


type Msg
    = PlayerNameChanged String
    | AddPlayer
    | RemovePlayer Int
    | RandomizeSeating
    | ClearSeating
    | GotRandomSeed Int


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

        RandomizeSeating ->
            if List.isEmpty model.players then
                ( model, Cmd.none )

            else
                ( model
                , Random.generate GotRandomSeed (Random.int 0 2147483647)
                )

        GotRandomSeed seed ->
            let
                shuffledPlayers =
                    shufflePlayers seed model.players

                tables =
                    distributeIntoTables shuffledPlayers
            in
            ( { model | seatingArrangement = Just tables }, Cmd.none )

        ClearSeating ->
            ( { model | seatingArrangement = Nothing }, Cmd.none )


shufflePlayers : Int -> List Player -> List Player
shufflePlayers seed players =
    let
        randomSeed =
            Random.initialSeed seed

        generateRandomNumbers : List Player -> Random.Seed -> ( List ( Float, Player ), Random.Seed )
        generateRandomNumbers remaining currentSeed =
            case remaining of
                [] ->
                    ( [], currentSeed )

                first :: rest ->
                    let
                        ( randomValue, newSeed ) =
                            Random.step (Random.float 0 1) currentSeed

                        ( restWithRandoms, finalSeed ) =
                            generateRandomNumbers rest newSeed
                    in
                    ( ( randomValue, first ) :: restWithRandoms, finalSeed )

        ( playersWithRandoms, _ ) =
            generateRandomNumbers players randomSeed
    in
    playersWithRandoms
        |> List.sortBy Tuple.first
        |> List.map Tuple.second


distributeIntoTables : List Player -> List Table
distributeIntoTables players =
    let
        playerCount =
            List.length players

        tablesNeeded =
            if playerCount < 6 then
                1

            else
                ceiling (toFloat playerCount / 8)

        playersPerTable =
            if playerCount < 6 then
                playerCount

            else
                playerCount // tablesNeeded

        remainder =
            if playerCount < 6 then
                0

            else
                modBy tablesNeeded playerCount

        distribute : List Player -> Int -> Int -> List Table -> List Table
        distribute remainingPlayers tableIndex remainingCount acc =
            case remainingPlayers of
                [] ->
                    List.reverse acc

                _ ->
                    let
                        playersToTake =
                            if tableIndex < remainder then
                                playersPerTable + 1

                            else
                                playersPerTable

                        tablePlayers =
                            List.take playersToTake remainingPlayers

                        rest =
                            List.drop playersToTake remainingPlayers

                        newTable =
                            Table tablePlayers

                        newAcc =
                            newTable :: acc
                    in
                    distribute rest (tableIndex + 1) (remainingCount - 1) newAcc
    in
    distribute players 0 tablesNeeded []



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
            , viewSeatingControls model colors
            , case model.seatingArrangement of
                Just tables ->
                    viewSeatingArrangement tables colors

                Nothing ->
                    Element.none
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


viewSeatingControls : Model -> Theme.ColorPalette -> Element.Element Msg
viewSeatingControls model colors =
    Element.row
        [ Element.width Element.fill
        , Element.spacing 10
        ]
        [ Element.Input.button
            [ Element.padding 8
            , Element.Background.color colors.primary
            , Element.Font.color colors.text
            ]
            { onPress =
                if List.isEmpty model.players || model.seatingArrangement /= Nothing then
                    Nothing

                else
                    Just RandomizeSeating
            , label = Element.text "Randomize Seating"
            }
        , Element.Input.button
            [ Element.padding 8
            , Element.Background.color colors.accent
            , Element.Font.color colors.text
            ]
            { onPress =
                if model.seatingArrangement == Nothing then
                    Nothing

                else
                    Just ClearSeating
            , label = Element.text "Clear Seating"
            }
        ]


viewSeatingArrangement : List Table -> Theme.ColorPalette -> Element.Element Msg
viewSeatingArrangement tables colors =
    Element.column
        [ Element.width Element.fill
        , Element.spacing 15
        ]
        [ Element.text "Seating Arrangement:"
        , Element.row
            [ Element.width Element.fill
            , Element.spacing 20
            , Element.alignTop
            ]
            (List.indexedMap (\index table -> viewTable (index + 1) table colors) tables)
        ]


viewTable : Int -> Table -> Theme.ColorPalette -> Element.Element Msg
viewTable tableNumber table colors =
    let
        players =
            case table of
                Table tablePlayers ->
                    tablePlayers
    in
    Element.column
        [ Element.width (Element.fillPortion 1)
        , Element.spacing 8
        , Element.padding 12
        , Element.Background.color colors.surface
        , Element.alignTop
        ]
        [ Element.el
            [ Element.Font.bold
            , Element.Font.size 16
            ]
            (Element.text ("TABLE " ++ String.fromInt tableNumber))
        , Element.column
            [ Element.width Element.fill
            , Element.spacing 4
            ]
            (List.map (\player -> viewSeatedPlayer player colors) players)
        ]


viewSeatedPlayer : Player -> Theme.ColorPalette -> Element.Element Msg
viewSeatedPlayer player colors =
    let
        playerName =
            case player of
                Player name ->
                    name
    in
    Element.el
        [ Element.paddingXY 8 4
        , Element.Font.color colors.text
        ]
        (Element.text ("• " ++ playerName))



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
