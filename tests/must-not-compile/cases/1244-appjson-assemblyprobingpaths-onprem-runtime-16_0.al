// @expect AL0124 | The property 'assemblyProbingPaths' cannot be used in this context
// @target OnPrem
// @appjson {"runtime": "16.0", "assemblyProbingPaths": ["./.netpackages"]}
// assemblyProbingPaths in app.json is refused for a Target = OnPrem app too (the Cloud form is case 0007).
codeunit 50000 "MNC BB Codeunit"
{
}
