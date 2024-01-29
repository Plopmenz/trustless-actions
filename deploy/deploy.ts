import { Address, Deployer } from "../web3webdeploy/types";

export interface DeploymentSettings {}

export interface Deployment {
  optimisticActions: Address;
}

export async function deploy(
  deployer: Deployer,
  settings?: DeploymentSettings
): Promise<Deployment> {
  const optimisticActions = await deployer.deploy({
    id: "OptimisticActions",
    contract: "OptimisticActions",
  });
  return {
    optimisticActions: optimisticActions,
  };
}
