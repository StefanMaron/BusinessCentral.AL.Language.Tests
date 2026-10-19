// @expect AL0133 | Argument 1: cannot convert from 'Text[100]' to 'var Code[20]'
// Corpus issue #672 item 56: a Text[100] table field passed to a var parameter of type Code[20]. A value parameter accepts it (the length
// is checked at run time: tests/al-language/text/lt-cr-text-leads/CrTextLeads.al LongTextField_ToCode20Parameter); a var parameter does not.
table 51736 "MNC CR T1736"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[100]) { }
    }
}

codeunit 51736 "MNC CR C1736"
{
    local procedure TakeVarCode20(var C: Code[20])
    begin
        C := 'X';
    end;

    procedure Probe()
    var
        Rec: Record "MNC CR T1736";
    begin
        TakeVarCode20(Rec.Name);
    end;
}
