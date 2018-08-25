import RNFS from "react-native-fs"
import { compileModel } from "react-native-coreml"
const fetchModel = async modelName => {
  const compiledPath = RNFS.DocumentDirectoryPath + "/" + modelName + ".mlmodelc"
  if (await RNFS.exists(compiledPath)) {
    return compiledPath
  }

  const sourceURL = `https://s3-us-west-2.amazonaws.com/coreml-models/${modelName}.mlmodel`
  const toFile = RNFS.TemporaryDirectoryPath + modelName + ".mlmodel"
  const { promise, jobId } = RNFS.downloadFile({
    fromUrl: sourceURL,
    toFile: toFile,
  })
  await promise
  const tempPath = await compileModel(toFile)
  await RNFS.moveFile(tempPath, compiledPath)
  return "file://" + compiledPath
}

export default fetchModel
