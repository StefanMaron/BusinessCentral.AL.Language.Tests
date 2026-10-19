// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-truncate-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT P163 TG Run (73326, a table-bound codeunit whose OnRun truncates the record it gets)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Known pins: misc/lt-probes-needed-3/PnC03Truncate.al (Media table, temporary record, each alone)

table 73239 "LT P163 TG Media"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Pic; Media) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 73240 "LT P163 TG MediaSet"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Pics; MediaSet) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 73241 "LT P163 TG Plain"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 73326 "LT P163 TG Run"
{
    TableNo = "LT P163 TG Plain";

    trigger OnRun()
    begin
        Rec.Truncate();
    end;
}

codeunit 73242 "LT P163 Truncate Guards"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P163_Truncate_TemporaryAndMedia_WhichGuardFirst()
    var
        TempMedia: Record "LT P163 TG Media" temporary;
        TempMediaSet: Record "LT P163 TG MediaSet" temporary;
        TempPlain: Record "LT P163 TG Plain" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        TempMedia.Id := 1;
        TempMedia.Insert();
        asserterror TempMedia.Truncate();
        Observer.ObserveError('temporary_media');
        Observer.Observe('temporary_media_rows_left', Format(TempMedia.Count()));
        TempMediaSet.Id := 1;
        TempMediaSet.Insert();
        asserterror TempMediaSet.Truncate();
        Observer.ObserveError('temporary_mediaset');
        TempPlain.Id := 1;
        TempPlain.Insert();
        asserterror TempPlain.Truncate();
        Observer.ObserveError('temporary_plain');
        Observer.Observe('temporary_plain_rows_left', Format(TempPlain.Count()));
        Observer.Expect('temporary_media|text', 'Temporary tables does not support truncation.');
        Observer.Expect('temporary_media|code', 'DB:Ok');
        Observer.Expect('temporary_media_rows_left', '1');
        Observer.Expect('temporary_mediaset|text', 'Temporary tables does not support truncation.');
        Observer.Expect('temporary_mediaset|code', 'DB:Ok');
        Observer.Expect('temporary_plain|text', 'Temporary tables does not support truncation.');
        Observer.Expect('temporary_plain|code', 'DB:Ok');
        Observer.Expect('temporary_plain_rows_left', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P163_Truncate_MediaSetTable_AndFilters()
    var
        MediaSetRec: Record "LT P163 TG MediaSet";
        Plain: Record "LT P163 TG Plain";
        Observer: Codeunit "Probe Observer";
    begin
        MediaSetRec.DeleteAll();
        MediaSetRec.Id := 1;
        MediaSetRec.Insert();
        asserterror MediaSetRec.Truncate();
        Observer.ObserveError('mediaset');
        Observer.Observe('mediaset_rows_left', Format(MediaSetRec.Count()));
        Plain.DeleteAll();
        Plain.Id := 1;
        Plain.Insert();
        Plain.Id := 2;
        Plain.Insert();
        Plain.SetRange(Id, 1);
        asserterror Observer.Observe('truncate_with_filter_ran', Format(Codeunit.Run(Codeunit::"LT P163 TG Run", Plain)));
        Observer.ObserveError('af115');
        Observer.Observe('truncate_with_filter_error', GetLastErrorText());
        Observer.Observe('rows_after_filtered_truncate', Format(CountAll(Plain)));
        Observer.Expect('mediaset|text', 'Truncate is not supported when the field has Media and/or MediaSet fields.');
        Observer.Expect('mediaset|code', 'DB:Ok');
        Observer.Expect('mediaset_rows_left', '0');
        Observer.Expect('af115|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('af115|code', 'DB:Ok');
        Observer.Expect('truncate_with_filter_error', '');
        Observer.Expect('rows_after_filtered_truncate', '0');
        Observer.Verify();
    end;

    local procedure CountAll(var Plain: Record "LT P163 TG Plain"): Integer
    begin
        Plain.Reset();
        exit(Plain.Count());
    end;

    [Test]
    procedure P163_Truncate_TableOtherRecordsRead()
    var
        Plain: Record "LT P163 TG Plain";
        Reader: Record "LT P163 TG Plain";
        Observer: Codeunit "Probe Observer";
    begin
        Plain.DeleteAll();
        Plain.Id := 1;
        Plain.Insert();
        Reader.FindFirst();
        asserterror Observer.Observe('truncate_ran', Format(Codeunit.Run(Codeunit::"LT P163 TG Run", Plain)));
        Observer.ObserveError('af139');
        Observer.Observe('truncate_error', GetLastErrorText());
        Observer.Observe('rows_after_truncate', Format(CountAll(Plain)));
        Observer.Observe('reader_get_after_truncate', Format(Reader.Get(1)));
        Observer.Observe('second_truncate_ran', Format(Codeunit.Run(Codeunit::"LT P163 TG Run", Plain)));
        Observer.Observe('second_truncate_rows', Format(CountAll(Plain)));
        Observer.Expect('af139|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('af139|code', 'DB:Ok');
        Observer.Expect('truncate_error', '');
        Observer.Expect('rows_after_truncate', '0');
        Observer.Expect('reader_get_after_truncate', 'No');
        Observer.Expect('second_truncate_ran', 'Yes');
        Observer.Expect('second_truncate_rows', '0');
        Observer.Verify();
    end;
}
