// @expect AL0124 | The property 'assemblyProbingPaths' cannot be used in this context
// @appjson {"runtime": "18.0", "assemblyProbingPaths": ["./.netpackages"]}
// assemblyProbingPaths in app.json at runtime 18.0 (Cloud): still AL0124 (runtimes 15.0 to 17.0 are cases 0007, 0071 to 0073).
codeunit 50000 "MNC BB Codeunit"
{
}
