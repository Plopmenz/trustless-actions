import { Address, DeployInfo, Deployer } from "../web3webdeploy/types";

export interface OptimisticActionsDeploymentSettings
  extends Omit<DeployInfo, "contract" | "args"> {}

export interface OptimisticActionsDeployment {
  optimisticActions: Address;
}

export async function deploy(
  deployer: Deployer,
  settings?: OptimisticActionsDeploymentSettings
): Promise<OptimisticActionsDeployment> {
  const optimisticActions = await deployer.deploy({
    id: "OptimisticActions",
    contract: "OptimisticActions",
    ...settings,
  });

  const deployment = {
    optimisticActions: optimisticActions,
  };
  await deployer.saveDeployment({
    deploymentName: "latest.json",
    deployment: deployment,
  });
  return deployment;
}
