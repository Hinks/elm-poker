module Page.Playground exposing (view)

import Element
import Element.Background as Background
import Element.Font as Font
import Html
import Icons
import Theme exposing (Theme)


view : Theme -> Element.Element msg
view theme =
    let
        colors =
            Theme.getColors theme
    in
    Element.el
        [ Element.width Element.fill
        , Element.padding 20
        , Background.color colors.background
        , Font.color colors.text
        ]
        (Element.column
            [ Element.spacing 30
            , Element.width Element.fill
            ]
            [ Element.el
                [ Font.size 32
                , Font.bold
                , Font.color colors.text
                ]
                (Element.text "Playground")
            , Element.paragraph
                [ Font.size 18
                , Font.color colors.textSecondary
                , Element.spacing 4
                ]
                [ Element.text "Development playground for testing components and icons."
                ]
            , Element.el
                [ Element.width Element.fill
                , Element.spacing 20
                ]
                (Element.column
                    [ Element.spacing 20
                    , Element.width Element.fill
                    ]
                    [ viewIconSection "Poker Card"
                        colors
                        (Icons.pokerCard
                            { size = 120
                            , rank = "K"
                            , suit = Icons.Diamond
                            , backgroundColor = Element.rgb255 230 238 244
                            , rankColor = Element.rgb255 215 30 0
                            , suitColor = Element.rgb255 215 30 0
                            }
                        )
                    , viewAllSuitsRow colors
                    , viewCardsRow colors
                    , viewSpadeCardsRow colors
                    , viewClubCardsRow colors
                    , viewHeartCardsRow colors
                    , viewIconSection "Poker Chip"
                        colors
                        (Icons.pokerChip
                            { size = 100
                            , color = colors.primary
                            , spinSpeed = 2.0
                            , value = Just 100
                            , textColor = colors.chipTextOnLight
                            }
                        )
                    , viewIconSection "Poker Table"
                        colors
                        (Icons.pokerTable
                            { size = 200
                            , color = colors.primary
                            }
                        )
                    , viewIconSection "Dollar"
                        colors
                        (Icons.dollar
                            { size = 100
                            , color = colors.accent
                            }
                        )
                    , viewIconSection "Timer"
                        colors
                        (Icons.timer
                            { size = 200
                            , backgroundColor = colors.surface
                            , armColor = colors.accent
                            , progress = 0.5
                            , duration = 60
                            }
                        )
                    , viewIconSection "Big Blind"
                        colors
                        (Icons.bigBlind
                            { size = 200
                            , backgroundColor = colors.primary
                            , labelTextColor = colors.chipTextOnDark
                            , valueTextColor = colors.chipTextOnDark
                            , value = 100
                            }
                        )
                    , viewIconSection "Small Blind"
                        colors
                        (Icons.smallBlind
                            { size = 200
                            , backgroundColor = colors.accent
                            , labelTextColor = colors.chipTextOnDark
                            , valueTextColor = colors.chipTextOnDark
                            , value = 50
                            }
                        )
                    ]
                )
            ]
        )


viewIconSection : String -> Theme.ColorPalette -> Html.Html msg -> Element.Element msg
viewIconSection title colors icon =
    Element.column
        [ Element.spacing 10
        , Element.width Element.fill
        , Element.padding 20
        , Background.color colors.surface
        ]
        [ Element.el
            [ Font.size 20
            , Font.bold
            , Font.color colors.text
            ]
            (Element.text title)
        , Element.el
            [ Element.padding 10
            ]
            (Element.html icon)
        ]


viewCardsRow : Theme.ColorPalette -> Element.Element msg
viewCardsRow colors =
    let
        ranks =
            [ "A", "K", "Q", "J", "10" ]

        card rank =
            Element.el
                [ Element.paddingEach { top = 0, right = 10, bottom = 0, left = 10 }
                ]
                (Element.html
                    (Icons.pokerCard
                        { size = 120
                        , rank = rank
                        , suit = Icons.Diamond
                        , backgroundColor = Element.rgb255 230 238 244
                        , rankColor = Element.rgb255 215 30 0
                        , suitColor = Element.rgb255 215 30 0
                        }
                    )
                )
    in
    Element.column
        [ Element.spacing 10
        , Element.width Element.fill
        , Element.padding 20
        , Background.color colors.surface
        ]
        [ Element.el
            [ Font.size 20
            , Font.bold
            , Font.color colors.text
            ]
            (Element.text "Diamond Cards Row")
        , Element.row
            [ Element.spacing 20
            , Element.padding 10
            ]
            (List.map card ranks)
        ]


