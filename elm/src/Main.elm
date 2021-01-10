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
  = FetchPerson
  | FetchedPerson (Result Http.Error PersonPb.GetPersonResponse)
  | AgePerson
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
    , H.button [HE.onClick FetchPerson] [H.text "Refresh"]
    , H.text " "
    , H.button [HE.onClick AgePerson] [H.text "Age"]
    ]

type alias Endpoint req resp = { url : String , toEncoder : req -> PBE.Encoder , decoder : PBD.Decoder resp }
getPerson = { url = "/api/get_person" , toEncoder = PersonPb.toGetPersonRequestEncoder , decoder = PersonPb.getPersonResponseDecoder }
agePerson = { url = "/api/age_person" , toEncoder = PersonPb.toAgePersonRequestEncoder , decoder = PersonPb.agePersonResponseDecoder }

hitEndpoint : Endpoint req resp -> (Result Http.Error resp -> msg) -> req -> Cmd msg
hitEndpoint endpoint toMsg req =
  Http.post
    { url = endpoint.url
    , body = endpoint.toEncoder req |> PBE.encode |> Http.bytesBody "application/octet-stream"
    , expect = PBD.expectBytes toMsg endpoint.decoder
    }

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of

    FetchPerson ->
      ( { model | working = True }
      , hitEndpoint getPerson FetchedPerson {}
      )

    FetchedPerson (Ok resp) ->
      ( { model | working = False, person = resp.person }
      , Cmd.none
      )

    FetchedPerson (Err e) -> Debug.log ("error fetching person: " ++ Debug.toString e)
      ( { model | working = False, person = Nothing }
      , Cmd.none
      )

    AgePerson ->
      ( { model | working = True }
      , hitEndpoint agePerson AgedPerson {delta=1}
      )

    AgedPerson (Ok resp) ->
      ( { model | working = False }
      , hitEndpoint getPerson FetchedPerson {}
      )

    AgedPerson (Err e) -> Debug.log ("error aging person: " ++ Debug.toString e)
      ( { model | working = False, person = Nothing }
      , Cmd.none
      )
