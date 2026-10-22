// @expect AL0124 | The property 'assemblyProbingPaths' cannot be used in this context
// @appjson {"assemblyProbingPaths": ["./.netpackages"]}
// app.json of an app with the runtime 16.0 does not take assemblyProbingPaths (the compiler option /assemblyprobingpaths does).
codeunit 50000 "MNC Codeunit"
{
}
