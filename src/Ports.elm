port module Ports exposing (Incoming(..), Outgoing(..), send, subscriptions)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


port toJs : Encode.Value -> Cmd msg


port fromJs : (Decode.Value -> msg) -> Sub msg


type Outgoing
    = BlindTimerAlert


type Incoming
    = IncomingNoOp


encodeOutgoing : Outgoing -> Encode.Value
encodeOutgoing outgoing =
    case outgoing of
        BlindTimerAlert ->
            Encode.object
                [ ( "tag", Encode.string "BlindTimerAlert" )
                , ( "data", Encode.null )
                ]


send : Outgoing -> Cmd msg
send outgoing =
    toJs (encodeOutgoing outgoing)


incomingDecoder : Decoder Incoming
incomingDecoder =
    Decode.field "tag" Decode.string
        |> Decode.andThen
            (\tag ->
                case tag of
                    "IncomingNoOp" ->
                        Decode.succeed IncomingNoOp

                    _ ->
                        Decode.succeed IncomingNoOp
            )


decodeIncoming : Decode.Value -> Incoming
decodeIncoming value =
    case Decode.decodeValue incomingDecoder value of
        Ok incoming ->
            incoming

        Err _ ->
            IncomingNoOp


subscriptions : (Incoming -> msg) -> Sub msg
subscriptions tagger =
    fromJs (decodeIncoming >> tagger)


