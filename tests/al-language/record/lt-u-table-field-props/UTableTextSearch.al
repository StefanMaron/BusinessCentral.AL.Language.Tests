// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-optimizefortextsearch-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe (issue 599.2): OptimizeForTextSearch on a Text field: filters give the same rows as a plain field. Object ids 69580 and 69584.

table 69580 "LT U Text Search"
{
    DataClassification = SystemMetadata;
    Caption = 'Text search caption', MaxLength = 5;

    fields
    {
        field(1; Id; Integer) { }
        field(3; Txt; Text[30])
        {
            Caption = 'Text field caption', MaxLength = 4;
            OptimizeForTextSearch = true;
        }
        field(4; Plain; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 69584 "LT U Text Search Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure MaxLength_CaptionLongerThanLimit()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT U Text Search";
    begin
        Observer.Observe('table_caption', Rec.TableCaption());
        Observer.Observe('table_caption_length', Format(StrLen(Rec.TableCaption())));
        Observer.Observe('field_caption', Rec.FieldCaption(Txt));
        Observer.Observe('field_caption_length', Format(StrLen(Rec.FieldCaption(Txt))));
        Observer.Finish();
    end;

    [Test]
    procedure OptimizeForTextSearch_FiltersMatchPlainField()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT U Text Search";
        OnTxt: Integer;
        OnPlain: Integer;
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.Id := 1;
        Rec.Txt := 'apple pie';
        Rec.Plain := 'apple pie';
        Rec.Insert();
        Rec.Id := 2;
        Rec.Txt := 'Banana';
        Rec.Plain := 'Banana';
        Rec.Insert();
        Rec.Id := 3;
        Rec.Txt := 'cherry APPLE';
        Rec.Plain := 'cherry APPLE';
        Rec.Insert();

        Rec.SetFilter(Txt, '@*apple*');
        OnTxt := Rec.Count();
        Rec.Reset();
        Rec.SetFilter(Plain, '@*apple*');
        OnPlain := Rec.Count();
        Observer.Observe('contains_ci_txt', Format(OnTxt));
        Observer.Observe('contains_ci_plain', Format(OnPlain));
        Rec.Reset();
        Rec.SetFilter(Txt, '*apple*');
        OnTxt := Rec.Count();
        Rec.Reset();
        Rec.SetFilter(Plain, '*apple*');
        OnPlain := Rec.Count();
        Observer.Observe('contains_cs_txt', Format(OnTxt));
        Observer.Observe('contains_cs_plain', Format(OnPlain));
        Rec.Reset();
        Rec.SetRange(Txt, 'Banana');
        Observer.Observe('range_txt', Format(Rec.Count()));
        Rec.Reset();
        Rec.SetFilter(Txt, 'a*');
        Observer.Observe('starts_a_txt', Format(Rec.Count()));
        Rec.Reset();
        Rec.SetCurrentKey(Txt);
        Rec.FindFirst();
        Observer.Observe('first_by_txt', Format(Rec.Id));
        Rec.DeleteAll();
        Observer.Finish();
    end;
}
