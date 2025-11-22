module Icons.Timer exposing (TimerOptions, timer)

import Element exposing (Color)
import Html
import Html.Attributes
import Icons.Internal
import Svg
import Svg.Attributes exposing (cx, cy, dominantBaseline, fill, fontSize, r, stroke, strokeLinecap, strokeWidth, textAnchor, viewBox, x, x1, x2, y, y1, y2)


type alias TimerOptions =
    { size : Float
    , backgroundColor : Color
    , armColor : Color
    , progress : Float
    , duration : Float
    }


timer : TimerOptions -> Html.Html msg
timer options =
    let
        sizeStr =
            String.fromFloat options.size

        backgroundColorStr =
            Icons.Internal.colorToRgbString options.backgroundColor

        armColorStr =
            Icons.Internal.colorToRgbString options.armColor

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

        -- Check if duration is divisible by 4
        isDivisibleBy4 =
            modBy 4 (round options.duration) == 0
    in
    Svg.svg
        [ Svg.Attributes.width sizeStr
        , Svg.Attributes.height sizeStr
        , viewBox "0 0 400 400"
        , Html.Attributes.style "display" "block"
        ]
        ([ Svg.circle
            [ cx (String.fromFloat centerX)
            , cy (String.fromFloat centerY)
            , r (String.fromFloat radius)
            , fill backgroundColorStr
            ]
            []

         -- Marker at 12 o'clock (top) - always visible
         , Svg.text_
            [ x (String.fromFloat marker12X)
            , y (String.fromFloat marker12Y)
            , textAnchor "middle"
            , dominantBaseline "middle"
            , fontSize "24"
            , fill armColorStr
            ]
            [ Svg.text (String.fromInt (round marker4)) ]
         ]
            ++ (if isDivisibleBy4 then
                    -- Show all 4 markers when divisible by 4
                    [ -- Marker at 3 o'clock (right)
                      Svg.text_
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
                    ]

                else
                    -- Only show top marker when not divisible by 4
                    []
               )
            ++ [ Svg.line
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
        )
