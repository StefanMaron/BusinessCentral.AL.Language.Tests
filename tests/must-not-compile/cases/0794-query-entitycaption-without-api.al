// @expect AL0223 | The Property 'EntityCaption' can only be used if the property 'QueryType' is set to 'API'
// EntityCaption on a query that is not of QueryType API.
query 59990 "MNC X Q" { EntityCaption = 'Item'; elements { dataitem(C; Customer) { column(No; "No.") { } } } }
