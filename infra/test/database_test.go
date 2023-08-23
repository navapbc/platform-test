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
}

func EnableDestroyDatabase(t *testing.T, terraformOptions *terraform.Options) {
	fmt.Println("::group::Setting deletion_protection = false")
	shell.RunCommand(t, shell.Command{
		Command: "sed",
		Args: []string{
			"-i.bak",
			"s/deletion_protection[ ]*= true/deletion_protection = false/g",
			"infra/modules/database/main.tf",
		},
		WorkingDir: "../../",
	})
	terraform.Apply(t, terraformOptions)
}

func DestroyDatabase(t *testing.T, terraformOptions *terraform.Options) {
	EnableDestroyDatabase(t, terraformOptions)
	terraform.Destroy(t, terraformOptions)
}
