package test

import (
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/shell"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestDev(t *testing.T) {
	BuildAndPublish(t)

	uniqueId := strings.ToLower(random.UniqueId())
	workspaceName := fmt.Sprintf("t-%s", uniqueId)
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../infra/app/envs/dev/",
	})

	defer DestroyDevEnvironmentAndWorkspace(t, terraformOptions, workspaceName)
	CreateDevEnvironmentInWorkspace(t, terraformOptions, workspaceName)
	WaitForServiceToBeStable(t, workspaceName)
	RunEndToEndTests(t, terraformOptions)
}

func BuildAndPublish(t *testing.T) {
	err := shell.RunCommandE(t, shell.Command{
		Command:    "make",
		Args:       []string{"release-build"},
		WorkingDir: "../",
	})
	assert.NoError(t, err, "Could not build release")

	err = shell.RunCommandE(t, shell.Command{
		Command:    "make",
		Args:       []string{"release-publish"},
		WorkingDir: "../",
	})
	assert.NoError(t, err, "Could not publish release")
}

func CreateDevEnvironmentInWorkspace(t *testing.T, terraformOptions *terraform.Options, workspaceName string) {
	terraform.WorkspaceSelectOrNew(t, terraformOptions, workspaceName)
	terraform.InitAndApply(t, terraformOptions)
}

func WaitForServiceToBeStable(t *testing.T, workspaceName string) {
	appName := "app"
	environmentName := "dev"
	serviceName := fmt.Sprintf("%s-%s-%s", workspaceName, appName, environmentName)
	err := shell.RunCommandE(t, shell.Command{
		Command:    "aws",
		Args:       []string{"ecs", "wait", "services-stable", "--cluster", serviceName, "--services", serviceName},
		WorkingDir: "../",
	})
	assert.NoError(t, err, "Error when waiting for service to be stable")
}

func RunEndToEndTests(t *testing.T, terraformOptions *terraform.Options) {
	serviceEndpoint := terraform.Output(t, terraformOptions, "service_endpoint")
	http_helper.HttpGetWithRetry(t, serviceEndpoint, nil, 200, "Hello, World!", 3, 1)
}

func DestroyDevEnvironmentAndWorkspace(t *testing.T, terraformOptions *terraform.Options, workspaceName string) {
	terraform.Destroy(t, terraformOptions)
	terraform.WorkspaceDelete(t, terraformOptions, workspaceName)
}
