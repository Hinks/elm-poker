module Theme exposing (ColorPalette, Theme(..), defaultTheme, getColors)

import Element exposing (Color, rgb255)


type Theme
    = Light
    | Dark


type alias ColorPalette =
    { background : Color
    , surface : Color
    , text : Color
    , textSecondary : Color
    , primary : Color
    , accent : Color
    , border : Color
    }


getColors : Theme -> ColorPalette
getColors theme =
    case theme of
        Light ->
            { background = rgb255 255 255 255
            , surface = rgb255 250 250 250
            , text = rgb255 33 33 33
            , textSecondary = rgb255 117 117 117
            , primary = rgb255 25 118 210
            , accent = rgb255 48 63 159
            , border = rgb255 224 224 224
            }

        Dark ->
            { background = rgb255 18 18 18
            , surface = rgb255 30 30 30
            , text = rgb255 255 255 255
            , textSecondary = rgb255 189 189 189
            , primary = rgb255 66 165 245
            , accent = rgb255 100 181 246
            , border = rgb255 66 66 66
            }


defaultTheme : Theme
defaultTheme =
    Light
