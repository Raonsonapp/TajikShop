package storage

import (
	"context"
	"fmt"
	"mime/multipart"
	"path/filepath"
	"strings"
	"sync"
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

	mu     sync.RWMutex
	status string // натиҷаи охирини санҷиш (бе ҳеҷ гуна калид)
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
		status:    "not checked",
	}, nil
}

// ── Санҷиши калидҳо ─────────────────────────────────────────────────────────
//
// ⚠️ `NewR2Client` бо Cloudflare ҲЕҶ ГОҲ тамос намегирад — он танҳо объекти
// клиентро месозад. Барои ҳамин пештар лог ҳатто бо калиди КӮҲНАИ мӯҳлаташ
// гузашта ҳам «✅ R2 connected» менавишт, ва хатогӣ танҳо вақте маълум мешуд,
// ки корбар расм бор карда наметавонист. Акнун ҳангоми оғоз як дархости
// воқеӣ (HeadBucket) фиристода мешавад ва натиҷаи рост сабт мегардад.

// Verify — калидҳоро бо як дархости воқеӣ ба Cloudflare месанҷад.
func (r *R2Client) Verify(ctx context.Context) error {
	_, err := r.client.HeadBucket(ctx, &s3.HeadBucketInput{
		Bucket: aws.String(r.bucket),
	})
	r.mu.Lock()
	r.status = classifyR2Error(err, r.bucket)
	r.mu.Unlock()
	return err
}

// Status — натиҷаи охирини санҷиш барои `/health`.
func (r *R2Client) Status() string {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return r.status
}

// PublicURLSet — оё `R2_PUBLIC_URL` гузошта шудааст? Бе он линки расмҳо
// нопурра месозад ва дар барнома расмҳо кушода намешаванд.
func (r *R2Client) PublicURLSet() bool { return strings.TrimSpace(r.publicURL) != "" }

// classifyR2Error — хатои Cloudflare-ро ба паёми кӯтоҳ ва БЕХАТАР табдил
// медиҳад. Матни хоми SDK метавонад Access Key ID-ро дар бар гирад, бинобар
// ин он ҳеҷ гоҳ на ба лог меравад, на ба `/health`.
func classifyR2Error(err error, bucket string) string {
	if err == nil {
		return "ok"
	}
	// Ҳарфҳои калон/хурдро ба назар намегирем: SDK «StatusCode: 403» менависад,
	// сервер метавонад «status code» диҳад — ҳарду бояд як хел фаҳмида шаванд.
	msg := strings.ToLower(err.Error())
	switch {
	case containsAny(msg, "invalidaccesskeyid", "signaturedoesnotmatch",
		"invalidargument", "accessdenied", "access denied", "forbidden",
		"statuscode: 401", "statuscode: 403",
		"status code: 401", "status code: 403"):
		// Маҳз ҳамин ҳолат ҳангоми иваз кардани калидҳо рух медиҳад.
		return "credentials rejected — R2_ACCESS_KEY/R2_SECRET_KEY-ро санҷед"
	case containsAny(msg, "nosuchbucket", "notfound", "not found",
		"statuscode: 404", "status code: 404"):
		return "bucket not found: " + bucket
	default:
		return "unreachable — R2_ENDPOINT ё шабакаро санҷед"
	}
}

func containsAny(s string, subs ...string) bool {
	for _, sub := range subs {
		if strings.Contains(s, sub) {
			return true
		}
	}
	return false
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
		// Ҳолатро навсозӣ мекунем: агар калид дар вақти кор бекор шуда
		// бошад, `/health` ва паёми хато бояд ростро гӯянд, на «ok»-и кӯҳна.
		r.mu.Lock()
		r.status = classifyR2Error(err, r.bucket)
		r.mu.Unlock()
		return "", fmt.Errorf("upload failed: %w", err)
	}
	r.mu.Lock()
	r.status = "ok"
	r.mu.Unlock()
	return fmt.Sprintf("%s/%s", strings.TrimRight(r.publicURL, "/"), key), nil
}

func (r *R2Client) Delete(key string) error {
	_, err := r.client.DeleteObject(context.TODO(), &s3.DeleteObjectInput{
		Bucket: aws.String(r.bucket),
		Key:    aws.String(key),
	})
	return err
}

// keyFromURL — калиди объектро аз URL-и оммавӣ ҷудо мекунад (пок, тестшаванда).
// Агар URL ба publicURL мувофиқат накунад, "" бармегардонад.
func keyFromURL(publicURL, fileURL string) string {
	prefix := strings.TrimRight(publicURL, "/") + "/"
	if fileURL == "" || !strings.HasPrefix(fileURL, prefix) {
		return ""
	}
	return strings.TrimPrefix(fileURL, prefix)
}

// DeleteByURL — объектро аз рӯи URL-и оммавии он ҳазф мекунад (best-effort).
// URL шакли {publicURL}/{key} дорад; калидро ҷудо карда, ҳазф мекунем.
func (r *R2Client) DeleteByURL(fileURL string) error {
	key := keyFromURL(r.publicURL, fileURL)
	if key == "" {
		return nil
	}
	return r.Delete(key)
}
