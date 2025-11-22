module Icons.PokerCard exposing (CardOptions, Suit(..), pokerCard)

import Element exposing (Color)
import Html
import Html.Attributes
import Icons.Internal
import Svg
import Svg.Attributes exposing (d, dominantBaseline, fill, fontSize, fontWeight, height, points, rx, ry, textAnchor, viewBox, width, x, y)


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


pokerCard : CardOptions -> Html.Html msg
pokerCard options =
    let
        sizeStr =
            String.fromFloat options.size

        heightStr =
            String.fromFloat (options.size * 1.4)

        backgroundColorStr =
            Icons.Internal.colorToRgbString options.backgroundColor

        rankColorStr =
            Icons.Internal.colorToRgbString options.rankColor

        suitColorStr =
            Icons.Internal.colorToRgbString options.suitColor

        -- Card dimensions in viewBox coordinates
        cardWidth =
            250.0

        cardHeight =
            350.0

        -- Position for rank (upper half, centered)
        rankX =
            cardWidth / 2

        rankY =
            cardHeight * 0.18

        -- Position for suit (lower half, centered)
        suitX =
            cardWidth / 2

        suitY =
            cardHeight * 0.68

        -- Font size for rank (proportional to card size)
        rankFontSize =
            String.fromFloat (options.size * 0.75)

        -- Diamond size in viewBox coordinates (proportional to card width)
        diamondSize =
            cardWidth * 0.5

        -- Diamond points (centered at suitX, suitY)
        -- Make diamond taller for more vertical presence
        diamondHalfWidth =
            diamondSize / 2

        diamondHalfHeight =
            diamondSize * 0.7

        diamondPoints =
            String.fromFloat suitX
                ++ ","
                ++ String.fromFloat (suitY - diamondHalfHeight)
                ++ " "
                ++ String.fromFloat (suitX + diamondHalfWidth)
                ++ ","
                ++ String.fromFloat suitY
                ++ " "
                ++ String.fromFloat suitX
                ++ ","
                ++ String.fromFloat (suitY + diamondHalfHeight)
                ++ " "
                ++ String.fromFloat (suitX - diamondHalfWidth)
                ++ ","
                ++ String.fromFloat suitY

        -- Rounded corner radius
        cornerRadius =
            15.0
    in
    Svg.svg
        [ width sizeStr
        , height heightStr
        , viewBox "0 0 250 350"
        , Html.Attributes.style "display" "block"
        ]
        ([ -- Card background with rounded corners
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

         -- Rank text in upper half
         , Svg.text_
            [ x (String.fromFloat rankX)
            , y (String.fromFloat rankY)
            , textAnchor "middle"
            , dominantBaseline "middle"
            , fontSize rankFontSize
            , fontWeight "bold"
            , fill rankColorStr
            ]
            [ Svg.text options.rank ]
         ]
            ++ (case options.suit of
                    Diamond ->
                        [ -- Diamond suit symbol in lower half
                          Svg.polygon
                            [ points diamondPoints
                            , fill suitColorStr
                            ]
                            []
                        ]

                    Heart ->
                        [ -- Heart suit symbol in lower half
                          -- Scale and position the heart path from 512x512 viewBox to card coordinates
                          -- Original path is centered around (256, 256) in 512x512, we center at suitX, suitY
                          -- Scale factor 0.72 makes heart slightly smaller than diamond (diamondSize = cardWidth * 0.5 = 125)
                          -- Positioned slightly higher than suitY for better visual balance
                          Svg.g
                            [ Svg.Attributes.transform
                                ("translate("
                                    ++ String.fromFloat suitX
                                    ++ ","
                                    ++ String.fromFloat (suitY - 18)
                                    ++ ") scale(0.72) translate(-256,-256)"
                                )
                            ]
                            [ Svg.path
                                [ d "M256,238.345c9.507-24.214,29.625-44.138,54.881-44.138c21.257,0,40.201,9.993,52.966,26.483c16.013,20.692,27.33,66.754-7.715,101.8C338.353,340.268,256,423.724,256,423.724s-82.353-83.456-100.131-101.235c-35.046-35.046-23.729-81.108-7.715-101.8c12.765-16.49,31.709-26.483,52.966-26.483C226.375,194.207,246.493,214.131,256,238.345"
                                , fill suitColorStr
                                ]
                                []
                            ]
                        ]

                    Spade ->
                        [ -- Spade suit symbol in lower half
                          -- Scale and position the spade path from 512x512 viewBox to card coordinates
                          -- Original path is centered around (256, 256) in 512x512, we center at suitX, suitY
                          -- Scale factor 0.72 makes spade slightly smaller than diamond (diamondSize = cardWidth * 0.5 = 125)
                          -- Positioned slightly higher than suitY for better visual balance
                          Svg.g
                            [ Svg.Attributes.transform
                                ("translate("
                                    ++ String.fromFloat suitX
                                    ++ ","
                                    ++ String.fromFloat (suitY - 18)
                                    ++ ") scale(0.72) translate(-256,-256)"
                                )
                            ]
                            [ Svg.path
                                [ d "M282.483,361.931L282.483,361.931c0,0,44.323,44.323,79.448-8.828c18.282-27.666,5.888-54.616-13.603-73.242l-83.906-82.635c-4.723-4.025-11.979-4.025-16.711,0l-85.124,82.635c-16.746,17.523-31.011,45.506-12.518,73.242c35.31,52.966,79.448,8.828,79.448,8.828c0,22.625-6.444,51.703-8.324,59.683c-0.256,1.112,0.6,2.11,1.739,2.11h66.145c1.139,0,1.986-0.997,1.73-2.101C288.936,413.617,282.483,384.415,282.483,361.931"
                                , fill suitColorStr
                                ]
                                []
                            ]
                        ]

                    Club ->
                        [ -- Club suit symbol in lower half
                          -- Scale and position the club path from 512x512 viewBox to card coordinates
                          -- Original path is centered around (256, 256) in 512x512, we center at suitX, suitY
                          -- Scale factor 0.72 makes club slightly smaller than diamond (diamondSize = cardWidth * 0.5 = 125)
                          -- Positioned slightly higher than suitY for better visual balance
                          Svg.g
                            [ Svg.Attributes.transform
                                ("translate("
                                    ++ String.fromFloat suitX
                                    ++ ","
                                    ++ String.fromFloat (suitY - 18)
                                    ++ ") scale(0.72) translate(-256,-256)"
                                )
                            ]
                            [ Svg.path
                                [ d "M282.482,370.759c0,21.91,6.047,43.82,8.13,50.732c0.344,1.139-0.521,2.233-1.704,2.233h-65.827c-1.183,0-2.039-1.095-1.704-2.225c2.074-6.947,8.139-29.096,8.139-50.741c-8.722,6.321-18.803,9.578-29.917,9.578c-32.274,0-60.275-27.101-58.253-59.78c1.13-18.379,12.835-34.145,28.425-43.926c15.651-9.825,30.164-10.611,43.14-7.459c-8.298-9.825-13.312-22.502-13.312-36.361c0-34.834,31.576-62.296,67.663-55.314c22.59,4.361,40.545,22.925,44.332,45.612c2.948,17.602-2.304,33.986-12.5,46.062c13.065-3.169,27.692-2.348,43.467,7.662c15.519,9.852,27.18,25.582,28.248,43.926c1.889,32.591-26.2,59.577-58.403,59.577C301.444,380.337,291.045,376.947,282.482,370.759"
                                , fill suitColorStr
                                ]
                                []
                            ]
                        ]
               )
        )
