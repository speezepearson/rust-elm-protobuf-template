module Main exposing (..)

import Browser
import Html as H
import Json.Decode as JD

import Base64
import Protobuf.Decode as PBD
import Protobuf.Person as PersonPb


-- MODEL

type alias Model =
  { person : Maybe PersonPb.Person
  }

type Msg = Noop


-- LOGIC

main = Browser.element
  { init = init
  , view = view
  , update = update
  , subscriptions = \_ -> Sub.none
  }

parseB64Person : String -> Maybe PersonPb.Person
parseB64Person s =
  s
  |> Base64.toBytes
  |> Maybe.andThen (PBD.decode PersonPb.personDecoder)

flagsDecoder : JD.Decoder { person : Maybe PersonPb.Person }
flagsDecoder =
  JD.map
    (\s -> { person = s })
    (JD.field "person_proto_b64" <| JD.map parseB64Person JD.string)

init : JD.Value -> ( Model , Cmd Msg )
init flagsJson =
  case JD.decodeValue flagsDecoder flagsJson of
    Ok flags ->
      ( { person = flags.person }
      , Cmd.none
      )
    Err e -> Debug.log ("failed to parse flags: " ++ Debug.toString e)
      ( { person = Nothing }
      , Cmd.none
      )

view : Model -> H.Html Msg
view model = H.text <| Debug.toString model

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
     Noop -> ( model , Cmd.none )
