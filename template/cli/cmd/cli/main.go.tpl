package main

import (
	"log"

	"{{MODULE_NAME}}/platform/cli/commands"
	"{{MODULE_NAME}}/platform/config"
	containerdi "{{MODULE_NAME}}/platform/di"
	"{{MODULE_NAME}}/platform/openai"
)

func main() {
	cfgRepo, err := config.New("{{SERVICE_NAME}}")
	if err != nil {
		log.Fatal(err)
	}

	serviceCfg := cfgRepo.ServiceConfig()
	openaiRepo := openai.NewOpenAIRepository(cfgRepo.OpenAIProviderConfig(), nil)

	containerBuilder := containerdi.New(openaiRepo, "{{SERVICE_NAME}}", serviceCfg.Version)
	container, err := containerBuilder.Build()
	if err != nil {
		log.Fatal(err)
	}

	runner := (*container).Get(commands.RootCommandLabel).(commands.Runner)
	if err := runner.Execute(); err != nil {
		log.Fatal(err)
	}
}
