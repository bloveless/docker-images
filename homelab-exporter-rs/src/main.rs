// Will create an exporter with a single metric that does not change

use anyhow::Result;
use env_logger::{Builder, Env};
use log::info;
use prometheus_exporter::prometheus::register_gauge;
use serde::{Deserialize, Serialize};
use std::env;
use std::net::SocketAddr;

#[derive(Serialize, Deserialize, Debug)]
struct ShellyResponseTemperature {
    #[serde(rename = "tC")]
    // Temperature in Celsius (null if temperature is out of the measurement range)
    celsius: f64,
    #[serde(rename = "tF")]
    // Temperature in Fahrenheit (null if temperature is out of the measurement
    fahrenheit: f64,
}

#[derive(Serialize, Deserialize, Debug)]
struct ShellyResponseActiveEnergy {
    // Total energy consumed in Watt-hours
    total: f64,
    // Energy consumption by minute (in Milliwatt-hours) for the last three minutes (the lower the index of the element in the array, the closer to the current moment the minute)
    by_minute: Vec<f64>,
    // Unix timestamp of the first second of the last minute (in UTC)
    minute_ts: i64,
}

#[derive(Serialize, Deserialize, Debug)]
struct ShellyResponse {
    // Id of the Switch component instance
    id: i64,
    // Source of the last command, for example: init, WS_in, http, ...
    source: String,
    // true if the output channel is currently on, false otherwise
    output: bool,
    // Last measured instantaneous active power (in Watts) delivered to the attached load (shown if applicable)
    apower: f64,
    // Last measured voltage in Volts (shown if applicable)
    voltage: f64,
    // Last measured current in Amperes (shown if applicable)
    current: f64,
    #[serde(rename = "aenergy")]
    // Information about the active energy counter (shown if applicable)
    active_energy: ShellyResponseActiveEnergy,
    temperature: ShellyResponseTemperature,
}

#[tokio::main]
async fn main() -> Result<()> {
    let port = env::var("PORT").unwrap_or("9090".to_string());

    // Setup logger with default level info so we can see the messages from
    // prometheus_exporter.
    Builder::from_env(Env::default().default_filter_or("info")).init();

    // Parse address used to bind exporter to.
    let addr_raw = format!("0.0.0.0:{}", port);
    let addr: SocketAddr = addr_raw.parse().expect("can not parse listen addr");

    // Create metrics
    let voltage_guage = register_gauge!(
        "homelab_power_volts",
        "Last measured voltage (Volts) of the homelab"
    )
    .expect("can not create gauge voltage_guage");

    let amperage_guage = register_gauge!(
        "homelab_power_amps",
        "Last measured amerage (Amperes) of the homelab"
    )
    .expect("can not create gauge amperage_gauge");

    let temperature_guage = register_gauge!(
        "homelab_power_temperature_f",
        "Last measured temperature of the power meter (Fahrenheit)"
    )
    .expect("can not create gauge temperature_gauge");

    let power_guage = register_gauge!(
        "homelab_power_watts",
        "Last measured instantaneous active power (Watts) delivered to the attached load"
    )
    .expect("can not create gauge power_guage");

    let power_counter = register_gauge!(
        "homelab_power_watt_hours_total",
        "Total energy consumed in Watt-hours"
    )
    .expect("can not create gauge power_counter");

    let mut last_power_reading = 0.00;

    // Start exporter
    let exporter = prometheus_exporter::start(addr).expect("can not start exporter");

    loop {
        let _guard = exporter.wait_request();
        info!("Updating metrics");

        let shelly_response: ShellyResponse =
            reqwest::get("http://192.168.4.220/rpc/Switch.GetStatus?id=0")
                .await?
                .json()
                .await?;

        info!("Shelly metrics:\n{:?}", shelly_response);

        voltage_guage.set(shelly_response.voltage);
        amperage_guage.set(shelly_response.current);
        temperature_guage.set(shelly_response.temperature.fahrenheit);
        power_guage.set(shelly_response.active_energy.total);
        power_counter.add(shelly_response.active_energy.total - last_power_reading);

        last_power_reading = shelly_response.active_energy.total;
    }
}
