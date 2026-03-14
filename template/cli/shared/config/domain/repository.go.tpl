package domain

import aiDomain "{{MODULE_NAME}}/shared/ai/domain"

type Repository interface {
	OpenAIProviderConfig() aiDomain.ProviderConfig
	ServiceConfig() ServiceConfig
}
