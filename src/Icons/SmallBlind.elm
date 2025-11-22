module Icons.SmallBlind exposing (smallBlind)

import Html
import Html.Attributes
import Icons.BlindOptions
import Icons.Internal
import Svg
import Svg.Attributes exposing (cx, cy, dominantBaseline, fill, fontSize, fontWeight, r, textAnchor, viewBox, x, y)


smallBlind : Icons.BlindOptions.BlindOptions -> Html.Html msg
smallBlind options =
    let
        sizeStr =
            String.fromFloat options.size

        backgroundColorStr =
            Icons.Internal.colorToRgbString options.backgroundColor

        labelTextColorStr =
            Icons.Internal.colorToRgbString options.labelTextColor

        valueTextColorStr =
            Icons.Internal.colorToRgbString options.valueTextColor

        centerX =
            100.0

        centerY =
            100.0

        radius =
            90.0

        smallLabelY =
            32.0

        blindLabelY =
            48.0

        valueY =
            centerY

        labelFontSize =
            String.fromFloat (options.size * 0.12)

        valueFontSize =
            String.fromFloat (options.size * 0.25)
    in
    Svg.svg
        [ Svg.Attributes.width sizeStr
        , Svg.Attributes.height sizeStr
        , viewBox "0 0 200 200"
        , Html.Attributes.style "display" "block"
        ]
        [ Svg.circle
            [ cx (String.fromFloat centerX)
            , cy (String.fromFloat centerY)
            , r (String.fromFloat radius)
            , fill backgroundColorStr
            ]
            []
        , Svg.text_
            [ x (String.fromFloat centerX)
            , y (String.fromFloat smallLabelY)
            , textAnchor "middle"
            , dominantBaseline "middle"
            , fontSize labelFontSize
            , fill labelTextColorStr
            ]
            [ Svg.text "SMALL" ]
        , Svg.text_
            [ x (String.fromFloat centerX)
            , y (String.fromFloat blindLabelY)
            , textAnchor "middle"
            , dominantBaseline "middle"
            , fontSize labelFontSize
            , fill labelTextColorStr
            ]
            [ Svg.text "BLIND" ]
        , Svg.text_
            [ x (String.fromFloat centerX)
            , y (String.fromFloat valueY)
            , textAnchor "middle"
            , dominantBaseline "middle"
            , fontSize valueFontSize
            , fontWeight "bold"
            , fill valueTextColorStr
            ]
            [ Svg.text (String.fromInt options.value) ]
        ]
