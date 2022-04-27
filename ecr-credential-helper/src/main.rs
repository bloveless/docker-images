use std::env;
use std::error::Error;

use base64;

use dotenv::dotenv;
use serde_json::json;
use rusoto_core::Region;
use rusoto_ecr::{EcrClient, Ecr, GetAuthorizationTokenRequest};

use kube::{
    api::{RawApi, PostParams, DeleteParams},
    client::APIClient,
    config,
};

#[derive(Clone)]
struct DockerLogin {
    region: Option<Region>,
    username: Option<String>,
    password: Option<String>,
    email: Option<String>,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    dotenv().ok();
    std::env::set_var("RUST_LOG", "info,kube=trace");

    let aws_account_id = env::var("AWS_ACCOUNT_ID").unwrap();
    let aws_default_region = env::var("AWS_DEFAULT_REGION").unwrap();
    let email = env::var("EMAIL").unwrap();
    let namespaces = env::var("NAMESPACES").unwrap();

    // if running in a kubernetes cluster the assumption is that the KUBERNETES_SERVICE_HOST env
    // var will exists and only in that environment
    let config = match env::var("KUBERNETES_SERVICE_HOST") {
        Ok(_) => {
            println!("Found env KUBERNETES_SERVICE_HOST using in cluster config\n");
            config::incluster_config()?
        },
        Err(_) => {
            println!("Did not find env KUBERNETES_SERVICE_HOST using kube config file\n");
            config::load_kube_config().await?
        },
    };

    let client = APIClient::new(config);

    let docker_login = get_docker_login_from_aws_ecr(
        aws_default_region.parse::<Region>()?,
        aws_account_id.as_str(),
        email.as_str()
    )?;

    let ecr_url = format!("https://{}.dkr.ecr.{}.amazonaws.com", aws_account_id, aws_default_region);

    for namespace in namespaces.split(",") {
        println!("-- Processing namespace \"{}\" --", namespace);
        match delete_secret_in_namespace(client.clone(), aws_default_region.as_str(), namespace).await {
            Ok(_) => (),
            Err(_) => println!("Unable to delete secret. Continuing"),
        };
        update_secret_in_namespace(client.clone(), aws_default_region.as_str(), namespace, ecr_url.as_str(), docker_login.clone()).await?;
        // TODO: I forgot to actually assign the secret to the service account
        println!("-- Finished processing namespace \"{}\" --\n", namespace);
    }

    Ok(())
}

fn get_docker_login_from_aws_ecr(region: Region, aws_account_id: &str, email: &str) -> Result<DockerLogin, Box<dyn Error>> {
    println!("Retrieving docker login from aws ecr");

    let client = EcrClient::new(region.clone());
    let token_request = GetAuthorizationTokenRequest {
        registry_ids: Some(vec![aws_account_id.to_string()])
    };

    let auth_token_response = client
        .get_authorization_token(token_request)
        .sync()?;

    let auth_data = auth_token_response
        .authorization_data
        .ok_or("Unable to get authorization data")?;

    let token = auth_data.first().ok_or("Response didn't contain a token")?;
    let authorization_token = token.authorization_token.clone().unwrap();
    let dec_authorization_token = String::from_utf8(base64::decode(&authorization_token)?)?;
    let mut username: Option<String> = None;
    let mut password: Option<String> = None;

    for (i, token) in dec_authorization_token.split(":").enumerate() {
        if i == 0 {
            username = Some(token.to_string());
        } else if i == 1 {
            password = Some(token.to_string());
        }
    }

    println!("Successfully retrieved docker login from aws ecr\n");

    Ok(DockerLogin{
        region: Some(region),
        username,
        password,
        email: Some(email.to_string()),
    })
}

async fn delete_secret_in_namespace(client: APIClient, region: &str, namespace: &str) -> Result<(), Box<dyn std::error::Error>> {
    let secret_name = format!("{}-ecr-registry", region);
    println!("Deleting secret \"{}\" from namespace \"{}\"", secret_name, namespace);

    let sec = RawApi::v1Secret().within(namespace);
    let req = sec.delete(secret_name.as_str(), &DeleteParams::default())?;
    let _ = client.request_text(req).await?;

    println!("Successfully deleted secret \"{}\" from namespace \"{}\"", secret_name, namespace);

    Ok(())
}

async fn update_secret_in_namespace(
    client: APIClient,
    region: &str,
    namespace: &str,
    ecr_url: &str,
    docker_login: DockerLogin
) -> Result<(), Box<dyn std::error::Error>> {
    let secret_name = format!("{}-ecr-registry", region);
    println!("Creating new secret \"{}\" in namespace \"{}\"", secret_name, namespace);

    let secret_data = json!({
        "auths": {
            ecr_url: {
                "username": "AWS",
                "password": docker_login.password.clone().unwrap(),
                "email": docker_login.email.unwrap(),
                "auth": base64::encode(format!("{}:{}", docker_login.username.unwrap(), docker_login.password.unwrap()).as_bytes()),
            },
        }
    });

    let secret_yaml = json!({
        "apiVersion": "v1",
        "type": "kubernetes.io/dockerconfigjson",
        "metadata": {
            "name": secret_name,
            "namespace": namespace,
        },
        "data": {
            ".dockerconfigjson": base64::encode(secret_data.to_string().as_bytes()),
        },
    });

    let sec = RawApi::v1Secret().within(namespace);
    let req = sec.create(&PostParams::default(), secret_yaml.to_string().as_bytes().to_vec())?;
    let _ = client.request_text(req).await?;

    println!("Finished creating secret \"{}\" in namespace \"{}\"", secret_name, namespace);

    Ok(())
}
