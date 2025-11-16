module Icons exposing (CircleOptions, PokerChipOptions, pokerChip)

import Element exposing (Color)
import Html
import Html.Attributes
import Svg
import Svg.Attributes exposing (cx, cy, d, fill, r, stroke, strokeWidth, viewBox)


type alias CircleOptions =
    { size : Float
    , color : Color
    }


type alias PokerChipOptions =
    { size : Float
    , color : Color
    , spinSpeed : Float
    }


colorToRgbString : Color -> String
colorToRgbString color =
    let
        rgb =
            Element.toRgb color
    in
    "rgb("
        ++ String.fromInt (round (rgb.red * 255))
        ++ ","
        ++ String.fromInt (round (rgb.green * 255))
        ++ ","
        ++ String.fromInt (round (rgb.blue * 255))
        ++ ")"


pokerChip : PokerChipOptions -> Html.Html msg
pokerChip options =
    let
        sizeStr =
            String.fromFloat options.size

        spinSpeedStr =
            String.fromFloat options.spinSpeed ++ "s"
    in
    Html.div
        [ Html.Attributes.style "perspective" "500px"
        , Html.Attributes.style "perspective-origin" "center"
        , Html.Attributes.style "display" "inline-block"
        ]
        [ Html.node "style"
            []
            [ Html.text
                ("""
                @keyframes chipSpin {
                    0% {
                        transform: rotateY(0deg) scaleX(1);
                    }
                    12.5% {
                        transform: rotateY(45deg) scaleX(0.7);
                    }
                    25% {
                        transform: rotateY(90deg) scaleX(0.05);
                    }
                    37.5% {
                        transform: rotateY(135deg) scaleX(0.7);
                    }
                    50% {
                        transform: rotateY(180deg) scaleX(1);
                    }
                    62.5% {
                        transform: rotateY(225deg) scaleX(0.7);
                    }
                    75% {
                        transform: rotateY(270deg) scaleX(0.05);
                    }
                    87.5% {
                        transform: rotateY(315deg) scaleX(0.7);
                    }
                    100% {
                        transform: rotateY(360deg) scaleX(1);
                    }
                }
                .poker-chip-container {
                    animation: chipSpin """
                    ++ spinSpeedStr
                    ++ """ linear infinite;
                    transform-style: preserve-3d;
                    display: inline-block;
                    transform-origin: center center;
                }
            """
                )
            ]
        , Html.div
            [ Html.Attributes.class "poker-chip-container"
            ]
            [ Svg.svg
                [ Svg.Attributes.width sizeStr
                , Svg.Attributes.height sizeStr
                , viewBox "0 0 256 256"
                , Html.Attributes.style "display" "block"
                , Html.Attributes.style "transform-style" "preserve-3d"
                ]
                [ Svg.circle
                    [ cx "128"
                    , cy "128"
                    , r "100"
                    , fill (colorToRgbString options.color)
                    ]
                    []
                , Svg.path
                    [ d "M199.03711,198.30981a99.82288,99.82288,0,0,0,0-140.61962A3.982,3.982,0,0,0,198.71,57.29a3.90416,3.90416,0,0,0-.40088-.32776,99.8226,99.8226,0,0,0-140.61816,0A3.90416,3.90416,0,0,0,57.29,57.29a3.982,3.982,0,0,0-.32715.40015,99.82288,99.82288,0,0,0,0,140.61962A3.982,3.982,0,0,0,57.29,198.71a3.93475,3.93475,0,0,0,.40088.32764,99.82231,99.82231,0,0,0,140.61816,0A3.93475,3.93475,0,0,0,198.71,198.71,3.982,3.982,0,0,0,199.03711,198.30981ZM36.09229,132H68.14844a59.72942,59.72942,0,0,0,14.72217,35.47327L60.2124,190.13135A91.64821,91.64821,0,0,1,36.09229,132ZM60.2124,65.86865,82.87061,88.52673A59.72942,59.72942,0,0,0,68.14844,124H36.09229A91.64821,91.64821,0,0,1,60.2124,65.86865ZM219.90771,124H187.85156a59.72942,59.72942,0,0,0-14.72217-35.47327L195.7876,65.86865A91.64821,91.64821,0,0,1,219.90771,124ZM128,180a52,52,0,1,1,52-52A52.059,52.059,0,0,1,128,180Zm39.47314-97.12952A59.73257,59.73257,0,0,0,132,68.14819V36.09229A91.64757,91.64757,0,0,1,190.13135,60.2124ZM124,68.14819A59.73257,59.73257,0,0,0,88.52686,82.87048L65.86865,60.2124A91.64757,91.64757,0,0,1,124,36.09229ZM88.52686,173.12952A59.73257,59.73257,0,0,0,124,187.85181v32.0559A91.64757,91.64757,0,0,1,65.86865,195.7876ZM132,187.85181a59.73257,59.73257,0,0,0,35.47314-14.72229l22.65821,22.65808A91.64757,91.64757,0,0,1,132,219.90771Zm41.12939-20.37854A59.72942,59.72942,0,0,0,187.85156,132h32.05615a91.64821,91.64821,0,0,1-24.12011,58.13135Z"
                    , fill "none"
                    , stroke "black"
                    , strokeWidth (String.fromFloat (options.size * 0.03125))
                    ]
                    []
                ]
            ]
        ]
