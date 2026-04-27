module Page.Champion exposing (Intent(..), ViewData, WinnerFlow(..), addWinner, canAddWinner, removeWinner, selectDivision, view)

import Element
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import Player exposing (Player)
import Theme exposing (Theme)



-- MODEL


type PotDivision
    = WinnerTakesAll
    | FirstSecond
    | FirstSecondThird


type alias Winner =
    { player : Player
    , phoneNumber : String
    , position : Int
    }


type WinnerFlow
    = AwaitingDivision
    | DivisionSelected SelectionState


type alias SelectionState =
    { division : PotDivision
    , winners : List Winner
    }


type alias ViewData =
    { winnerFlow : WinnerFlow
    , players : List Player
    , totalPot : Int
    , buyInPlayers : List Player
    , initialBuyIn : Int
    , rebuyAmount : Int
    }


positionsFor : PotDivision -> List Int
positionsFor division =
    case division of
        WinnerTakesAll ->
            [ 1 ]

        FirstSecond ->
            [ 1, 2 ]

        FirstSecondThird ->
            [ 1, 2, 3 ]


selectDivision : PotDivision -> WinnerFlow -> WinnerFlow
selectDivision division flow =
    let
        existingWinners =
            case flow of
                DivisionSelected state ->
                    state.winners

                AwaitingDivision ->
                    []

        trimmedWinners =
            existingWinners
                |> List.take (List.length (positionsFor division))
                |> List.indexedMap
                    (\idx winner ->
                        { winner | position = idx + 1 }
                    )
    in
    DivisionSelected
        { division = division
        , winners = trimmedWinners
        }


availablePositions : SelectionState -> List Int
availablePositions state =
    positionsFor state.division
        |> List.filter
            (\pos ->
                not (List.any (\winner -> winner.position == pos) state.winners)
            )


canAddWinner : SelectionState -> Player -> Int -> Bool
canAddWinner state player position =
    not (List.any (\winner -> winner.player == player) state.winners)
        && List.member position (availablePositions state)


addWinner : SelectionState -> Player -> Int -> SelectionState
addWinner state player position =
    let
        newWinner =
            { player = player
            , phoneNumber = ""
            , position = position
            }
    in
    { state | winners = state.winners ++ [ newWinner ] }


removeWinner : SelectionState -> Player -> SelectionState
removeWinner state player =
    let
        updatedWinners =
            state.winners
                |> List.filter (\winner -> winner.player /= player)
                |> List.indexedMap
                    (\idx winner ->
                        { winner | position = idx + 1 }
                    )
    in
    { state | winners = updatedWinners }


isDivisionSelected : WinnerFlow -> PotDivision -> Bool
isDivisionSelected flow division =
    case flow of
        DivisionSelected state ->
            state.division == division

        AwaitingDivision ->
            False



-- UPDATE


type Intent
    = PotDivisionSelected PotDivision
    | WinnerSelected Player Int
    | WinnerRemoved Player
    | PhoneNumberChanged Player String
    | ClearWinners


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
        , Font.color colors.text
        ]
        (Element.column
            [ Element.width Element.fill
            , Element.spacing 20
            ]
            [ viewPotDivisionSelector viewData.winnerFlow colors
            , viewDivider colors
            , viewWinnerSelection viewData colors
            , viewDivider colors
            , viewPaymentCalculations viewData colors
            ]
        )


viewDivider : Theme.ColorPalette -> Element.Element Msg
viewDivider colors =
    Element.el
        [ Element.width Element.fill
        , Element.height (Element.px 1)
        , Background.color colors.border
        ]
        Element.none


viewPotDivisionSelector : WinnerFlow -> Theme.ColorPalette -> Element.Element Msg
viewPotDivisionSelector winnerFlow colors =
    Element.column
        [ Element.width Element.fill
        , Element.spacing 10
        ]
        [ Element.el
            [ Font.size 18
            , Font.bold
            ]
            (Element.text "Pot Division:")
        , Element.column
            [ Element.width Element.fill
            , Element.spacing 10
            ]
            [ viewDivisionOption
                winnerFlow
                colors
                WinnerTakesAll
                "Winner Takes All (100%)"
            , viewDivisionOption
                winnerFlow
                colors
                FirstSecond
                "First Place 80% / Second Place 20%"
            , viewDivisionOption
                winnerFlow
                colors
                FirstSecondThird
                "First Place 70% / Second Place 20% / Third Place 10%"
            ]
        ]


