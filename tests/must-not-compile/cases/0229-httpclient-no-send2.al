// @expect AL0132 | 'HttpClient' does not contain a definition for 'Send2'
// HttpClient has no Send2 method.
codeunit 50035 "MNC C229"
{
    procedure Run1()
    var
        H: HttpClient;
        M: HttpRequestMessage;
        R: HttpResponseMessage;
    begin
        H.Send2(M, R);
    end;
}
