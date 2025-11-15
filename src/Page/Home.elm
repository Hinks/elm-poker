module Page.Home exposing (view)

import Element
import Element.Font as Font
import Theme exposing (Theme)


view : Theme -> Element.Element msg
view theme =
    let
        colors =
            Theme.getColors theme
    in
    Element.el
        [ Element.width Element.fill
        , Element.padding 20
        , Font.color colors.text
        ]
        (Element.text "Home Content")
