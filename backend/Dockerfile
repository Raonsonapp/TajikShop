FROM golang:1.22-alpine AS builder
WORKDIR /app

# Ҳамаи файлҳоро аввал нусха мекунем, то папкаи дурустро пайдо кунад
COPY . .

# Агар файлҳо дар даруни папкаи дигар бошанд, ба он ҷо мегузарем
# Агар файлҳо дар папкаи асосӣ бошанд, ин сатр халал намерасонад
RUN if [ -f "go.mod" ]; then echo "Root"; else cd $(dirname $(find . -name "go.mod" | head -n 1)) && cp -r * /app/; fi

RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux go build -o tajikshop-api ./main.go

FROM alpine:3.19
WORKDIR /app
COPY --from=builder /app/tajikshop-api .
RUN chmod +x tajikshop-api
EXPOSE 7860
ENV PORT=7860
ENV GIN_MODE=release
CMD ["./tajikshop-api"]
