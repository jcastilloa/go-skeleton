package main

import (
	"log"

	"{{MODULE_NAME}}/platform/config"
	containerdi "{{MODULE_NAME}}/platform/di"
	"{{MODULE_NAME}}/platform/openai"
	"{{MODULE_NAME}}/platform/server"
)

func main() {
	cfgRepo, err := config.New("{{SERVICE_NAME}}")
	if err != nil {
		log.Fatal(err)
	}

	serviceCfg := cfgRepo.ServiceConfig()
	openaiCfg := cfgRepo.OpenAIProviderConfig()
	openaiRepo := openai.NewOpenAIRepository(openaiCfg, nil)

	containerBuilder := containerdi.New(openaiRepo, serviceCfg.Version)
	container, err := containerBuilder.Build()
	if err != nil {
		log.Fatal(err)
	}

	httpServer := server.New(*container, serviceCfg.APIPrefix)
	log.Printf("http server listening on %s%s", serviceCfg.HTTPAddress(), serviceCfg.NormalizedAPIPrefix())

	if err := httpServer.Run(serviceCfg.HTTPAddress()); err != nil {
		log.Fatal(err)
	}
}
