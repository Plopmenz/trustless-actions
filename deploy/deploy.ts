import { Address, Deployer } from "../web3webdeploy/types";
import { deploy as ensReverseRegistrarDeploy } from "../lib/ens-reverse-registrar/deploy/deploy";

export interface DeploymentSettings {
  admin?: Address;
  ensReverseRegistar?: Address;
}

export interface Deployment {
  optimisticActions: Address;
}

export async function deploy(
  deployer: Deployer,
  settings?: DeploymentSettings
): Promise<Deployment> {
  const admin = settings?.admin ?? "0x2309762aAcA0a8F689463a42c0A6A84BE3A7ea51";
  deployer.startContext("lib/ens-reverse-registrar");
  const ensReverseRegistrar =
    settings?.ensReverseRegistar ??
    (await ensReverseRegistrarDeploy(deployer)).reverseRegistrar;
  deployer.finishContext();

  const optimisticActions = await deployer.deploy({
    id: "OptimisticActions",
    contract: "OptimisticActions",
    args: [admin, ensReverseRegistrar],
  });
  return {
    optimisticActions: optimisticActions,
  };
}
