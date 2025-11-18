module Icons exposing (CircleOptions, DollarOptions, PokerChipOptions, PokerTableOptions, TimerOptions, dollar, pokerChip, pokerTable, timer)

import Element exposing (Color)
import Html
import Html.Attributes
import Svg
import Svg.Attributes exposing (cx, cy, d, dominantBaseline, fill, fontSize, r, stroke, strokeLinecap, strokeWidth, textAnchor, viewBox, x, x1, x2, y, y1, y2)


type alias CircleOptions =
    { size : Float
    , color : Color
    }


type alias PokerChipOptions =
    { size : Float
    , color : Color
    , spinSpeed : Float
    }


type alias PokerTableOptions =
    { size : Float
    , color : Color
    }


type alias DollarOptions =
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
                    , stroke "silver"
                    , strokeWidth (String.fromFloat (options.size * 0.03125))
                    ]
                    []
                ]
            ]
        ]


pokerTable : PokerTableOptions -> Html.Html msg
pokerTable options =
    let
        sizeStr =
            String.fromFloat options.size

        colorStr =
            colorToRgbString options.color
    in
    Svg.svg
        [ Svg.Attributes.width sizeStr
        , Svg.Attributes.height sizeStr
        , viewBox "0 0 452.307 452.307"
        , Html.Attributes.style "display" "block"
        , Html.Attributes.style "transform" "scaleY(-1)"
        ]
        [ Svg.path
            [ d "M337.029,129.905h-43.978c-12.694,0-25.607,2.427-38.382,7.212 c-9.105,3.411-18.7,5.141-28.517,5.141c-9.817,0-19.411-1.729-28.517-5.141 c-12.774-4.786-25.688-7.212-38.382-7.212h-43.977c-53.072,0-96.249,43.177-96.249,96.249 s43.177,96.249,96.249,96.249h221.752c53.071,0,96.248-43.177,96.248-96.249 C433.277,173.082,390.101,129.905,337.029,129.905z  M425.277,226.154c0,6.906-0.799,13.629-2.307,20.083l-52.619-12.025 c0.547-2.622,0.835-5.317,0.835-8.058c0-11.668-5.046-21.946-12.086-29.023l29.154-42.797 C410.651,170.355,425.277,196.578,425.277,226.154z  M381.54,149.98l-28.659,42.07c-4.811-3.148-10.046-4.934-15.022-4.934l-49.59,0 l9.156-49.212h39.604C353.253,137.905,368.464,142.31,381.54,149.98z  M226.153,150.258c10.778,0,21.316-1.901,31.323-5.649 c10.602-3.972,21.277-6.182,31.794-6.613l-9.747,52.39c-0.218,1.168,0.097,2.374,0.856,3.288 s1.888,1.443,3.076,1.443l54.402,0c11.472,0,25.327,13.845,25.327,31.037c0,8.293-3.228,16.088-9.088,21.949 c-5.86,5.86-13.655,9.088-21.949,9.088H120.153c-17.114,0-31.037-13.923-31.037-31.037c0-8.293,3.228-16.088,9.088-21.949 c5.437-5.436,13.095-9.088,19.056-9.088l52.125,0c1.189,0,2.316-0.529,3.076-1.443c0.76-0.914,1.074-2.12,0.856-3.288 l-9.745-52.377c10.343,0.484,20.837,2.696,31.257,6.6C204.836,148.357,215.375,150.258,226.153,150.258z  M127.575,265.191h94.578v49.211H119.945L127.575,265.191z  M230.153,265.191h95.412l7.63,49.211H230.153V265.191z  M155.416,137.905l9.156,49.212l-47.312,0c-5.305,0-11.313,1.95-16.783,5.253l-29.116-42.741 c12.941-7.455,27.939-11.723,43.916-11.723H155.416z  M64.617,153.937l29.426,43.197c-0.51,0.46-1.011,0.929-1.496,1.414 c-7.372,7.372-11.431,17.176-11.431,27.606c0,2.826,0.309,5.581,0.883,8.239L29.38,246.417 c-1.535-6.509-2.351-13.293-2.351-20.264C27.029,196.33,41.901,169.919,64.617,153.937z  M31.574,254.122l52.928-12.096c6.008,13.441,19.393,22.882,34.98,23.147l-7.621,49.156 C74.461,312.898,42.952,288.086,31.574,254.122z  M341.275,314.298l-7.619-49.144c9.865-0.372,19.083-4.379,26.098-11.395 c3.486-3.486,6.22-7.52,8.146-11.902l52.89,12.087C409.546,287.748,378.376,312.532,341.275,314.298z"
            , fill colorStr
            ]
            []
        , Svg.path
            [ d "M337.263,111.11h-74.512c-0.771,0-1.527,0.223-2.175,0.643 c-10.268,6.653-22.171,10.169-34.423,10.169c-12.252,0-24.156-3.516-34.423-10.169 c-0.648-0.42-1.403-0.643-2.175-0.643h-74.512C51.608,111.11,0,162.718,0,226.154 c0,63.435,51.608,115.043,115.043,115.043h222.219c63.436,0,115.044-51.608,115.044-115.044 C452.307,162.718,400.698,111.11,337.263,111.11z  M337.263,333.197H115.043C56.02,333.197,8,285.177,8,226.153 C8,167.129,56.02,119.11,115.043,119.11h73.348c11.333,7.078,24.362,10.812,37.762,10.812 c13.399,0,26.429-3.734,37.762-10.812h73.348c59.024,0,107.044,48.02,107.044,107.044 C444.307,285.177,396.287,333.197,337.263,333.197z"
            , fill colorStr
            ]
            []
        ]


