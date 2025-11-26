module Page.Players exposing (Model, Msg, Player, getPlayerName, init, update, view)

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
    , players : List Player
    , newPlayerName : String
    , initialBuyIn : Int
    , seatingArrangement : Maybe (List Table)
    , playerListCollapsed : Bool
    }


type Player
    = Player String


type Table
    = Table (List Player)


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
            , seatingArrangement = Nothing
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

                    updatedPlayers =
                        model.players ++ [ newPlayer ]

                    updatedSeatingArrangement =
                        Maybe.map (addPlayerToSeatingArrangement newPlayer) model.seatingArrangement
                in
                ( { model
                    | players = updatedPlayers
                    , newPlayerName = ""
                    , seatingArrangement = updatedSeatingArrangement
                  }
                , Cmd.none
                )

        RemovePlayer index ->
            let
                playerToRemove =
                    model.players
                        |> List.drop index
                        |> List.head

                updatedPlayers =
                    model.players
                        |> List.indexedMap Tuple.pair
                        |> List.filter (\( i, _ ) -> i /= index)
                        |> List.map Tuple.second

                updatedSeatingArrangement =
                    case ( playerToRemove, model.seatingArrangement ) of
                        ( Just player, Just tables ) ->
                            let
                                updatedTables =
                                    removePlayerFromSeatingArrangement player tables
                            in
                            if List.isEmpty updatedTables then
                                Nothing

                            else
                                Just updatedTables

                        _ ->
                            model.seatingArrangement
            in
            ( { model
                | players = updatedPlayers
                , seatingArrangement = updatedSeatingArrangement
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
            ( { model
                | seatingArrangement = Just tables
                , playerListCollapsed = True
              }
            , Cmd.none
            )

        TogglePlayerList ->
            ( { model | playerListCollapsed = not model.playerListCollapsed }, Cmd.none )

        ClearSeating ->
            ( { model
                | seatingArrangement = Nothing
                , playerListCollapsed = False
              }
            , Cmd.none
            )


isPlayerNameUnique : String -> List Player -> Bool
isPlayerNameUnique name players =
    let
        trimmedName =
            String.trim name

        extractPlayerName : Player -> String
        extractPlayerName player =
            case player of
                Player playerName ->
                    playerName

        existingNames =
            List.map extractPlayerName players
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


addPlayerToTable : Player -> Table -> Table
addPlayerToTable player table =
    case table of
        Table players ->
            Table (players ++ [ player ])


removePlayerFromTable : Player -> Table -> Table
removePlayerFromTable playerToRemove table =
    case table of
        Table players ->
            Table (List.filter (\player -> player /= playerToRemove) players)


findTableWithLeastPlayersIndex : List Table -> Int
findTableWithLeastPlayersIndex tables =
    let
        indexedTables =
            List.indexedMap Tuple.pair tables

        findMinIndex : List ( Int, Table ) -> Int -> Int -> Int
        findMinIndex remaining currentIndex minCount =
            case remaining of
                [] ->
                    currentIndex

                ( index, table ) :: rest ->
                    let
                        count =
                            getTablePlayerCount table
                    in
                    if count < minCount then
                        findMinIndex rest index count

                    else
                        findMinIndex rest currentIndex minCount
    in
    case indexedTables of
        [] ->
            0

        ( firstIndex, firstTable ) :: rest ->
            findMinIndex rest firstIndex (getTablePlayerCount firstTable)


addPlayerToSeatingArrangement : Player -> List Table -> List Table
addPlayerToSeatingArrangement player tables =
    let
        targetIndex =
            findTableWithLeastPlayersIndex tables

        updateTableAtIndex : Int -> List Table -> List Table
        updateTableAtIndex targetIdx remaining =
            case remaining of
                [] ->
                    []

                table :: rest ->
                    if targetIdx == 0 then
                        addPlayerToTable player table :: rest

                    else
                        table :: updateTableAtIndex (targetIdx - 1) rest
    in
    updateTableAtIndex targetIndex tables


removePlayerFromSeatingArrangement : Player -> List Table -> List Table
removePlayerFromSeatingArrangement playerToRemove tables =
    tables
        |> List.map (removePlayerFromTable playerToRemove)
        |> List.filter (\table -> getTablePlayerCount table > 0)



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
            , case model.seatingArrangement of
                Just tables ->
                    viewSeatingArrangement tables colors

                Nothing ->
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
                    , color = Element.rgb255 232 67 63
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


viewCollapseExpandButton : Model -> Theme.ColorPalette -> Element.Element Msg
viewCollapseExpandButton model colors =
    if not (List.isEmpty model.players) then
        Element.Input.button
            [ Element.padding 4
            , Element.width (Element.px 40)
            , Element.height (Element.px 40)
            , Element.Background.color colors.primary
            , Element.Font.color colors.text
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
