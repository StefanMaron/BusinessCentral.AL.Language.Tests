// @expect AL0440 | The PageExtension 'MNC BO 1414 PE2' already defines a method called 'foo' with the same parameter types
// @expect AL0440 | The PageExtension 'MNC BO 1414 PE1' already defines a method called 'foo' with the same parameter types
// @expect AL0440 | The TableExtension 'MNC BO 1414 TE2' already defines a method called 'foo' with the same parameter types
// @expect AL0440 | The TableExtension 'MNC BO 1414 TE1' already defines a method called 'foo' with the same parameter types
// Two page extensions of one page (and two table extensions of one table) in one app each declare procedure foo(): AL0440 on both
// declarations. Two extensions of one target in one app compile otherwise (no AL0334 today: the corpus app has three table extensions of
// Job). The cross-app form (two apps, a third calls foo()) needs three apps. Corpus issue 664 items 89 and 94 (microsoft/AL#4997). Writer BO.
// (4 diagnostics)
pageextension 51419 "MNC BO 1414 PE1" extends "Customer List" { procedure foo() begin end; }
pageextension 51420 "MNC BO 1414 PE2" extends "Customer List" { procedure foo() begin end; }
tableextension 51419 "MNC BO 1414 TE1" extends Customer { procedure foo() begin end; }
tableextension 51420 "MNC BO 1414 TE2" extends Customer { procedure foo() begin end; }
