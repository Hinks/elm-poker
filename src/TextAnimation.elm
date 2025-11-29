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
    , message : String
    }


defaultConfig : Config
defaultConfig =
    { speed = 10.0
    , repeat = 3
    , textColor = Element.rgb255 255 255 255
    , fontSizeMin = 0.5
    , fontSizePreferred = "6vh"
    , fontSizeMax = 1.5
    , message = ""
    }



-- Style Helpers


fontSizeClampString : Config -> String
fontSizeClampString config =
    "clamp("
        ++ String.fromFloat config.fontSizeMin
        ++ "rem, "
        ++ config.fontSizePreferred
        ++ ", "
        ++ String.fromFloat config.fontSizeMax
        ++ "rem)"



-- Bright white gradient with strong shadow for visibility on dark backgrounds


gradientBackground : String
gradientBackground =
    "linear-gradient(90deg, #ffffff, #f5f5f5, #ffffff, #fafafa, #ffffff, #f0f0f0)"


textStyles : Config -> List (Html.Attribute msg)
textStyles config =
    [ Attr.style "position" "absolute"
    , Attr.style "white-space" "nowrap"
    , Attr.style "display" "inline-block"
    , Attr.style "font-size" (fontSizeClampString config)
    , Attr.style "font-weight" "900"
    , Attr.style "background" gradientBackground
    , Attr.style "-webkit-background-clip" "text"
    , Attr.style "background-clip" "text"
    , Attr.style "-webkit-text-fill-color" "transparent"
    , Attr.style "color" "transparent"
    , Attr.style "filter" "drop-shadow(0 0 3px rgba(0, 0, 0, 0.9)) drop-shadow(0 0 6px rgba(0, 0, 0, 0.7)) drop-shadow(0 0 9px rgba(0, 0, 0, 0.5))"
    , Attr.style "font-family" "Arial, sans-serif"
    , Attr.style "letter-spacing" "0.05em"
    , Attr.style "animation" ("marquee-left " ++ String.fromFloat config.speed ++ "s linear infinite")
    ]


keyframesCss : String
keyframesCss =
    "@keyframes marquee-left {\n"
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


view : Config -> Html.Html msg
view config =
    let
        repeatedText =
            String.join " " (List.repeat config.repeat config.message)

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

        containerStyles : List (Html.Attribute msg)
        containerStyles =
            [ Attr.style "position" "relative"
            , Attr.style "width" "100%"
            , Attr.style "height" "100%"
            , Attr.style "overflow" "hidden"
            , Attr.style "display" "flex"
            , Attr.style "align-items" "center"
            , Attr.style "background-color" "transparent"
            ]
    in
    Html.div
        containerStyles
        [ Html.node "style" [] [ Html.text keyframesCss ]
        , Html.div
            (textStyles { config | speed = adjustedSpeed })
            [ Html.text repeatedText ]
        ]
