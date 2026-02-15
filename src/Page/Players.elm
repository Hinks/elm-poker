module Page.Players exposing (Intent(..), PlayerEntry, ViewData, assignSeats, clearSeats, distributeIntoTables, hasSeatingEntries, seatsFromTables, shufflePlayers, view)

import Element
import Element.Background
import Element.Font
import Element.Input
import Html.Attributes
import Html.Events
import Icons
import Json.Decode as Decode
import Player exposing (Player(..))
import Random
import Theme exposing (Theme)



-- MODEL


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


type alias ViewData =
    { players : List PlayerEntry
    , initialBuyIn : Int
    , newPlayerName : String
    , playerListCollapsed : Bool
    }



-- UPDATE


type Intent
    = PlayerNameChanged String
    | InitialBuyInChanged String
    | AddPlayer
    | RemovePlayer Int
    | RandomizeSeating
    | ClearSeating
    | GotRandomSeed Int
    | TogglePlayerList


type alias Msg =
    Intent



-- VIEW


view : ViewData -> Theme -> Element.Element Intent
view viewData theme =
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
            [ viewInitialBuyInSection viewData colors
            , viewDivider colors
            , viewAddPlayerSection viewData colors
            , viewDivider colors
            , viewCurrentPlayersSection viewData colors
            , viewSeatingControls viewData colors
            , if hasSeatingEntries viewData.players then
                viewSeatingArrangement viewData.players colors

              else
                Element.none
            ]
        )


viewInitialBuyInSection : ViewData -> Theme.ColorPalette -> Element.Element Msg
viewInitialBuyInSection viewData colors =
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
                , text = String.fromInt viewData.initialBuyIn
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


viewAddPlayerSection : ViewData -> Theme.ColorPalette -> Element.Element Msg
viewAddPlayerSection viewData colors =
    let
        canAdd =
            canAddPlayer viewData
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
                , text = viewData.newPlayerName
                , placeholder = Just (Element.Input.placeholder [] (Element.text "Enter player name"))
                , label = Element.Input.labelHidden "Player name"
                }
            , viewCollapseExpandButton viewData colors
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


viewCurrentPlayersSection : ViewData -> Theme.ColorPalette -> Element.Element Msg
viewCurrentPlayersSection viewData colors =
    Element.column
        [ Element.width Element.fill
        , Element.spacing 10
        ]
        [ Element.text "Current Players:"
        , if List.isEmpty viewData.players then
            Element.el
                [ Element.Font.color colors.textSecondary
                , Element.Font.italic
                ]
                (Element.text "No players added yet.")

          else if viewData.playerListCollapsed then
            Element.el
                [ Element.Font.color colors.textSecondary
                , Element.Font.italic
                ]
                (Element.text (String.fromInt (List.length viewData.players) ++ " players"))

          else
            Element.column
                [ Element.width Element.fill
                , Element.spacing 8
                ]
                (List.indexedMap (\index player -> viewPlayerRow index player colors) viewData.players)
        ]


viewPlayerRow : Int -> PlayerEntry -> Theme.ColorPalette -> Element.Element Msg
viewPlayerRow index entry colors =
    let
        playerName =
            Player.getName entry.player
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


viewSeatingControls : ViewData -> Theme.ColorPalette -> Element.Element Msg
viewSeatingControls viewData colors =
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
                if List.isEmpty viewData.players || hasSeatingEntries viewData.players then
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
                if hasSeatingEntries viewData.players then
                    Just ClearSeating

                else
                    Nothing
            , label = Element.text "Clear Seating"
            }
        ]


viewSeatingArrangement : List PlayerEntry -> Theme.ColorPalette -> Element.Element Msg
viewSeatingArrangement players colors =
    let
        tables =
            seatingTables players
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
                    (List.map (\( tableNumber, tablePlayers ) -> viewTable tableNumber tablePlayers colors) tables)
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
            Player.getName player
    in
    Element.el
        [ Element.paddingXY 8 4
        , Element.Font.color colors.text
        ]
        (Element.text ("• " ++ playerName))


viewCollapseExpandButton : ViewData -> Theme.ColorPalette -> Element.Element Msg
viewCollapseExpandButton viewData colors =
    if not (List.isEmpty viewData.players) then
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
                        (if viewData.playerListCollapsed then
                            "↓"

                         else
                            "↑"
                        )
                    )
            }

    else
        Element.none



-- Helper functions (general utilities)


hasSeatingEntries : List PlayerEntry -> Bool
hasSeatingEntries players =
    List.any (\entry -> entry.seat /= Nothing) players


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

                    ( tableNumber, tablePlayers ) :: rest_ ->
                        if tableNumber == seat.table then
                            ( tableNumber, tablePlayers ++ [ player ] ) :: rest_

                        else
                            ( seat.table, [ player ] ) :: acc
            )
            []
        |> List.reverse


isPlayerNameUnique : String -> List PlayerEntry -> Bool
isPlayerNameUnique name players =
    let
        trimmedName =
            String.trim name

        existingNames =
            List.map (\entry -> Player.getName entry.player) players
    in
    not (List.member trimmedName existingNames)


canAddPlayer : ViewData -> Bool
canAddPlayer viewData =
    let
        trimmedName =
            String.trim viewData.newPlayerName
    in
    trimmedName /= "" && isPlayerNameUnique trimmedName viewData.players


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

                first :: rest_ ->
                    let
                        ( randomValue, newSeed ) =
                            Random.step (Random.float 0 1) currentSeed

                        ( restWithRandoms, finalSeed ) =
                            generateRandomNumbers rest_ newSeed
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

                        rest_ =
                            List.drop playersToTake remainingPlayers

                        newTable =
                            Table tablePlayers

                        newAcc =
                            newTable :: acc
                    in
                    distribute rest_ (tableIndex + 1) (remainingCount - 1) newAcc
    in
    distribute players 0 tablesNeeded []


onEnterPress : Intent -> Element.Attribute Intent
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


onEnterPressIf : Bool -> Intent -> Element.Attribute Intent
onEnterPressIf condition msg =
    if condition then
        onEnterPress msg

    else
        Element.htmlAttribute (Html.Attributes.class "")
