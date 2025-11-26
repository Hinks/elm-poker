module Icons exposing (BlindOptions, CardOptions, CircleOptions, DollarOptions, PokerChipOptions, PokerTableOptions, StrawberryOptions, Suit(..), TimerOptions, bigBlind, dollar, pokerCard, pokerChip, pokerTable, smallBlind, strawberry, timer)

import Element exposing (Color)
import Html
import Icons.BigBlind
import Icons.BlindOptions
import Icons.Dollar
import Icons.PokerCard
import Icons.PokerChip
import Icons.PokerTable
import Icons.SmallBlind
import Icons.Strawberry
import Icons.Timer



-- Re-export type aliases (must match exactly, not reference other modules' types)


type alias BlindOptions =
    { size : Float
    , backgroundColor : Color
    , labelTextColor : Color
    , valueTextColor : Color
    , value : Int
    }


type alias CardOptions =
    { size : Float
    , rank : String
    , suit : Suit
    , backgroundColor : Color
    , rankColor : Color
    , suitColor : Color
    }


type alias CircleOptions =
    { size : Float
    , color : Color
    }


type alias DollarOptions =
    { size : Float
    , color : Color
    }


type alias PokerChipOptions =
    { size : Float
    , color : Color
    , spinSpeed : Float
    , value : Maybe Int
    , textColor : Color
    }


type alias PokerTableOptions =
    { size : Float
    , color : Color
    }


type alias StrawberryOptions =
    { size : Float
    , color : Color
    }


type alias TimerOptions =
    { size : Float
    , backgroundColor : Color
    , armColor : Color
    , progress : Float
    , duration : Float
    }



-- Re-export custom types (must match Icons.PokerCard.Suit exactly)


type Suit
    = Diamond
    | Heart
    | Spade
    | Club



-- Helper function to convert Suit to Icons.PokerCard.Suit


suitToPokerCardSuit : Suit -> Icons.PokerCard.Suit
suitToPokerCardSuit suit =
    case suit of
        Diamond ->
            Icons.PokerCard.Diamond

        Heart ->
            Icons.PokerCard.Heart

        Spade ->
            Icons.PokerCard.Spade

        Club ->
            Icons.PokerCard.Club



-- Re-export functions


bigBlind : BlindOptions -> Html.Html msg
bigBlind options =
    Icons.BigBlind.bigBlind
        { size = options.size
        , backgroundColor = options.backgroundColor
        , labelTextColor = options.labelTextColor
        , valueTextColor = options.valueTextColor
        , value = options.value
        }


dollar : DollarOptions -> Html.Html msg
dollar options =
    Icons.Dollar.dollar
        { size = options.size
        , color = options.color
        }


pokerCard : CardOptions -> Html.Html msg
pokerCard options =
    Icons.PokerCard.pokerCard
        { size = options.size
        , rank = options.rank
        , suit = suitToPokerCardSuit options.suit
        , backgroundColor = options.backgroundColor
        , rankColor = options.rankColor
        , suitColor = options.suitColor
        }


pokerChip : PokerChipOptions -> Html.Html msg
pokerChip options =
    Icons.PokerChip.pokerChip
        { size = options.size
        , color = options.color
        , spinSpeed = options.spinSpeed
        , value = options.value
        , textColor = options.textColor
        }


pokerTable : PokerTableOptions -> Html.Html msg
pokerTable options =
    Icons.PokerTable.pokerTable
        { size = options.size
        , color = options.color
        }


smallBlind : BlindOptions -> Html.Html msg
smallBlind options =
    Icons.SmallBlind.smallBlind
        { size = options.size
        , backgroundColor = options.backgroundColor
        , labelTextColor = options.labelTextColor
        , valueTextColor = options.valueTextColor
        , value = options.value
        }


strawberry : StrawberryOptions -> Html.Html msg
strawberry options =
    Icons.Strawberry.strawberry
        { size = options.size
        , color = options.color
        }


timer : TimerOptions -> Html.Html msg
timer options =
    Icons.Timer.timer
        { size = options.size
        , backgroundColor = options.backgroundColor
        , armColor = options.armColor
        , progress = options.progress
        , duration = options.duration
        }
