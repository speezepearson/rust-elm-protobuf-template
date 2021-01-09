use actix_web::{App, HttpServer, HttpResponse, web};
use ::protobuf::Message;

mod protobuf;
use crate::protobuf::person::Person;

struct AppState {
    tera: tera::Tera,
    person: Person,
}

async fn get_index(state: web::Data<AppState>) -> HttpResponse {
    let mut context = tera::Context::new();
    context.insert("person_proto_b64", &base64::encode(state.person.write_to_bytes().unwrap()));
    let rendered = match state.tera.render("index.html", &context) {
        Ok(s) => { s }
        Err(e) => { println!("error rendering index: {}", e); return HttpResponse::InternalServerError().finish(); }
    };
    HttpResponse::Ok()
        .body(rendered)
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let state = web::Data::new(AppState {
        tera: match tera::Tera::new("templates/*.html") {
            Ok(t) => { t }
            Err(e) => { panic!(format!("unable to initialize Tera: {:?}", e)); }
        },
        person: { 
            let mut p = Person::new();
            p.set_name("Spencer".to_string());
            p.set_age(12);
            p
        },
    });
    HttpServer::new(move || {
        App::new()
            .app_data(state.clone())
            .route("/", web::get().to(get_index))
            .service(actix_files::Files::new("/static", "./static/"))
    })
        .bind(("127.0.0.1", 8080))?
        .run()
        .await
}
