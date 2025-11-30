module Page.Players exposing (Model, Msg, Player, getPlayerName, init, roster, update, view)

import Element
import Element.Background
import Element.Font
import Element.Input
import Html.Attributes
import Html.Events
import Icons
import Json.Decode as Decode
import Random
import Theme exposing (Theme)



-- MODEL


type alias Model =
    { pageName : String
    , players : List PlayerEntry
    , newPlayerName : String
    , initialBuyIn : Int
    , playerListCollapsed : Bool
    }


type Player
    = Player String


type alias PlayerEntry =
    { player : Player
    , seat : Maybe TablePosition
    }


type Table
    = Table (List Player)


type alias TablePosition =
    { table : Int
    , position : Int
    }


init : Maybe Model -> Model
init maybeExistingModel =
    case maybeExistingModel of
        Just existingModel ->
            existingModel

        Nothing ->
            { pageName = "Players"
            , players = []
            , newPlayerName = ""
            , initialBuyIn = 0
            , playerListCollapsed = False
            }



-- UPDATE


type Msg
    = PlayerNameChanged String
    | InitialBuyInChanged String
    | AddPlayer
    | RemovePlayer Int
    | RandomizeSeating
    | ClearSeating
    | GotRandomSeed Int
    | TogglePlayerList


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PlayerNameChanged name ->
            ( { model | newPlayerName = name }, Cmd.none )

        InitialBuyInChanged buyInStr ->
            ( { model
                | initialBuyIn =
                    case String.toInt buyInStr of
                        Just buyIn ->
                            buyIn

                        Nothing ->
                            0
              }
            , Cmd.none
            )

        AddPlayer ->
            if not (canAddPlayer model) then
                ( model, Cmd.none )

            else
                let
                    newPlayer =
                        Player (String.trim model.newPlayerName)

                    newEntry =
                        { player = newPlayer
                        , seat = Nothing
                        }
                in
                ( { model
                    | players = model.players ++ [ newEntry ]
                    , newPlayerName = ""
                  }
                , Cmd.none
                )

        RemovePlayer index ->
            let
                updatedPlayers =
                    model.players
                        |> List.indexedMap Tuple.pair
                        |> List.filter (\( i, _ ) -> i /= index)
                        |> List.map Tuple.second
            in
            ( { model
                | players = updatedPlayers
              }
            , Cmd.none
            )

        RandomizeSeating ->
            if List.isEmpty model.players || hasSeating model then
                ( model, Cmd.none )

            else
                ( model
                , Random.generate GotRandomSeed (Random.int 0 2147483647)
                )

        GotRandomSeed seed ->
            let
                shuffledPlayers =
                    shufflePlayers seed (roster model)

                tables =
                    distributeIntoTables shuffledPlayers

                assignments =
                    seatsFromTables tables

                updatedPlayers =
                    assignSeats model.players assignments
            in
            ( { model
                | players = updatedPlayers
                , playerListCollapsed = True
              }
            , Cmd.none
            )

        TogglePlayerList ->
            ( { model | playerListCollapsed = not model.playerListCollapsed }, Cmd.none )

        ClearSeating ->
            ( { model
                | players = clearSeats model.players
                , playerListCollapsed = False
              }
            , Cmd.none
            )


isPlayerNameUnique : String -> List PlayerEntry -> Bool
isPlayerNameUnique name players =
    let
        trimmedName =
            String.trim name

        existingNames =
            List.map (\entry -> getPlayerName entry.player) players
    in
    not (List.member trimmedName existingNames)


canAddPlayer : Model -> Bool
canAddPlayer model =
    let
        trimmedName =
            String.trim model.newPlayerName
    in
    trimmedName /= "" && isPlayerNameUnique trimmedName model.players


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


getTablePlayerCount : Table -> Int
getTablePlayerCount table =
    case table of
        Table players ->
            List.length players



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
            [ viewInitialBuyInSection model colors
            , viewDivider colors
            , viewAddPlayerSection model colors
            , viewDivider colors
            , viewCurrentPlayersSection model colors
            , viewSeatingControls model colors
            , if hasSeating model then
                viewSeatingArrangement model colors

              else
                Element.none
            ]
        )


viewInitialBuyInSection : Model -> Theme.ColorPalette -> Element.Element Msg
viewInitialBuyInSection model colors =
    Element.column
        [ Element.width Element.fill
        , Element.spacing 10
        ]
        [ Element.text "Initial buy-in:"
        , Element.row
            [ Element.width Element.fill
            , Element.spacing 10
            , Element.alignLeft
            ]
            [ Element.Input.text
                [ Element.width (Element.px 200)
                , Element.padding 8
                , Element.Background.color colors.surface
                , Element.Font.color colors.text
                ]
                { onChange = InitialBuyInChanged
                , text = String.fromInt model.initialBuyIn
                , placeholder = Just (Element.Input.placeholder [] (Element.text "Enter initial buy-in amount"))
                , label = Element.Input.labelHidden "Initial buy-in amount"
                }
            , Element.html
                (Icons.strawberry
                    { size = 32.0
                    , color = colors.removeButton
                    }
                )
            ]
        ]


