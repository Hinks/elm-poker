module Icons.BlindOptions exposing (BlindOptions)

import Element exposing (Color)


type alias BlindOptions =
    { size : Float
    , backgroundColor : Color
    , labelTextColor : Color
    , valueTextColor : Color
    , value : Int
    }
