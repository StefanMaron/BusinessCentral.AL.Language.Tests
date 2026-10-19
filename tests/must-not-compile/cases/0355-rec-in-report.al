// @expect AL0118 | The name 'Rec' does not exist in the current context.
// Rec in a report trigger.
report 50173 "MNC R355"
{
    trigger OnPreReport()
    begin
        Rec.Init();
    end;
}
