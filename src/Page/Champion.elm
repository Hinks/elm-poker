module Page.Champion exposing (Model, Msg, init, update, view)

import Element
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import Page.Players exposing (Player)
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


type alias Model =
    { pageName : String
    , potDivision : Maybe PotDivision
    , winners : List Winner
    , players : List Player
    , totalPot : Int
    , buyInPlayers : List Player
    , initialBuyIn : Int
    }


init : List Player -> Int -> List Player -> Int -> Model
init players totalPot buyInPlayers initialBuyIn =
    { pageName = "Champion"
    , potDivision = Nothing
    , winners = []
    , players = players
    , totalPot = totalPot
    , buyInPlayers = buyInPlayers
    , initialBuyIn = initialBuyIn
    }



-- UPDATE


type Msg
    = PotDivisionSelected PotDivision
    | WinnerSelected Player Int
    | WinnerRemoved Player
    | PhoneNumberChanged Player String
    | ClearWinners


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PotDivisionSelected division ->
            let
                maxWinners =
                    case division of
                        WinnerTakesAll ->
                            1

                        FirstSecond ->
                            2

                        FirstSecondThird ->
                            3

                updatedWinners =
                    model.winners
                        |> List.take maxWinners
                        |> List.indexedMap
                            (\idx winner ->
                                { winner | position = idx + 1 }
                            )
            in
            ( { model
                | potDivision = Just division
                , winners = updatedWinners
              }
            , Cmd.none
            )

        WinnerSelected player position ->
            let
                isAlreadyWinner =
                    List.any (\w -> w.player == player) model.winners

                maxWinners =
                    case model.potDivision of
                        Just WinnerTakesAll ->
                            1

                        Just FirstSecond ->
                            2

                        Just FirstSecondThird ->
                            3

                        Nothing ->
                            0

                canAdd =
                    not isAlreadyWinner
                        && List.length model.winners
                        < maxWinners
                        && model.potDivision
                        /= Nothing

                newWinner =
                    { player = player
                    , phoneNumber = ""
                    , position = position
                    }
            in
            if canAdd then
                ( { model | winners = model.winners ++ [ newWinner ] }, Cmd.none )

            else
                ( model, Cmd.none )

        WinnerRemoved player ->
            let
                updatedWinners =
                    List.filter (\w -> w.player /= player) model.winners
                        |> List.indexedMap
                            (\idx winner ->
                                { winner | position = idx + 1 }
                            )
            in
            ( { model | winners = updatedWinners }, Cmd.none )

        PhoneNumberChanged player phoneNumber ->
            let
                updateWinner winner =
                    if winner.player == player then
                        { winner | phoneNumber = phoneNumber }

                    else
                        winner
            in
            ( { model | winners = List.map updateWinner model.winners }, Cmd.none )

        ClearWinners ->
            ( { model | winners = [] }, Cmd.none )



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
        , Font.color colors.text
        ]
        (Element.column
            [ Element.width Element.fill
            , Element.spacing 20
            ]
            [ viewPotDivisionSelector model colors
            , viewDivider colors
            , viewWinnerSelection model colors
            , viewDivider colors
            , viewPaymentCalculations model colors
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


viewPotDivisionSelector : Model -> Theme.ColorPalette -> Element.Element Msg
viewPotDivisionSelector model colors =
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
                model
                colors
                WinnerTakesAll
                "Winner Takes All (100%)"
            , viewDivisionOption
                model
                colors
                FirstSecond
                "First Place 80% / Second Place 20%"
            , viewDivisionOption
                model
                colors
                FirstSecondThird
                "First Place 70% / Second Place 20% / Third Place 10%"
            ]
        ]


viewDivisionOption : Model -> Theme.ColorPalette -> PotDivision -> String -> Element.Element Msg
viewDivisionOption model colors division label =
    Input.button
        [ Element.width Element.fill
        , Element.padding 12
        , Background.color
            (if model.potDivision == Just division then
                colors.primary

             else
                colors.surface
            )
        , Font.color
            (if model.potDivision == Just division then
                colors.text

             else
                colors.textSecondary
            )
        ]
        { onPress = Just (PotDivisionSelected division)
        , label = Element.text label
        }


