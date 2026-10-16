// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-layout-custom
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT RptMrg Helper (70835), LT RptMrg Capture (70831), report 70883 of ReportMergerFixtures.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// (byte order mark or not) and the text itself in pieces of 800 characters (line breaks written as <NL>). Rows: row 1 has Decimal 12.5 and 1234567.891, Date 31 Jan 2024,
// Boolean true, an enum value, DateTime and Time; row 2 has a text with XML special characters and an accent, a negative Decimal, empty Date/DateTime/Time, Boolean false.
// Facts: root element, data item and column element names, element or attribute form, how Decimal/Date/Boolean/Option/DateTime/Time are written, labels, captions.
// BC versions: 29 (the final facts get added later)

codeunit 70837 "LT RptMrg XmlData"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ObserveXml(var Observer: Codeunit "Probe Observer"; Fmt: ReportFormat; RequestXml: Text; Rows: Integer)
    var
        Helper: Codeunit "LT RptMrg Helper";
        Cap: Codeunit "LT RptMrg Capture";
    begin
        Helper.SeedRows(Rows);
        Helper.ProbeSave(Observer, Fmt, RequestXml, Cap);
        Observer.Observe('xml info', Cap.Item('xml info', 1));
        Helper.ObserveLong(Observer, 'xml', Cap.Item('xml', 1));
    end;

    [Test]
    procedure SaveAs_Pdf_TwoRows_XmlDataText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveXml(Observer, ReportFormat::Pdf, '', 2);
        Observer.Expect('try completed', 'Yes');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('output', 'RLB-RENDEREDLMC-OUT');
        Observer.Expect('calls', '1');
        Observer.Expect('xml info', 'bytes=32379 cr=114 lf=114 first=Ù,‹,');
        Observer.Expect('xml length', '32603');
        Observer.Expect('xml part 2', '     <TenantEntraId>x</TenantEntraId><NL>      <EnvironmentName>x</EnvironmentName><NL>      <EnvironmentType>x</EnvironmentType><NL>      <CompanyName>x</CompanyName><NL>      <CompanyDisplayName>x</CompanyDisplayName><NL>      <CompanyId>x</CompanyId><NL>      <UserName>x</UserName><NL>      <DateAndTime>x</DateAndTime><NL>      <Language>en-US</Language><NL>      <FormatRegion>en-US</FormatRegion><NL>      <DateTimeValues><NL>        <Year>x</Year><NL>        <MonthNumber>x</MonthNumber><NL>        <DayNumber>x</DayNumber><NL>        <Hour>x</Hour><NL>        <Minute>x</Minute><NL>      </DateTimeValues><NL>    </ReportRequest><NL>    <CompanyMeta');
        Observer.Expect('xml part 3', 'data><NL>      <CompanyName>x</CompanyName><NL>      <CompanyDisplayName>x</CompanyDisplayName><NL>      <CompanyAddressLines><NL>        <CompanyAddressLine1><Company></CompanyAddressLine1><NL>        <CompanyAddressLine2>5 The Ring</CompanyAddressLine2><NL>        <CompanyAddressLine3>Westminster</CompanyAddressLine3><NL>        <CompanyAddressLine4>London, W2 8HG</CompanyAddressLine4><NL>        <CompanyAddressLine5>Great Britain</CompanyAddressLine5><NL>        <CompanyAddressLine6></CompanyAddressLine6><NL>        <CompanyAddressLine7></CompanyAddressLine7><NL>        <CompanyAddressLine8></CompanyAddressLine8><NL>      </CompanyAddressLines><NL>      <CompanyPhone>0666-666-6666</CompanyPhone><NL>      <CompanyPhoneCaptio');
        Observer.Expect('xml part 4', 'n>Phone No.</CompanyPhoneCaption><NL>      <CompanyFaxNo>0666-666-6660</CompanyFaxNo><NL>      <CompanyFaxNoCaption>Fax No.</CompanyFaxNoCaption><NL>      <CompanyEmail></CompanyEmail><NL>      <CompanyEmailCaption>Email</CompanyEmailCaption><NL>      <CompanyHomePage></CompanyHomePage><NL>      <CompanyHomePageCaption>Home Page</CompanyHomePageCaption><NL>      <CompanyLogo>iVBORw0KGgoAAAANSUhEUgAAAlgAAAEsCAYAAAAfPc2WAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAE3DSURBVHhe7b1ntyRXeb6vj+CP4FcER362MRlENsHGBoEINuAE2JhgbNYyIBi9sI0IBkvgCCghCQFWDiNA2UggAZJRQkJZownv/BH6v672/z7zzKPqPt3Vfc6cM3Ndaz2rqqurdu2879p7164TThARERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERER');
        Observer.Expect('xml part 5', 'ERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERGRcTz88MOT66+/fnLFFVdMLrvsssnll18+3f/JT34yefLJJ8/q54uIiIjIDO64447J17/+9cmXv/zlyb/8y79M/uM//mPy7//+75N/+7d/mx77z//8z8lXv/rVqfg6cODAnf16ERERESlcddVVk6985StTIYWwwhBW//qv/zrdIq7YZv+cc86ZHDp0aNLdEREREZETTjiBYUB6qjYzxBYijN4thNbXvvY1e7JEREREOj/84Q+noqmLqW4IKrb0bCG0cvwb3/jGZO/evb/Y3RURERE5LmHCOuLqS1/60lMEVTd6rRgaZBtBxnwshhTvvPNOhwpFREREgLcCM5k986tmGaIKyxwshBUiK8e722N44IEHfv++++6bXHzxxdPhxwg7esluuOGGyWOPPbaW+4iIiMhxyr59+774s5/9bHLrrbdOrr766sn3vve96TIJBw4cWJvI+Na3vrUx9NcF1ZDR05VerFyXa/fv37+Sv26//fap0DvjjDM2esZyHyyT7S+44ILJvn37VrqXiIiIHGfQS8O6UwgZxEt6lyI+OH7eeedN7rrrrpVFRnqIqliaZ5xX/YUhhBBELPHQ3V+EPXv2/MJFF100dSu9aVkeos4Ni7hLLxprdX');
        Observer.Expect('xml part 6', 'W3RERERJ4CvVUMjVWhkblP7OcNPgQNguOSSy6Z3H777c/q7ixKeoYiaDazKvYiyrLPZPnu/iIgrvADRjgx9glneq24R5aJ4J55m/H+++8fdU8RERE5TmCOUQRPRBZiIsIiYiMCI0N1CBR6gbp7ixCB1IXUkFWxV0VWtgxfdvc340c/+tGG27lPD3f+z34VmGefffZKAlNERESOYRju64ImhrCIuKjHEB0RWvRkdTcXoQuZbvXevdcqPV/pcUIsdffn8fjjj58a0TbrnvVY/Y97IrAQWt/5zneWuq+IiIgcB/DmHJ+n6eKmWxUeEVhsmQNFj9e99967tND49re/vdEzNSRsqkVQ5Zys+B6BtOwk99tuu216XRd4Q37gGPdHUGU/PXgccx0uEREROQJ6r+iNicAZEhjdEBhsI3D4feGFFy4lcIAlEU4//fSNieNxH3czbFcFTYYpM1eK/xFa55577tL3ZukF3IpoqmKqhzdhzn8Rexj3f/DBB5e+v4iIiBzDfPOb33xKL86QRVCkFwmrxxAdBw4cuKG7Pw96zxBHcauKvCpo6jHOyxt9/EacjZngTq9b7tvDOmSZ4F+FFcfYH3N/EREROYbpQmLIqvDpvUtsETrYz3/+86WFBmttIZgisNjWifW4X4Ud/yGOEDjssy5Vd3MREraIth7mWZbzqwgcM8FeREREjlHocapCqVsVVvldh8fqeRwfKzRuvvnmqRuss0UvET1D/S0+LL1IEWJnnnnm5NChQ//b3VuECLS438Pe4yU9VjX8iRsWKe3ui4iIyHEKK5');
        Observer.Expect('xml part 7', 'LPEldDhqhIr01ECSIlYmMVofHd7353uoBp5nTVe7KNsIoAO+ecc1ZaVZ7rq1Aciod6jP0IP37Hjxxf9g1GEREROcapomlIZMQy36kKjyoycGcVgQX33HPPhDlhEWwRQHVYju1111238pt7e/fuPUIo9rD3+Mhv/BKxl3hb9g1GEREROcZhmC1iKSImQ2FVPEVoZHmELrA4vuwk91k88cQTk+9///uTK664YnLppZdOLrvsssk111wzufvuuyePPvroh/v5Y2BZifRGZTgylvDn/8RBjiWu+I9zu9siIiJynHPjjTdOxUKEQ8RDxFPtOUovFmIq/+X/s846a9cJjfPPP/8IYZWwYFlfq8ZJ3iKsvVpjv4EoIiIixzBPPvnkhqjI+lIIqAiL/MebflmWAHGB2OBcjvNW39gJ7kcTPmxd51QlbFVo1V66ulQDv1kotbspIiIiMoU5TYiGLDianqqIi4iOLKfAcURVhsxYrLO7uVtgDasMEWZuVSbuJ+xVYOV/hlYPHjz4aHdPREREZAofLP7Wt751hKBANKUXq4qs9PZUQcKcqe7mboK1uBKu9GhlyYg654pj7NNzdeDAgTu7OyIiIiJPgQnltRcrvTbZzzYihP/GfINwJ8IEfSbVI6IIG3PK0nOFsU+vlXOuREREZCnuvvvuExkyy0R2em3yrcAIrawFxZt963prcCdBbx7fFmTx0yuvvHJyww03TJefeOSRRxRWIiIiMp59+/Z9EaF1+eWXH9GDxQeSma/FAqX9Glkc4peesAzLppcMQXvJJZdM+Aj2qu');
        Observer.Expect('xml part 8', 't8iYiIyIrw0WQnXO8OfvzjH0+HGhFWdZ2tzAHLG4pnn3325Kc//alCVkREZLtgsU16QC688MIj3mxjn7lD9D499NBD7+7XydFjz549v8Dq8XUtrawnlrcY60sEmePGEGV3S0RERNYM603RIDMZmwY4DXUaa97+yzpW9Jb06+XowEr0pE8EVt5QrEtERGzV7y7yW5ElIiKyhWTV9bp0QhrlDDdlraqIsIsvvnhC70l3S7YPPvGT4b/0ONbhwPRA5sWCWJaIIF0ffvhhRZaIiMi6uf7666eNbl3ss8/dqQ02x9Ogs/xAd0+2B97MPOecczaEFelH2qSHKkIqYjnp2tOS4WCFsoiIyBq5//77N4aLsoRChpTSSFeBRSONpVeE85wwfXR46KGHNtIrQ7oRUln2YqhHKwI5Q4b8z6d9uvsiIiIykgsuuGBDWEU40fimEY7QSuOdHpL0jLBl8jtrPHW3ZWu56aabNgRVeh4jersYThpGdGUuVoT1LbfcosASERFZB/v37z9CMKXhrUIq83QiqNITkv9zLj1h3X3ZWliQNQKK4UG2SccqlJNO6XXkeF5YYJ80Z12y7r6IiIiM4Ac/+MHGsNE8i4iaZTTyvo22/fBR7Cqg0pOVIcP0VvEf++nlqmmXNFZgiYiIrAm+D9jF0hijZwS3uvuytfAWJ4IJgZR5culpxOjVQlilhyvn8V/v3VJgiYiIrAlEUZ0cvYopsLafq666amMuFYbYQkilBys9WhFT9HixH7FVBdd3vvMd009ERGQdsMRCHzIaY7ihwNp+7rzzzm');
        Observer.Ignore('xml part 1'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;





    [Test]
    procedure SaveAs_Pdf_NoRows_XmlDataText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveXml(Observer, ReportFormat::Pdf, '', 0);
        Observer.Expect('try completed', 'Yes');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('output', 'RLB-RENDEREDLMC-OUT');
        Observer.Expect('calls', '1');
        Observer.Expect('xml info', 'bytes=30830 cr=83 lf=83 first=Ù,‹,');
        Observer.Expect('xml length', '30993');
        Observer.Expect('xml part 2', '     <TenantEntraId>x</TenantEntraId><NL>      <EnvironmentName>x</EnvironmentName><NL>      <EnvironmentType>x</EnvironmentType><NL>      <CompanyName>x</CompanyName><NL>      <CompanyDisplayName>x</CompanyDisplayName><NL>      <CompanyId>x</CompanyId><NL>      <UserName>x</UserName><NL>      <DateAndTime>x</DateAndTime><NL>      <Language>en-US</Language><NL>      <FormatRegion>en-US</FormatRegion><NL>      <DateTimeValues><NL>        <Year>x</Year><NL>        <MonthNumber>x</MonthNumber><NL>        <DayNumber>x</DayNumber><NL>        <Hour>x</Hour><NL>        <Minute>x</Minute><NL>      </DateTimeValues><NL>    </ReportRequest><NL>    <CompanyMeta');
        Observer.Expect('xml part 3', 'data><NL>      <CompanyName>x</CompanyName><NL>      <CompanyDisplayName>x</CompanyDisplayName><NL>      <CompanyAddressLines><NL>        <CompanyAddressLine1><Company></CompanyAddressLine1><NL>        <CompanyAddressLine2>5 The Ring</CompanyAddressLine2><NL>        <CompanyAddressLine3>Westminster</CompanyAddressLine3><NL>        <CompanyAddressLine4>London, W2 8HG</CompanyAddressLine4><NL>        <CompanyAddressLine5>Great Britain</CompanyAddressLine5><NL>        <CompanyAddressLine6></CompanyAddressLine6><NL>        <CompanyAddressLine7></CompanyAddressLine7><NL>        <CompanyAddressLine8></CompanyAddressLine8><NL>      </CompanyAddressLines><NL>      <CompanyPhone>0666-666-6666</CompanyPhone><NL>      <CompanyPhoneCaptio');
        Observer.Expect('xml part 4', 'n>Phone No.</CompanyPhoneCaption><NL>      <CompanyFaxNo>0666-666-6660</CompanyFaxNo><NL>      <CompanyFaxNoCaption>Fax No.</CompanyFaxNoCaption><NL>      <CompanyEmail></CompanyEmail><NL>      <CompanyEmailCaption>Email</CompanyEmailCaption><NL>      <CompanyHomePage></CompanyHomePage><NL>      <CompanyHomePageCaption>Home Page</CompanyHomePageCaption><NL>      <CompanyLogo>iVBORw0KGgoAAAANSUhEUgAAAlgAAAEsCAYAAAAfPc2WAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAE3DSURBVHhe7b1ntyRXeb6vj+CP4FcER362MRlENsHGBoEINuAE2JhgbNYyIBi9sI0IBkvgCCghCQFWDiNA2UggAZJRQkJZownv/BH6v672/z7zzKPqPt3Vfc6cM3Ndaz2rqqurdu2879p7164TThARERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERER');
        Observer.Expect('xml part 5', 'ERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERGRcTz88MOT66+/fnLFFVdMLrvsssnll18+3f/JT34yefLJJ8/q54uIiIjIDO64447J17/+9cmXv/zlyb/8y79M/uM//mPy7//+75N/+7d/mx77z//8z8lXv/rVqfg6cODAnf16ERERESlcddVVk6985StTIYWwwhBW//qv/zrdIq7YZv+cc86ZHDp0aNLdEREREZETTjiBYUB6qjYzxBYijN4thNbXvvY1e7JEREREOj/84Q+noqmLqW4IKrb0bCG0cvwb3/jGZO/evb/Y3RURERE5LmHCOuLqS1/60lMEVTd6rRgaZBtBxnwshhTvvPNOhwpFREREgLcCM5k986tmGaIKyxwshBUiK8e722N44IEHfv++++6bXHzxxdPhxwg7esluuOGGyWOPPbaW+4iIiMhxyr59+774s5/9bHLrrbdOrr766sn3vve96TIJBw4cWJvI+Na3vrUx9NcF1ZDR05VerFyXa/fv37+Sv26//fap0DvjjDM2esZyHyyT7S+44ILJvn37VrqXiIiIHGfQS8O6UwgZxEt6lyI+OH7eeedN7rrrrpVFRnqIqliaZ5xX/YUhhBBELPHQ3V+EPXv2/MJFF100dSu9aVkeos4Ni7hLLxprdX');
        Observer.Expect('xml part 6', 'W3RERERJ4CvVUMjVWhkblP7OcNPgQNguOSSy6Z3H777c/q7ixKeoYiaDazKvYiyrLPZPnu/iIgrvADRjgx9glneq24R5aJ4J55m/H+++8fdU8RERE5TmCOUQRPRBZiIsIiYiMCI0N1CBR6gbp7ixCB1IXUkFWxV0VWtgxfdvc340c/+tGG27lPD3f+z34VmGefffZKAlNERESOYRju64ImhrCIuKjHEB0RWvRkdTcXoQuZbvXevdcqPV/pcUIsdffn8fjjj58a0TbrnvVY/Y97IrAQWt/5zneWuq+IiIgcB/DmHJ+n6eKmWxUeEVhsmQNFj9e99967tND49re/vdEzNSRsqkVQ5Zys+B6BtOwk99tuu216XRd4Q37gGPdHUGU/PXgccx0uEREROQJ6r+iNicAZEhjdEBhsI3D4feGFFy4lcIAlEU4//fSNieNxH3czbFcFTYYpM1eK/xFa55577tL3ZukF3IpoqmKqhzdhzn8Rexj3f/DBB5e+v4iIiBzDfPOb33xKL86QRVCkFwmrxxAdBw4cuKG7Pw96zxBHcauKvCpo6jHOyxt9/EacjZngTq9b7tvDOmSZ4F+FFcfYH3N/EREROYbpQmLIqvDpvUtsETrYz3/+86WFBmttIZgisNjWifW4X4Ud/yGOEDjssy5Vd3MREraIth7mWZbzqwgcM8FeREREjlHocapCqVsVVvldh8fqeRwfKzRuvvnmqRuss0UvET1D/S0+LL1IEWJnnnnm5NChQ//b3VuECLS438Pe4yU9VjX8iRsWKe3ui4iIyHEKK5');
        Observer.Expect('xml part 7', 'LPEldDhqhIr01ECSIlYmMVofHd7353uoBp5nTVe7KNsIoAO+ecc1ZaVZ7rq1Aciod6jP0IP37Hjxxf9g1GEREROcapomlIZMQy36kKjyoycGcVgQX33HPPhDlhEWwRQHVYju1111238pt7e/fuPUIo9rD3+Mhv/BKxl3hb9g1GEREROcZhmC1iKSImQ2FVPEVoZHmELrA4vuwk91k88cQTk+9///uTK664YnLppZdOLrvsssk111wzufvuuyePPvroh/v5Y2BZifRGZTgylvDn/8RBjiWu+I9zu9siIiJynHPjjTdOxUKEQ8RDxFPtOUovFmIq/+X/s846a9cJjfPPP/8IYZWwYFlfq8ZJ3iKsvVpjv4EoIiIixzBPPvnkhqjI+lIIqAiL/MebflmWAHGB2OBcjvNW39gJ7kcTPmxd51QlbFVo1V66ulQDv1kotbspIiIiMoU5TYiGLDianqqIi4iOLKfAcURVhsxYrLO7uVtgDasMEWZuVSbuJ+xVYOV/hlYPHjz4aHdPREREZAofLP7Wt751hKBANKUXq4qs9PZUQcKcqe7mboK1uBKu9GhlyYg654pj7NNzdeDAgTu7OyIiIiJPgQnltRcrvTbZzzYihP/GfINwJ8IEfSbVI6IIG3PK0nOFsU+vlXOuREREZCnuvvvuExkyy0R2em3yrcAIrawFxZt963prcCdBbx7fFmTx0yuvvHJyww03TJefeOSRRxRWIiIiMp59+/Z9EaF1+eWXH9GDxQeSma/FAqX9Glkc4peesAzLppcMQXvJJZdM+Aj2qu');
        Observer.Expect('xml part 8', 't8iYiIyIrw0WQnXO8OfvzjH0+HGhFWdZ2tzAHLG4pnn3325Kc//alCVkREZLtgsU16QC688MIj3mxjn7lD9D499NBD7+7XydFjz549v8Dq8XUtrawnlrcY60sEmePGEGV3S0RERNYM603RIDMZmwY4DXUaa97+yzpW9Jb06+XowEr0pE8EVt5QrEtERGzV7y7yW5ElIiKyhWTV9bp0QhrlDDdlraqIsIsvvnhC70l3S7YPPvGT4b/0ONbhwPRA5sWCWJaIIF0ffvhhRZaIiMi6uf7666eNbl3ss8/dqQ02x9Ogs/xAd0+2B97MPOecczaEFelH2qSHKkIqYjnp2tOS4WCFsoiIyBq5//77N4aLsoRChpTSSFeBRSONpVeE85wwfXR46KGHNtIrQ7oRUln2YqhHKwI5Q4b8z6d9uvsiIiIykgsuuGBDWEU40fimEY7QSuOdHpL0jLBl8jtrPHW3ZWu56aabNgRVeh4jersYThpGdGUuVoT1LbfcosASERFZB/v37z9CMKXhrUIq83QiqNITkv9zLj1h3X3ZWliQNQKK4UG2SccqlJNO6XXkeF5YYJ80Z12y7r6IiIiM4Ac/+MHGsNE8i4iaZTTyvo22/fBR7Cqg0pOVIcP0VvEf++nlqmmXNFZgiYiIrAm+D9jF0hijZwS3uvuytfAWJ4IJgZR5culpxOjVQlilhyvn8V/v3VJgiYiIrAlEUZ0cvYopsLafq666amMuFYbYQkilBys9WhFT9HixH7FVBdd3vvMd009ERGQdsMRCHzIaY7ihwNp+7rzzzm');
        Observer.Ignore('xml part 1'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;





    [Test]
    procedure SaveAs_Word_OneRow_XmlDataText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveXml(Observer, ReportFormat::Word, '', 1);
        Observer.Expect('try completed', 'Yes');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('output', 'RLB-RENDEREDLMC-OUT');
        Observer.Expect('calls', '1');
        Observer.Expect('xml info', 'bytes=31621 cr=99 lf=99 first=Ù,‹,');
        Observer.Expect('xml length', '31816');
        Observer.Expect('xml part 2', '     <TenantEntraId>x</TenantEntraId><NL>      <EnvironmentName>x</EnvironmentName><NL>      <EnvironmentType>x</EnvironmentType><NL>      <CompanyName>x</CompanyName><NL>      <CompanyDisplayName>x</CompanyDisplayName><NL>      <CompanyId>x</CompanyId><NL>      <UserName>x</UserName><NL>      <DateAndTime>x</DateAndTime><NL>      <Language>en-US</Language><NL>      <FormatRegion>en-US</FormatRegion><NL>      <DateTimeValues><NL>        <Year>x</Year><NL>        <MonthNumber>x</MonthNumber><NL>        <DayNumber>x</DayNumber><NL>        <Hour>x</Hour><NL>        <Minute>x</Minute><NL>      </DateTimeValues><NL>    </ReportRequest><NL>    <CompanyMeta');
        Observer.Expect('xml part 3', 'data><NL>      <CompanyName>x</CompanyName><NL>      <CompanyDisplayName>x</CompanyDisplayName><NL>      <CompanyAddressLines><NL>        <CompanyAddressLine1><Company></CompanyAddressLine1><NL>        <CompanyAddressLine2>5 The Ring</CompanyAddressLine2><NL>        <CompanyAddressLine3>Westminster</CompanyAddressLine3><NL>        <CompanyAddressLine4>London, W2 8HG</CompanyAddressLine4><NL>        <CompanyAddressLine5>Great Britain</CompanyAddressLine5><NL>        <CompanyAddressLine6></CompanyAddressLine6><NL>        <CompanyAddressLine7></CompanyAddressLine7><NL>        <CompanyAddressLine8></CompanyAddressLine8><NL>      </CompanyAddressLines><NL>      <CompanyPhone>0666-666-6666</CompanyPhone><NL>      <CompanyPhoneCaptio');
        Observer.Expect('xml part 4', 'n>Phone No.</CompanyPhoneCaption><NL>      <CompanyFaxNo>0666-666-6660</CompanyFaxNo><NL>      <CompanyFaxNoCaption>Fax No.</CompanyFaxNoCaption><NL>      <CompanyEmail></CompanyEmail><NL>      <CompanyEmailCaption>Email</CompanyEmailCaption><NL>      <CompanyHomePage></CompanyHomePage><NL>      <CompanyHomePageCaption>Home Page</CompanyHomePageCaption><NL>      <CompanyLogo>iVBORw0KGgoAAAANSUhEUgAAAlgAAAEsCAYAAAAfPc2WAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAE3DSURBVHhe7b1ntyRXeb6vj+CP4FcER362MRlENsHGBoEINuAE2JhgbNYyIBi9sI0IBkvgCCghCQFWDiNA2UggAZJRQkJZownv/BH6v672/z7zzKPqPt3Vfc6cM3Ndaz2rqqurdu2879p7164TThARERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERER');
        Observer.Expect('xml part 5', 'ERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERGRcTz88MOT66+/fnLFFVdMLrvsssnll18+3f/JT34yefLJJ8/q54uIiIjIDO64447J17/+9cmXv/zlyb/8y79M/uM//mPy7//+75N/+7d/mx77z//8z8lXv/rVqfg6cODAnf16ERERESlcddVVk6985StTIYWwwhBW//qv/zrdIq7YZv+cc86ZHDp0aNLdEREREZETTjiBYUB6qjYzxBYijN4thNbXvvY1e7JEREREOj/84Q+noqmLqW4IKrb0bCG0cvwb3/jGZO/evb/Y3RURERE5LmHCOuLqS1/60lMEVTd6rRgaZBtBxnwshhTvvPNOhwpFREREgLcCM5k986tmGaIKyxwshBUiK8e722N44IEHfv++++6bXHzxxdPhxwg7esluuOGGyWOPPbaW+4iIiMhxyr59+774s5/9bHLrrbdOrr766sn3vve96TIJBw4cWJvI+Na3vrUx9NcF1ZDR05VerFyXa/fv37+Sv26//fap0DvjjDM2esZyHyyT7S+44ILJvn37VrqXiIiIHGfQS8O6UwgZxEt6lyI+OH7eeedN7rrrrpVFRnqIqliaZ5xX/YUhhBBELPHQ3V+EPXv2/MJFF100dSu9aVkeos4Ni7hLLxprdX');
        Observer.Expect('xml part 6', 'W3RERERJ4CvVUMjVWhkblP7OcNPgQNguOSSy6Z3H777c/q7ixKeoYiaDazKvYiyrLPZPnu/iIgrvADRjgx9glneq24R5aJ4J55m/H+++8fdU8RERE5TmCOUQRPRBZiIsIiYiMCI0N1CBR6gbp7ixCB1IXUkFWxV0VWtgxfdvc340c/+tGG27lPD3f+z34VmGefffZKAlNERESOYRju64ImhrCIuKjHEB0RWvRkdTcXoQuZbvXevdcqPV/pcUIsdffn8fjjj58a0TbrnvVY/Y97IrAQWt/5zneWuq+IiIgcB/DmHJ+n6eKmWxUeEVhsmQNFj9e99967tND49re/vdEzNSRsqkVQ5Zys+B6BtOwk99tuu216XRd4Q37gGPdHUGU/PXgccx0uEREROQJ6r+iNicAZEhjdEBhsI3D4feGFFy4lcIAlEU4//fSNieNxH3czbFcFTYYpM1eK/xFa55577tL3ZukF3IpoqmKqhzdhzn8Rexj3f/DBB5e+v4iIiBzDfPOb33xKL86QRVCkFwmrxxAdBw4cuKG7Pw96zxBHcauKvCpo6jHOyxt9/EacjZngTq9b7tvDOmSZ4F+FFcfYH3N/EREROYbpQmLIqvDpvUtsETrYz3/+86WFBmttIZgisNjWifW4X4Ud/yGOEDjssy5Vd3MREraIth7mWZbzqwgcM8FeREREjlHocapCqVsVVvldh8fqeRwfKzRuvvnmqRuss0UvET1D/S0+LL1IEWJnnnnm5NChQ//b3VuECLS438Pe4yU9VjX8iRsWKe3ui4iIyHEKK5');
        Observer.Expect('xml part 7', 'LPEldDhqhIr01ECSIlYmMVofHd7353uoBp5nTVe7KNsIoAO+ecc1ZaVZ7rq1Aciod6jP0IP37Hjxxf9g1GEREROcapomlIZMQy36kKjyoycGcVgQX33HPPhDlhEWwRQHVYju1111238pt7e/fuPUIo9rD3+Mhv/BKxl3hb9g1GEREROcZhmC1iKSImQ2FVPEVoZHmELrA4vuwk91k88cQTk+9///uTK664YnLppZdOLrvsssk111wzufvuuyePPvroh/v5Y2BZifRGZTgylvDn/8RBjiWu+I9zu9siIiJynHPjjTdOxUKEQ8RDxFPtOUovFmIq/+X/s846a9cJjfPPP/8IYZWwYFlfq8ZJ3iKsvVpjv4EoIiIixzBPPvnkhqjI+lIIqAiL/MebflmWAHGB2OBcjvNW39gJ7kcTPmxd51QlbFVo1V66ulQDv1kotbspIiIiMoU5TYiGLDianqqIi4iOLKfAcURVhsxYrLO7uVtgDasMEWZuVSbuJ+xVYOV/hlYPHjz4aHdPREREZAofLP7Wt751hKBANKUXq4qs9PZUQcKcqe7mboK1uBKu9GhlyYg654pj7NNzdeDAgTu7OyIiIiJPgQnltRcrvTbZzzYihP/GfINwJ8IEfSbVI6IIG3PK0nOFsU+vlXOuREREZCnuvvvuExkyy0R2em3yrcAIrawFxZt963prcCdBbx7fFmTx0yuvvHJyww03TJefeOSRRxRWIiIiMp59+/Z9EaF1+eWXH9GDxQeSma/FAqX9Glkc4peesAzLppcMQXvJJZdM+Aj2qu');
        Observer.Expect('xml part 8', 't8iYiIyIrw0WQnXO8OfvzjH0+HGhFWdZ2tzAHLG4pnn3325Kc//alCVkREZLtgsU16QC688MIj3mxjn7lD9D499NBD7+7XydFjz549v8Dq8XUtrawnlrcY60sEmePGEGV3S0RERNYM603RIDMZmwY4DXUaa97+yzpW9Jb06+XowEr0pE8EVt5QrEtERGzV7y7yW5ElIiKyhWTV9bp0QhrlDDdlraqIsIsvvnhC70l3S7YPPvGT4b/0ONbhwPRA5sWCWJaIIF0ffvhhRZaIiMi6uf7666eNbl3ss8/dqQ02x9Ogs/xAd0+2B97MPOecczaEFelH2qSHKkIqYjnp2tOS4WCFsoiIyBq5//77N4aLsoRChpTSSFeBRSONpVeE85wwfXR46KGHNtIrQ7oRUln2YqhHKwI5Q4b8z6d9uvsiIiIykgsuuGBDWEU40fimEY7QSuOdHpL0jLBl8jtrPHW3ZWu56aabNgRVeh4jersYThpGdGUuVoT1LbfcosASERFZB/v37z9CMKXhrUIq83QiqNITkv9zLj1h3X3ZWliQNQKK4UG2SccqlJNO6XXkeF5YYJ80Z12y7r6IiIiM4Ac/+MHGsNE8i4iaZTTyvo22/fBR7Cqg0pOVIcP0VvEf++nlqmmXNFZgiYiIrAm+D9jF0hijZwS3uvuytfAWJ4IJgZR5culpxOjVQlilhyvn8V/v3VJgiYiIrAlEUZ0cvYopsLafq666amMuFYbYQkilBys9WhFT9HixH7FVBdd3vvMd009ERGQdsMRCHzIaY7ihwNp+7rzzzm');
        Observer.Ignore('xml part 1'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;





    [Test]
    procedure SaveAs_Excel_OneRow_XmlDataText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveXml(Observer, ReportFormat::Excel, '', 1);
        Observer.Expect('try completed', 'Yes');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('output', 'RLB-RENDEREDLMC-OUT');
        Observer.Expect('calls', '1');
        Observer.Expect('xml info', 'bytes=31621 cr=99 lf=99 first=Ù,‹,');
        Observer.Expect('xml length', '31816');
        Observer.Expect('xml part 2', '     <TenantEntraId>x</TenantEntraId><NL>      <EnvironmentName>x</EnvironmentName><NL>      <EnvironmentType>x</EnvironmentType><NL>      <CompanyName>x</CompanyName><NL>      <CompanyDisplayName>x</CompanyDisplayName><NL>      <CompanyId>x</CompanyId><NL>      <UserName>x</UserName><NL>      <DateAndTime>x</DateAndTime><NL>      <Language>en-US</Language><NL>      <FormatRegion>en-US</FormatRegion><NL>      <DateTimeValues><NL>        <Year>x</Year><NL>        <MonthNumber>x</MonthNumber><NL>        <DayNumber>x</DayNumber><NL>        <Hour>x</Hour><NL>        <Minute>x</Minute><NL>      </DateTimeValues><NL>    </ReportRequest><NL>    <CompanyMeta');
        Observer.Expect('xml part 3', 'data><NL>      <CompanyName>x</CompanyName><NL>      <CompanyDisplayName>x</CompanyDisplayName><NL>      <CompanyAddressLines><NL>        <CompanyAddressLine1><Company></CompanyAddressLine1><NL>        <CompanyAddressLine2>5 The Ring</CompanyAddressLine2><NL>        <CompanyAddressLine3>Westminster</CompanyAddressLine3><NL>        <CompanyAddressLine4>London, W2 8HG</CompanyAddressLine4><NL>        <CompanyAddressLine5>Great Britain</CompanyAddressLine5><NL>        <CompanyAddressLine6></CompanyAddressLine6><NL>        <CompanyAddressLine7></CompanyAddressLine7><NL>        <CompanyAddressLine8></CompanyAddressLine8><NL>      </CompanyAddressLines><NL>      <CompanyPhone>0666-666-6666</CompanyPhone><NL>      <CompanyPhoneCaptio');
        Observer.Expect('xml part 4', 'n>Phone No.</CompanyPhoneCaption><NL>      <CompanyFaxNo>0666-666-6660</CompanyFaxNo><NL>      <CompanyFaxNoCaption>Fax No.</CompanyFaxNoCaption><NL>      <CompanyEmail></CompanyEmail><NL>      <CompanyEmailCaption>Email</CompanyEmailCaption><NL>      <CompanyHomePage></CompanyHomePage><NL>      <CompanyHomePageCaption>Home Page</CompanyHomePageCaption><NL>      <CompanyLogo>iVBORw0KGgoAAAANSUhEUgAAAlgAAAEsCAYAAAAfPc2WAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAE3DSURBVHhe7b1ntyRXeb6vj+CP4FcER362MRlENsHGBoEINuAE2JhgbNYyIBi9sI0IBkvgCCghCQFWDiNA2UggAZJRQkJZownv/BH6v672/z7zzKPqPt3Vfc6cM3Ndaz2rqqurdu2879p7164TThARERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERER');
        Observer.Expect('xml part 5', 'ERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERGRcTz88MOT66+/fnLFFVdMLrvsssnll18+3f/JT34yefLJJ8/q54uIiIjIDO64447J17/+9cmXv/zlyb/8y79M/uM//mPy7//+75N/+7d/mx77z//8z8lXv/rVqfg6cODAnf16ERERESlcddVVk6985StTIYWwwhBW//qv/zrdIq7YZv+cc86ZHDp0aNLdEREREZETTjiBYUB6qjYzxBYijN4thNbXvvY1e7JEREREOj/84Q+noqmLqW4IKrb0bCG0cvwb3/jGZO/evb/Y3RURERE5LmHCOuLqS1/60lMEVTd6rRgaZBtBxnwshhTvvPNOhwpFREREgLcCM5k986tmGaIKyxwshBUiK8e722N44IEHfv++++6bXHzxxdPhxwg7esluuOGGyWOPPbaW+4iIiMhxyr59+774s5/9bHLrrbdOrr766sn3vve96TIJBw4cWJvI+Na3vrUx9NcF1ZDR05VerFyXa/fv37+Sv26//fap0DvjjDM2esZyHyyT7S+44ILJvn37VrqXiIiIHGfQS8O6UwgZxEt6lyI+OH7eeedN7rrrrpVFRnqIqliaZ5xX/YUhhBBELPHQ3V+EPXv2/MJFF100dSu9aVkeos4Ni7hLLxprdX');
        Observer.Expect('xml part 6', 'W3RERERJ4CvVUMjVWhkblP7OcNPgQNguOSSy6Z3H777c/q7ixKeoYiaDazKvYiyrLPZPnu/iIgrvADRjgx9glneq24R5aJ4J55m/H+++8fdU8RERE5TmCOUQRPRBZiIsIiYiMCI0N1CBR6gbp7ixCB1IXUkFWxV0VWtgxfdvc340c/+tGG27lPD3f+z34VmGefffZKAlNERESOYRju64ImhrCIuKjHEB0RWvRkdTcXoQuZbvXevdcqPV/pcUIsdffn8fjjj58a0TbrnvVY/Y97IrAQWt/5zneWuq+IiIgcB/DmHJ+n6eKmWxUeEVhsmQNFj9e99967tND49re/vdEzNSRsqkVQ5Zys+B6BtOwk99tuu216XRd4Q37gGPdHUGU/PXgccx0uEREROQJ6r+iNicAZEhjdEBhsI3D4feGFFy4lcIAlEU4//fSNieNxH3czbFcFTYYpM1eK/xFa55577tL3ZukF3IpoqmKqhzdhzn8Rexj3f/DBB5e+v4iIiBzDfPOb33xKL86QRVCkFwmrxxAdBw4cuKG7Pw96zxBHcauKvCpo6jHOyxt9/EacjZngTq9b7tvDOmSZ4F+FFcfYH3N/EREROYbpQmLIqvDpvUtsETrYz3/+86WFBmttIZgisNjWifW4X4Ud/yGOEDjssy5Vd3MREraIth7mWZbzqwgcM8FeREREjlHocapCqVsVVvldh8fqeRwfKzRuvvnmqRuss0UvET1D/S0+LL1IEWJnnnnm5NChQ//b3VuECLS438Pe4yU9VjX8iRsWKe3ui4iIyHEKK5');
        Observer.Expect('xml part 7', 'LPEldDhqhIr01ECSIlYmMVofHd7353uoBp5nTVe7KNsIoAO+ecc1ZaVZ7rq1Aciod6jP0IP37Hjxxf9g1GEREROcapomlIZMQy36kKjyoycGcVgQX33HPPhDlhEWwRQHVYju1111238pt7e/fuPUIo9rD3+Mhv/BKxl3hb9g1GEREROcZhmC1iKSImQ2FVPEVoZHmELrA4vuwk91k88cQTk+9///uTK664YnLppZdOLrvsssk111wzufvuuyePPvroh/v5Y2BZifRGZTgylvDn/8RBjiWu+I9zu9siIiJynHPjjTdOxUKEQ8RDxFPtOUovFmIq/+X/s846a9cJjfPPP/8IYZWwYFlfq8ZJ3iKsvVpjv4EoIiIixzBPPvnkhqjI+lIIqAiL/MebflmWAHGB2OBcjvNW39gJ7kcTPmxd51QlbFVo1V66ulQDv1kotbspIiIiMoU5TYiGLDianqqIi4iOLKfAcURVhsxYrLO7uVtgDasMEWZuVSbuJ+xVYOV/hlYPHjz4aHdPREREZAofLP7Wt751hKBANKUXq4qs9PZUQcKcqe7mboK1uBKu9GhlyYg654pj7NNzdeDAgTu7OyIiIiJPgQnltRcrvTbZzzYihP/GfINwJ8IEfSbVI6IIG3PK0nOFsU+vlXOuREREZCnuvvvuExkyy0R2em3yrcAIrawFxZt963prcCdBbx7fFmTx0yuvvHJyww03TJefeOSRRxRWIiIiMp59+/Z9EaF1+eWXH9GDxQeSma/FAqX9Glkc4peesAzLppcMQXvJJZdM+Aj2qu');
        Observer.Expect('xml part 8', 't8iYiIyIrw0WQnXO8OfvzjH0+HGhFWdZ2tzAHLG4pnn3325Kc//alCVkREZLtgsU16QC688MIj3mxjn7lD9D499NBD7+7XydFjz549v8Dq8XUtrawnlrcY60sEmePGEGV3S0RERNYM603RIDMZmwY4DXUaa97+yzpW9Jb06+XowEr0pE8EVt5QrEtERGzV7y7yW5ElIiKyhWTV9bp0QhrlDDdlraqIsIsvvnhC70l3S7YPPvGT4b/0ONbhwPRA5sWCWJaIIF0ffvhhRZaIiMi6uf7666eNbl3ss8/dqQ02x9Ogs/xAd0+2B97MPOecczaEFelH2qSHKkIqYjnp2tOS4WCFsoiIyBq5//77N4aLsoRChpTSSFeBRSONpVeE85wwfXR46KGHNtIrQ7oRUln2YqhHKwI5Q4b8z6d9uvsiIiIykgsuuGBDWEU40fimEY7QSuOdHpL0jLBl8jtrPHW3ZWu56aabNgRVeh4jersYThpGdGUuVoT1LbfcosASERFZB/v37z9CMKXhrUIq83QiqNITkv9zLj1h3X3ZWliQNQKK4UG2SccqlJNO6XXkeF5YYJ80Z12y7r6IiIiM4Ac/+MHGsNE8i4iaZTTyvo22/fBR7Cqg0pOVIcP0VvEf++nlqmmXNFZgiYiIrAm+D9jF0hijZwS3uvuytfAWJ4IJgZR5culpxOjVQlilhyvn8V/v3VJgiYiIrAlEUZ0cvYopsLafq666amMuFYbYQkilBys9WhFT9HixH7FVBdd3vvMd009ERGQdsMRCHzIaY7ihwNp+7rzzzm');
        Observer.Ignore('xml part 1'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;





    [Test]
    procedure SaveAs_Html_OneRow_XmlDataText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveXml(Observer, ReportFormat::Html, '', 1);
        Observer.Expect('try completed', 'Yes');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('output', 'RLB-RENDEREDLMC-OUT');
        Observer.Expect('calls', '1');
        Observer.Expect('xml info', 'bytes=31621 cr=99 lf=99 first=Ù,‹,');
        Observer.Expect('xml length', '31816');
        Observer.Expect('xml part 2', '     <TenantEntraId>x</TenantEntraId><NL>      <EnvironmentName>x</EnvironmentName><NL>      <EnvironmentType>x</EnvironmentType><NL>      <CompanyName>x</CompanyName><NL>      <CompanyDisplayName>x</CompanyDisplayName><NL>      <CompanyId>x</CompanyId><NL>      <UserName>x</UserName><NL>      <DateAndTime>x</DateAndTime><NL>      <Language>en-US</Language><NL>      <FormatRegion>en-US</FormatRegion><NL>      <DateTimeValues><NL>        <Year>x</Year><NL>        <MonthNumber>x</MonthNumber><NL>        <DayNumber>x</DayNumber><NL>        <Hour>x</Hour><NL>        <Minute>x</Minute><NL>      </DateTimeValues><NL>    </ReportRequest><NL>    <CompanyMeta');
        Observer.Expect('xml part 3', 'data><NL>      <CompanyName>x</CompanyName><NL>      <CompanyDisplayName>x</CompanyDisplayName><NL>      <CompanyAddressLines><NL>        <CompanyAddressLine1><Company></CompanyAddressLine1><NL>        <CompanyAddressLine2>5 The Ring</CompanyAddressLine2><NL>        <CompanyAddressLine3>Westminster</CompanyAddressLine3><NL>        <CompanyAddressLine4>London, W2 8HG</CompanyAddressLine4><NL>        <CompanyAddressLine5>Great Britain</CompanyAddressLine5><NL>        <CompanyAddressLine6></CompanyAddressLine6><NL>        <CompanyAddressLine7></CompanyAddressLine7><NL>        <CompanyAddressLine8></CompanyAddressLine8><NL>      </CompanyAddressLines><NL>      <CompanyPhone>0666-666-6666</CompanyPhone><NL>      <CompanyPhoneCaptio');
        Observer.Expect('xml part 4', 'n>Phone No.</CompanyPhoneCaption><NL>      <CompanyFaxNo>0666-666-6660</CompanyFaxNo><NL>      <CompanyFaxNoCaption>Fax No.</CompanyFaxNoCaption><NL>      <CompanyEmail></CompanyEmail><NL>      <CompanyEmailCaption>Email</CompanyEmailCaption><NL>      <CompanyHomePage></CompanyHomePage><NL>      <CompanyHomePageCaption>Home Page</CompanyHomePageCaption><NL>      <CompanyLogo>iVBORw0KGgoAAAANSUhEUgAAAlgAAAEsCAYAAAAfPc2WAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAE3DSURBVHhe7b1ntyRXeb6vj+CP4FcER362MRlENsHGBoEINuAE2JhgbNYyIBi9sI0IBkvgCCghCQFWDiNA2UggAZJRQkJZownv/BH6v672/z7zzKPqPt3Vfc6cM3Ndaz2rqqurdu2879p7164TThARERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERER');
        Observer.Expect('xml part 5', 'ERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERGRcTz88MOT66+/fnLFFVdMLrvsssnll18+3f/JT34yefLJJ8/q54uIiIjIDO64447J17/+9cmXv/zlyb/8y79M/uM//mPy7//+75N/+7d/mx77z//8z8lXv/rVqfg6cODAnf16ERERESlcddVVk6985StTIYWwwhBW//qv/zrdIq7YZv+cc86ZHDp0aNLdEREREZETTjiBYUB6qjYzxBYijN4thNbXvvY1e7JEREREOj/84Q+noqmLqW4IKrb0bCG0cvwb3/jGZO/evb/Y3RURERE5LmHCOuLqS1/60lMEVTd6rRgaZBtBxnwshhTvvPNOhwpFREREgLcCM5k986tmGaIKyxwshBUiK8e722N44IEHfv++++6bXHzxxdPhxwg7esluuOGGyWOPPbaW+4iIiMhxyr59+774s5/9bHLrrbdOrr766sn3vve96TIJBw4cWJvI+Na3vrUx9NcF1ZDR05VerFyXa/fv37+Sv26//fap0DvjjDM2esZyHyyT7S+44ILJvn37VrqXiIiIHGfQS8O6UwgZxEt6lyI+OH7eeedN7rrrrpVFRnqIqliaZ5xX/YUhhBBELPHQ3V+EPXv2/MJFF100dSu9aVkeos4Ni7hLLxprdX');
        Observer.Expect('xml part 6', 'W3RERERJ4CvVUMjVWhkblP7OcNPgQNguOSSy6Z3H777c/q7ixKeoYiaDazKvYiyrLPZPnu/iIgrvADRjgx9glneq24R5aJ4J55m/H+++8fdU8RERE5TmCOUQRPRBZiIsIiYiMCI0N1CBR6gbp7ixCB1IXUkFWxV0VWtgxfdvc340c/+tGG27lPD3f+z34VmGefffZKAlNERESOYRju64ImhrCIuKjHEB0RWvRkdTcXoQuZbvXevdcqPV/pcUIsdffn8fjjj58a0TbrnvVY/Y97IrAQWt/5zneWuq+IiIgcB/DmHJ+n6eKmWxUeEVhsmQNFj9e99967tND49re/vdEzNSRsqkVQ5Zys+B6BtOwk99tuu216XRd4Q37gGPdHUGU/PXgccx0uEREROQJ6r+iNicAZEhjdEBhsI3D4feGFFy4lcIAlEU4//fSNieNxH3czbFcFTYYpM1eK/xFa55577tL3ZukF3IpoqmKqhzdhzn8Rexj3f/DBB5e+v4iIiBzDfPOb33xKL86QRVCkFwmrxxAdBw4cuKG7Pw96zxBHcauKvCpo6jHOyxt9/EacjZngTq9b7tvDOmSZ4F+FFcfYH3N/EREROYbpQmLIqvDpvUtsETrYz3/+86WFBmttIZgisNjWifW4X4Ud/yGOEDjssy5Vd3MREraIth7mWZbzqwgcM8FeREREjlHocapCqVsVVvldh8fqeRwfKzRuvvnmqRuss0UvET1D/S0+LL1IEWJnnnnm5NChQ//b3VuECLS438Pe4yU9VjX8iRsWKe3ui4iIyHEKK5');
        Observer.Expect('xml part 7', 'LPEldDhqhIr01ECSIlYmMVofHd7353uoBp5nTVe7KNsIoAO+ecc1ZaVZ7rq1Aciod6jP0IP37Hjxxf9g1GEREROcapomlIZMQy36kKjyoycGcVgQX33HPPhDlhEWwRQHVYju1111238pt7e/fuPUIo9rD3+Mhv/BKxl3hb9g1GEREROcZhmC1iKSImQ2FVPEVoZHmELrA4vuwk91k88cQTk+9///uTK664YnLppZdOLrvsssk111wzufvuuyePPvroh/v5Y2BZifRGZTgylvDn/8RBjiWu+I9zu9siIiJynHPjjTdOxUKEQ8RDxFPtOUovFmIq/+X/s846a9cJjfPPP/8IYZWwYFlfq8ZJ3iKsvVpjv4EoIiIixzBPPvnkhqjI+lIIqAiL/MebflmWAHGB2OBcjvNW39gJ7kcTPmxd51QlbFVo1V66ulQDv1kotbspIiIiMoU5TYiGLDianqqIi4iOLKfAcURVhsxYrLO7uVtgDasMEWZuVSbuJ+xVYOV/hlYPHjz4aHdPREREZAofLP7Wt751hKBANKUXq4qs9PZUQcKcqe7mboK1uBKu9GhlyYg654pj7NNzdeDAgTu7OyIiIiJPgQnltRcrvTbZzzYihP/GfINwJ8IEfSbVI6IIG3PK0nOFsU+vlXOuREREZCnuvvvuExkyy0R2em3yrcAIrawFxZt963prcCdBbx7fFmTx0yuvvHJyww03TJefeOSRRxRWIiIiMp59+/Z9EaF1+eWXH9GDxQeSma/FAqX9Glkc4peesAzLppcMQXvJJZdM+Aj2qu');
        Observer.Expect('xml part 8', 't8iYiIyIrw0WQnXO8OfvzjH0+HGhFWdZ2tzAHLG4pnn3325Kc//alCVkREZLtgsU16QC688MIj3mxjn7lD9D499NBD7+7XydFjz549v8Dq8XUtrawnlrcY60sEmePGEGV3S0RERNYM603RIDMZmwY4DXUaa97+yzpW9Jb06+XowEr0pE8EVt5QrEtERGzV7y7yW5ElIiKyhWTV9bp0QhrlDDdlraqIsIsvvnhC70l3S7YPPvGT4b/0ONbhwPRA5sWCWJaIIF0ffvhhRZaIiMi6uf7666eNbl3ss8/dqQ02x9Ogs/xAd0+2B97MPOecczaEFelH2qSHKkIqYjnp2tOS4WCFsoiIyBq5//77N4aLsoRChpTSSFeBRSONpVeE85wwfXR46KGHNtIrQ7oRUln2YqhHKwI5Q4b8z6d9uvsiIiIykgsuuGBDWEU40fimEY7QSuOdHpL0jLBl8jtrPHW3ZWu56aabNgRVeh4jersYThpGdGUuVoT1LbfcosASERFZB/v37z9CMKXhrUIq83QiqNITkv9zLj1h3X3ZWliQNQKK4UG2SccqlJNO6XXkeF5YYJ80Z12y7r6IiIiM4Ac/+MHGsNE8i4iaZTTyvo22/fBR7Cqg0pOVIcP0VvEf++nlqmmXNFZgiYiIrAm+D9jF0hijZwS3uvuytfAWJ4IJgZR5culpxOjVQlilhyvn8V/v3VJgiYiIrAlEUZ0cvYopsLafq666amMuFYbYQkilBys9WhFT9HixH7FVBdd3vvMd009ERGQdsMRCHzIaY7ihwNp+7rzzzm');
        Observer.Ignore('xml part 1'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;





    [Test]
    procedure SaveAs_Formats_XmlDataSameText()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RptMrg Helper";
        CapPdf: Codeunit "LT RptMrg Capture";
        CapWord: Codeunit "LT RptMrg Capture";
        CapExcel: Codeunit "LT RptMrg Capture";
        CapHtml: Codeunit "LT RptMrg Capture";
        Output: Text;
        Saved: Boolean;
    begin
        Helper.SeedRows(2);
        BindSubscription(CapPdf);
        if Helper.TrySaveAs(ReportFormat::Pdf, '', Output, Saved) then;
        UnbindSubscription(CapPdf);
        BindSubscription(CapWord);
        if Helper.TrySaveAs(ReportFormat::Word, '', Output, Saved) then;
        UnbindSubscription(CapWord);
        BindSubscription(CapExcel);
        if Helper.TrySaveAs(ReportFormat::Excel, '', Output, Saved) then;
        UnbindSubscription(CapExcel);
        BindSubscription(CapHtml);
        if Helper.TrySaveAs(ReportFormat::Html, '', Output, Saved) then;
        UnbindSubscription(CapHtml);
        Observer.Observe('pdf = word', Format(CapPdf.Item('xml', 1) = CapWord.Item('xml', 1)));
        Observer.Observe('pdf = excel', Format(CapPdf.Item('xml', 1) = CapExcel.Item('xml', 1)));
        Observer.Observe('pdf = html', Format(CapPdf.Item('xml', 1) = CapHtml.Item('xml', 1)));
        Observer.Observe('pdf info', CapPdf.Item('xml info', 1));
        Observer.Observe('word info', CapWord.Item('xml info', 1));
        Observer.Observe('excel info', CapExcel.Item('xml info', 1));
        Observer.Observe('html info', CapHtml.Item('xml info', 1));
        Observer.Expect('pdf = word', 'Yes');
        Observer.Expect('pdf = excel', 'Yes');
        Observer.Expect('pdf = html', 'Yes');
        Observer.Expect('pdf info', 'bytes=32379 cr=114 lf=114 first=Ù,‹,');
        Observer.Expect('word info', 'bytes=32379 cr=114 lf=114 first=Ù,‹,');
        Observer.Expect('excel info', 'bytes=32379 cr=114 lf=114 first=Ù,‹,');
        Observer.Expect('html info', 'bytes=32379 cr=114 lf=114 first=Ù,‹,');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_Pdf_RequestValue_XmlDataText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveXml(Observer, ReportFormat::Pdf, '<?xml version="1.0" standalone="yes"?><ReportParameters name="LT RptMrg Report" id="70883"><Options><Field name="ModeVal">7</Field></Options><DataItems><DataItem name="Rows">VERSION(1) SORTING(Id) WHERE(Id=1(1))</DataItem></DataItems></ReportParameters>', 2);
        Observer.Expect('try completed', 'Yes');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('output', 'RLB-RENDEREDLMC-OUT');
        Observer.Expect('calls', '1');
        Observer.Expect('xml info', 'bytes=31621 cr=99 lf=99 first=Ù,‹,');
        Observer.Expect('xml length', '31816');
        Observer.Expect('xml part 2', '     <TenantEntraId>x</TenantEntraId><NL>      <EnvironmentName>x</EnvironmentName><NL>      <EnvironmentType>x</EnvironmentType><NL>      <CompanyName>x</CompanyName><NL>      <CompanyDisplayName>x</CompanyDisplayName><NL>      <CompanyId>x</CompanyId><NL>      <UserName>x</UserName><NL>      <DateAndTime>x</DateAndTime><NL>      <Language>en-US</Language><NL>      <FormatRegion>en-US</FormatRegion><NL>      <DateTimeValues><NL>        <Year>x</Year><NL>        <MonthNumber>x</MonthNumber><NL>        <DayNumber>x</DayNumber><NL>        <Hour>x</Hour><NL>        <Minute>x</Minute><NL>      </DateTimeValues><NL>    </ReportRequest><NL>    <CompanyMeta');
        Observer.Expect('xml part 3', 'data><NL>      <CompanyName>x</CompanyName><NL>      <CompanyDisplayName>x</CompanyDisplayName><NL>      <CompanyAddressLines><NL>        <CompanyAddressLine1><Company></CompanyAddressLine1><NL>        <CompanyAddressLine2>5 The Ring</CompanyAddressLine2><NL>        <CompanyAddressLine3>Westminster</CompanyAddressLine3><NL>        <CompanyAddressLine4>London, W2 8HG</CompanyAddressLine4><NL>        <CompanyAddressLine5>Great Britain</CompanyAddressLine5><NL>        <CompanyAddressLine6></CompanyAddressLine6><NL>        <CompanyAddressLine7></CompanyAddressLine7><NL>        <CompanyAddressLine8></CompanyAddressLine8><NL>      </CompanyAddressLines><NL>      <CompanyPhone>0666-666-6666</CompanyPhone><NL>      <CompanyPhoneCaptio');
        Observer.Expect('xml part 4', 'n>Phone No.</CompanyPhoneCaption><NL>      <CompanyFaxNo>0666-666-6660</CompanyFaxNo><NL>      <CompanyFaxNoCaption>Fax No.</CompanyFaxNoCaption><NL>      <CompanyEmail></CompanyEmail><NL>      <CompanyEmailCaption>Email</CompanyEmailCaption><NL>      <CompanyHomePage></CompanyHomePage><NL>      <CompanyHomePageCaption>Home Page</CompanyHomePageCaption><NL>      <CompanyLogo>iVBORw0KGgoAAAANSUhEUgAAAlgAAAEsCAYAAAAfPc2WAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAE3DSURBVHhe7b1ntyRXeb6vj+CP4FcER362MRlENsHGBoEINuAE2JhgbNYyIBi9sI0IBkvgCCghCQFWDiNA2UggAZJRQkJZownv/BH6v672/z7zzKPqPt3Vfc6cM3Ndaz2rqqurdu2879p7164TThARERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERER');
        Observer.Expect('xml part 5', 'ERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERGRcTz88MOT66+/fnLFFVdMLrvsssnll18+3f/JT34yefLJJ8/q54uIiIjIDO64447J17/+9cmXv/zlyb/8y79M/uM//mPy7//+75N/+7d/mx77z//8z8lXv/rVqfg6cODAnf16ERERESlcddVVk6985StTIYWwwhBW//qv/zrdIq7YZv+cc86ZHDp0aNLdEREREZETTjiBYUB6qjYzxBYijN4thNbXvvY1e7JEREREOj/84Q+noqmLqW4IKrb0bCG0cvwb3/jGZO/evb/Y3RURERE5LmHCOuLqS1/60lMEVTd6rRgaZBtBxnwshhTvvPNOhwpFREREgLcCM5k986tmGaIKyxwshBUiK8e722N44IEHfv++++6bXHzxxdPhxwg7esluuOGGyWOPPbaW+4iIiMhxyr59+774s5/9bHLrrbdOrr766sn3vve96TIJBw4cWJvI+Na3vrUx9NcF1ZDR05VerFyXa/fv37+Sv26//fap0DvjjDM2esZyHyyT7S+44ILJvn37VrqXiIiIHGfQS8O6UwgZxEt6lyI+OH7eeedN7rrrrpVFRnqIqliaZ5xX/YUhhBBELPHQ3V+EPXv2/MJFF100dSu9aVkeos4Ni7hLLxprdX');
        Observer.Expect('xml part 6', 'W3RERERJ4CvVUMjVWhkblP7OcNPgQNguOSSy6Z3H777c/q7ixKeoYiaDazKvYiyrLPZPnu/iIgrvADRjgx9glneq24R5aJ4J55m/H+++8fdU8RERE5TmCOUQRPRBZiIsIiYiMCI0N1CBR6gbp7ixCB1IXUkFWxV0VWtgxfdvc340c/+tGG27lPD3f+z34VmGefffZKAlNERESOYRju64ImhrCIuKjHEB0RWvRkdTcXoQuZbvXevdcqPV/pcUIsdffn8fjjj58a0TbrnvVY/Y97IrAQWt/5zneWuq+IiIgcB/DmHJ+n6eKmWxUeEVhsmQNFj9e99967tND49re/vdEzNSRsqkVQ5Zys+B6BtOwk99tuu216XRd4Q37gGPdHUGU/PXgccx0uEREROQJ6r+iNicAZEhjdEBhsI3D4feGFFy4lcIAlEU4//fSNieNxH3czbFcFTYYpM1eK/xFa55577tL3ZukF3IpoqmKqhzdhzn8Rexj3f/DBB5e+v4iIiBzDfPOb33xKL86QRVCkFwmrxxAdBw4cuKG7Pw96zxBHcauKvCpo6jHOyxt9/EacjZngTq9b7tvDOmSZ4F+FFcfYH3N/EREROYbpQmLIqvDpvUtsETrYz3/+86WFBmttIZgisNjWifW4X4Ud/yGOEDjssy5Vd3MREraIth7mWZbzqwgcM8FeREREjlHocapCqVsVVvldh8fqeRwfKzRuvvnmqRuss0UvET1D/S0+LL1IEWJnnnnm5NChQ//b3VuECLS438Pe4yU9VjX8iRsWKe3ui4iIyHEKK5');
        Observer.Expect('xml part 7', 'LPEldDhqhIr01ECSIlYmMVofHd7353uoBp5nTVe7KNsIoAO+ecc1ZaVZ7rq1Aciod6jP0IP37Hjxxf9g1GEREROcapomlIZMQy36kKjyoycGcVgQX33HPPhDlhEWwRQHVYju1111238pt7e/fuPUIo9rD3+Mhv/BKxl3hb9g1GEREROcZhmC1iKSImQ2FVPEVoZHmELrA4vuwk91k88cQTk+9///uTK664YnLppZdOLrvsssk111wzufvuuyePPvroh/v5Y2BZifRGZTgylvDn/8RBjiWu+I9zu9siIiJynHPjjTdOxUKEQ8RDxFPtOUovFmIq/+X/s846a9cJjfPPP/8IYZWwYFlfq8ZJ3iKsvVpjv4EoIiIixzBPPvnkhqjI+lIIqAiL/MebflmWAHGB2OBcjvNW39gJ7kcTPmxd51QlbFVo1V66ulQDv1kotbspIiIiMoU5TYiGLDianqqIi4iOLKfAcURVhsxYrLO7uVtgDasMEWZuVSbuJ+xVYOV/hlYPHjz4aHdPREREZAofLP7Wt751hKBANKUXq4qs9PZUQcKcqe7mboK1uBKu9GhlyYg654pj7NNzdeDAgTu7OyIiIiJPgQnltRcrvTbZzzYihP/GfINwJ8IEfSbVI6IIG3PK0nOFsU+vlXOuREREZCnuvvvuExkyy0R2em3yrcAIrawFxZt963prcCdBbx7fFmTx0yuvvHJyww03TJefeOSRRxRWIiIiMp59+/Z9EaF1+eWXH9GDxQeSma/FAqX9Glkc4peesAzLppcMQXvJJZdM+Aj2qu');
        Observer.Expect('xml part 8', 't8iYiIyIrw0WQnXO8OfvzjH0+HGhFWdZ2tzAHLG4pnn3325Kc//alCVkREZLtgsU16QC688MIj3mxjn7lD9D499NBD7+7XydFjz549v8Dq8XUtrawnlrcY60sEmePGEGV3S0RERNYM603RIDMZmwY4DXUaa97+yzpW9Jb06+XowEr0pE8EVt5QrEtERGzV7y7yW5ElIiKyhWTV9bp0QhrlDDdlraqIsIsvvnhC70l3S7YPPvGT4b/0ONbhwPRA5sWCWJaIIF0ffvhhRZaIiMi6uf7666eNbl3ss8/dqQ02x9Ogs/xAd0+2B97MPOecczaEFelH2qSHKkIqYjnp2tOS4WCFsoiIyBq5//77N4aLsoRChpTSSFeBRSONpVeE85wwfXR46KGHNtIrQ7oRUln2YqhHKwI5Q4b8z6d9uvsiIiIykgsuuGBDWEU40fimEY7QSuOdHpL0jLBl8jtrPHW3ZWu56aabNgRVeh4jersYThpGdGUuVoT1LbfcosASERFZB/v37z9CMKXhrUIq83QiqNITkv9zLj1h3X3ZWliQNQKK4UG2SccqlJNO6XXkeF5YYJ80Z12y7r6IiIiM4Ac/+MHGsNE8i4iaZTTyvo22/fBR7Cqg0pOVIcP0VvEf++nlqmmXNFZgiYiIrAm+D9jF0hijZwS3uvuytfAWJ4IJgZR5culpxOjVQlilhyvn8V/v3VJgiYiIrAlEUZ0cvYopsLafq666amMuFYbYQkilBys9WhFT9HixH7FVBdd3vvMd009ERGQdsMRCHzIaY7ihwNp+7rzzzm');
        Observer.Ignore('xml part 1'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;




}
