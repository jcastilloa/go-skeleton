package tools

import (
	"context"

	helloApp "{{MODULE_NAME}}/mcp/application/hello"

	"github.com/mark3labs/mcp-go/mcp"
)

type HelloWorld struct {
	service helloApp.Service
}

func NewHelloWorld(service helloApp.Service) HelloWorld {
	return HelloWorld{service: service}
}

func (h HelloWorld) Definition() mcp.Tool {
	return mcp.NewTool("hello_world",
		mcp.WithDescription("Say hello to someone"),
		mcp.WithString("name",
			mcp.Required(),
			mcp.Description("Name of the person to greet"),
		),
	)
}

func (h HelloWorld) Handler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	_ = ctx
	name := mcp.ParseString(request, "name", "world")
	return mcp.NewToolResultText(h.service.Execute(name)), nil
}
