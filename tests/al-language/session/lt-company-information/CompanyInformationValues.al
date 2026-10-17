// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-workdate-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: (1) WorkDate() against Today() at the start of a test, with the difference in days; (2) the Company Information row of the corpus database (Name, Address,
// Address 2, City, Post Code, Country/Region Code, Phone No.) and the captions of those fields. The report dataset header carries these values; the company
// name is replaced by <Company> in an observation. Object id 67858.

codeunit 67858 "LT Company Information Values"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure WorkDate_AgainstToday()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('workdate_equals_today', Format(WorkDate() = Today()));
        Observer.Observe('days_apart', Format(WorkDate() - Today()));
        Observer.Observe('workdate_filter_equals_today_filter', Format(Format(WorkDate(), 0, 9) = Format(Today(), 0, 9)));
        Observer.Finish();
    end;

    [Test]
    procedure WorkDate_SetAndRestore()
    var
        Observer: Codeunit "Probe Observer";
        Saved: Date;
    begin
        Saved := WorkDate();
        WorkDate(Saved + 3);
        Observer.Observe('after_set_days_from_today', Format(WorkDate() - Today()));
        WorkDate(Saved);
        Observer.Observe('after_restore_equals_saved', Format(WorkDate() = Saved));
        Observer.Finish();
    end;

    [Test]
    procedure CompanyInformation_Values()
    var
        Observer: Codeunit "Probe Observer";
        Info: Record "Company Information";
    begin
        Observer.Observe('get', Format(Info.Get()));
        Observer.Observe('name', Info.Name);
        Observer.Observe('address', Info.Address);
        Observer.Observe('address_2', Info."Address 2");
        Observer.Observe('city', Info.City);
        Observer.Observe('post_code', Info."Post Code");
        Observer.Observe('country_region_code', Info."Country/Region Code");
        Observer.Observe('county', Info.County);
        Observer.Observe('phone_no', Info."Phone No.");
        Observer.Observe('name_equals_company_name', Format(Info.Name = CompanyName()));
        Observer.Finish();
    end;

    [Test]
    procedure CompanyInformation_Captions()
    var
        Observer: Codeunit "Probe Observer";
        Info: Record "Company Information";
    begin
        Observer.Observe('table_caption', Info.TableCaption());
        Observer.Observe('name', Info.FieldCaption(Name));
        Observer.Observe('address', Info.FieldCaption(Address));
        Observer.Observe('address_2', Info.FieldCaption("Address 2"));
        Observer.Observe('city', Info.FieldCaption(City));
        Observer.Observe('post_code', Info.FieldCaption("Post Code"));
        Observer.Observe('country_region_code', Info.FieldCaption("Country/Region Code"));
        Observer.Observe('phone_no', Info.FieldCaption("Phone No."));
        Observer.Observe('vat_registration_no', Info.FieldCaption("VAT Registration No."));
        Observer.Observe('bank_name', Info.FieldCaption("Bank Name"));
        Observer.Observe('iban', Info.FieldCaption(IBAN));
        Observer.Finish();
    end;
}
