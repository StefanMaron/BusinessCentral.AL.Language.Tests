// @expect AL0104 | Syntax error, ')' expected
// @expect AL0104 | Syntax error, 'procedure' expected
// @expect AL0104 | Syntax error, '(' expected
// @expect AL0107 | Syntax error, identifier expected.
// @expect AL0104 | Syntax error, ':' expected
// An attribute on a parameter ([SecurityFiltering(SecurityFilter::Ignored)] before a Record parameter) is a syntax error: attributes stand
// only before a procedure or a variable. Corpus issue 664 item 112 (microsoft/AL#5796). Writer BO. (5 diagnostics)
codeunit 51437 "MNC BO 1428"
{
    procedure P([SecurityFiltering(SecurityFilter::Ignored)] Contact: Record Contact) begin end;
}
