use actix_web::{App, HttpServer, HttpResponse, web};
use ::protobuf::Message;

mod protobuf;
use crate::protobuf::person::Person;

struct AppState {
    tera: tera::Tera,
    person: std::sync::Mutex<Person>,
}

async fn get_index(state: web::Data<AppState>) -> HttpResponse {
    let mut context = tera::Context::new();
    context.insert("person_proto_b64", &base64::encode(state.person.lock().unwrap().write_to_bytes().unwrap()));
    let rendered = match state.tera.render("index.html", &context) {
        Ok(s) => { s }
        Err(e) => { println!("error rendering index: {}", e); return HttpResponse::InternalServerError().finish(); }
    };
    HttpResponse::Ok()
        .body(rendered)
}

async fn api_get_person(state: web::Data<AppState>) -> HttpResponse {
    HttpResponse::Ok()
        .header("Content-Type", "application/octet-stream")
        .body({
            let mut resp = protobuf::person::GetPersonResponse::new();
            resp.set_person(state.person.lock().unwrap().clone());
            resp
        }.write_to_bytes().unwrap())
}

async fn api_age_person(state: web::Data<AppState>) -> HttpResponse {
    let mut person = state.person.lock().unwrap();
    person.age = person.age + 1;
    HttpResponse::Ok()
        .header("Content-Type", "application/octet-stream")
        .body(protobuf::person::AgePersonResponse::new().write_to_bytes().unwrap())
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let state = web::Data::new(AppState {
        tera: match tera::Tera::new("templates/*.html") {
            Ok(t) => { t }
            Err(e) => { panic!(format!("unable to initialize Tera: {:?}", e)); }
        },
        person: std::sync::Mutex::new({
            let mut p = Person::new();
            p.set_name("Spencer".to_string());
            p.set_age(12);
            p
        }),
    });
    HttpServer::new(move || {
        App::new()
            .app_data(state.clone())
            .route("/", web::get().to(get_index))
            .route("/api/get_person", web::post().to(api_get_person))
            .route("/api/age_person", web::post().to(api_age_person))
            .service(actix_files::Files::new("/static", "./static/"))
    })
        .bind(("127.0.0.1", 8080))?
        .run()
        .await
}
