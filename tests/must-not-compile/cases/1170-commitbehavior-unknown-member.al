// CommitBehavior has two members, Ignore and Error (corpus issue 647 item 4, writer AV): any other name is refused.
// @expect AL0132 | 'CommitBehavior' does not contain a definition for 'Allow'
codeunit 51170 "MNC AV CommitBehavior Member"
{
    [CommitBehavior(CommitBehavior::Allow)]
    procedure Probe()
    begin
    end;
}
