// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-editable-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-openview-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-lookupmode-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-editable-method
// Scope: in-scope
// Fixtures used: CER Row (68016), CER Card (68017), CER Part (68018), CER Host (68019),
//                CER List (68020), CER ReEdit Card (68021), CER Lock Card (68022),
//                CER Probe (68023), Assert (60021)
//
/// <summary>
/// What a control's Editable() answers on the page routes codeunit 68015 "RSV Tests" did not
/// measure. Every arm reads two controls and asserts one string:
///     ctlEd=   a control bound to a field of Rec (Name)
///     varEd=   a control bound to a page variable (NoteCtl)
/// beside the page's own Editable() (pageEd=), and for a part the host's (hostEd=) and the
/// part's (partEd=).
///
/// The routes:
///     a subpage part, the host opened with OpenEdit(), OpenView(), or OpenEdit() then View()
///     a card and a list handed to a [ModalPageHandler] with LookupMode(true), and without it
///     a card opened by an action with RunPageMode = View, read in the [PageHandler]
///     a card whose OnOpenPage calls CurrPage.Editable(true), opened with OpenView()
///     a card whose OnOpenPage calls CurrPage.Editable(false), opened with OpenEdit()
///
/// Written by agent stma-auto-5, an automated implementation agent acting on the account
/// holder's behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#5012.
/// </summary>

table 68016 "CER Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[50]) { }
        field(3; Parent; Code[20]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

page 68017 "CER Card"
{
    PageType = Card;
    SourceTable = "CER Row";
    ApplicationArea = All;
    Caption = 'CER Card';

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
            field(NoteCtl; Note)
            {
                ApplicationArea = All;
                Caption = 'Note';
            }
        }
    }

    var
        Note: Text[50];
}

page 68018 "CER Part"
{
    PageType = ListPart;
    SourceTable = "CER Row";
    ApplicationArea = All;
    Caption = 'CER Part';

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(NoteCtl; Note)
                {
                    ApplicationArea = All;
                    Caption = 'Note';
                }
            }
        }
    }

    var
        Note: Text[50];
}

page 68019 "CER Host"
{
    PageType = Card;
    SourceTable = "CER Row";
    ApplicationArea = All;
    Caption = 'CER Host';

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "CER Part")
            {
                ApplicationArea = All;
                SubPageLink = Parent = field("No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenCardView)
            {
                ApplicationArea = All;
                Caption = 'Open Card View';
                RunObject = page "CER Card";
                RunPageMode = View;
            }
        }
    }
}

page 68020 "CER List"
{
    PageType = List;
    SourceTable = "CER Row";
    ApplicationArea = All;
    Caption = 'CER List';

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(NoteCtl; Note)
                {
                    ApplicationArea = All;
                    Caption = 'Note';
                }
            }
        }
    }

    var
        Note: Text[50];
}

