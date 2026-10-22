// @expect AL0408 | The type 'Record' cannot be used as a type argument in this context.
// @expect AL0408 | The type 'Record' cannot be used as a type argument in this context.
// Corpus issue 670 item 6: Dictionary of [Integer, Record ...] and List of [Record ...] are refused. List of [RecordRef] compiles (runtime test: collections/lt-cs-odd-leads/CsCollections.al).
codeunit 50748 "MNC C1748"
{
    procedure Run1()
    var
        D: Dictionary of [Integer, Record "Company Information"];
    begin
    end;

    procedure Run2()
    var
        L: List of [Record "Company Information"];
    begin
    end;
}
