// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subpages-overview
// Scope: in-scope
// Fixtures used: none (self-contained host table + pages, per the ListPart/TestPage
//   conventions already used by TestPageModalPart_PartList.al)
//
// A page (or ListPart) declared SourceTable = Integer; SourceTableTemporary = true; must
// bind to its OWN empty temporary rowset -- exactly like a temporary source table over any
// other table -- never to the platform's shared/virtual Integer rows. Number starts
// unpositioned (First() = false on an empty page) and the only rows present after the page
// (or its host) inserts them are the ones it inserted itself, starting at Number = 1.

table 60622 "Test TmpInt Host Row"
{
    fields
    {
        field(1; "No."; Code[20]) { }
    }
    keys { key(PK; "No.") { Clustered = true; } }
}

page 60623 "Test TmpInt Array Part"
{
    PageType = ListPart;
    SourceTable = Integer;
    SourceTableTemporary = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Number; Rec.Number) { ApplicationArea = All; }
                field(ValueAtNumber; Values[Rec.Number]) { ApplicationArea = All; Caption = 'Value'; }
            }
        }
    }

    var
        Values: array[20] of Decimal;

    internal procedure Load(Count: Integer)
    var
        i: Integer;
    begin
        Rec.DeleteAll();
        for i := 1 to Count do begin
            Values[i] := i * 10;
            Rec.Init();
            Rec.Number := i;
            Rec.Insert();
        end;
        CurrPage.Update(false);
    end;
}

page 60624 "Test TmpInt Host Card"
{
    PageType = Card;
    SourceTable = "Test TmpInt Host Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Prices; "Test TmpInt Array Part") { ApplicationArea = All; }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.Prices.Page.Load(3);
    end;
}

codeunit 60625 "Test TmpInt ListPart"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure TempIntegerPart_DirectOpen_StartsEmpty()
    // CLAIM: a TestPage over a page declaring SourceTable = Integer;
    // SourceTableTemporary = true; opens on an empty rowset -- never the platform's
    // materialised/virtual Integer rows.
    var
        Part: TestPage "Test TmpInt Array Part";
    begin
        Initialize();

        Part.OpenView();
        Assert.IsFalse(Part.First(), 'a never-populated temporary-Integer part must start empty');
        Part.Close();
    end;

    [Test]
    procedure TempIntegerPart_SelfLoaded_FirstRowIsNumberOne()
    // CLAIM: rows the temporary-Integer page inserts itself are the ONLY rows visible,
    // and Number/array-indexed columns read back exactly what was inserted.
    var
        Part: TestPage "Test TmpInt Array Part";
    begin
        Initialize();

        Part.OpenView();
        Part.Load(3);
        Assert.IsTrue(Part.First(), 'part must have rows after Load');
        Assert.AreEqual('1', Part.Number.Value(), 'first row Number');
        Assert.AreEqual('10', Part.ValueAtNumber.Value(), 'first row Values[Number]');
        Part.Close();
    end;

    [Test]
    procedure TempIntegerPart_HostPushed_ReadsInsertedRows()
    // CLAIM: the same claim, but the part is hosted on a Card and populated from the
    // host's OnAfterGetCurrRecord via CurrPage.<part>.Page.<method> -- the runner-observed
    // trigger shape for issue #2516.
    var
        Row: Record "Test TmpInt Host Row";
        Card: TestPage "Test TmpInt Host Card";
    begin
        Initialize();

        Row.Init();
        Row."No." := 'ROW-1';
        Row.Insert();

        Card.OpenEdit();
        Card.GoToRecord(Row);
        Assert.IsTrue(Card.Prices.First(), 'hosted part must have rows after host push');
        Assert.AreEqual('1', Card.Prices.Number.Value(), 'first row Number');
        Assert.AreEqual('10', Card.Prices.ValueAtNumber.Value(), 'first row Values[Number]');
        Card.Close();
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
        Row_DeleteAll();
    end;

    local procedure Row_DeleteAll()
    var
        Row: Record "Test TmpInt Host Row";
    begin
        Row.DeleteAll();
    end;
}
