module Marquee exposing (view)

import Element
import Html
import Html.Attributes as Attr


generateCss : String -> String
generateCss animationDuration =
    ".marquee-container {\n"
        ++ "    width: 100%;\n"
        ++ "    height: 40px;\n"
        ++ "    background-color: transparent;\n"
        ++ "    overflow: hidden;\n"
        ++ "    white-space: nowrap;\n"
        ++ "    display: flex;\n"
        ++ "    position: relative;\n"
        ++ "}\n\n"
        ++ ".marquee-item {\n"
        ++ "    animation: marquee-content "
        ++ animationDuration
        ++ " linear infinite;\n"
        ++ "    padding: 5px 15px;\n"
        ++ "    line-height: 40px;\n"
        ++ "    font-size: 16px;\n"
        ++ "    color: rgb(255, 255, 255);\n"
        ++ "    font-weight: 500;\n"
        ++ "    white-space: nowrap;\n"
        ++ "    flex-shrink: 0;\n"
        ++ "}\n\n"
        ++ "@keyframes marquee-content {\n"
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
            [ Html.node "style" [] [ Html.text (generateCss animationDuration) ]
            , Html.div
                [ Attr.class "marquee-container" ]
                [ Html.div
                    [ Attr.class "marquee-item" ]
                    [ Html.text marqueeText ]
                , Html.div
                    [ Attr.class "marquee-item" ]
                    [ Html.text marqueeText ]
                ]
            ]
