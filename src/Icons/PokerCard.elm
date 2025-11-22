module Icons.PokerCard exposing (CardOptions, Suit(..), pokerCard)

import Element exposing (Color)
import Html
import Html.Attributes
import Icons.Internal
import Svg
import Svg.Attributes exposing (d, dominantBaseline, fill, fontSize, fontWeight, height, rx, ry, textAnchor, viewBox, width, x, y)


type Suit
    = Diamond
    | Heart
    | Spade
    | Club


type alias CardOptions =
    { size : Float
    , rank : String
    , suit : Suit
    , backgroundColor : Color
    , rankColor : Color
    , suitColor : Color
    }



-- Constants for card dimensions (viewBox coordinates)


cardWidth : Float
cardWidth =
    250.0


cardHeight : Float
cardHeight =
    350.0


viewBoxStr : String
viewBoxStr =
    "0 0 250 350"



-- Layout constants (as ratios of card dimensions)


heightRatio : Float
heightRatio =
    1.4


rankYRatio : Float
rankYRatio =
    0.28


suitYRatio : Float
suitYRatio =
    0.68


rankFontSizeRatio : Float
rankFontSizeRatio =
    2.0



-- Path-based suit constants (Diamond, Heart, Spade, Club)
-- All suits are normalized to match diamond's size and position
-- Scale factor adjusted to match diamond's ~168x192 unit bounding box


pathSuitScale : Float
pathSuitScale =
    0.5


pathSuitVerticalOffset : Float
pathSuitVerticalOffset =
    0.0


pathSuitOriginX : Float
pathSuitOriginX =
    256.0


pathSuitOriginY : Float
pathSuitOriginY =
    256.0



-- Styling constants


cornerRadius : Float
cornerRadius =
    15.0



-- Suit path data (from 512x512 viewBox, centered at 256,256)


diamondPath : String
diamondPath =
    "M256,176.552 L361.931,308.966 L256,441.379 L150.069,308.966 Z"


heartPath : String
heartPath =
    "M256,238.345c9.507-24.214,29.625-44.138,54.881-44.138c21.257,0,40.201,9.993,52.966,26.483c16.013,20.692,27.33,66.754-7.715,101.8C338.353,340.268,256,423.724,256,423.724s-82.353-83.456-100.131-101.235c-35.046-35.046-23.729-81.108-7.715-101.8c12.765-16.49,31.709-26.483,52.966-26.483C226.375,194.207,246.493,214.131,256,238.345"


spadePath : String
spadePath =
    "M282.483,361.931L282.483,361.931c0,0,44.323,44.323,79.448-8.828c18.282-27.666,5.888-54.616-13.603-73.242l-83.906-82.635c-4.723-4.025-11.979-4.025-16.711,0l-85.124,82.635c-16.746,17.523-31.011,45.506-12.518,73.242c35.31,52.966,79.448,8.828,79.448,8.828c0,22.625-6.444,51.703-8.324,59.683c-0.256,1.112,0.6,2.11,1.739,2.11h66.145c1.139,0,1.986-0.997,1.73-2.101C288.936,413.617,282.483,384.415,282.483,361.931"


clubPath : String
clubPath =
    "M282.482,370.759c0,21.91,6.047,43.82,8.13,50.732c0.344,1.139-0.521,2.233-1.704,2.233h-65.827c-1.183,0-2.039-1.095-1.704-2.225c2.074-6.947,8.139-29.096,8.139-50.741c-8.722,6.321-18.803,9.578-29.917,9.578c-32.274,0-60.275-27.101-58.253-59.78c1.13-18.379,12.835-34.145,28.425-43.926c15.651-9.825,30.164-10.611,43.14-7.459c-8.298-9.825-13.312-22.502-13.312-36.361c0-34.834,31.576-62.296,67.663-55.314c22.59,4.361,40.545,22.925,44.332,45.612c2.948,17.602-2.304,33.986-12.5,46.062c13.065-3.169,27.692-2.348,43.467,7.662c15.519,9.852,27.18,25.582,28.248,43.926c1.889,32.591-26.2,59.577-58.403,59.577C301.444,380.337,291.045,376.947,282.482,370.759"



-- Helper: Create SVG transform string for path-based suits


pathSuitTransform : Float -> Float -> String
pathSuitTransform centerX centerY =
    "translate("
        ++ String.fromFloat centerX
        ++ ","
        ++ String.fromFloat (centerY + pathSuitVerticalOffset)
        ++ ") scale("
        ++ String.fromFloat pathSuitScale
        ++ ") translate(-"
        ++ String.fromFloat pathSuitOriginX
        ++ ",-"
        ++ String.fromFloat pathSuitOriginY
        ++ ")"



-- Helper: Render path-based suit (Diamond, Heart, Spade, Club)


viewPathSuit : Float -> Float -> String -> String -> Svg.Svg msg
viewPathSuit suitX suitY pathData colorStr =
    Svg.g
        [ Svg.Attributes.transform (pathSuitTransform suitX suitY)
        ]
        [ Svg.path
            [ d pathData
            , fill colorStr
            ]
            []
        ]



-- Helper: Render card background


viewCardBackground : String -> Svg.Svg msg
viewCardBackground backgroundColorStr =
    Svg.rect
        [ x "0"
        , y "0"
        , width (String.fromFloat cardWidth)
        , height (String.fromFloat cardHeight)
        , rx (String.fromFloat cornerRadius)
        , ry (String.fromFloat cornerRadius)
        , fill backgroundColorStr
        ]
        []



-- Helper: Render rank text


viewRankText : Float -> Float -> String -> String -> String -> Svg.Svg msg
viewRankText rankX rankY rankFontSize rankText rankColorStr =
    Svg.text_
        [ x (String.fromFloat rankX)
        , y (String.fromFloat rankY)
        , textAnchor "middle"
        , dominantBaseline "middle"
        , fontSize rankFontSize
        , fontWeight "bold"
        , fill rankColorStr
        ]
        [ Svg.text rankText ]



-- Helper: Render suit symbol


viewSuit : Suit -> Float -> Float -> String -> Svg.Svg msg
viewSuit suit suitX suitY suitColorStr =
    case suit of
        Diamond ->
            viewPathSuit suitX suitY diamondPath suitColorStr

        Heart ->
            viewPathSuit suitX suitY heartPath suitColorStr

        Spade ->
            viewPathSuit suitX suitY spadePath suitColorStr

        Club ->
            viewPathSuit suitX suitY clubPath suitColorStr


pokerCard : CardOptions -> Html.Html msg
pokerCard options =
    let
        -- Convert colors to RGB strings
        backgroundColorStr =
            Icons.Internal.colorToRgbString options.backgroundColor

        rankColorStr =
            Icons.Internal.colorToRgbString options.rankColor

        suitColorStr =
            Icons.Internal.colorToRgbString options.suitColor

        -- Calculate dimensions
        sizeStr =
            String.fromFloat options.size

        heightStr =
            String.fromFloat (options.size * heightRatio)

        rankFontSize =
            String.fromFloat (options.size * rankFontSizeRatio)

        -- Calculate positions
        rankX =
            cardWidth / 2

        rankY =
            cardHeight * rankYRatio

        suitX =
            cardWidth / 2

        suitY =
            cardHeight * suitYRatio
    in
    Svg.svg
        [ width sizeStr
        , height heightStr
        , viewBox viewBoxStr
        , Html.Attributes.style "display" "block"
        ]
        [ viewCardBackground backgroundColorStr
        , viewRankText rankX rankY rankFontSize options.rank rankColorStr
        , viewSuit options.suit suitX suitY suitColorStr
        ]
