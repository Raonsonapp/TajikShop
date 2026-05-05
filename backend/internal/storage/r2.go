package storage

import (
	"bytes"
	"context"
	"fmt"
	"mime/multipart"
	"os"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

var client *s3.Client

func InitR2() {
	cfg, _ := config.LoadDefaultConfig(context.TODO(),
		config.WithRegion("auto"),
		config.WithCredentialsProvider(
			aws.NewCredentialsCache(
				aws.StaticCredentialsProvider{
					Value: aws.Credentials{
						AccessKeyID:     os.Getenv("R2_ACCESS_KEY"),
						SecretAccessKey: os.Getenv("R2_SECRET_KEY"),
					},
				},
			),
		),
	)

	client = s3.NewFromConfig(cfg, func(o *s3.Options) {
		o.BaseEndpoint = aws.String(os.Getenv("R2_ENDPOINT"))
	})
}

func Upload(file multipart.File, filename string) (string, error) {
	buf := new(bytes.Buffer)
	buf.ReadFrom(file)

	_, err := client.PutObject(context.TODO(), &s3.PutObjectInput{
		Bucket: aws.String(os.Getenv("R2_BUCKET")),
		Key:    aws.String(filename),
		Body:   bytes.NewReader(buf.Bytes()),
	})

	if err != nil {
		return "", err
	}

	url := fmt.Sprintf("%s/%s/%s",
		os.Getenv("R2_ENDPOINT"),
		os.Getenv("R2_BUCKET"),
		filename,
	)

	return url, nil
}
