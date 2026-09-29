// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpageview-property
// Scope: in-scope
// Fixtures used: Assert (60021) -- and Base Application page 790 "G/L Account Categories"
//                with its two factbox parts on page 791 "G/L Accounts ListPart"
//
/// <summary>
/// Pins that a part's SubPageView filters the part on a host page that ships PRECOMPILED in
/// Base Application, not only on a page this app compiles.
///
/// TestPartSubPageView.al pins the same rule on pages this app declares. The claim here is the
/// same; the route is not. A client that reads a precompiled page's layout from the app's
/// symbols has to carry the part's SubPageView over by itself, and dropping it shows the part
/// every row its view excludes. Written for AL Runner issue
/// StefanMaron/BusinessCentral.AL.Runner#4968, where exactly that happened.
///
/// Page 790 carries two parts over the same page 791 and the same G/L Account rows:
///
///   "G/L Accounts without Category"  SubPageView = where("Account Subcategory Entry No." = const(0))
///   "G/L Accounts in Category"       SubPageLink = "Account Subcategory Entry No." = field("Entry No.")
///
/// Each test seeds two accounts: one with no subcategory (-IN) and one under a category it
/// inserts (-OUT), under numbers of its own so the two tests do not collide within one
/// codeunit's isolation. The view arm asserts the -IN account is in its part and the -OUT one
/// is not, so an empty part cannot pass it. The link arm is the control: parked on the
/// inserted category, the other part shows the -OUT account and not the -IN one, so both rows
/// are reachable through page 791.
///
/// GoToKey rather than a First/Next walk: a company with demo data has other accounts in both
/// parts, and this test asserts only about the two rows it inserted.
///
/// Written by agent stma-auto-5, an automated implementation agent acting on the account
/// holder's behalf.
/// </summary>
codeunit 67990 "SPVP Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure PrecompiledHostPartSubPageViewShowsOnlyTheRowsItsViewSelects()
    var
        GLAccountCategory: Record "G/L Account Category";
        Host: TestPage "G/L Account Categories";
    begin
        InsertCategory(GLAccountCategory);
        InsertAccount('SPVP-IN', 0);
        InsertAccount('SPVP-OUT', GLAccountCategory."Entry No.");

        Host.OpenView();
        Assert.IsTrue(Host."G/L Accounts without Category".GoToKey('SPVP-IN'),
            'the view part must show an account with no subcategory');
        Assert.IsFalse(Host."G/L Accounts without Category".GoToKey('SPVP-OUT'),
            'the view part must not show an account its SubPageView excludes');
        Host.Close();
    end;

    [Test]
    procedure PrecompiledHostLinkedPartShowsTheRowTheViewExcluded()
    var
        GLAccountCategory: Record "G/L Account Category";
        Host: TestPage "G/L Account Categories";
    begin
        InsertCategory(GLAccountCategory);
        InsertAccount('SPVP-LINK-IN', 0);
        InsertAccount('SPVP-LINK-OUT', GLAccountCategory."Entry No.");

        Host.OpenView();
        Assert.IsTrue(Host.GoToRecord(GLAccountCategory), 'the host must find the inserted category');
        Assert.IsTrue(Host."G/L Accounts in Category".GoToKey('SPVP-LINK-OUT'),
            'the linked part must show the account under the host''s category');
        Assert.IsFalse(Host."G/L Accounts in Category".GoToKey('SPVP-LINK-IN'),
            'the linked part must not show an account under no category');
        Host.Close();
    end;

    local procedure InsertCategory(var GLAccountCategory: Record "G/L Account Category")
    begin
        GLAccountCategory.Init();
        GLAccountCategory."Entry No." := 0;
        GLAccountCategory.Description := 'SPVP Category';
        GLAccountCategory.Insert();
        Assert.AreNotEqual(0, GLAccountCategory."Entry No.", 'the inserted category must get an entry number');
    end;

    local procedure InsertAccount(No: Code[20]; SubcategoryEntryNo: Integer)
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Init();
        GLAccount."No." := No;
        GLAccount.Name := No;
        GLAccount."Account Type" := GLAccount."Account Type"::Posting;
        GLAccount."Account Subcategory Entry No." := SubcategoryEntryNo;
        GLAccount.Insert();
    end;
}
