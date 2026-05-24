FROM golang:1.22-alpine AS builder
WORKDIR /app

# Нусхабардории файлҳои вобастагӣ
COPY go.mod go.sum ./
RUN go mod download

# Нусхабардории тамоми код
COPY . .

# Компилятсияи код аз папкаи cmd/api/
RUN CGO_ENABLED=0 GOOS=linux go build -o tajikshop-api ./cmd/api/main.go

FROM alpine:3.19
WORKDIR /app

# Нусхабардории файли бинарӣ ба сервери асосӣ
COPY --from=builder /app/tajikshop-api .

RUN chmod +x tajikshop-api
EXPOSE 7860
ENV PORT=7860
ENV GIN_MODE=release

CMD ["./tajikshop-api"]
