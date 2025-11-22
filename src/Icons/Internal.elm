module Icons.Internal exposing (colorToRgbString)

import Element exposing (Color)


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