viewDivisionOption : WinnerFlow -> Theme.ColorPalette -> PotDivision -> String -> Element.Element Msg
viewDivisionOption flow colors division label =
    Input.button
        [ Element.width Element.fill
        , Element.padding 12
        , Background.color
            (if isDivisionSelected flow division then
                colors.primary

             else
                colors.surface
            )
        , Font.color
            (if isDivisionSelected flow division then
                colors.text

             else
                colors.textSecondary
            )
        ]
        { onPress = Just (PotDivisionSelected division)
        , label = Element.text label
        }


viewWinnerSelection : ViewData -> Theme.ColorPalette -> Element.Element Msg
viewWinnerSelection viewData colors =
    Element.column
        [ Element.width Element.fill
        , Element.spacing 15
        ]
        [ Element.el
            [ Font.size 18
            , Font.bold
            ]
            (Element.text "Select Winners:")
        , case viewData.winnerFlow of
            AwaitingDivision ->
                Element.el
                    [ Font.color colors.textSecondary
                    , Font.italic
                    ]
                    (Element.text "Please select a pot division type first.")

            DivisionSelected selection ->
                let
                    maxWinners =
                        List.length (positionsFor selection.division)

                    openSlots =
                        availablePositions selection
                in
                Element.column
                    [ Element.width Element.fill
                    , Element.spacing 15
                    ]
                    [ Element.el
                        [ Font.size 14
                        , Font.color colors.textSecondary
                        ]
                        (Element.text
                            ("Select up to "
                                ++ String.fromInt maxWinners
                                ++ " winner(s):"
                            )
                        )
                    , Element.column
                        [ Element.width Element.fill
                        , Element.spacing 10
                        ]
                        (List.map
                            (\player ->
                                viewPlayerSelectionOption
                                    selection
                                    colors
                                    player
                                    openSlots
                            )
                            viewData.players
                        )
                    , if List.isEmpty selection.winners then
                        Element.none

                      else
                        Element.column
                            [ Element.width Element.fill
                            , Element.spacing 10
                            ]
                            (List.map
                                (\winner -> viewWinnerWithPhoneInput colors winner)
                                (List.sortBy .position selection.winners)
                            )
                    ]
        ]


viewPlayerSelectionOption : SelectionState -> Theme.ColorPalette -> Player -> List Int -> Element.Element Msg
viewPlayerSelectionOption selection colors player remainingPositions =
    let
        playerName =
            Player.getName player

        isWinner =
            List.any (\w -> w.player == player) selection.winners

        canSelect =
            not isWinner && not (List.isEmpty remainingPositions)
    in
    Element.column
        [ Element.width Element.fill
        , Element.spacing 5
        ]
        [ Element.row
            [ Element.width Element.fill
            , Element.spacing 10
            ]
            [ Element.el
                [ Element.width Element.fill
                ]
                (Element.text ("• " ++ playerName))
            , if isWinner then
                Input.button
                    [ Element.padding 8
                    , Background.color colors.accent
                    , Font.color colors.buttonText
                    ]
                    { onPress = Just (WinnerRemoved player)
                    , label = Element.text "Remove"
                    }

              else if canSelect then
                Element.row
                    [ Element.spacing 5
                    ]
                    (List.map
                        (\position ->
                            Input.button
                                [ Element.padding 8
                                , Background.color colors.primary
                                , Font.color colors.buttonText
                                ]
                                { onPress = Just (WinnerSelected player position)
                                , label =
                                    Element.text
                                        (case position of
                                            1 ->
                                                "1st"

                                            2 ->
                                                "2nd"

                                            3 ->
                                                "3rd"

                                            _ ->
                                                String.fromInt position ++ "th"
                                        )
                                }
                        )
                        remainingPositions
                    )

              else
                Element.none
            ]
        ]


viewWinnerWithPhoneInput : Theme.ColorPalette -> Winner -> Element.Element Msg
viewWinnerWithPhoneInput colors winner =
    let
        playerName =
            Player.getName winner.player

        positionLabel =
            case winner.position of
                1 ->
                    "1st Place"

                2 ->
                    "2nd Place"

                3 ->
                    "3rd Place"

                _ ->
                    String.fromInt winner.position ++ "th Place"
    in
    Element.column
        [ Element.width Element.fill
        , Element.spacing 8
        , Element.padding 12
        , Background.color colors.surface
        ]
        [ Element.row
            [ Element.width Element.fill
            , Element.spacing 10
            ]
            [ Element.el
                [ Font.bold
                , Font.size 16
                ]
                (Element.text (positionLabel ++ ": " ++ playerName))
            , Input.button
                [ Element.padding 6
                , Background.color colors.accent
                , Font.color colors.buttonText
                ]
                { onPress = Just (WinnerRemoved winner.player)
                , label = Element.text "Remove"
                }
            ]
        , Element.column
            [ Element.width Element.fill
            , Element.spacing 5
            ]
            [ Element.el
                [ Font.size 14
                , Font.color colors.textSecondary
                ]
                (Element.text "Phone Number:")
            , Input.text
                [ Element.width Element.fill
                , Element.padding 8
                , Background.color colors.background
                , Font.color colors.text
                ]
                { onChange = \phone -> PhoneNumberChanged winner.player phone
                , text = winner.phoneNumber
                , placeholder = Just (Input.placeholder [] (Element.text "Enter phone number"))
                , label = Input.labelHidden "Phone number"
                }
            ]
        ]


