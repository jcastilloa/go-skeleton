package routes

import (
	systemHandler "{{MODULE_NAME}}/platform/handlers/system"

	"github.com/gin-gonic/gin"
	"github.com/sarulabs/di"
)

func AddSystemRoutes(group *gin.RouterGroup, container di.Container) {
	group.GET("/version", buildEndpoint(container, systemHandler.GetVersionHandlerLabel))
}
