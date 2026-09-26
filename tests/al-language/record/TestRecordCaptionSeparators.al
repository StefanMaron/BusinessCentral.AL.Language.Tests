// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-tablecaption-method
// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-fieldcaption-method
// Scope: in-scope
// Fixtures used: ALT Separator Captioned (60026), ALT Separator Captioned Ext (60026),
//                ALT Separator Caption Query (60023)
//
// A declared Caption is stored as a multi-language value, whose own syntax uses ';', '='
// and a leading '"'. These tests pin that a caption containing any of them is returned
// whole: 'Before; after' is not cut at the ';', and '"Quoted" start' keeps its quotes.

codeunit 60038 "Test Record Caption Separators"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Record_TableCaption_CaptionWithSemicolon_ReturnsWholeCaption()
    var
        Rec: Record "ALT Separator Captioned";
    begin
        Assert.AreEqual('Before; after', Rec.TableCaption(),
            'TableCaption() must return the whole declared Caption, including the text after ";"');
    end;

    [Test]
    procedure RecordRef_Caption_CaptionWithSemicolon_ReturnsWholeCaption()
    var
        Rec: Record "ALT Separator Captioned";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        Assert.AreEqual('Before; after', RecRef.Caption(),
            'RecordRef.Caption() must return the whole declared Caption, including the text after ";"');
    end;

    [Test]
    procedure Record_FieldCaption_CaptionWithSemicolon_ReturnsWholeCaption()
    var
        Rec: Record "ALT Separator Captioned";
    begin
        Assert.AreEqual('Left; right', Rec.FieldCaption("Entry No."),
            'FieldCaption() must return the whole declared Caption, including the text after ";"');
    end;

    [Test]
    procedure FieldRef_Caption_CaptionWithSemicolon_ReturnsWholeCaption()
    var
        Rec: Record "ALT Separator Captioned";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.GetTable(Rec);
        FldRef := RecRef.Field(Rec.FieldNo("Entry No."));
        Assert.AreEqual('Left; right', FldRef.Caption(),
            'FieldRef.Caption() must return the whole declared Caption, including the text after ";"');
    end;

    [Test]
    procedure Record_FieldCaption_CaptionStartingWithQuote_KeepsTheQuotes()
    var
        Rec: Record "ALT Separator Captioned";
    begin
        Assert.AreEqual('"Quoted" start', Rec.FieldCaption("Quoted Start"),
            'FieldCaption() must return a Caption that opens with a double quote unchanged');
    end;

    [Test]
    procedure Record_FieldCaption_CaptionWithEqualsSign_ReturnsWholeCaption()
    var
        Rec: Record "ALT Separator Captioned";
    begin
        Assert.AreEqual('Rate = 5%', Rec.FieldCaption("Equals Sign"),
            'FieldCaption() must return a Caption containing "=" unchanged');
    end;

    [Test]
    procedure Record_FieldCaption_ModifiedCaptionWithSemicolonAndQuotes_ReturnsWholeCaption()
    var
        Rec: Record "ALT Separator Captioned";
    begin
        Assert.AreEqual('Changed; by "extension"', Rec.FieldCaption("Modified Field"),
            'FieldCaption() must return the whole Caption a tableextension set through modify()');
    end;

    [Test]
    procedure Query_ColumnCaption_CaptionWithSemicolon_ReturnsWholeCaption()
    var
        SeparatorQuery: Query "ALT Separator Caption Query";
    begin
        Assert.AreEqual('Column; with semicolon', SeparatorQuery.ColumnCaption(EntryNo),
            'Query.ColumnCaption() must return the whole declared Caption, including the text after ";"');
    end;

    [Test]
    procedure Query_ColumnCaption_CaptionStartingWithQuote_KeepsTheQuotes()
    var
        SeparatorQuery: Query "ALT Separator Caption Query";
    begin
        Assert.AreEqual('"Quoted" column', SeparatorQuery.ColumnCaption(QuotedStart),
            'Query.ColumnCaption() must return a Caption that opens with a double quote unchanged');
    end;

    [Test]
    procedure Record_TableName_CaptionWithSemicolon_StillReturnsTheName()
    var
        Rec: Record "ALT Separator Captioned";
    begin
        // Negative direction: the object name is not a multi-language value and is untouched.
        Assert.AreEqual('ALT Separator Captioned', Rec.TableName(),
            'TableName() must return the object name, not the declared Caption');
    end;

    [Test]
    procedure Record_FieldName_CaptionWithSemicolon_StillReturnsTheName()
    var
        Rec: Record "ALT Separator Captioned";
    begin
        Assert.AreEqual('Entry No.', Rec.FieldName("Entry No."),
            'FieldName() must return the field name, not the declared Caption');
    end;
}
