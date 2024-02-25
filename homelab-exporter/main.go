package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/collectors"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

type GetStatusReponse struct {
	// Id of the Switch component instance
	Id int64 `json:"id"`
	// Source of the last command, for example: init, WS_in, http, ...
	Source string `json:"source"`
	// true if the output channel is currently on, false otherwise
	Output bool `json:"output"`
	// Last measured instantaneous active power (in Watts) delivered to the attached load (shown if applicable)
	APower float64 `json:"apower"`
	// Last measured voltage in Volts (shown if applicable)
	Voltage float64 `json:"voltage"`
	// Last measured current in Amperes (shown if applicable)
	Current float64 `json:"current"`
	// Information about the active energy counter (shown if applicable)
	AEnergy struct {
		// Total energy consumed in Watt-hours
		Total float64 `json:"total"`
		// Energy consumption by minute (in Milliwatt-hours) for the last three minutes (the lower the index of the element in the array, the closer to the current moment the minute)
		ByMinute []float64 `json:"by_minute"`
		// Unix timestamp of the first second of the last minute (in UTC)
		MinuteTs int64 `json:"minute_ts"`
		Minute   time.Time
	} `json:"aenergy"`
	// Information about the temperature
	Temperature struct {
		// Temperature in Celsius (null if temperature is out of the measurement range)
		TC float64 `json:"tC"`
		// Temperature in Fahrenheit (null if temperature is out of the measurement
		TF float64 `json:"tF"`
	} `json:"temperature"`
}

func main() {
	var (
		listenAddr = flag.String("listen-address", "0.0.0.0:8080", "The address to listen on for HTTP requests.")
		switchAddr = flag.String("switch-address", "0.0.0.0", "The address to where the shelly switch can be polled.")
	)

	flag.Parse()

	log.Printf("Config - listen address: %s switch address: %s", *listenAddr, *switchAddr)

	var (
		voltageGauge = prometheus.NewGauge(
			prometheus.GaugeOpts{
				Name: "homelab_power_volts",
				Help: "Last measured voltage (Volts) of the homelab",
			},
		)
		amperageGauge = prometheus.NewGauge(
			prometheus.GaugeOpts{
				Name: "homelab_power_amps",
				Help: "Last measured amerage (Amperes) of the homelab",
			},
		)
		temperatureGauge = prometheus.NewGauge(
			prometheus.GaugeOpts{
				Name: "homelab_power_temperature_f",
				Help: "Last measured temperature of the power meter (Fahrenheit)",
			},
		)
		powerGauge = prometheus.NewGauge(
			prometheus.GaugeOpts{
				Name: "homelab_power_watts",
				Help: "Last measured instantaneous active power (Watts) delivered to the attached load",
			},
		)
		powerCounter = prometheus.NewGauge(
			prometheus.GaugeOpts{
				Name: "homelab_power_watt_hours_total",
				Help: "Total energy consumed in Watt-hours",
			},
		)
		lastPowerReading = 0.00
	)

	// Register the summary and the histogram with Prometheus's default registry.
	prometheus.MustRegister(voltageGauge)
	prometheus.MustRegister(amperageGauge)
	prometheus.MustRegister(temperatureGauge)
	prometheus.MustRegister(powerGauge)
	prometheus.MustRegister(powerCounter)
	// Add Go module build info.
	prometheus.MustRegister(collectors.NewBuildInfoCollector())

	// Periodically record some sample latencies for the three services.
	go func() {
		for {
			resp, err := http.Get(fmt.Sprintf("http://%s/rpc/Switch.GetStatus?id=0", *switchAddr))
			if err != nil {
				panic(err)
			}

			body, err := io.ReadAll(resp.Body)
			if err != nil {
				panic(err)
			}

			sr := &GetStatusReponse{}
			err = json.Unmarshal(body, &sr)
			if err != nil {
				panic(err)
			}

			sr.AEnergy.Minute = time.Unix(sr.AEnergy.MinuteTs, 0)

			fmt.Printf("%+v\n", sr)

			voltageGauge.Set(sr.Voltage)
			amperageGauge.Set(sr.Current)
			temperatureGauge.Set(sr.Temperature.TF)
			powerGauge.Set(sr.APower)
			powerCounter.Add(sr.AEnergy.Total - lastPowerReading)

			lastPowerReading = sr.AEnergy.Total
			time.Sleep(5 * time.Second)
		}
	}()

	// Expose the registered metrics via HTTP.
	http.Handle("/metrics", promhttp.HandlerFor(
		prometheus.DefaultGatherer,
		promhttp.HandlerOpts{
			// Opt into OpenMetrics to support exemplars.
			EnableOpenMetrics: true,
		},
	))
	fmt.Printf("Listening on %v\n", *listenAddr)
	log.Fatal(http.ListenAndServe(*listenAddr, nil))
}
