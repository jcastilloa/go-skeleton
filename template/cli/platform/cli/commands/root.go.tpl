package commands

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"

	"{{MODULE_NAME}}/platform/config"
	"{{MODULE_NAME}}/platform/openai"
	aiDomain "{{MODULE_NAME}}/shared/ai/domain"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

func Execute(defaultServiceName string) error {
	return newRootCommand(defaultServiceName).Execute()
}

func newRootCommand(defaultServiceName string) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "{{SERVICE_NAME}}",
		Short: "CLI scaffold with Cobra + Viper",
		RunE:  runPrompt(defaultServiceName),
	}

	cmd.Flags().String("service", defaultServiceName, "service name for config discovery")
	cmd.Flags().String("prompt", "", "user prompt")
	cmd.Flags().String("system", "", "system prompt")
	cmd.Flags().String("model", "", "model override")
	cmd.Flags().Bool("json", false, "request JSON response mode")

	_ = cmd.MarkFlagRequired("prompt")

	_ = viper.BindPFlag("service", cmd.Flags().Lookup("service"))
	_ = viper.BindPFlag("prompt", cmd.Flags().Lookup("prompt"))
	_ = viper.BindPFlag("system", cmd.Flags().Lookup("system"))
	_ = viper.BindPFlag("model", cmd.Flags().Lookup("model"))
	_ = viper.BindPFlag("json", cmd.Flags().Lookup("json"))

	viper.SetEnvPrefix("CLI")
	viper.AutomaticEnv()

	return cmd
}

func runPrompt(defaultServiceName string) func(cmd *cobra.Command, args []string) error {
	return func(cmd *cobra.Command, args []string) error {
		serviceName := strings.TrimSpace(viper.GetString("service"))
		if serviceName == "" {
			serviceName = defaultServiceName
		}

		cfgRepo, err := config.New(serviceName)
		if err != nil {
			return err
		}

		openAICfg := cfgRepo.OpenAIProviderConfig()
		if model := strings.TrimSpace(viper.GetString("model")); model != "" {
			openAICfg.Model = model
		}

		repo := openai.NewOpenAIRepository(openAICfg, nil)

		req := aiDomain.NewRequest(viper.GetString("system"), viper.GetString("prompt"))
		if viper.GetBool("json") {
			req.ResponseMode = aiDomain.ResponseModeJSON
		}

		resp, err := repo.GetAIResponse(context.Background(), req)
		if err != nil {
			return err
		}
		if resp.HasError {
			return fmt.Errorf("provider error: %s", resp.ErrorMsg)
		}

		if req.ResponseMode == aiDomain.ResponseModeJSON && resp.OutputMap != nil {
			payload, err := json.MarshalIndent(resp.OutputMap, "", "  ")
			if err != nil {
				return err
			}
			fmt.Println(string(payload))
			return nil
		}

		fmt.Println(strings.TrimSpace(resp.OutputText))
		return nil
	}
}
