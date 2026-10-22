// @expect AL0528 | The name of field controls in pages of the type API must be alphanumeric.
// @expect AL0528 | The name of field controls in pages of the type API must be alphanumeric.
// Field control names on a page with PageType = API (microsoft/AL issue 3962): a name with a space and a name with a quoted special
// character are refused. The other names here compile: a digit inside the name (BlobValueEncoded64), a leading digit ("1abc") and an
// underscore (my_field). The case pins that only the two names give a diagnostic.
table 51430 "MNC BP T1430"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; "Blob Value"; Text[30]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 51430 "MNC BP P1430"
{
    PageType = API;
    APIPublisher = 'bp';
    APIGroup = 'bp';
    APIVersion = 'v1.0';
    EntityName = 'bpThing';
    EntitySetName = 'bpThings';
    SourceTable = "MNC BP T1430";
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(G)
            {
                field(id; Rec.Id) { }
                field(BlobValueEncoded64; Rec."Blob Value") { }
                field("1abc"; Rec."Blob Value") { }
                field(my_field; Rec."Blob Value") { }
                field("two words"; Rec."Blob Value") { }
                field("my#field"; Rec."Blob Value") { }
            }
        }
    }
}
