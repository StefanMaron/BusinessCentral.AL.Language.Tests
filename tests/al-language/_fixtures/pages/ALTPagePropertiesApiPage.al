// The API/Entity group of "Page Metadata" (2000000138) columns, which only compile on a
// PageType = API page: APIPublisher (9), APIGroup (10), APIVersion (11), EntitySetName (12),
// EntityName (13), and ChangeTrackingAllowed (27) — the compiler rejects the last one on any
// other PageType with AL0223.
page 60902 "ALT Page Properties Api Page"
{
    PageType = API;
    SourceTable = "ALT Keyed";
    APIPublisher = 'altpublisher';
    APIGroup = 'altgroup';
    APIVersion = 'v1.0';
    EntityName = 'altPagePropertiesEntity';
    EntitySetName = 'altPagePropertiesEntities';
    ChangeTrackingAllowed = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(id; Rec.SystemId) { }
                field(entryNo; Rec."Entry No.") { }
            }
        }
    }
}
