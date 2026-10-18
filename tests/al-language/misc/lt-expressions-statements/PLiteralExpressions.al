// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-literals
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained codeunit 67291
// Every literal form: integer, big integer, decimal, text (with an escaped quote and empty), boolean, date, time, datetime, duration-free forms, and the undefined date, time and datetime. Dates and times are shown in the invariant format (Format(x, 0, 9)).
// BC versions: 27, 28, 29
codeunit 67291 "LT P Literal Expressions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PLiteral_Numbers()
    var
        Observer: Codeunit "Probe Observer";
        Big: BigInteger;
        Dec: Decimal;
    begin
        Observer.Observe('int_42', Format(42));
        Observer.Observe('int_0', Format(0));
        Observer.Observe('int_max', Format(2147483647));
        Observer.Observe('int_negative', Format(-7));
        Big := 9223372036854775807L;
        Observer.Observe('big_max', Format(Big));
        Big := -9223372036854775807L;
        Observer.Observe('big_negative', Format(Big));
        Observer.Observe('big_literal_over_int', Format(2147483648L));
        Dec := 3.14;
        Observer.Observe('dec_3_14', Format(Dec, 0, 9));
        Observer.Observe('dec_0_5', Format(0.5, 0, 9));
        Observer.Observe('dec_trailing_zero', Format(1.10, 0, 9));
        Observer.Observe('dec_whole', Format(100.0, 0, 9));
        Observer.Observe('dec_many_digits', Format(123456789.123456, 0, 9));
        Observer.Observe('dec_negative', Format(-0.25, 0, 9));
        Observer.Finish();
    end;

    [Test]
    procedure PLiteral_Text()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('text_abc', 'abc');
        Observer.Observe('text_empty_length', Format(StrLen('')));
        Observer.Observe('text_quote', 'it''s');
        Observer.Observe('text_quote_length', Format(StrLen('it''s')));
        Observer.Observe('text_only_quote', '''');
        Observer.Observe('text_double_quote', 'say "hi"');
        Observer.Observe('text_space', '[ ]');
        Observer.Observe('text_unicode', 'ä€');
        Observer.Observe('text_unicode_length', Format(StrLen('ä€')));
        Observer.Finish();
    end;

    [Test]
    procedure PLiteral_Boolean()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('true', Format(true));
        Observer.Observe('false', Format(false));
        Observer.Observe('true_xml', Format(true, 0, 9));
        Observer.Observe('false_xml', Format(false, 0, 9));
        Observer.Finish();
    end;

    [Test]
    procedure PLiteral_DateTimeForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('date_ymd', Format(20260115D, 0, 9));
        Observer.Observe('date_undefined', Format(0D, 0, 9));
        Observer.Observe('date_undefined_is_zero', Format(0D = 0D));
        Observer.Observe('date_leap_day', Format(20240229D, 0, 9));
        Observer.Observe('time_hms', Format(123456T, 0, 9));
        Observer.Observe('time_midnight', Format(000000T, 0, 9));
        Observer.Observe('time_undefined', Format(0T, 0, 9));
        Observer.Observe('time_millis', Format(235959.999T, 0, 9));
        Observer.Observe('datetime_ymdhms', Format(CreateDateTime(20260115D, 123456T), 0, 9));
        Observer.Observe('datetime_undefined', Format(0DT, 0, 9));
        Observer.Finish();
    end;

    [Test]
    procedure PLiteral_Char()
    var
        Observer: Codeunit "Probe Observer";
        C: Char;
    begin
        C := 65;
        Observer.Observe('char_from_integer', Format(C));
        Observer.Observe('char_equals_65', Format(C = 65));
        Observer.Observe('char_length_as_text', Format(StrLen(Format(C))));
        C := 'B';
        Observer.Observe('char_from_text_literal', Format(C));
        Observer.Finish();
    end;
}
