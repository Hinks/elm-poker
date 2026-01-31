module Page.Playground exposing (view)

import Element
import Element.Background
import Element.Font
import Html
import Icons
import Marquee
import PokerHandRanking
import TextAnimation
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
        , Element.Background.color colors.background
        , Element.Font.color colors.text
        ]
        (Element.column
            [ Element.spacing 30
            , Element.width Element.fill
            ]
            [ Element.el
                [ Element.Font.size 32
                , Element.Font.bold
                , Element.Font.color colors.text
                ]
                (Element.text "Playground")
            , Element.paragraph
                [ Element.Font.size 18
                , Element.Font.color colors.textSecondary
                , Element.spacing 4
                ]
                [ Element.text "Development playground for testing components and icons."
                ]
            , Element.column
                [ Element.spacing 10
                , Element.width Element.fill
                , Element.padding 20
                , Element.Background.color colors.surface
                ]
                [ Element.el
                    [ Element.Font.size 20
                    , Element.Font.bold
                    , Element.Font.color colors.text
                    ]
                    (Element.text "Text Animation")
                , Element.el
                    [ Element.padding 10
                    , Element.width Element.fill
                    , Element.height (Element.px 400)
                    ]
                    (Element.html
                        (let
                            textAnimationConfig : TextAnimation.Config
                            textAnimationConfig =
                                { speed = 10.0
                                , repeat = 3
                                , textColor = colors.text
                                , fontSizeMin = 0.5
                                , fontSizePreferred = "6vh"
                                , fontSizeMax = 1.5
                                , message = "ELM POKER"
                                }
                         in
                         TextAnimation.view textAnimationConfig
                        )
                    )
                ]
            , Element.column
                [ Element.spacing 10
                , Element.width Element.fill
                , Element.padding 20
                , Element.Background.color colors.surface
                ]
                [ Element.el
                    [ Element.Font.size 20
                    , Element.Font.bold
                    , Element.Font.color colors.text
                    ]
                    (Element.text "Marquee")
                , Marquee.view
                    [ "Welcome to Elm Poker"
                    , "Test marquee component"
                    , "Scrolling text animation"
                    , "Right to left movement"
                    ]
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
                            { size = 80
                            , rank = "K"
                            , suit = Icons.Diamond
                            , backgroundColor = colors.cardBackground
                            , rankColor = colors.cardRedSuit
                            , suitColor = colors.cardRedSuit
                            }
                        )
                    , viewIconSection "Poker Card Big"
                        colors
                        (Icons.pokerCard
                            { size = 160
                            , rank = "K"
                            , suit = Icons.Diamond
                            , backgroundColor = colors.cardBackground
                            , rankColor = colors.cardRedSuit
                            , suitColor = colors.cardRedSuit
                            }
                        )
                    , viewIconSection "Poker Chip"
                        colors
                        (Icons.pokerChip
                            { size = 100
                            , color = colors.primary
                            , spinSpeed = 3.0
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
                    , viewIconSection "Strawberry"
                        colors
                        (Icons.strawberry
                            { size = 200
                            , color = colors.removeButton
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
        , Element.Background.color colors.surface
        ]
        [ Element.el
            [ Element.Font.size 20
            , Element.Font.bold
            , Element.Font.color colors.text
            ]
            (Element.text title)
        , Element.el
            [ Element.padding 10
            , Element.width Element.fill
            , Element.height Element.shrink
            ]
            (Element.html icon)
        ]
