// Common functions used by test files
package test

import (
	"crypto/md5"
	"encoding/hex"
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/git"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

// Wrapper function for terraform init using a passed in backend config file. This is needed since
// terratest currently does not support passing a file as the -backend-config option
// so we need to manually call terraform rather than using terraform.Init
// see https://github.com/gruntwork-io/terratest/issues/517
// it looks like this PR would add functionality for this: https://github.com/gruntwork-io/terratest/pull/558
// after which we add BackendConfig: []string{"dev.s3.tfbackend": terraform.KeyOnly} to terraformOptions
// and replace the call to terraform.RunTerraformCommand with terraform.Init
func TerraformInit(t *testing.T, terraformOptions *terraform.Options, backendConfig string) {
	terraform.RunTerraformCommand(t, terraformOptions, "init", fmt.Sprintf("-backend-config=%s", backendConfig))
}

func RandomWorkspaceName() string {
	var uniqueId = strings.ToLower(random.UniqueId())
	var workspaceName = fmt.Sprintf("t-%s", uniqueId)
	return workspaceName
}

// Generate a workspace name based on the current branch by taking the last 6
// characters of the md5 hash of the branch name
func BranchWorkspaceName(t *testing.T) string {
	branchName := git.GetCurrentBranchName(t)
	hash := md5.Sum([]byte(branchName))
	stringHash := hex.EncodeToString(hash[:])
	return stringHash[len(stringHash)-6:]
}
