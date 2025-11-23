module PokerHandRanking exposing (view)

import Element
import Element.Font as Font
import Html
import Html.Attributes
import Icons exposing (Suit(..))
import Theme exposing (ColorPalette)


type alias Card =
    { rank : String
    , suit : Suit
    }


type alias HandRanking =
    { number : Int
    , name : String
    , cards : List Card
    }


handRankings : List HandRanking
handRankings =
    [ { number = 1
      , name = "Royal Flush"
      , cards =
            [ { rank = "A", suit = Diamond }
            , { rank = "K", suit = Diamond }
            , { rank = "Q", suit = Diamond }
            , { rank = "J", suit = Diamond }
            , { rank = "10", suit = Diamond }
            ]
      }
    , { number = 2
      , name = "Straight Flush"
      , cards =
            [ { rank = "J", suit = Spade }
            , { rank = "10", suit = Spade }
            , { rank = "9", suit = Spade }
            , { rank = "8", suit = Spade }
            , { rank = "7", suit = Spade }
            ]
      }
    , { number = 3
      , name = "Four of a Kind"
      , cards =
            [ { rank = "9", suit = Heart }
            , { rank = "9", suit = Club }
            , { rank = "9", suit = Diamond }
            , { rank = "9", suit = Spade }
            ]
      }
    , { number = 4
      , name = "Full House"
      , cards =
            [ { rank = "A", suit = Heart }
            , { rank = "A", suit = Club }
            , { rank = "A", suit = Diamond }
            , { rank = "3", suit = Spade }
            , { rank = "3", suit = Heart }
            ]
      }
    , { number = 5
      , name = "Flush"
      , cards =
            [ { rank = "K", suit = Club }
            , { rank = "10", suit = Club }
            , { rank = "8", suit = Club }
            , { rank = "7", suit = Club }
            , { rank = "5", suit = Club }
            ]
      }
    , { number = 6
      , name = "Straight"
      , cards =
            [ { rank = "10", suit = Heart }
            , { rank = "9", suit = Club }
            , { rank = "8", suit = Diamond }
            , { rank = "7", suit = Spade }
            , { rank = "6", suit = Heart }
            ]
      }
    , { number = 7
      , name = "Three of a Kind"
      , cards =
            [ { rank = "7", suit = Heart }
            , { rank = "7", suit = Diamond }
            , { rank = "7", suit = Club }
            ]
      }
    , { number = 8
      , name = "Two Pair"
      , cards =
            [ { rank = "J", suit = Heart }
            , { rank = "J", suit = Club }
            , { rank = "7", suit = Diamond }
            , { rank = "7", suit = Spade }
            ]
      }
    , { number = 9
      , name = "Pair"
      , cards =
            [ { rank = "A", suit = Heart }
            , { rank = "A", suit = Club }
            ]
      }
    , { number = 10
      , name = "High Card"
      , cards =
            [ { rank = "K", suit = Heart }
            ]
      }
    ]


getSuitColor : Suit -> Element.Color
getSuitColor suit =
    case suit of
        Diamond ->
            Element.rgb255 215 30 0

        Heart ->
            Element.rgb255 215 30 0

        Spade ->
            Element.rgb255 0 0 0

        Club ->
            Element.rgb255 0 0 0


viewCard : Float -> Float -> Card -> Element.Element msg
viewCard cardSize opacity card =
    Element.el
        [ Element.paddingEach { top = 0, right = 10, bottom = 0, left = 10 }
        ]
        (Element.html
            (Html.div
                [ Html.Attributes.style "opacity" (String.fromFloat opacity)
                ]
                [ Icons.pokerCard
                    { size = cardSize
                    , rank = card.rank
                    , suit = card.suit
                    , backgroundColor = Element.rgb255 230 238 244
                    , rankColor = getSuitColor card.suit
                    , suitColor = getSuitColor card.suit
                    }
                ]
            )
        )


getPlaceholderCards : Int -> List Card
getPlaceholderCards rankingNumber =
    case rankingNumber of
        3 ->
            -- Four of a Kind: 1 placeholder
            [ { rank = "K", suit = Heart } ]

        7 ->
            -- Three of a Kind: 2 placeholders
            [ { rank = "Q", suit = Spade }
            , { rank = "3", suit = Heart }
            ]

        8 ->
            -- Two Pair: 1 placeholder
            [ { rank = "7", suit = Heart } ]

        9 ->
            -- Pair: 3 placeholders
            [ { rank = "K", suit = Diamond }
            , { rank = "J", suit = Spade }
            , { rank = "7", suit = Heart }
            ]

        10 ->
            -- High Card: 4 placeholders
            [ { rank = "8", suit = Club }
            , { rank = "Q", suit = Diamond }
            , { rank = "2", suit = Spade }
            , { rank = "7", suit = Heart }
            ]

        _ ->
            -- Default: King of Hearts for any other case
            [ { rank = "K", suit = Heart } ]


padCardsToFive : Int -> List Card -> List ( Card, Float )
padCardsToFive rankingNumber cards =
    let
        placeholderOpacity : Float
        placeholderOpacity =
            0.5

        numPlaceholders : Int
        numPlaceholders =
            5 - List.length cards

        placeholderCards : List Card
        placeholderCards =
            getPlaceholderCards rankingNumber

        placeholders : List ( Card, Float )
        placeholders =
            placeholderCards
                |> List.take numPlaceholders
                |> List.map (\card -> ( card, placeholderOpacity ))

        actualCards : List ( Card, Float )
        actualCards =
            List.map (\card -> ( card, 1.0 )) cards
    in
    actualCards ++ placeholders


viewHandRanking : Float -> ColorPalette -> HandRanking -> Element.Element msg
viewHandRanking cardSize colors ranking =
    Element.column
        [ Element.spacing 5
        , Element.width Element.fill
        , Element.padding 0
        ]
        [ Element.el
            [ Font.size 18
            , Font.bold
            , Font.color colors.text
            ]
            (Element.text (String.fromInt ranking.number ++ ". " ++ ranking.name))
        , Element.row
            [ Element.spacing 0
            , Element.padding 0
            ]
            (ranking.cards
                |> padCardsToFive ranking.number
                |> List.map (\( card, opacity ) -> viewCard cardSize opacity card)
            )
        ]


view : Float -> ColorPalette -> Element.Element msg
view cardSize colors =
    Element.column
        [ Element.spacing 20
        , Element.width Element.fill
        ]
        (List.map (viewHandRanking cardSize colors) handRankings)
