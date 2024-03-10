import { Address, DeployInfo, Deployer } from "../../web3webdeploy/types";

export interface DeployOptimisticActionsSettings
  extends Omit<DeployInfo, "contract" | "args"> {}

export async function deployOptimsticActions(
  deployer: Deployer,
  settings: DeployOptimisticActionsSettings
): Promise<Address> {
  return await deployer
    .deploy({
      id: "OptimisticActions",
      contract: "OptimisticActions",
      ...settings,
    })
    .then((deployment) => deployment.address);
}
