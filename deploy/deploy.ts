import { Address, Deployer } from "../web3webdeploy/types";
import {
  DeployOptimisticActionsSettings,
  deployOptimisticActions,
} from "./internal/OptimisticActions";

export interface OptimisticActionsDeploymentSettings {
  optimisticActionsSettings: DeployOptimisticActionsSettings;
  forceRedeploy?: boolean;
}

export interface OptimisticActionsDeployment {
  optimisticActions: Address;
}

export async function deploy(
  deployer: Deployer,
  settings?: OptimisticActionsDeploymentSettings
): Promise<OptimisticActionsDeployment> {
  if (settings?.forceRedeploy !== undefined && !settings.forceRedeploy) {
    return await deployer.loadDeployment({ deploymentName: "latest.json" });
  }

  const optimisticActions = await deployOptimisticActions(
    deployer,
    settings?.optimisticActionsSettings ?? {}
  );

  const deployment = {
    optimisticActions: optimisticActions,
  };
  await deployer.saveDeployment({
    deploymentName: "latest.json",
    deployment: deployment,
  });
  return deployment;
}
