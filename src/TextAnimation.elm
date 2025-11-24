module TextAnimation exposing (Config, defaultConfig, view)

import Element exposing (Color)
import Html
import Html.Attributes as Attr



-- Config


type alias Config =
    { speed : Float
    , repeat : Int
    , textColor : Color
    , fontSizeMin : Float
    , fontSizePreferred : String
    , fontSizeMax : Float
    }


defaultConfig : Config
defaultConfig =
    { speed = 10.0
    , repeat = 3
    , textColor = Element.rgb255 255 255 255
    , fontSizeMin = 0.5
    , fontSizePreferred = "6vh"
    , fontSizeMax = 1.5
    }



-- Color Conversion


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



-- CSS Styles


generateCss : Config -> String
generateCss config =
    let
        textColorStr =
            colorToRgbString config.textColor

        fontSizeClamp =
            "clamp("
                ++ String.fromFloat config.fontSizeMin
                ++ "rem, "
                ++ config.fontSizePreferred
                ++ ", "
                ++ String.fromFloat config.fontSizeMax
                ++ "rem)"
    in
    ".marquee-container {\n"
        ++ "    position: relative;\n"
        ++ "    width: 100%;\n"
        ++ "    height: 100%;\n"
        ++ "    overflow: hidden;\n"
        ++ "    display: flex;\n"
        ++ "    align-items: center;\n"
        ++ "    background-color: transparent;\n"
        ++ "}\n\n"
        ++ ".marquee-text {\n"
        ++ "    position: absolute;\n"
        ++ "    white-space: nowrap;\n"
        ++ "    display: inline-block;\n"
        ++ "    font-size: "
        ++ fontSizeClamp
        ++ ";\n"
        ++ "    font-weight: bold;\n"
        ++ "    color: "
        ++ textColorStr
        ++ " !important;\n"
        ++ "    -webkit-text-stroke: 1px black;\n"
        ++ "    text-shadow: -1px -1px 0 #000, 1px -1px 0 #000, -1px 1px 0 #000, 1px 1px 0 #000, 0 0 1px #000;\n"
        ++ "    font-family: Arial, sans-serif;\n"
        ++ "    animation: marquee-left "
        ++ String.fromFloat config.speed
        ++ "s linear infinite;\n"
        ++ "}\n\n"
        ++ "@keyframes marquee-left {\n"
        ++ "    0% {\n"
        ++ "        left: 100%;\n"
        ++ "        transform: translateX(0);\n"
        ++ "    }\n"
        ++ "    100% {\n"
        ++ "        left: 0;\n"
        ++ "        transform: translateX(-100%);\n"
        ++ "    }\n"
        ++ "}"



-- View


view : Config -> String -> Html.Html msg
view config message =
    let
        repeatedText =
            String.join " " (List.repeat config.repeat message)

        -- Calculate animation duration based on text length
        -- To make all text move at the same visual speed, we scale the duration
        -- proportionally to the text length. Longer text gets longer duration,
        -- so the visual speed (characters per second) remains constant.
        textLength : Float
        textLength =
            toFloat (String.length repeatedText)

        -- Reference length: 20 characters (roughly "Royal Flush" length)
        -- Text longer than this gets proportionally longer duration
        -- Text shorter than this gets proportionally shorter duration
        referenceLength : Float
        referenceLength =
            20.0

        -- Scale duration: if text is 2x longer, duration is 2x longer
        -- This maintains the same visual speed for all text lengths
        adjustedSpeed : Float
        adjustedSpeed =
            config.speed * (textLength / referenceLength)
    in
    Html.div
        [ Attr.class "marquee-container" ]
        [ Html.node "style" [] [ Html.text (generateCss { config | speed = adjustedSpeed }) ]
        , Html.div
            [ Attr.class "marquee-text" ]
            [ Html.text repeatedText ]
        ]
