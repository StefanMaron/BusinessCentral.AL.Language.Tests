// @expect AL0223 | The Property 'LinkedInTransaction' can only be used if the property 'LinkedObject' is set to 'true'
// LinkedInTransaction on a table that is not LinkedObject.
table 59990 "MNC X T" { LinkedInTransaction = false; fields { field(1; Id; Integer) { } } keys { key(PK; Id) { Clustered = true; } } }
