// Fixture for TestDateVirtualTableFlowField.al (codeunit 60779).
//
// FlowFields whose CalcFormula source is a COMPUTED system virtual table — Date (2000000007)
// and Integer (2000000026). Neither table stores rows: the platform computes them per request,
// so these formulas are the shape that asks whether a FlowField can be calculated over a source
// with no stored rows at all, and whether the range it names is the range the platform walks.
//
// "Date Filter" is a FlowFilter rather than a literal inside the formula on purpose: a date
// written into a CalcFormula is parsed by the platform's filter parser under the session's
// culture, and the same filter set from AL with DMY2Date carries no culture at all. The two
// arms are both here so the pair states which forms the platform accepts.
table 60778 "DVT Flow Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
        }
        field(2; "Date Filter"; Date)
        {
            FieldClass = FlowFilter;
        }
        field(3; "Days In Date Filter"; Integer)
        {
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = count(Date where("Period Type" = const(Date), "Period Start" = field("Date Filter")));
        }
        field(4; "Earliest Day In Filter"; Date)
        {
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = min("Date"."Period Start" where("Period Type" = const(Date), "Period Start" = field("Date Filter")));
        }
        field(5; "Latest Day In Filter"; Date)
        {
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = max("Date"."Period Start" where("Period Type" = const(Date), "Period Start" = field("Date Filter")));
        }
        field(6; "Any Week In Filter"; Boolean)
        {
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = exist(Date where("Period Type" = const(Week), "Period Start" = field("Date Filter")));
        }
        field(7; "Number Filter"; Integer)
        {
            FieldClass = FlowFilter;
        }
        field(8; "Integers In Filter"; Integer)
        {
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = count(Integer where(Number = field("Number Filter")));
        }
        field(9; "Related Period"; Date)
        {
            DataClassification = CustomerContent;
            TableRelation = Date."Period Start" where("Period Type" = const(Date));
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
