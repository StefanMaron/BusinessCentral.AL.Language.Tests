// @expect AL0471 | The format of link 'not a url' is not valid. It should be using the HTTP or HTTPS protocol.
// HelpLink with a text that is not a URL.
query 59990 "MNC X Q" { HelpLink = 'not a url'; elements { dataitem(C; Customer) { column(No; "No.") { } } } }
