// @expect AL0428 | Cannot specify EntityCaptionML and EntityCaption property at the same time. Use only the EntityCaption property.
// @expect AL0428 | Cannot specify EntityCaptionML and EntityCaption property at the same time. Use only the EntityCaption property.
// @expect AL0428 | Cannot specify EntitySetCaptionML and EntitySetCaption property at the same time. Use only the EntitySetCaption property.
// @expect AL0428 | Cannot specify EntitySetCaptionML and EntitySetCaption property at the same time. Use only the EntitySetCaption property.
// EntityCaption together with EntityCaptionML (and EntitySetCaption with EntitySetCaptionML).
table 59991 "MNC X Src" { fields { field(1; Id; Integer) { } } keys { key(PK; Id) { Clustered = true; } } }
query 59990 "MNC X Q" { QueryType = API; APIPublisher = 'p'; APIGroup = 'g'; APIVersion = 'v1.0'; EntityName = 'e'; EntitySetName = 'es'; EntityCaption = 'A'; EntityCaptionML = ENU = 'A'; EntitySetCaption = 'As'; EntitySetCaptionML = ENU = 'As'; elements { dataitem(S; "MNC X Src") { column(Id; Id) { } } } }