viewPaymentCalculations : ViewData -> Theme.ColorPalette -> Element.Element Msg
viewPaymentCalculations viewData colors =
    let
        calculations =
            calculatePayments viewData
    in
    Element.column
        [ Element.width Element.fill
        , Element.spacing 15
        ]
        [ Element.el
            [ Font.size 18
            , Font.bold
            ]
            (Element.text "Payment Calculations:")
        , Element.el
            [ Font.size 16
            , Font.color colors.textSecondary
            ]
            (Element.text ("Total Pot: " ++ String.fromInt viewData.totalPot))
        , case viewData.winnerFlow of
            AwaitingDivision ->
                Element.el
                    [ Font.color colors.textSecondary
                    , Font.italic
                    ]
                    (Element.text "Select winners to see payment calculations.")

            DivisionSelected selection ->
                if List.isEmpty selection.winners then
                    Element.el
                        [ Font.color colors.textSecondary
                        , Font.italic
                        ]
                        (Element.text "Select winners to see payment calculations.")

                else
                    Element.column
                        [ Element.width Element.fill
                        , Element.spacing 20
                        ]
                        (List.map
                            (\calc ->
                                viewPaymentCalculation colors calc
                            )
                            calculations
                        )
        ]


viewPaymentCalculation : Theme.ColorPalette -> PaymentCalculation -> Element.Element Msg
viewPaymentCalculation colors calc =
    Element.column
        [ Element.width Element.fill
        , Element.spacing 10
        , Element.padding 15
        , Background.color colors.surface
        ]
        [ Element.row
            [ Element.width Element.fill
            , Element.spacing 10
            ]
            [ Element.el
                [ Font.bold
                , Font.size 16
                ]
                (Element.text (calc.winnerName ++ " (" ++ calc.positionLabel ++ ")"))
            , Element.el
                [ Font.bold
                , Font.size 16
                , Font.color colors.primary
                ]
                (Element.text ("Wins: " ++ String.fromInt calc.payoutAmount))
            ]
        , if calc.phoneNumber /= "" then
            Element.el
                [ Font.size 14
                , Font.color colors.textSecondary
                ]
                (Element.text ("Phone: " ++ calc.phoneNumber))

          else
            Element.none
        , Element.el
            [ Font.size 14
            , Font.bold
            , Element.paddingEach { top = 5, right = 0, bottom = 0, left = 0 }
            ]
            (Element.text "Players who need to pay:")
        , Element.column
            [ Element.width Element.fill
            , Element.spacing 5
            ]
            (if List.isEmpty calc.payers then
                [ Element.el
                    [ Font.color colors.textSecondary
                    , Font.italic
                    ]
                    (Element.text "No payments needed (all players are winners).")
                ]

             else
                List.map
                    (\payer ->
                        Element.row
                            [ Element.width Element.fill
                            , Element.spacing 10
                            ]
                            [ Element.el
                                [ Element.width Element.fill
                                ]
                                (Element.text ("• " ++ payer.payerName))
                            , Element.el
                                [ Font.bold
                                , Font.color colors.primary
                                ]
                                (Element.text (String.fromInt payer.amountOwed))
                            ]
                    )
                    calc.payers
            )
        ]



-- CALCULATION LOGIC


type alias PaymentCalculation =
    { winnerName : String
    , positionLabel : String
    , phoneNumber : String
    , payoutAmount : Int
    , payers : List PayerInfo
    }


type alias PayerInfo =
    { payerName : String
    , amountOwed : Int
    }