viewWinnerSelection : Model -> Theme.ColorPalette -> Element.Element Msg
viewWinnerSelection model colors =
    Element.column
        [ Element.width Element.fill
        , Element.spacing 15
        ]
        [ Element.el
            [ Font.size 18
            , Font.bold
            ]
            (Element.text "Select Winners:")
        , case model.potDivision of
            Nothing ->
                Element.el
                    [ Font.color colors.textSecondary
                    , Font.italic
                    ]
                    (Element.text "Please select a pot division type first.")

            Just division ->
                let
                    maxWinners =
                        case division of
                            WinnerTakesAll ->
                                1

                            FirstSecond ->
                                2

                            FirstSecondThird ->
                                3

                    availablePositions =
                        List.range 1 maxWinners
                            |> List.filter
                                (\pos ->
                                    not (List.any (\w -> w.position == pos) model.winners)
                                )
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
                                    model
                                    colors
                                    player
                                    availablePositions
                            )
                            model.players
                        )
                    , if List.isEmpty model.winners then
                        Element.none

                      else
                        Element.column
                            [ Element.width Element.fill
                            , Element.spacing 10
                            ]
                            (List.map
                                (\winner ->
                                    viewWinnerWithPhoneInput model colors winner
                                )
                                (List.sortBy .position model.winners)
                            )
                    ]
        ]


viewPlayerSelectionOption : Model -> Theme.ColorPalette -> Player -> List Int -> Element.Element Msg
viewPlayerSelectionOption model colors player availablePositions =
    let
        playerName =
            Page.Players.getPlayerName player

        isWinner =
            List.any (\w -> w.player == player) model.winners

        canSelect =
            not isWinner && not (List.isEmpty availablePositions)
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
                        availablePositions
                    )

              else
                Element.none
            ]
        ]


viewWinnerWithPhoneInput : Model -> Theme.ColorPalette -> Winner -> Element.Element Msg
viewWinnerWithPhoneInput model colors winner =
    let
        playerName =
            Page.Players.getPlayerName winner.player

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


viewPaymentCalculations : Model -> Theme.ColorPalette -> Element.Element Msg
viewPaymentCalculations model colors =
    let
        calculations =
            calculatePayments model
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
            (Element.text ("Total Pot: " ++ String.fromInt model.totalPot))
        , if List.isEmpty model.winners || model.potDivision == Nothing then
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

        -- Assign each payer to a winner using round-robin
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
                                { payerName = Page.Players.getPlayerName payer
                                , amountOwed = payerContribution
                                }
                        in
                        ( winnerIndex, payerInfo )
                    )

        -- Group payers by their assigned winner index
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


calculatePayments : Model -> List PaymentCalculation
calculatePayments model =
    case model.potDivision of
        Nothing ->
            []

        Just division ->
            let
                winnerPayouts =
                    calculateWinnerPayouts division model.totalPot model.winners model.players

                -- Calculate each player's contribution to the pot
                playerContributions =
                    calculatePlayerContributions model.players model.buyInPlayers model.initialBuyIn

                nonWinners =
                    model.players
                        |> List.filter
                            (\player ->
                                not (List.any (\w -> w.player == player) model.winners)
                            )

                -- Assign payers to winners using round-robin
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
                            -- Find payers assigned to this winner (by index)
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


calculatePlayerContributions : List Player -> List Player -> Int -> List ( Player, Int )
calculatePlayerContributions players buyInPlayers initialBuyIn =
    let
        -- Count buy-ins per player
        countBuyInsForPlayer : Player -> List Player -> Int
        countBuyInsForPlayer player buyInPlayerList =
            List.length
                (List.filter (\p -> p == player) buyInPlayerList)

        -- Calculate contribution for each player: initial buy-in + (buy-in count * initial buy-in)
        playerContributions =
            players
                |> List.map
                    (\player ->
                        let
                            additionalBuyInCount =
                                countBuyInsForPlayer player buyInPlayers

                            contribution =
                                initialBuyIn + (additionalBuyInCount * initialBuyIn)
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
calculateWinnerPayouts division totalPot winners players =
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
                    Page.Players.getPlayerName winner.player

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
