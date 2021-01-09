module Main exposing (..)

import Browser
import Html as H
import Json.Decode as JD

-- MODEL

type alias Model =
  { person : Maybe String
  }

type Msg = Noop


-- LOGIC

main = Browser.element
  { init = init
  , view = view
  , update = update
  , subscriptions = \_ -> Sub.none
  }

flagsDecoder : JD.Decoder { person : Maybe String }
flagsDecoder =
  JD.map
    (\s -> { person = s })
    (JD.field "person" <| JD.nullable JD.string)

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
