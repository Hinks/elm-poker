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
    , chipTextOnLight : Color
    , chipTextOnDark : Color
    }


getColors : Theme -> ColorPalette
getColors theme =
    case theme of
        Light ->
            { background = rgb255 245 247 250
            , surface = rgb255 235 238 242
            , text = rgb255 30 35 45
            , textSecondary = rgb255 100 110 125
            , primary = rgb255 20 150 70
            , accent = rgb255 50 180 100
            , border = rgb255 200 210 220
            , chipTextOnLight = rgb255 33 33 33
            , chipTextOnDark = rgb255 255 255 255
            }

        Dark ->
            { background = rgb255 18 18 18
            , surface = rgb255 30 30 30
            , text = rgb255 255 255 255
            , textSecondary = rgb255 189 189 189
            , primary = rgb255 50 180 100
            , accent = rgb255 80 200 120
            , border = rgb255 66 66 66
            , chipTextOnLight = rgb255 33 33 33
            , chipTextOnDark = rgb255 255 255 255
            }


defaultTheme : Theme
defaultTheme =
    Dark
