import { getRequiredEnvVariable, type EnvLoaderConfig } from "../env"

export async function resolveLocuToken(config: EnvLoaderConfig = {}): Promise<string> {
  return getRequiredEnvVariable("LOCU_PAT", config)
}
