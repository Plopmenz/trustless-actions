import { Address, DeployInfo, Deployer } from "../../web3webdeploy/types";

export interface DeployPessimisticActionsSettings
  extends Omit<DeployInfo, "contract" | "args"> {}

export async function deployPessimisticActions(
  deployer: Deployer,
  settings: DeployPessimisticActionsSettings
): Promise<Address> {
  return await deployer
    .deploy({
      id: "PessimisticActions",
      contract: "PessimisticActions",
      ...settings,
    })
    .then((deployment) => deployment.address);
}
