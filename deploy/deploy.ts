import { Address, Deployer } from "../web3webdeploy/types";
import {
  DeployOptimisticActionsSettings,
  deployOptimisticActions,
} from "./internal/OptimisticActions";
import {
  DeployPessimisticActionsSettings,
  deployPessimisticActions,
} from "./internal/PessimisticActions";

export interface TrustlessActionsDeploymentSettings {
  optimisticActionsSettings: DeployOptimisticActionsSettings;
  pessimisticActionsSettings: DeployPessimisticActionsSettings;
  forceRedeploy?: boolean;
}

export interface TrustlessActionsDeployment {
  optimisticActions: Address;
}

export async function deploy(
  deployer: Deployer,
  settings?: TrustlessActionsDeploymentSettings
): Promise<TrustlessActionsDeployment> {
  if (settings?.forceRedeploy !== undefined && !settings.forceRedeploy) {
    return await deployer.loadDeployment({ deploymentName: "latest.json" });
  }

  const optimisticActions = await deployOptimisticActions(
    deployer,
    settings?.optimisticActionsSettings ?? {}
  );

  const pessimisticActions = await deployPessimisticActions(
    deployer,
    settings?.pessimisticActionsSettings ?? {}
  );

  const deployment = {
    optimisticActions: optimisticActions,
    pessimisticActions: pessimisticActions,
  };
  await deployer.saveDeployment({
    deploymentName: "latest.json",
    deployment: deployment,
  });
  return deployment;
}
