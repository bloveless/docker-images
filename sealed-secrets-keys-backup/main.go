package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"sort"
	"strconv"
	"strings"
	"time"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"sigs.k8s.io/yaml"
)

func checkBackupsDirectory(backupsDirectory string) error {
	_, err := os.Stat(backupsDirectory)
	if err != nil {
		return fmt.Errorf("Unable to get file info for backups directory %s: %w", backupsDirectory, err)
	}

	return nil
}

func cleanupBackupsDirectory(backupsDirectory string, numberOfBackupsToKeep int) error {
	files, err := ioutil.ReadDir(backupsDirectory)
	if err != nil {
		return fmt.Errorf("Unable to clean up backups directory: %w", err)
	}

	sort.Slice(files, func(i, j int) bool {
		return files[i].ModTime().After(files[j].ModTime())
	})

	if len(files) > numberOfBackupsToKeep {
		numberOfBackupsToRemove := len(files) - numberOfBackupsToKeep
		log.Printf("Found %d current backups. Number of backups to keep is %d. Removing %d oldest backups", len(files), numberOfBackupsToKeep, numberOfBackupsToRemove)

		filesToDelete := files[len(files)-numberOfBackupsToRemove:]

		for _, fileToDelete := range filesToDelete {
			log.Printf("Deleting file %s", backupsDirectory+fileToDelete.Name())
			os.Remove(backupsDirectory + fileToDelete.Name())
		}

		return nil
	}

	log.Printf("Found %d current backups. Number of backups to keep is %d. No backups to remove", len(files), numberOfBackupsToKeep)

	return nil
}

func main() {
	backupsDirectory := "/backups"
	if value, ok := os.LookupEnv("BACKUPS_DIRECTORY"); ok {
		backupsDirectory = value
	}

	backupsDirectory = strings.TrimRight(backupsDirectory, "/") + "/"

	sealedSecretsControllerNamespace := "kube-system"
	if value, ok := os.LookupEnv("SEALED_SECRETS_CONTROLLER_NAMESPACE"); ok {
		sealedSecretsControllerNamespace = value
	}

	if err := checkBackupsDirectory(backupsDirectory); err != nil {
		log.Fatalf("Backups directory invalid: %v", err)
	}

	numberOfBackupsToKeep := 24
	if value, ok := os.LookupEnv("NUMBER_OF_BACKUPS_TO_KEEP"); ok {
		strconv.ParseInt(value, 10, 0)
	}

	config, err := rest.InClusterConfig()
	if err != nil {
		panic(err.Error())
	}

	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		panic(err.Error())
	}

	secrets, err := clientset.CoreV1().Secrets(sealedSecretsControllerNamespace).List(context.TODO(), metav1.ListOptions{
		LabelSelector: "sealedsecrets.bitnami.com/sealed-secrets-key",
	})
	if err != nil {
		panic(err.Error())
	}

	secretsBytesJson, err := json.Marshal(secrets)
	if err != nil {
		panic(err.Error())
	}

	secretsBytesYaml, err := yaml.JSONToYAML(secretsBytesJson)
	if err != nil {
		panic(err.Error())
	}

	outputFileName := backupsDirectory + time.Now().UTC().Format("20060102150405") + "-master-keys.yaml"

	if err := os.WriteFile(outputFileName, secretsBytesYaml, 0444); err != nil {
		log.Fatalf("Unable to write master keys to %s: %s", outputFileName, err.Error())
	}

	log.Println("Wrote latest master keys to", outputFileName)

	cleanupBackupsDirectory(backupsDirectory, numberOfBackupsToKeep)

	log.Println("Finished backing up current keys and cleaning up old keys")
}
