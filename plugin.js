const { spawnSync } = require("child_process");
const xcode = require("@raydeck/xcode");
const { join, basename, isAbsolute } = require("path");
const {
  existsSync,
  renameSync,
  writeFileSync,
  createWriteStream
} = require("fs");
const { sync } = require("glob");
const request = require("request");
const rimraf = require("rimraf");
module.exports = [
  {
    name: "add-mlmodel <modelpath>",
    description: "Add and compile mlmodel into your IOS project assets",
    func: async (argv, _, options) => {
      let tempPath;
      const outPath = options.outPath ? options.outPath : ".";
      const finalLocation = join(outPath, basename(argv[0]) + "c");
      const projectPath = sync(
        join(process.cwd(), "ios", "**", "project.pbxproj")
      )[0];
      if (!projectPath) {
        console.error("Cannot find an XCode project to modify: aborting");
        return;
      }
      if (existsSync(finalLocation)) {
        console.log(
          "Aborting compile: The mlmodelc directory already exists at ",
          finalLocation
        );
        addToProject(finalLocation, projectPath);
        const base = basename(finalLocation);
        const parts = base.split(".");
        parts.pop();
        const newBase = parts.join("."); //.replace("-", "_");
        console.log(
          `Model added. You may refer to it as ${newBase} in your code.`
        );
        return;
      }
      const finish = tempPath => {
        if (tempPath) {
          renameSync(tempPath, finalLocation);
        }
        addToProject(finalLocation, projectPath);
        const base = basename(finalLocation);
        const parts = base.split(".");
        parts.pop();
        const newBase = parts.join("."); //.replace("-", "_");
        console.log(
          `Model added. You may refer to it as ${newBase} in your code.`
        );
      };

      if (argv[0].includes("://")) {
        //URL!
        //transfer URL to our temp Path
        console.log(
          "I was passed a URL - attempting download. Big models can take a little time"
        );
        const outFile = join(process.env.TMPDIR, basename(argv[0]));
        request(argv[0])
          .pipe(createWriteStream(outFile))
          .on("finish", () => {
            tempPath = compileMLModel(outFile);
            finish(tempPath);
          });
      } else {
        tempPath = compileMLModel(argv[0]);
        finish(tempPath);
      }
    }
  }
];
const compileMLModel = (originPath, destinationPath = process.env.TMPDIR) => {
  const result = join(destinationPath, basename(originPath) + "c");
  try {
    if (existsSync(result)) rimraf.sync(result);
  } catch (e) {}
  spawnSync(
    "xcrun",
    ["coremlcompiler", "compile", originPath, destinationPath],
    {
      stdio: "inherit"
    }
  );
  //We know what the tail result will be
  return existsSync(result) ? result : false;
};
const addToProject = (fileToAdd, projectPath) => {
  if (!isAbsolute(fileToAdd)) fileToAdd = join(process.cwd(), fileToAdd);
  const project = xcode.project(projectPath);
  project.parseSync();
  console.log("Adding file ", fileToAdd);
  try {
    project.removeResourceFile(fileToAdd);
  } catch (e) {}
  project.addResourceFile(fileToAdd, {
    target: project.getFirstTarget().uuid,
    lastKnownFileType: "folder"
  });
  const outText = project.writeSync();
  writeFileSync(projectPath, outText);
};