viewSpadeCardsRow : Theme.ColorPalette -> Element.Element msg
viewSpadeCardsRow colors =
    let
        ranks =
            [ "A", "K", "Q", "J", "10" ]

        card rank =
            Element.el
                [ Element.paddingEach { top = 0, right = 10, bottom = 0, left = 10 }
                ]
                (Element.html
                    (Icons.pokerCard
                        { size = 120
                        , rank = rank
                        , suit = Icons.Spade
                        , backgroundColor = Element.rgb255 230 238 244
                        , rankColor = Element.rgb255 0 0 0
                        , suitColor = Element.rgb255 0 0 0
                        }
                    )
                )
    in
    Element.column
        [ Element.spacing 10
        , Element.width Element.fill
        , Element.padding 20
        , Background.color colors.surface
        ]
        [ Element.el
            [ Font.size 20
            , Font.bold
            , Font.color colors.text
            ]
            (Element.text "Spade Cards Row")
        , Element.row
            [ Element.spacing 20
            , Element.padding 10
            ]
            (List.map card ranks)
        ]


viewClubCardsRow : Theme.ColorPalette -> Element.Element msg
viewClubCardsRow colors =
    let
        ranks =
            [ "A", "K", "Q", "J", "10" ]

        card rank =
            Element.el
                [ Element.paddingEach { top = 0, right = 10, bottom = 0, left = 10 }
                ]
                (Element.html
                    (Icons.pokerCard
                        { size = 120
                        , rank = rank
                        , suit = Icons.Club
                        , backgroundColor = Element.rgb255 230 238 244
                        , rankColor = Element.rgb255 0 0 0
                        , suitColor = Element.rgb255 0 0 0
                        }
                    )
                )
    in
    Element.column
        [ Element.spacing 10
        , Element.width Element.fill
        , Element.padding 20
        , Background.color colors.surface
        ]
        [ Element.el
            [ Font.size 20
            , Font.bold
            , Font.color colors.text
            ]
            (Element.text "Club Cards Row")
        , Element.row
            [ Element.spacing 20
            , Element.padding 10
            ]
            (List.map card ranks)
        ]


viewAllSuitsRow : Theme.ColorPalette -> Element.Element msg
viewAllSuitsRow colors =
    let
        suits =
            [ ( Icons.Diamond, Element.rgb255 215 30 0 )
            , ( Icons.Spade, Element.rgb255 0 0 0 )
            , ( Icons.Club, Element.rgb255 0 0 0 )
            , ( Icons.Heart, Element.rgb255 215 30 0 )
            ]

        card ( suit, suitColor ) =
            Element.el
                [ Element.paddingEach { top = 0, right = 10, bottom = 0, left = 10 }
                ]
                (Element.html
                    (Icons.pokerCard
                        { size = 120
                        , rank = "A"
                        , suit = suit
                        , backgroundColor = Element.rgb255 230 238 244
                        , rankColor = suitColor
                        , suitColor = suitColor
                        }
                    )
                )
    in
    Element.column
        [ Element.spacing 10
        , Element.width Element.fill
        , Element.padding 20
        , Background.color colors.surface
        ]
        [ Element.el
            [ Font.size 20
            , Font.bold
            , Font.color colors.text
            ]
            (Element.text "All Suits Row")
        , Element.row
            [ Element.spacing 20
            , Element.padding 10
            ]
            (List.map card suits)
        ]


viewHeartCardsRow : Theme.ColorPalette -> Element.Element msg
viewHeartCardsRow colors =
    let
        ranks =
            [ "A", "K", "Q", "J", "10" ]

        card rank =
            Element.el
                [ Element.paddingEach { top = 0, right = 10, bottom = 0, left = 10 }
                ]
                (Element.html
                    (Icons.pokerCard
                        { size = 120
                        , rank = rank
                        , suit = Icons.Heart
                        , backgroundColor = Element.rgb255 230 238 244
                        , rankColor = Element.rgb255 215 30 0
                        , suitColor = Element.rgb255 215 30 0
                        }
                    )
                )
    in
    Element.column
        [ Element.spacing 10
        , Element.width Element.fill
        , Element.padding 20
        , Background.color colors.surface
        ]
        [ Element.el
            [ Font.size 20
            , Font.bold
            , Font.color colors.text
            ]
            (Element.text "Heart Cards Row")
        , Element.row
            [ Element.spacing 20
            , Element.padding 10
            ]
            (List.map card ranks)
        ]