dollar : DollarOptions -> Html.Html msg
dollar options =
    let
        sizeStr =
            String.fromFloat options.size

        colorStr =
            colorToRgbString options.color
    in
    Svg.svg
        [ Svg.Attributes.width sizeStr
        , Svg.Attributes.height sizeStr
        , viewBox "0 0 32 32"
        , Html.Attributes.style "display" "block"
        ]
        [ Svg.path
            [ d "M0 25v-18h32v18h-32zM2 8.938v14.062h28v-14.062h-28zM21 16c0-3.313-2.238-6-5-6h13v12h-13c2.762 0 5-2.687 5-6zM25 18c0.828 0 1.5-0.896 1.5-2s-0.672-2-1.5-2-1.5 0.896-1.5 2 0.672 2 1.5 2zM18.118 13.478c-0.015 0.055-0.036 0.094-0.062 0.119-0.027 0.025-0.063 0.037-0.109 0.037s-0.118-0.028-0.219-0.086c-0.1-0.059-0.223-0.121-0.368-0.189-0.146-0.068-0.314-0.13-0.506-0.187s-0.402-0.083-0.631-0.083c-0.18 0-0.336 0.021-0.469 0.065s-0.245 0.104-0.334 0.18c-0.090 0.077-0.156 0.17-0.2 0.277s-0.065 0.222-0.065 0.342c0 0.18 0.049 0.335 0.147 0.466s0.229 0.248 0.394 0.35c0.165 0.103 0.351 0.198 0.56 0.287 0.207 0.090 0.42 0.185 0.637 0.284 0.217 0.101 0.429 0.214 0.637 0.341s0.395 0.279 0.557 0.456 0.293 0.385 0.394 0.624c0.1 0.24 0.149 0.521 0.149 0.847 0 0.425-0.078 0.797-0.236 1.118s-0.373 0.588-0.645 0.802c-0.271 0.215-0.587 0.376-0.949 0.484-0.046 0.014-0.096 0.020-0.143 0.031v1.092h-0.983v-0.963c-0.013 0-0.024 0.002-0.036 0.002-0.279 0-0.539-0.022-0.778-0.067s-0.451-0.101-0.634-0.164c-0.184-0.064-0.336-0.131-0.459-0.201s-0.211-0.132-0.265-0.186c-0.054-0.054-0.093-0.132-0.116-0.234-0.023-0.103-0.035-0.249-0.035-0.441 0-0.129 0.004-0.237 0.013-0.325s0.022-0.158 0.041-0.213 0.043-0.093 0.075-0.116c0.031-0.022 0.067-0.034 0.109-0.034 0.058 0 0.14 0.034 0.247 0.103s0.243 0.145 0.409 0.228c0.167 0.084 0.365 0.159 0.597 0.229 0.231 0.068 0.499 0.103 0.803 0.103 0.2 0 0.379-0.024 0.537-0.072s0.293-0.115 0.403-0.203 0.194-0.196 0.253-0.325c0.059-0.13 0.088-0.273 0.088-0.433 0-0.183-0.051-0.34-0.15-0.472-0.1-0.131-0.23-0.247-0.391-0.35-0.16-0.102-0.342-0.197-0.546-0.287s-0.414-0.185-0.631-0.284c-0.216-0.1-0.427-0.213-0.631-0.341s-0.386-0.278-0.546-0.455c-0.16-0.177-0.291-0.387-0.39-0.628s-0.15-0.531-0.15-0.868c0-0.388 0.072-0.728 0.215-1.021s0.337-0.537 0.581-0.73 0.531-0.338 0.862-0.434c0.17-0.050 0.346-0.085 0.526-0.109v-1.034h0.983v1.034c0.039 0.005 0.078 0.003 0.117 0.009 0.191 0.029 0.371 0.068 0.537 0.118 0.167 0.049 0.314 0.104 0.444 0.167 0.129 0.062 0.214 0.113 0.256 0.155s0.069 0.076 0.085 0.105c0.014 0.029 0.026 0.068 0.037 0.116s0.018 0.108 0.021 0.182c0.004 0.072 0.006 0.163 0.006 0.271 0 0.121-0.003 0.224-0.009 0.308-0.009 0.079-0.019 0.149-0.034 0.203zM11 16c0 3.313 2.238 6 5 6h-13v-12h13c-2.762 0-5 2.687-5 6zM7 14c-0.829 0-1.5 0.896-1.5 2s0.671 2 1.5 2c0.828 0 1.5-0.896 1.5-2s-0.672-2-1.5-2z"
            , fill colorStr
            ]
            []
        ]


