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
    rootModuleConfigs.push(...getAppConfigs(appName))
  }

  console.log(JSON.stringify(rootModuleConfigs));
}

function getAccountLayerConfigs() {
  return getRootModuleConfigs("accounts")
}

function getNetworkLayerConfigs() {
  networkLayerConfigs = getRootModuleConfigs("networks")
  networkLayerConfigs.forEach(config => {
    config.extra_params = `-var="network_name=${config.backend_config_name}"`
  })
  return networkLayerConfigs
}

function getAppConfigs(appName) {
  const rootModuleConfigs = []

  // TODO: Add back in database layer once we can figure out how to get around
  // the role-manager issues
  // for (const infraLayer of ["build-repository", "database", "service"]) {
  for (const infraLayer of ["build-repository", "service"]) {
    rootModuleConfigs.push(...getRootModuleConfigs(infraLayer, appName))
  }
  rootModuleConfigs.forEach(config => {
    if (config.backend_config_name != "shared") {
      config.app_name = appName
      config.extra_params = `-var="environment_name=${config.backend_config_name}"`
    }
  })
  return rootModuleConfigs
}

function getRootModuleConfigs(infraLayer, appName = null) {
  rootModuleSubdir = appName ? `${appName}/${infraLayer}` : infraLayer
  return getBackendConfigNames(rootModuleSubdir).map(backendConfigName => {
    return {
      backend_config_name: backendConfigName,
      infra_layer: infraLayer,
      root_module_subdir: rootModuleSubdir,
    };
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
