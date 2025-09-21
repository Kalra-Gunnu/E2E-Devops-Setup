package test

import (
    "testing"
    "os"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestDevInfra(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../terraform/envs/dev",
    }

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    vpcId := terraform.Output(t, terraformOptions, "vpc_id")
    privateSubnets := terraform.OutputList(t, terraformOptions, "private_subnet_ids")
    publicSubnets := terraform.OutputList(t, terraformOptions, "public_subnet_ids")
    ecrRepos := terraform.OutputMap(t, terraformOptions, "ecr_repository_urls")

    assert.NotEmpty(t, vpcId)
    assert.GreaterOrEqual(t, len(privateSubnets), 1)
    assert.GreaterOrEqual(t, len(publicSubnets), 1)
    assert.NotEmpty(t, ecrRepos)
}