package commands

import (
	"fmt"

	mcpserver "{{MODULE_NAME}}/platform/mcp/server"
	"{{MODULE_NAME}}/platform/mcp/tools"
	configDomain "{{MODULE_NAME}}/shared/config/domain"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

const RootCommandLabel = "mcp.root.command"

type Runner struct {
	serviceName string
	serviceCfg  configDomain.ServiceConfig
	server      *mcpserver.Server
	helloTool   tools.HelloWorld
}

func NewRunner(serviceName string, serviceCfg configDomain.ServiceConfig, server *mcpserver.Server, helloTool tools.HelloWorld) Runner {
	return Runner{
		serviceName: serviceName,
		serviceCfg:  serviceCfg,
		server:      server,
		helloTool:   helloTool,
	}
}

func (r Runner) Execute() error {
	return r.newRootCommand().Execute()
}

func (r Runner) newRootCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   r.serviceName,
		Short: "MCP scaffold with Cobra + Viper + DI",
		RunE:  r.runServer(),
	}

	defaultTransport := r.serviceCfg.NormalizedTransport()
	cmd.Flags().String("transport", defaultTransport, "MCP transport (supported: stdio)")

	_ = viper.BindPFlag("service.transport", cmd.Flags().Lookup("transport"))
	viper.SetDefault("service.transport", defaultTransport)
	viper.SetEnvPrefix("MCP")
	viper.AutomaticEnv()

	cmd.AddCommand(r.newVersionCommand())
	return cmd
}

func (r Runner) runServer() func(cmd *cobra.Command, args []string) error {
	return func(cmd *cobra.Command, args []string) error {
		r.server.AddTool(r.helloTool.Definition(), r.helloTool.Handler)

		transport := viper.GetString("service.transport")
		if transport == "" {
			transport = r.serviceCfg.NormalizedTransport()
		}

		fmt.Printf("mcp server ready: service=%s version=%s transport=%s\n", r.serviceName, r.serviceCfg.Version, transport)
		return r.server.Run(transport)
	}
}

func (r Runner) newVersionCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "version",
		Short: "Print service version",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Println(r.serviceCfg.Version)
		},
	}
}