page 68021 "CER ReEdit Card"
{
    PageType = Card;
    SourceTable = "CER Row";
    ApplicationArea = All;
    Caption = 'CER ReEdit Card';

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
            field(NoteCtl; Note)
            {
                ApplicationArea = All;
                Caption = 'Note';
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrPage.Editable(true);
    end;

    var
        Note: Text[50];
}

page 68022 "CER Lock Card"
{
    PageType = Card;
    SourceTable = "CER Row";
    ApplicationArea = All;
    Caption = 'CER Lock Card';

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
            field(NoteCtl; Note)
            {
                ApplicationArea = All;
                Caption = 'Note';
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrPage.Editable(false);
    end;

    var
        Note: Text[50];
}

codeunit 68023 "CER Probe"
{
    SingleInstance = true;

    var
        Seen: Text;

    procedure Reset()
    begin
        Seen := '';
    end;

    procedure Save(NewSeen: Text)
    begin
        Seen := NewSeen;
    end;

    procedure Recorded(): Text
    begin
        exit(Seen);
    end;
}

codeunit 68024 "CER Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Seed()
    var
        Row: Record "CER Row";
        Probe: Codeunit "CER Probe";
    begin
        Probe.Reset();
        Row.DeleteAll();
        AddRow('H', 'Header', '');
        AddRow('L1', 'Line one', 'H');
        AddRow('L2', 'Line two', 'H');
    end;

    local procedure AddRow(No: Code[20]; NewName: Text[50]; NewParent: Code[20])
    var
        Row: Record "CER Row";
    begin
        Row.Init();
        Row."No." := No;
        Row.Name := NewName;
        Row.Parent := NewParent;
        Row.Insert();
    end;

    local procedure Editability(PageEditable: Boolean; RecControlEditable: Boolean; VarControlEditable: Boolean): Text
    begin
        exit('pageEd=' + Format(PageEditable) + ';ctlEd=' + Format(RecControlEditable) + ';varEd=' + Format(VarControlEditable));
    end;

    local procedure PartEditability(var Host: TestPage "CER Host"): Text
    begin
        Host.Lines.First();
        exit('hostEd=' + Format(Host.Editable()) + ';partEd=' + Format(Host.Lines.Editable()) +
             ';ctlEd=' + Format(Host.Lines.Name.Editable()) + ';varEd=' + Format(Host.Lines.NoteCtl.Editable()));
    end;

    // ---- A subpage part ---------------------------------------------------------------------

    [Test]
    procedure Part_HostOpenEdit()
    // The control: an editable host and an editable part.
    var
        Host: TestPage "CER Host";
    begin
        Seed();
        Host.OpenEdit();
        Host.GoToKey('H');
        Assert.AreEqual('hostEd=Yes;partEd=Yes;ctlEd=Yes;varEd=Yes', PartEditability(Host),
            'A part''s controls on a host opened with OpenEdit.');
        Host.Close();
    end;

    [Test]
    procedure Part_HostOpenView()
    var
        Host: TestPage "CER Host";
    begin
        Seed();
        Host.OpenView();
        Host.GoToKey('H');
        Assert.AreEqual('hostEd=No;partEd=No;ctlEd=No;varEd=Yes', PartEditability(Host),
            'A part''s controls on a host opened with OpenView.');
        Host.Close();
    end;

    [Test]
    procedure Part_HostOpenEdit_ThenViewAction()
    var
        Host: TestPage "CER Host";
    begin
        Seed();
        Host.OpenEdit();
        Host.GoToKey('H');
        Host.View().Invoke();
        Assert.AreEqual('hostEd=No;partEd=No;ctlEd=No;varEd=Yes', PartEditability(Host),
            'A part''s controls after the host''s built-in View action.');
        Host.Close();
    end;

    // ---- Lookup mode ------------------------------------------------------------------------

    [Test]
    [HandlerFunctions('ListModalHandler')]
    procedure List_RunModal_NotLookupMode()
    // The control for the two lookup arms below.
    var
        ListPage: Page "CER List";
        Probe: Codeunit "CER Probe";
    begin
        Seed();
        ListPage.RunModal();
        Assert.AreEqual('pageEd=Yes;ctlEd=Yes;varEd=Yes', Probe.Recorded(),
            'A list handed to a ModalPageHandler, not in lookup mode.');
    end;

    [Test]
    [HandlerFunctions('ListModalHandler')]
    procedure List_RunModal_LookupMode()
    var
        ListPage: Page "CER List";
        Probe: Codeunit "CER Probe";
    begin
        Seed();
        ListPage.LookupMode(true);
        ListPage.RunModal();
        Assert.AreEqual('pageEd=No;ctlEd=No;varEd=Yes', Probe.Recorded(),
            'A list handed to a ModalPageHandler in lookup mode.');
    end;

    [Test]
    [HandlerFunctions('CardModalHandler')]
    procedure Card_RunModal_LookupMode()
    var
        CardPage: Page "CER Card";
        Probe: Codeunit "CER Probe";
    begin
        Seed();
        CardPage.LookupMode(true);
        CardPage.RunModal();
        Assert.AreEqual('pageEd=No;ctlEd=No;varEd=Yes', Probe.Recorded(),
            'A card handed to a ModalPageHandler in lookup mode.');
    end;

    // ---- An action with RunPageMode = View ----------------------------------------------------

    [Test]
    [HandlerFunctions('CardPageHandler')]
    procedure RunPageModeView_PageVariableControl()
    var
        Host: TestPage "CER Host";
        Probe: Codeunit "CER Probe";
    begin
        Seed();
        Host.OpenEdit();
        Host.GoToKey('H');
        Host.OpenCardView.Invoke();
        Host.Close();
        Assert.AreEqual('pageEd=No;ctlEd=No;varEd=Yes', Probe.Recorded(),
            'A card opened by an action with RunPageMode = View, read in the PageHandler.');
    end;

    // ---- CurrPage.Editable in OnOpenPage ------------------------------------------------------

    [Test]
    procedure CurrPageEditableTrue_OpenView()
    var
        Card: TestPage "CER ReEdit Card";
    begin
        Seed();
        Card.OpenView();
        Assert.AreEqual('pageEd=Yes;ctlEd=Yes;varEd=Yes', Editability(Card.Editable(), Card.Name.Editable(), Card.NoteCtl.Editable()),
            'OnOpenPage calls CurrPage.Editable(true) on a card opened with OpenView.');
        Card.Close();
    end;

    [Test]
    procedure CurrPageEditableFalse_OpenEdit()
    var
        Card: TestPage "CER Lock Card";
    begin
        Seed();
        Card.OpenEdit();
        Assert.AreEqual('pageEd=No;ctlEd=No;varEd=Yes', Editability(Card.Editable(), Card.Name.Editable(), Card.NoteCtl.Editable()),
            'OnOpenPage calls CurrPage.Editable(false) on a card opened with OpenEdit.');
        Card.Close();
    end;

    // ---- Handlers ------------------------------------------------------------------------------

    [ModalPageHandler]
    procedure ListModalHandler(var ListPage: TestPage "CER List")
    var
        Probe: Codeunit "CER Probe";
    begin
        ListPage.First();
        Probe.Save(Editability(ListPage.Editable(), ListPage.Name.Editable(), ListPage.NoteCtl.Editable()));
    end;

    [ModalPageHandler]
    procedure CardModalHandler(var CardPage: TestPage "CER Card")
    var
        Probe: Codeunit "CER Probe";
    begin
        Probe.Save(Editability(CardPage.Editable(), CardPage.Name.Editable(), CardPage.NoteCtl.Editable()));
    end;

    [PageHandler]
    procedure CardPageHandler(var CardPage: TestPage "CER Card")
    var
        Probe: Codeunit "CER Probe";
    begin
        Probe.Save(Editability(CardPage.Editable(), CardPage.Name.Editable(), CardPage.NoteCtl.Editable()));
        CardPage.Close();
    end;
}
