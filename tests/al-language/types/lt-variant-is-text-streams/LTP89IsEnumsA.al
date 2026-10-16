// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160), enum LT P89 Color (74626)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 74628 "LT P89 Is Enums A"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Flags(V: Variant): Text
    var
        R: Text;
    begin
        if V.IsAction() then
            R += 'Action,';
        if V.IsClientType() then
            R += 'ClientType,';
        if V.IsDataClassification() then
            R += 'DataClassification,';
        if V.IsDefaultLayout() then
            R += 'DefaultLayout,';
        if V.IsExecutionMode() then
            R += 'ExecutionMode,';
        if V.IsOption() then
            R += 'Option,';
        if V.IsInteger() then
            R += 'Integer,';
        if V.IsBigInteger() then
            R += 'BigInteger,';
        if V.IsText() then
            R += 'Text,';
        if V.IsCode() then
            R += 'Code,';
        if V.IsChar() then
            R += 'Char,';
        if V.IsByte() then
            R += 'Byte,';
        if V.IsBoolean() then
            R += 'Boolean,';
        exit(R);
    end;

    [Test]
    procedure Action_InVariant()
    var
        Observer: Codeunit "Probe Observer";
        X: Action;
        V: Variant;
    begin
        V := X;
        Observer.Observe('default', Flags(V));
        X := Action::OK;
        V := X;
        Observer.Observe('ok', Flags(V));
        Observer.Observe('ok_format', Format(X));
        V := Format(X);
        Observer.Observe('ok_text', Flags(V));
        X := Action::Cancel;
        V := X;
        Observer.Observe('cancel', Flags(V));
        Observer.Observe('cancel_format', Format(X));
        V := Format(X);
        Observer.Observe('cancel_text', Flags(V));
        X := Action::LookupOK;
        V := X;
        Observer.Observe('lookupok', Flags(V));
        Observer.Observe('lookupok_format', Format(X));
        V := Format(X);
        Observer.Observe('lookupok_text', Flags(V));
        X := Action::LookupCancel;
        V := X;
        Observer.Observe('lookupcancel', Flags(V));
        Observer.Observe('lookupcancel_format', Format(X));
        V := Format(X);
        Observer.Observe('lookupcancel_text', Flags(V));
        X := Action::Yes;
        V := X;
        Observer.Observe('yes', Flags(V));
        Observer.Observe('yes_format', Format(X));
        V := Format(X);
        Observer.Observe('yes_text', Flags(V));
        X := Action::No;
        V := X;
        Observer.Observe('no', Flags(V));
        Observer.Observe('no_format', Format(X));
        V := Format(X);
        Observer.Observe('no_text', Flags(V));
        V := Action::OK;
        Observer.Observe('literal', Flags(V));
        Observer.Finish();
    end;

    [Test]
    procedure ClientType_InVariant()
    var
        Observer: Codeunit "Probe Observer";
        X: ClientType;
        V: Variant;
    begin
        V := X;
        Observer.Observe('default', Flags(V));
        X := ClientType::Web;
        V := X;
        Observer.Observe('web', Flags(V));
        Observer.Observe('web_format', Format(X));
        V := Format(X);
        Observer.Observe('web_text', Flags(V));
        X := ClientType::Background;
        V := X;
        Observer.Observe('background', Flags(V));
        Observer.Observe('background_format', Format(X));
        V := Format(X);
        Observer.Observe('background_text', Flags(V));
        X := ClientType::Default;
        V := X;
        Observer.Observe('default', Flags(V));
        Observer.Observe('default_format', Format(X));
        V := Format(X);
        Observer.Observe('default_text', Flags(V));
        V := ClientType::Web;
        Observer.Observe('literal', Flags(V));
        Observer.Finish();
    end;

    [Test]
    procedure DataClassification_InVariant()
    var
        Observer: Codeunit "Probe Observer";
        X: DataClassification;
        V: Variant;
    begin
        V := X;
        Observer.Observe('default', Flags(V));
        X := DataClassification::CustomerContent;
        V := X;
        Observer.Observe('customercontent', Flags(V));
        Observer.Observe('customercontent_format', Format(X));
        V := Format(X);
        Observer.Observe('customercontent_text', Flags(V));
        X := DataClassification::SystemMetadata;
        V := X;
        Observer.Observe('systemmetadata', Flags(V));
        Observer.Observe('systemmetadata_format', Format(X));
        V := Format(X);
        Observer.Observe('systemmetadata_text', Flags(V));
        X := DataClassification::ToBeClassified;
        V := X;
        Observer.Observe('tobeclassified', Flags(V));
        Observer.Observe('tobeclassified_format', Format(X));
        V := Format(X);
        Observer.Observe('tobeclassified_text', Flags(V));
        V := DataClassification::CustomerContent;
        Observer.Observe('literal', Flags(V));
        Observer.Finish();
    end;

    [Test]
    procedure DefaultLayout_InVariant()
    var
        Observer: Codeunit "Probe Observer";
        X: DefaultLayout;
        V: Variant;
    begin
        V := X;
        Observer.Observe('default', Flags(V));
        X := DefaultLayout::RDLC;
        V := X;
        Observer.Observe('rdlc', Flags(V));
        Observer.Observe('rdlc_format', Format(X));
        V := Format(X);
        Observer.Observe('rdlc_text', Flags(V));
        X := DefaultLayout::Word;
        V := X;
        Observer.Observe('word', Flags(V));
        Observer.Observe('word_format', Format(X));
        V := Format(X);
        Observer.Observe('word_text', Flags(V));
        V := DefaultLayout::RDLC;
        Observer.Observe('literal', Flags(V));
        Observer.Finish();
    end;

    [Test]
    procedure ExecutionMode_InVariant()
    var
        Observer: Codeunit "Probe Observer";
        X: ExecutionMode;
        V: Variant;
    begin
        V := X;
        Observer.Observe('default', Flags(V));
        X := ExecutionMode::Debug;
        V := X;
        Observer.Observe('debug', Flags(V));
        Observer.Observe('debug_format', Format(X));
        V := Format(X);
        Observer.Observe('debug_text', Flags(V));
        X := ExecutionMode::Standard;
        V := X;
        Observer.Observe('standard', Flags(V));
        Observer.Observe('standard_format', Format(X));
        V := Format(X);
        Observer.Observe('standard_text', Flags(V));
        V := ExecutionMode::Debug;
        Observer.Observe('literal', Flags(V));
        Observer.Finish();
    end;

    [Test]
    procedure NearTypes()
    var
        Observer: Codeunit "Probe Observer";
        O: Option A,B,C;
        E: Enum "LT P89 Color";
        I: Integer;
        Bi: BigInteger;
        T: Text;
        C: Code[10];
        V: Variant;
    begin
        V := O; Observer.Observe('option', Flags(V));
        V := E; Observer.Observe('enum', Flags(V));
        V := I; Observer.Observe('integer', Flags(V));
        V := Bi; Observer.Observe('biginteger', Flags(V));
        T := 'x'; V := T; Observer.Observe('text', Flags(V));
        C := 'X'; V := C; Observer.Observe('code', Flags(V));
        V := true; Observer.Observe('boolean', Flags(V));
        Observer.Finish();
    end;
}
