package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"time"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"sigs.k8s.io/yaml"
)

func main() {
	config, err := rest.InClusterConfig()
	if err != nil {
		panic(err.Error())
	}

	// creates the clientset
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		panic(err.Error())
	}

	namespace := "kube-system"

	for {
		secrets, err := clientset.CoreV1().Secrets(namespace).List(context.TODO(), metav1.ListOptions{
			LabelSelector: "sealedsecrets.bitnami.com/sealed-secrets-key",
		})
		if err != nil {
			panic(err.Error())
		}
		fmt.Printf("There are %d secrets in the namespace %s\n", len(secrets.Items), namespace)

		secretsBytesJson, err := json.Marshal(secrets)
		if err != nil {
			panic(err.Error())
		}

		secretsBytesYaml, err := yaml.JSONToYAML(secretsBytesJson)
		if err != nil {
			panic(err.Error())
		}

		log.Println(string(secretsBytesYaml))

		time.Sleep(10 * time.Second)
	}
}
