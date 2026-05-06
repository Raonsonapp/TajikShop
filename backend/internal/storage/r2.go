package storage

import (
	"context"
	"fmt"
	"mime/multipart"
	"path/filepath"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/google/uuid"
)

type R2Client struct {
	client    *s3.Client
	bucket    string
	publicURL string
}

func NewR2Client(endpoint, accessKey, secretKey, bucket, publicURL string) (*R2Client, error) {
	r2Resolver := aws.EndpointResolverWithOptionsFunc(func(service, region string, options ...interface{}) (aws.Endpoint, error) {
		return aws.Endpoint{URL: endpoint}, nil
	})
	cfg, err := config.LoadDefaultConfig(context.TODO(),
		config.WithEndpointResolverWithOptions(r2Resolver),
		config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider(accessKey, secretKey, "")),
		config.WithRegion("auto"),
	)
	if err != nil {
		return nil, err
	}
	return &R2Client{
		client:    s3.NewFromConfig(cfg),
		bucket:    bucket,
		publicURL: publicURL,
	}, nil
}

func (r *R2Client) Upload(file multipart.File, header *multipart.FileHeader, folder string) (string, error) {
	ext := strings.ToLower(filepath.Ext(header.Filename))
	allowed := map[string]bool{".jpg": true, ".jpeg": true, ".png": true, ".webp": true, ".mp4": true, ".mov": true}
	if !allowed[ext] {
		return "", fmt.Errorf("file type %s not allowed", ext)
	}
	key := fmt.Sprintf("%s/%s_%d%s", folder, uuid.NewString(), time.Now().UnixMilli(), ext)
	contentType := "image/jpeg"
	if ext == ".png" {
		contentType = "image/png"
	} else if ext == ".webp" {
		contentType = "image/webp"
	} else if ext == ".mp4" || ext == ".mov" {
		contentType = "video/mp4"
	}
	_, err := r.client.PutObject(context.TODO(), &s3.PutObjectInput{
		Bucket:      aws.String(r.bucket),
		Key:         aws.String(key),
		Body:        file,
		ContentType: aws.String(contentType),
	})
	if err != nil {
		return "", fmt.Errorf("upload failed: %w", err)
	}
	return fmt.Sprintf("%s/%s", strings.TrimRight(r.publicURL, "/"), key), nil
}

func (r *R2Client) Delete(key string) error {
	_, err := r.client.DeleteObject(context.TODO(), &s3.DeleteObjectInput{
		Bucket: aws.String(r.bucket),
		Key:    aws.String(key),
	})
	return err
}
