package hello

type Repository interface {
	Greet(name string) string
}
