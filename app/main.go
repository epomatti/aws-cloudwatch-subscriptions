package main

import (
	"errors"
	"flag"
	"fmt"
	"net/http"

	log "github.com/sirupsen/logrus"
)

func main() {
	fmt.Println("Starting server...")
	log.SetFormatter(&log.JSONFormatter{})

	port := flag.Int("port", 8080, "The port on which to register the HTTP listener to.")
	flag.Parse()

	http.HandleFunc("/info", info)
	http.HandleFunc("/err", err)

	addr := fmt.Sprintf(":%d", *port)
	http.ListenAndServe(addr, nil)
}

func info(w http.ResponseWriter, r *http.Request) {
	log.Info("Just some information")
}

func err(w http.ResponseWriter, r *http.Request) {
	err := errors.New("Serious error")
	log.Error(err)
}
