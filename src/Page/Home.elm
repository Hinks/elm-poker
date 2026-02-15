module Page.Home exposing (view)

import Element
import Element.Font as Font
import Theme exposing (Theme)



-- VIEW


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
        (Element.column
            [ Element.spacing 16
            , Element.width Element.fill
            ]
            [ Element.el
                [ Font.size 32
                , Font.bold
                , Font.color colors.text
                ]
                (Element.text "Welcome to Office Poker Night!")
            , Element.paragraph
                [ Font.size 18
                , Font.color colors.textSecondary
                , Element.spacing 4
                ]
                [ Element.text "Organize players, view chip values, track blinds, and pick the champion."
                ]
            ]
        )
