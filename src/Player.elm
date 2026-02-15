module Player exposing (Player(..), getName)


type Player
    = Player String


getName : Player -> String
getName (Player name) =
    name
