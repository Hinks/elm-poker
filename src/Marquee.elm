module Marquee exposing (view)

import Element
import Html
import Html.Attributes as Attr


-- Style Helpers


containerStyles : List (Html.Attribute msg)
containerStyles =
    [ Attr.style "width" "100%"
    , Attr.style "height" "40px"
    , Attr.style "background-color" "transparent"
    , Attr.style "overflow" "hidden"
    , Attr.style "white-space" "nowrap"
    , Attr.style "display" "flex"
    , Attr.style "position" "relative"
    ]


itemStyles : String -> List (Html.Attribute msg)
itemStyles animationDuration =
    [ Attr.style "animation" ("marquee-content " ++ animationDuration ++ " linear infinite")
    , Attr.style "padding" "5px 15px"
    , Attr.style "line-height" "40px"
    , Attr.style "font-size" "16px"
    , Attr.style "color" "rgb(255, 255, 255)"
    , Attr.style "font-weight" "500"
    , Attr.style "white-space" "nowrap"
    , Attr.style "flex-shrink" "0"
    ]


keyframesCss : String
keyframesCss =
    "@keyframes marquee-content {\n"
        ++ "    0% {\n"
        ++ "        transform: translateX(0%);\n"
        ++ "    }\n"
        ++ "    100% {\n"
        ++ "        transform: translateX(-100%);\n"
        ++ "    }\n"
        ++ "}"


view : List String -> Element.Element msg
view strings =
    let
        marqueeText =
            String.join "   •   " strings

        -- Calculate duration based on text length to maintain consistent speed
        -- Using character count as a proxy for width
        -- Base speed: ~10 characters per second (adjustable)
        textLength =
            String.length marqueeText

        baseSpeedCharsPerSecond =
            10.0

        calculatedDurationSeconds =
            toFloat textLength / baseSpeedCharsPerSecond

        -- Minimum duration to prevent too-fast scrolling on short text
        minDurationSeconds =
            20.0

        finalDurationSeconds =
            max minDurationSeconds calculatedDurationSeconds

        animationDuration =
            String.fromFloat finalDurationSeconds ++ "s"
    in
    Element.html <|
        Html.div []
            [ Html.node "style" [] [ Html.text keyframesCss ]
            , Html.div
                containerStyles
                [ Html.div
                    (itemStyles animationDuration)
                    [ Html.text marqueeText ]
                , Html.div
                    (itemStyles animationDuration)
                    [ Html.text marqueeText ]
                ]
            ]
