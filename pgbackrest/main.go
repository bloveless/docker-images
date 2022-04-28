package main

import (
	"bufio"
	"bytes"
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"
	"time"

	"github.com/go-co-op/gocron"
)

func main() {
	cronFile := os.Args[1]
	if cronFile == "" {
		fmt.Println("You must provide a file as the first and only argument")
	}

	s := gocron.NewScheduler(time.UTC)

	file, err := os.Open(cronFile)
	if err != nil {
		log.Fatal("Unable to read cron file")
	}

	scanner := bufio.NewScanner(file)
	// optionally, resize scanner's capacity for lines over 64K, see next example
	for scanner.Scan() {
		line := scanner.Text()
		lineParts := strings.Split(line, " ")
		cronString := strings.Join(lineParts[0:5], " ")
		commandString := strings.Join(lineParts[5:], " ")

		fmt.Println("Adding cron string", cronString, "for command", commandString)

		_, err = s.Cron(cronString).Do(func() {
			fmt.Println("Running command", commandString)
			cmd := exec.Command(lineParts[5], lineParts[6:]...)
			// Pass in the entire environment from the parent
			// TODO: Test this with removing the /usr/local/bin/ prefix from the pgbackrest command
			cmd.Env = os.Environ()
			var stdout bytes.Buffer
			cmd.Stdout = &stdout
			var stderr bytes.Buffer
			cmd.Stderr = &stderr
			err := cmd.Run()
			if err != nil {
				fmt.Println("error running command", commandString, "error: ", err)
				fmt.Println("stderr", stderr.String())
			}

			fmt.Println("stdout", stdout.String())
		})

		if err != nil {
			log.Fatal("Unable to run cron:", err)
		}
	}

	if err := scanner.Err(); err != nil {
		log.Fatal(err)
	}

	// starts the scheduler and blocks current execution path
	s.StartBlocking()
}