assignPayersRoundRobin : List WinnerPayout -> List Player -> List ( Player, Int ) -> List ( Int, List PayerInfo )
assignPayersRoundRobin winnerPayouts nonWinners playerContributions =
    let
        numWinners =
            List.length winnerPayouts

        payerAssignments =
            nonWinners
                |> List.indexedMap
                    (\index payer ->
                        let
                            winnerIndex =
                                modBy numWinners index

                            payerContribution =
                                playerContributions
                                    |> List.filter (\( p, _ ) -> p == payer)
                                    |> List.head
                                    |> Maybe.map Tuple.second
                                    |> Maybe.withDefault 0

                            payerInfo =
                                { payerName = Player.getName payer
                                , amountOwed = payerContribution
                                }
                        in
                        ( winnerIndex, payerInfo )
                    )

        groupedPayers =
            payerAssignments
                |> List.foldl
                    (\( winnerIndex, payerInfo ) acc ->
                        let
                            existingPayers =
                                acc
                                    |> List.filter (\( idx, _ ) -> idx == winnerIndex)
                                    |> List.head
                                    |> Maybe.map Tuple.second
                                    |> Maybe.withDefault []

                            updatedPayers =
                                payerInfo :: existingPayers

                            filteredAcc =
                                acc
                                    |> List.filter (\( idx, _ ) -> idx /= winnerIndex)
                        in
                        ( winnerIndex, updatedPayers ) :: filteredAcc
                    )
                    []
    in
    groupedPayers


calculatePayments : ViewData -> List PaymentCalculation
calculatePayments viewData =
    case viewData.winnerFlow of
        AwaitingDivision ->
            []

        DivisionSelected selection ->
            let
                winnerPayouts =
                    calculateWinnerPayouts selection.division viewData.totalPot selection.winners viewData.players

                playerContributions =
                    calculatePlayerContributions viewData.players viewData.buyInPlayers viewData.initialBuyIn viewData.rebuyAmount

                nonWinners =
                    viewData.players
                        |> List.filter
                            (\player ->
                                not (List.any (\w -> w.player == player) selection.winners)
                            )

                payerAssignments =
                    if List.isEmpty nonWinners || List.isEmpty winnerPayouts then
                        []

                    else
                        assignPayersRoundRobin winnerPayouts nonWinners playerContributions
            in
            winnerPayouts
                |> List.indexedMap
                    (\index winnerPayout ->
                        let
                            payers =
                                payerAssignments
                                    |> List.filter (\( winnerIdx, _ ) -> winnerIdx == index)
                                    |> List.head
                                    |> Maybe.map Tuple.second
                                    |> Maybe.withDefault []
                                    |> List.reverse
                        in
                        { winnerName = winnerPayout.winnerName
                        , positionLabel = winnerPayout.positionLabel
                        , phoneNumber = winnerPayout.phoneNumber
                        , payoutAmount = winnerPayout.payoutAmount
                        , payers = payers
                        }
                    )


calculatePlayerContributions : List Player -> List Player -> Int -> Int -> List ( Player, Int )
calculatePlayerContributions players buyInPlayers initialBuyIn rebuyAmount =
    let
        countBuyInsForPlayer : Player -> List Player -> Int
        countBuyInsForPlayer player buyInPlayerList =
            List.length
                (List.filter (\p -> p == player) buyInPlayerList)

        playerContributions =
            players
                |> List.map
                    (\player ->
                        let
                            additionalBuyInCount =
                                countBuyInsForPlayer player buyInPlayers

                            contribution =
                                initialBuyIn + (additionalBuyInCount * rebuyAmount)
                        in
                        ( player, contribution )
                    )
    in
    playerContributions


type alias WinnerPayout =
    { winnerName : String
    , positionLabel : String
    , phoneNumber : String
    , payoutAmount : Int
    }


calculateWinnerPayouts : PotDivision -> Int -> List Winner -> List Player -> List WinnerPayout
calculateWinnerPayouts division totalPot winners _ =
    let
        percentages =
            case division of
                WinnerTakesAll ->
                    [ 1.0 ]

                FirstSecond ->
                    [ 0.8, 0.2 ]

                FirstSecondThird ->
                    [ 0.7, 0.2, 0.1 ]

        sortedWinners =
            List.sortBy .position winners
    in
    List.map2
        (\winner percentage ->
            let
                playerName =
                    Player.getName winner.player

                positionLabel =
                    case winner.position of
                        1 ->
                            "1st Place"

                        2 ->
                            "2nd Place"

                        3 ->
                            "3rd Place"

                        _ ->
                            String.fromInt winner.position ++ "th Place"

                payoutAmount =
                    round (toFloat totalPot * percentage)
            in
            { winnerName = playerName
            , positionLabel = positionLabel
            , phoneNumber = winner.phoneNumber
            , payoutAmount = payoutAmount
            }
        )
        sortedWinners
        percentages
