#!/bin/node
// Prints a list of all root module configurations in a JSON array that looks like:
// [["rootModule": "path/to/root/module", "backendConfigName": "dev"], ...]
const fs = require('fs');
const path = require('path');

let rootModuleConfigs = [];

function getBackendConfigNames(rootModule) {
  return fs.readdirSync(rootModule)
    .filter(file => file.endsWith('.s3.tfbackend'))
    .map(file => file.replace('.s3.tfbackend', ''));
}

function getAppNames() {
  return fs.readdirSync("infra")
    .filter(dir => fs.statSync(path.join("infra", dir)).isDirectory())
    .filter(dir => !['accounts', 'modules', 'networks', 'project-config', 'test'].includes(dir));
}

// Iterate over infra layers
for (const infraLayer of ["account", "network"]) {
  const rootModule = path.join('infra', `${infraLayer}s`);

  for (const backendConfigName of getBackendConfigNames(rootModule)) {
    rootModuleConfigs.push({root_module_subdir: rootModule, backend_config_name: backendConfigName});
  }
}

for (const appName of getAppNames()) {
  // Add ["infra/build-repository", "shared"] to rootModuleConfigs
  rootModuleConfigs.push({root_module_subdir: "build-repository", backend_config_name: "shared"});

  const infraLayers = ["database", "service"];
  for (const infraLayer of infraLayers) {
    const rootModule = path.join("infra", appName, infraLayer);

    for (const backendConfigName of getBackendConfigNames(rootModule)) {
      rootModuleConfigs.push({root_module_subdir: rootModule, backend_config_name: backendConfigName});
    }
  }
}

console.log(JSON.stringify(rootModuleConfigs));