viewAddPlayerSection : Model -> Theme.ColorPalette -> Element.Element Msg
viewAddPlayerSection model colors =
    let
        canAdd =
            canAddPlayer model
    in
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
                , onEnterPressIf canAdd AddPlayer
                ]
                { onChange = PlayerNameChanged
                , text = model.newPlayerName
                , placeholder = Just (Element.Input.placeholder [] (Element.text "Enter player name"))
                , label = Element.Input.labelHidden "Player name"
                }
            , viewCollapseExpandButton model colors
            , Element.Input.button
                [ Element.padding 8
                , Element.width (Element.fillPortion 1)
                , Element.Background.color
                    (if canAdd then
                        colors.primary

                     else
                        colors.surface
                    )
                , Element.Font.color
                    (if canAdd then
                        colors.text

                     else
                        colors.textSecondary
                    )
                ]
                { onPress =
                    if canAdd then
                        Just AddPlayer

                    else
                        Nothing
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

          else if model.playerListCollapsed then
            Element.el
                [ Element.Font.color colors.textSecondary
                , Element.Font.italic
                ]
                (Element.text (String.fromInt (List.length model.players) ++ " players"))

          else
            Element.column
                [ Element.width Element.fill
                , Element.spacing 8
                ]
                (List.indexedMap (\index player -> viewPlayerRow index player colors) model.players)
        ]


viewPlayerRow : Int -> PlayerEntry -> Theme.ColorPalette -> Element.Element Msg
viewPlayerRow index entry colors =
    let
        playerName =
            getPlayerName entry.player
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
            , Element.Font.color colors.buttonText
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
            , Element.Font.color colors.buttonText
            ]
            { onPress =
                if List.isEmpty model.players || hasSeating model then
                    Nothing

                else
                    Just RandomizeSeating
            , label = Element.text "Randomize Seating"
            }
        , Element.Input.button
            [ Element.padding 8
            , Element.Background.color colors.accent
            , Element.Font.color colors.buttonText
            ]
            { onPress =
                if hasSeating model then
                    Just ClearSeating

                else
                    Nothing
            , label = Element.text "Clear Seating"
            }
        ]


viewSeatingArrangement : Model -> Theme.ColorPalette -> Element.Element Msg
viewSeatingArrangement model colors =
    let
        tables =
            seatingTables model.players
    in
    case tables of
        [] ->
            Element.none

        _ ->
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
                    (List.map (\( tableNumber, players ) -> viewTable tableNumber players colors) tables)
                ]


viewTable : Int -> List Player -> Theme.ColorPalette -> Element.Element Msg
viewTable tableNumber players colors =
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
            getPlayerName player
    in
    Element.el
        [ Element.paddingXY 8 4
        , Element.Font.color colors.text
        ]
        (Element.text ("• " ++ playerName))


viewCollapseExpandButton : Model -> Theme.ColorPalette -> Element.Element Msg
viewCollapseExpandButton model colors =
    if not (List.isEmpty model.players) then
        Element.Input.button
            [ Element.padding 4
            , Element.width (Element.px 40)
            , Element.height (Element.px 40)
            , Element.Background.color colors.primary
            , Element.Font.color colors.buttonText
            ]
            { onPress = Just TogglePlayerList
            , label =
                Element.el
                    [ Element.centerX
                    , Element.centerY
                    ]
                    (Element.text
                        (if model.playerListCollapsed then
                            "↓"

                         else
                            "↑"
                        )
                    )
            }

    else
        Element.none



-- Helper functions (general utilities)


hasSeating : Model -> Bool
hasSeating model =
    List.any (\entry -> entry.seat /= Nothing) model.players


roster : Model -> List Player
roster model =
    List.map (\entry -> entry.player) model.players


clearSeats : List PlayerEntry -> List PlayerEntry
clearSeats =
    List.map (\entry -> { entry | seat = Nothing })


assignSeats : List PlayerEntry -> List ( Player, TablePosition ) -> List PlayerEntry
assignSeats entries assignments =
    List.map
        (\entry ->
            { entry
                | seat = seatForPlayer entry.player assignments
            }
        )
        entries


seatForPlayer : Player -> List ( Player, TablePosition ) -> Maybe TablePosition
seatForPlayer player assignments =
    assignments
        |> List.filter (\( assignedPlayer, _ ) -> assignedPlayer == player)
        |> List.head
        |> Maybe.map Tuple.second


seatsFromTables : List Table -> List ( Player, TablePosition )
seatsFromTables tables =
    tables
        |> List.indexedMap
            (\tableIndex table ->
                case table of
                    Table tablePlayers ->
                        tablePlayers
                            |> List.indexedMap
                                (\playerIndex player ->
                                    ( player
                                    , { table = tableIndex + 1, position = playerIndex + 1 }
                                    )
                                )
            )
        |> List.concat


seatingTables : List PlayerEntry -> List ( Int, List Player )
seatingTables entries =
    let
        assignments =
            entries
                |> List.filterMap
                    (\entry ->
                        Maybe.map (\seat -> ( seat, entry.player )) entry.seat
                    )
                |> List.sortBy (\( seat, _ ) -> ( seat.table, seat.position ))
    in
    assignments
        |> List.foldl
            (\( seat, player ) acc ->
                case acc of
                    [] ->
                        [ ( seat.table, [ player ] ) ]

                    ( tableNumber, tablePlayers ) :: rest ->
                        if tableNumber == seat.table then
                            ( tableNumber, tablePlayers ++ [ player ] ) :: rest

                        else
                            ( seat.table, [ player ] ) :: acc
            )
            []
        |> List.reverse


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


onEnterPressIf : Bool -> Msg -> Element.Attribute Msg
onEnterPressIf condition msg =
    if condition then
        onEnterPress msg

    else
        Element.htmlAttribute (Html.Attributes.class "")


getPlayerName : Player -> String
getPlayerName player =
    case player of
        Player name ->
            name
