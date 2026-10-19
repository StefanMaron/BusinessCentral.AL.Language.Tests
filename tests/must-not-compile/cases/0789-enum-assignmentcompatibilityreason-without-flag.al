// @expect AL0223 | The Property 'AssignmentCompatibilityReason' can only be used if the property 'AssignmentCompatibility' is set to 'true'
// AssignmentCompatibilityReason needs AssignmentCompatibility = true.
enum 59990 "MNC X Enum" { AssignmentCompatibilityReason = 'Because'; value(0; A) { } }
