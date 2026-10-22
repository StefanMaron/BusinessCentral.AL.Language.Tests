// @expect AL0471 | The format of link 'not a url' is not valid. It should be using the HTTP or HTTPS protocol.
report 50814 "MNC Y RP Help Url"
{
    ProcessingOnly = true;
    requestpage
    {
        HelpLink = 'not a url';
        layout { area(Content) { field(F; Fv) { ApplicationArea = All; } } }
    }
    var
        Fv: Integer;
}
