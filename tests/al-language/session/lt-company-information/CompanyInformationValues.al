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
        // The distance to Today() depends on the date of the test image, so only the kind of value is observed.
        Observer.Observe('workdate_not_blank', Format(WorkDate() <> 0D));
        Observer.Observe('workdate_is_a_whole_date', Format(WorkDate() = DT2Date(CreateDateTime(WorkDate(), 0T))));
        Observer.Expect('workdate_not_blank', 'Yes');
        Observer.Expect('workdate_is_a_whole_date', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure WorkDate_SetAndRestore()
    var
        Observer: Codeunit "Probe Observer";
        Saved: Date;
    begin
        Saved := WorkDate();
        WorkDate(Saved + 3);
        Observer.Observe('after_set_days_from_saved', Format(WorkDate() - Saved));
        WorkDate(Saved);
        Observer.Observe('after_restore_equals_saved', Format(WorkDate() = Saved));
        Observer.Expect('after_set_days_from_saved', '3');
        Observer.Expect('after_restore_equals_saved', 'Yes');
        Observer.Verify();
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
        Observer.Expect('get', 'Yes');
        Observer.Expect('name', '<Company>');
        Observer.Expect('address', '5 The Ring');
        Observer.Expect('address_2', 'Westminster');
        Observer.Expect('city', 'London');
        Observer.Expect('post_code', 'W2 8HG');
        Observer.Expect('country_region_code', 'GB');
        Observer.Expect('county', '');
        Observer.Expect('phone_no', '0666-666-6666');
        Observer.Expect('name_equals_company_name', 'Yes');
        Observer.Verify();
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
        Observer.Expect('table_caption', 'Company Information');
        Observer.Expect('name', 'Name');
        Observer.Expect('address', 'Address');
        Observer.Expect('address_2', 'Address 2');
        Observer.Expect('city', 'City');
        Observer.Expect('post_code', 'Post Code');
        Observer.Expect('country_region_code', 'Country/Region Code');
        Observer.Expect('phone_no', 'Phone No.');
        Observer.Expect('vat_registration_no', 'VAT Registration No.');
        Observer.Expect('bank_name', 'Bank Name');
        Observer.Expect('iban', 'IBAN');
        Observer.Verify();
    end;
}
