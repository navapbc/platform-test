package test

import (
	"fmt"
	"strings"
	"testing"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/shell"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestDev(t *testing.T) {
	BuildAndPublish(t)

	uniqueId := strings.ToLower(random.UniqueId())
	workspaceName := fmt.Sprintf("t-%s", uniqueId)
	imageTag := shell.RunCommandAndGetOutput(t, shell.Command{
		Command:    "git",
		Args:       []string{"rev-parse", "HEAD"},
		WorkingDir: "./",
	})
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../app/envs/dev/",
		Vars: map[string]interface{}{
			"image_tag": imageTag,
		},
	})

	defer DestroyDevEnvironmentAndWorkspace(t, terraformOptions, workspaceName)
	CreateDevEnvironmentInWorkspace(t, terraformOptions, workspaceName)
	WaitForServiceToBeStable(t, workspaceName)
	RunEndToEndTests(t, terraformOptions)
}

func BuildAndPublish(t *testing.T) {
	terraform.Init(t, &terraform.Options{
		TerraformDir: "../app/build-repository/",
	})

	shell.RunCommand(t, shell.Command{
		Command:    "make",
		Args:       []string{"release-build"},
		WorkingDir: "../../",
	})

	shell.RunCommand(t, shell.Command{
		Command:    "make",
		Args:       []string{"release-publish"},
		WorkingDir: "../../",
	})
}

func CreateDevEnvironmentInWorkspace(t *testing.T, terraformOptions *terraform.Options, workspaceName string) {
	terraform.Init(t, terraformOptions)
	terraform.WorkspaceSelectOrNew(t, terraformOptions, workspaceName)
	terraform.Apply(t, terraformOptions)
}

func WaitForServiceToBeStable(t *testing.T, workspaceName string) {
	appName := "app"
	environmentName := "dev"
	serviceName := fmt.Sprintf("%s-%s-%s", workspaceName, appName, environmentName)
	shell.RunCommand(t, shell.Command{
		Command:    "aws",
		Args:       []string{"ecs", "wait", "services-stable", "--cluster", serviceName, "--services", serviceName},
		WorkingDir: "../../",
	})
}

func RunEndToEndTests(t *testing.T, terraformOptions *terraform.Options) {
	serviceEndpoint := terraform.Output(t, terraformOptions, "service_endpoint")
	responseStatus, _ := http_helper.HttpGet(t, serviceEndpoint, nil)
	assert.Equal(t, 200, responseStatus)
}

func DestroyDevEnvironmentAndWorkspace(t *testing.T, terraformOptions *terraform.Options, workspaceName string) {
	terraform.Destroy(t, terraformOptions)
	terraform.WorkspaceDelete(t, terraformOptions, workspaceName)
}
