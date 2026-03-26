mod game;
mod routes;

use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use tower_http::services::ServeDir;

#[tokio::main]
async fn main() {
    let state = Arc::new(Mutex::new(HashMap::new()));

    let app = routes::api_router()
        .fallback_service(ServeDir::new("static"))
        .with_state(state);

    let listener = tokio::net::TcpListener::bind("127.0.0.1:3000")
        .await
        .unwrap();
    println!("Server running on http://127.0.0.1:3000");
    axum::serve(listener, app).await.unwrap();
}
