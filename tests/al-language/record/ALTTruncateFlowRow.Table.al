/// <summary>
/// Fixture for TestRecordTruncateEventAndFilterGuards.al — the table carrying a FlowField,
/// so a filter can be placed ON that FlowField.
///
/// BC's ValidateTruncateSupport ends with
/// FlowFieldsHelper.AnyFiltersOnFlowFields(record.RecordImplementation.TableState.FiltersAndMarks)
/// and raises Lang.TruncateFilterOnFlowField. Reaching it needs a table that HAS a
/// FlowField; every other fixture in this directory that has one is already the subject of
/// a CalcFields suite, and sharing one would couple two unrelated claims.
///
/// No OnBeforeDelete/OnAfterDelete subscriber exists for this table, so the
/// delete-subscriber guard (which runs EARLIER) cannot mask the FlowField guard.
/// </summary>
table 60516 "ALT Truncate Flow Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
        }
        field(2; "Link Code"; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(3; "Total Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("ALT Truncate Guard Row"."Amount Field");
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
