package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/shell"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestDatabase(t *testing.T) {
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		Reconfigure:  true,
		TerraformDir: "../app/database/",
		VarFiles:     []string{"dev.tfvars"},
	})

	fmt.Println("::group::Initializing database module")
	TerraformInit(t, terraformOptions, "dev.s3.tfbackend")
	fmt.Println("::endgroup::")

	workspaceName := RandomWorkspaceName()
	// defer terraform.WorkspaceDelete(t, terraformOptions, workspaceName)
	fmt.Println("::group::Creating new workspace")
	terraform.WorkspaceSelectOrNew(t, terraformOptions, workspaceName)
	fmt.Println("::endgroup::")

	// defer DestroyDatabase(t, terraformOptions)
	terraform.Apply(t, terraformOptions)

	WaitForRoleManagerUpdateToBeSuccessful(t, terraformOptions)
	ValidateDatabase(t, terraformOptions)
}

func WaitForRoleManagerUpdateToBeSuccessful(t *testing.T, terraformOptions *terraform.Options) {
	fmt.Println("::group::Wait for role manager lambda function to be stable")
	roleManagerFunctionName := terraform.Output(t, terraformOptions, "role_manager_function_name")
	shell.RunCommand(t, shell.Command{
		Command:    "aws",
		Args:       []string{"lambda", "wait", "function-updated-v2", "--function-name", roleManagerFunctionName},
		WorkingDir: "../../",
	})
	fmt.Println("::endgroup::")
}

func ValidateDatabase(t *testing.T, terraformOptions *terraform.Options) {
	shell.RunCommand(t, shell.Command{
		Command:    "make",
		Args:       []string{"infra-check-app-database-roles", "APP_NAME=app", "ENVIRONMENT=dev"},
		WorkingDir: "../../",
	})
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
