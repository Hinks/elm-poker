module Marquee exposing
    ( clampMarqueeFontSizePx
    , defaultFontSizePx
    , marqueeFontSizeMax
    , marqueeFontSizeMin
    , marqueeFontSizeStep
    , view
    )

import Element
import Html
import Html.Attributes as Attr


marqueeFontSizeMin : Int
marqueeFontSizeMin =
    10


marqueeFontSizeMax : Int
marqueeFontSizeMax =
    32


marqueeFontSizeStep : Int
marqueeFontSizeStep =
    2


defaultFontSizePx : Int
defaultFontSizePx =
    24


clampMarqueeFontSizePx : Int -> Int
clampMarqueeFontSizePx n =
    min marqueeFontSizeMax (max marqueeFontSizeMin n)



-- Style Helpers


containerStyles : Int -> List (Html.Attribute msg)
containerStyles rowHeightPx =
    [ Attr.style "width" "100%"
    , Attr.style "height" (String.fromInt rowHeightPx ++ "px")
    , Attr.style "background-color" "transparent"
    , Attr.style "overflow" "hidden"
    , Attr.style "white-space" "nowrap"
    , Attr.style "display" "flex"
    , Attr.style "position" "relative"
    ]


itemStyles : String -> Int -> Int -> List (Html.Attribute msg)
itemStyles animationDuration fontSizePx rowHeightPx =
    let
        verticalPad =
            max 2 (fontSizePx // 3)
    in
    [ Attr.style "animation" ("marquee-content " ++ animationDuration ++ " linear infinite")
    , Attr.style "padding" (String.fromInt verticalPad ++ "px 15px")
    , Attr.style "line-height" (String.fromInt rowHeightPx ++ "px")
    , Attr.style "font-size" (String.fromInt fontSizePx ++ "px")
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


view : Int -> List String -> Element.Element msg
view fontSizePx strings =
    let
        marqueeText =
            String.join "   •   " strings

        rowHeightPx =
            max 28 (fontSizePx * 5 // 2)

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

        itemAttrs =
            itemStyles animationDuration fontSizePx rowHeightPx
    in
    Element.html <|
        Html.div []
            [ Html.node "style" [] [ Html.text keyframesCss ]
            , Html.div
                (containerStyles rowHeightPx)
                [ Html.div
                    itemAttrs
                    [ Html.text marqueeText ]
                , Html.div
                    itemAttrs
                    [ Html.text marqueeText ]
                ]
            ]
