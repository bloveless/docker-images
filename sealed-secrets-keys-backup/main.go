package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
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

	for {
		// get pods in all the namespaces by omitting namespace
		// Or specify namespace to get pods in particular namespace
		namespace := "kube-system"
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

		// // Examples for error handling:
		// // - Use helper functions e.g. errors.IsNotFound()
		// // - And/or cast to StatusError and use its properties like e.g. ErrStatus.Message
		// _, err = clientset.CoreV1().Pods("default").Get(context.TODO(), "example-xxxxx", metav1.GetOptions{})
		// if errors.IsNotFound(err) {
		// 	fmt.Printf("Pod example-xxxxx not found in default namespace\n")
		// } else if statusError, isStatus := err.(*errors.StatusError); isStatus {
		// 	fmt.Printf("Error getting pod %v\n", statusError.ErrStatus.Message)
		// } else if err != nil {
		// 	panic(err.Error())
		// } else {
		// 	fmt.Printf("Found example-xxxxx pod in default namespace\n")
		// }

		time.Sleep(10 * time.Second)
	}

	fmt.Println("Hello from sealed secrets keys backup. Again. Yet again")

	log.Println("Listening on :8090")
	if err := http.ListenAndServe(":8090", nil); err != nil {
		log.Fatalf("Error listening on :8090, err: %v", err)
	}
}
