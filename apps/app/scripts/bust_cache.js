// Post-build: append a content hash to main.dart.js references so browsers
// and the Flutter service worker always fetch the latest bundle.
const fs = require("fs");
const path = require("path");

const webDir = path.join(__dirname, "..", "build", "web");
const mainJs = path.join(webDir, "main.dart.js");
const bootstrapJs = path.join(webDir, "flutter_bootstrap.js");

const hash = require("crypto")
  .createHash("sha256")
  .update(fs.readFileSync(mainJs))
  .digest("hex")
  .slice(0, 12);

let bootstrap = fs.readFileSync(bootstrapJs, "utf8");
bootstrap = bootstrap.replace(
  /"mainJsPath":"main\.dart\.js"/g,
  `"mainJsPath":"main.dart.js?v=${hash}"`,
);
bootstrap = bootstrap.replace(
  /entrypointUrl:\s*"main\.dart\.js"/g,
  `entrypointUrl: "main.dart.js?v=${hash}"`,
);
fs.writeFileSync(bootstrapJs, bootstrap);

console.log(`Cache-busted main.dart.js with ?v=${hash}`);
