package di

import (
	"fmt"

	helloApp "{{MODULE_NAME}}/mcp/application/hello"
	helloDomain "{{MODULE_NAME}}/mcp/domain/hello"
	"{{MODULE_NAME}}/platform/mcp/commands"
	helloInfra "{{MODULE_NAME}}/platform/mcp/hello"
	mcpserver "{{MODULE_NAME}}/platform/mcp/server"
	"{{MODULE_NAME}}/platform/mcp/tools"
	aiDomain "{{MODULE_NAME}}/shared/ai/domain"
	configDomain "{{MODULE_NAME}}/shared/config/domain"

	"github.com/sarulabs/di"
)

const OpenAIRepositoryLabel = "ai.openai.repository"

type Container struct {
	aiRepository aiDomain.AIRepository
	serviceName  string
	serviceCfg   configDomain.ServiceConfig
}

func New(aiRepository aiDomain.AIRepository, serviceName string, serviceCfg configDomain.ServiceConfig) *Container {
	return &Container{
		aiRepository: aiRepository,
		serviceName:  serviceName,
		serviceCfg:   serviceCfg,
	}
}

func (c *Container) Build() (*di.Container, error) {
	builder, err := di.NewBuilder()
	if err != nil {
		return nil, fmt.Errorf("create builder: %w", err)
	}

	err = builder.Add(
		di.Def{
			Name:  OpenAIRepositoryLabel,
			Scope: di.App,
			Build: func(ctn di.Container) (interface{}, error) {
				return c.aiRepository, nil
			},
		},
		di.Def{
			Name:  "mcp.hello.repository",
			Scope: di.App,
			Build: func(ctn di.Container) (interface{}, error) {
				return helloInfra.NewRepository(), nil
			},
		},
		di.Def{
			Name:  "mcp.hello.service",
			Scope: di.App,
			Build: func(ctn di.Container) (interface{}, error) {
				helloRepository := ctn.Get("mcp.hello.repository").(helloDomain.Repository)
				return helloApp.NewService(helloRepository), nil
			},
		},
		di.Def{
			Name:  "mcp.hello.tool",
			Scope: di.App,
			Build: func(ctn di.Container) (interface{}, error) {
				helloService := ctn.Get("mcp.hello.service").(helloApp.Service)
				return tools.NewHelloWorld(helloService), nil
			},
		},
		di.Def{
			Name:  "mcp.server",
			Scope: di.App,
			Build: func(ctn di.Container) (interface{}, error) {
				return mcpserver.New(c.serviceName, c.serviceCfg.Version), nil
			},
		},
		di.Def{
			Name:  commands.RootCommandLabel,
			Scope: di.App,
			Build: func(ctn di.Container) (interface{}, error) {
				server := ctn.Get("mcp.server").(*mcpserver.Server)
				helloTool := ctn.Get("mcp.hello.tool").(tools.HelloWorld)
				return commands.NewRunner(c.serviceName, c.serviceCfg, server, helloTool), nil
			},
		},
	)
	if err != nil {
		return nil, fmt.Errorf("register dependencies: %w", err)
	}

	container := builder.Build()
	return &container, nil
}