timer : TimerOptions -> Html.Html msg
timer options =
    let
        sizeStr =
            String.fromFloat options.size

        backgroundColorStr =
            colorToRgbString options.backgroundColor

        armColorStr =
            colorToRgbString options.armColor

        centerX =
            200.0

        centerY =
            200.0

        radius =
            120.0

        armLength =
            90.0

        markerRadius =
            100.0

        -- Calculate angle: progress 1.0 (full time) = top (12 o'clock), progress 0.0 (no time) = bottom (6 o'clock)
        -- Angle in radians: 2 * pi * (0.75 - progress) gives us clockwise rotation from top
        angle =
            2 * pi * (0.75 - options.progress)

        armX =
            centerX + armLength * cos angle

        armY =
            centerY + armLength * sin angle

        -- Calculate marker values based on duration
        marker1 =
            options.duration / 4

        marker2 =
            options.duration / 2

        marker3 =
            3 * options.duration / 4

        marker4 =
            options.duration

        -- Marker positions: 3 o'clock (right), 6 o'clock (bottom), 9 o'clock (left), 12 o'clock (top)
        marker3X =
            centerX + markerRadius

        marker3Y =
            centerY

        marker6X =
            centerX

        marker6Y =
            centerY + markerRadius

        marker9X =
            centerX - markerRadius

        marker9Y =
            centerY

        marker12X =
            centerX

        marker12Y =
            centerY - markerRadius
    in
    Svg.svg
        [ Svg.Attributes.width sizeStr
        , Svg.Attributes.height sizeStr
        , viewBox "0 0 400 400"
        , Html.Attributes.style "display" "block"
        ]
        [ Svg.circle
            [ cx (String.fromFloat centerX)
            , cy (String.fromFloat centerY)
            , r (String.fromFloat radius)
            , fill backgroundColorStr
            ]
            []

        -- Marker at 3 o'clock (right)
        , Svg.text_
            [ x (String.fromFloat marker3X)
            , y (String.fromFloat marker3Y)
            , textAnchor "middle"
            , dominantBaseline "middle"
            , fontSize "24"
            , fill armColorStr
            ]
            [ Svg.text (String.fromInt (round marker1)) ]

        -- Marker at 6 o'clock (bottom)
        , Svg.text_
            [ x (String.fromFloat marker6X)
            , y (String.fromFloat marker6Y)
            , textAnchor "middle"
            , dominantBaseline "middle"
            , fontSize "24"
            , fill armColorStr
            ]
            [ Svg.text (String.fromInt (round marker2)) ]

        -- Marker at 9 o'clock (left)
        , Svg.text_
            [ x (String.fromFloat marker9X)
            , y (String.fromFloat marker9Y)
            , textAnchor "middle"
            , dominantBaseline "middle"
            , fontSize "24"
            , fill armColorStr
            ]
            [ Svg.text (String.fromInt (round marker3)) ]

        -- Marker at 12 o'clock (top)
        , Svg.text_
            [ x (String.fromFloat marker12X)
            , y (String.fromFloat marker12Y)
            , textAnchor "middle"
            , dominantBaseline "middle"
            , fontSize "24"
            , fill armColorStr
            ]
            [ Svg.text (String.fromInt (round marker4)) ]
        , Svg.line
            [ x1 (String.fromFloat centerX)
            , y1 (String.fromFloat centerY)
            , x2 (String.fromFloat armX)
            , y2 (String.fromFloat armY)
            , stroke armColorStr
            , strokeWidth "6"
            , strokeLinecap "round"
            ]
            []
        ]
