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
    , buttonText : Color
    , chipWhite : Color
    , chipRed : Color
    , chipBlue : Color
    , chipGreen : Color
    , chipBlack : Color
    , bigBlindBackground : Color
    , smallBlindBackground : Color
    , timerBackground : Color
    , bigBlindText : Color
    , smallBlindText : Color
    , pokerTable : Color
    , prizeGold : Color
    , cardBackground : Color
    , cardRedSuit : Color
    , cardBlackSuit : Color
    , removeButton : Color
    }


getColors : Theme -> ColorPalette
getColors theme =
    case theme of
        Light ->
            { background = rgb255 250 250 252
            , surface = rgb255 255 255 255
            , text = rgb255 45 50 60
            , textSecondary = rgb255 90 100 115
            , primary = rgb255 34 197 94
            , accent = rgb255 52 211 153
            , border = rgb255 180 190 200
            , chipTextOnLight = rgb255 33 33 33
            , chipTextOnDark = rgb255 255 255 255
            , buttonText = rgb255 255 255 255
            , chipWhite = rgb255 255 255 255
            , chipRed = rgb255 220 20 60
            , chipBlue = rgb255 30 144 255
            , chipGreen = rgb255 34 139 34
            , chipBlack = rgb255 0 0 0
            , bigBlindBackground = rgb255 220 170 80
            , smallBlindBackground = rgb255 160 210 255
            , timerBackground = rgb255 180 230 210
            , bigBlindText = rgb255 255 215 0
            , smallBlindText = rgb255 30 144 255
            , pokerTable = rgb255 10 143 60
            , prizeGold = rgb255 255 215 0
            , cardBackground = rgb255 230 238 244
            , cardRedSuit = rgb255 215 30 0
            , cardBlackSuit = rgb255 0 0 0
            , removeButton = rgb255 232 67 63
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
            , buttonText = rgb255 255 255 255
            , chipWhite = rgb255 255 255 255
            , chipRed = rgb255 220 20 60
            , chipBlue = rgb255 30 144 255
            , chipGreen = rgb255 34 139 34
            , chipBlack = rgb255 0 0 0
            , bigBlindBackground = rgb255 220 170 80
            , smallBlindBackground = rgb255 160 210 255
            , timerBackground = rgb255 180 230 210
            , bigBlindText = rgb255 255 215 0
            , smallBlindText = rgb255 30 144 255
            , pokerTable = rgb255 10 143 60
            , prizeGold = rgb255 255 215 0
            , cardBackground = rgb255 230 238 244
            , cardRedSuit = rgb255 215 30 0
            , cardBlackSuit = rgb255 0 0 0
            , removeButton = rgb255 232 67 63
            }


defaultTheme : Theme
defaultTheme =
    Dark
