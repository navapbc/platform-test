package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestDatabase(t *testing.T) {
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		Reconfigure:  true,
		TerraformDir: "../app/database/",
		VarFiles:     []string{"dev.tfvars"},
	})

	TerraformInit(t, terraformOptions, "dev.s3.tfbackend")

	workspaceName := RandomWorkspaceName()
	// TODO: Uncomment
	// defer terraform.WorkspaceDelete(t, terraformOptions, workspaceName)
	terraform.WorkspaceSelectOrNew(t, terraformOptions, workspaceName)

	defer DestroyDatabase(t, terraformOptions)
	terraform.Apply(t, terraformOptions)
}

func DestroyDatabase(t *testing.T, terraformOptions *terraform.Options) {
	terraform.Destroy(t, terraformOptions)
}
