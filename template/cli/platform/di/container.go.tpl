package di

import (
	"fmt"

	"{{MODULE_NAME}}/platform/cli/commands"
	aiDomain "{{MODULE_NAME}}/shared/ai/domain"

	"github.com/sarulabs/di"
)

const OpenAIRepositoryLabel = "ai.openai.repository"

type Container struct {
	aiRepository   aiDomain.AIRepository
	serviceName    string
	serviceVersion string
}

func New(aiRepository aiDomain.AIRepository, serviceName, serviceVersion string) *Container {
	return &Container{
		aiRepository:   aiRepository,
		serviceName:    serviceName,
		serviceVersion: serviceVersion,
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
			Name:  commands.RootCommandLabel,
			Scope: di.App,
			Build: func(ctn di.Container) (interface{}, error) {
				return commands.NewRunner(c.aiRepository, c.serviceName, c.serviceVersion), nil
			},
		},
	)
	if err != nil {
		return nil, fmt.Errorf("register dependencies: %w", err)
	}

	container := builder.Build()
	return &container, nil
}
