package test

import (
    "testing"
    "os"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestBootstrapInfra(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../terraform/bootstrap",
    }

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    bucketName := terraform.Output(t, terraformOptions, "tfstate_bucket_name")
    tableName := terraform.Output(t, terraformOptions, "tfstate_lock_table_name")

    assert.NotEmpty(t, bucketName)
    assert.NotEmpty(t, tableName)
}