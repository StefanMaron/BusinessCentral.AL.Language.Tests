// @expect AL0118 | The name 'P' does not exist in the current context.
// The members of an option parameter (P: Option Alpha,Beta) are named through the parameter (P::Beta); outside the procedure the parameter
// name does not exist, so another procedure cannot name its members.
codeunit 51400 "MNC BN C1400"
{
    procedure Take(P: Option Alpha,Beta): Integer
    begin
        exit(P);
    end;

    procedure Use(): Integer
    begin
        exit(Take(P::Beta));
    end;
}
