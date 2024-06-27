#!/bin/node
// Prints a list of all root module configurations in a JSON array that looks like:
// [["rootModule": "path/to/root/module", "backendConfigName": "dev"], ...]
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

function main() {
  let rootModuleConfigs = [];

  // Account layer
  rootModuleConfigs.push(...getAccountLayerConfigs())

  // Network layer
  rootModuleConfigs.push(...getNetworkLayerConfigs())

  for (const appName of getAppNames()) {
    console.log(`Processing app: ${appName}`)
    rootModuleConfigs.push(...getAppConfigs(appName))
  }

  console.log(JSON.stringify(rootModuleConfigs));
}

function getAccountLayerConfigs() {
  accountLayerConfigs = getRootModuleConfigs("accounts")
  accountLayerConfigs.forEach(config => {
    config.account_name = config.backend_config_name.split(".")[0]
  })
  return accountLayerConfigs
}

function getNetworkLayerConfigs() {
  execSync("terraform -chdir=infra/project-config init")
  execSync("terraform -chdir=infra/project-config apply -auto-approve")
  const command = "terraform -chdir=infra/project-config output -json network_configs";
  const output = execSync(command, { encoding: 'utf8' });
  const networkConfigs = JSON.parse(output);
 
  networkLayerConfigs = getRootModuleConfigs("networks")
  networkLayerConfigs.forEach(config => {
    config.account_name = networkConfigs[config.backend_config_name].account_name
  })
  return networkLayerConfigs
}

function getAppConfigs(appName) {
  execSync(`terraform -chdir=infra/${appName}/app-config init`)
  execSync(`terraform -chdir=infra/${appName}/app-config apply -auto-approve`)
  const command = `terraform -chdir=infra/${appName}/app-config output -json account_names_by_environment`;
  const output = execSync(command, { encoding: 'utf8' });
  const accountNamesByEnvironment = JSON.parse(output);

  const rootModuleConfigs = []
  for (const infraLayer of ["build-repository", "database", "service"]) {
    rootModuleConfigs.push(...getRootModuleConfigs(path.join(appName, infraLayer)))
  }
  rootModuleConfigs.forEach(config => {
    config.account_name = accountNamesByEnvironment[config.backend_config_name]
  })
  return rootModuleConfigs
}

function getRootModuleConfigs(rootModuleSubdir) {
  return getBackendConfigNames(rootModuleSubdir).map(backendConfigName => {
    return {root_module_subdir: rootModuleSubdir, backend_config_name: backendConfigName};
  });
}

function getBackendConfigNames(rootModuleSubdir) {
  const rootModule = path.join("infra", rootModuleSubdir);
  if (fs.existsSync(rootModule)) {
    return fs.readdirSync(rootModule)
      .filter(file => file.endsWith('.s3.tfbackend'))
      .map(file => file.replace('.s3.tfbackend', ''));
  } else {
    return [];
  }
}

function getAppNames() {
  return fs.readdirSync("infra")
    .filter(dir => fs.statSync(path.join("infra", dir)).isDirectory())
    .filter(dir => !['accounts', 'modules', 'networks', 'project-config', 'test'].includes(dir));
}

main();
