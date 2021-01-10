module Main exposing (..)

import Browser
import Html as H
import Html.Events as HE
import Http
import Json.Decode as JD

import Base64
import Protobuf.Decode as PBD
import Protobuf.Encode as PBE
import Protobuf.Person as PersonPb


-- MODEL

type alias Model =
  { person : Maybe PersonPb.Person
  , working : Bool
  }

type Msg
  = AgePerson
  | AgedPerson (Result Http.Error PersonPb.AgePersonResponse)


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
      ( { person = flags.person , working = False }
      , Cmd.none
      )
    Err e -> Debug.log ("failed to parse flags: " ++ Debug.toString e)
      ( { person = Nothing , working = False }
      , Cmd.none
      )

view : Model -> H.Html Msg
view model =
  H.div []
    [ H.text <| Debug.toString model
    , H.br [] []
    , H.button [HE.onClick AgePerson] [H.text "Age"]
    ]

agePerson : PersonPb.AgePersonRequest -> Cmd Msg
agePerson req =
  Http.post
    { url = "/api/age_person"
    , body = req |> PersonPb.toAgePersonRequestEncoder |> PBE.encode |> Http.bytesBody "application/octet-stream"
    , expect = PBD.expectBytes AgedPerson PersonPb.agePersonResponseDecoder
    }

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of

    AgePerson ->
      ( { model | working = True }
      , agePerson {delta=1}
      )

    AgedPerson (Ok resp) ->
      ( { model | person = resp.newPerson , working = False }
      , Cmd.none
      )

    AgedPerson (Err e) -> Debug.log ("error aging person: " ++ Debug.toString e)
      ( { model | working = False, person = Nothing }
      , Cmd.none
      )
