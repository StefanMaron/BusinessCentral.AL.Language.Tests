// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-wordmergedataitem-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table and helper of CjFix.al; own reports 84656 (WordMergeDataItem = Row) and 84657 (no WordMergeDataItem),
//   test codeunit 84658; layouts LtCjSectionsMerge.docx and LtCjSectionsPlain.docx are hand-made: the compiler's generated layout with a next-page section break
//   between two paragraphs (two sections in the body)
// Probe: observed values; every literal asserted below is what the BC tiers of the corpus matrix produced.
// Facts (corpus issue 667, item 158): a Word layout that contains section breaks, on a report with WordMergeDataItem and on one without: whether
//   Report.SaveAs to Word and Pdf renders or raises (the docs name the error "You cannot run the report because the layout contains section breaks" for
//   releases before 2024 release wave 2), and how many sections the Word output has.
// BC versions: 27-29

report 84656 "LT CJ Word Sections Merge"
{
    UsageCategory = None;
    UseRequestPage = false;
    DefaultRenderingLayout = CjSectionsMerge;
    WordMergeDataItem = Row;

    dataset
    {
        dataitem(Row; "LT CJ Row")
        {
            column(RowId; Id) { }
        }
    }

    rendering
    {
        layout(CjSectionsMerge)
        {
            Type = Word;
            LayoutFile = './report/lt-cj-report-leads/LtCjSectionsMerge.docx';
        }
    }
}

report 84657 "LT CJ Word Sections Plain"
{
    UsageCategory = None;
    UseRequestPage = false;
    DefaultRenderingLayout = CjSectionsPlain;

    dataset
    {
        dataitem(Row; "LT CJ Row")
        {
            column(RowId; Id) { }
        }
    }

    rendering
    {
        layout(CjSectionsPlain)
        {
            Type = Word;
            LayoutFile = './report/lt-cj-report-leads/LtCjSectionsPlain.docx';
        }
    }
}

codeunit 84658 "LT CJ Word Sections Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT CJ Helper";

    [TryFunction]
    local procedure TrySave(ReportId: Integer; Fmt: ReportFormat; var TempBlob: Codeunit "Temp Blob"; var Ok: Boolean)
    var
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Ok := Report.SaveAs(ReportId, '', Fmt, OutS);
    end;

    // The number of section properties (<w:sectPr) in word/document.xml of a Word package; one per section.
    local procedure Sections(var TempBlob: Codeunit "Temp Blob"): Text
    var
        DataCompression: Codeunit "Data Compression";
        Entry: Codeunit "Temp Blob";
        InS: InStream;
        EntryOut: OutStream;
        EntryIn: InStream;
        Line: Text;
        Doc: Text;
        Length: Integer;
        Count: Integer;
        At: Integer;
    begin
        if TempBlob.Length() = 0 then
            exit('empty');
        TempBlob.CreateInStream(InS);
        DataCompression.OpenZipArchive(InS, false);
        Entry.CreateOutStream(EntryOut);
        DataCompression.ExtractEntry('word/document.xml', EntryOut, Length);
        DataCompression.CloseZipArchive();
        Entry.CreateInStream(EntryIn, TextEncoding::UTF8);
        while not EntryIn.EOS() do begin
            EntryIn.ReadText(Line);
            Doc += Line;
        end;
        At := Doc.IndexOf('<w:sectPr');
        while At > 0 do begin
            Count += 1;
            Doc := Doc.Substring(At + 9);
            At := Doc.IndexOf('<w:sectPr');
        end;
        exit(Format(Count));
    end;

    local procedure One(var Observer: Codeunit "Probe Observer"; ReportId: Integer; Name: Text; Fmt: ReportFormat)
    var
        TempBlob: Codeunit "Temp Blob";
        Ok: Boolean;
        Completed: Boolean;
    begin
        Helper.Seed();
        ClearLastError();
        Completed := TrySave(ReportId, Fmt, TempBlob, Ok);
        Observer.Observe(Name + ' completed', Format(Completed));
        Observer.Observe(Name + ' returned', Format(Ok));
        Observer.ObserveError(Name + ' err');
        Observer.Observe(Name + ' head', Helper.Head(TempBlob));
        if Completed and Ok and (Fmt = ReportFormat::Word) then
            Observer.Observe(Name + ' sections', Sections(TempBlob));
    end;

    [Test]
    procedure SectionBreaks_WordMergeDataItem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        One(Observer, Report::"LT CJ Word Sections Merge", 'Word', ReportFormat::Word);
        One(Observer, Report::"LT CJ Word Sections Merge", 'Pdf', ReportFormat::Pdf);
        Observer.Finish();
    end;

    [Test]
    procedure SectionBreaks_NoWordMergeDataItem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        One(Observer, Report::"LT CJ Word Sections Plain", 'Word', ReportFormat::Word);
        One(Observer, Report::"LT CJ Word Sections Plain", 'Pdf', ReportFormat::Pdf);
        Observer.Finish();
    end;
}
