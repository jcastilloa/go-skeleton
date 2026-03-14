package commands

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"

	aiDomain "{{MODULE_NAME}}/shared/ai/domain"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

const RootCommandLabel = "cli.root.command"

type Runner struct {
	aiRepository   aiDomain.AIRepository
	serviceName    string
	serviceVersion string
}

func NewRunner(aiRepository aiDomain.AIRepository, serviceName, serviceVersion string) Runner {
	return Runner{
		aiRepository:   aiRepository,
		serviceName:    serviceName,
		serviceVersion: serviceVersion,
	}
}

func (r Runner) Execute() error {
	return r.newRootCommand().Execute()
}

func (r Runner) newRootCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   r.serviceName,
		Short: "CLI scaffold with Cobra + Viper + DI",
		RunE:  r.runPrompt(),
	}

	cmd.Flags().String("prompt", "", "user prompt")
	cmd.Flags().String("system", "", "system prompt")
	cmd.Flags().String("model", "", "model override")
	cmd.Flags().Bool("json", false, "request JSON response mode")

	_ = cmd.MarkFlagRequired("prompt")

	_ = viper.BindPFlag("prompt", cmd.Flags().Lookup("prompt"))
	_ = viper.BindPFlag("system", cmd.Flags().Lookup("system"))
	_ = viper.BindPFlag("model", cmd.Flags().Lookup("model"))
	_ = viper.BindPFlag("json", cmd.Flags().Lookup("json"))

	viper.SetEnvPrefix("CLI")
	viper.AutomaticEnv()

	cmd.AddCommand(r.newVersionCommand())
	return cmd
}

func (r Runner) runPrompt() func(cmd *cobra.Command, args []string) error {
	return func(cmd *cobra.Command, args []string) error {
		req := aiDomain.NewRequest(viper.GetString("system"), viper.GetString("prompt"))
		if viper.GetBool("json") {
			req.ResponseMode = aiDomain.ResponseModeJSON
		}
		if model := strings.TrimSpace(viper.GetString("model")); model != "" {
			req.Model = model
		}

		resp, err := r.aiRepository.GetAIResponse(context.Background(), req)
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

func (r Runner) newVersionCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "version",
		Short: "Print service version",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Println(r.serviceVersion)
		},
	}
}
