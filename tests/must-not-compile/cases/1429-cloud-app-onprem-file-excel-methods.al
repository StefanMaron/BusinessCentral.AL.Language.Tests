// @expect AL0296 | The application object or method 'UploadFile' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'ServerCreateDirectory' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'OpenBook' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'CreateBook' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// A Cloud app calls the File Management / Excel Buffer methods UploadFile, ServerCreateDirectory, OpenBook and CreateBook (scope
// OnPrem). The table Object (scope OnPrem) is pinned by cases 0020 (BC 27) and 1240 (BC 28, 29); with it in this file the compiler
// reports only the table. The tables Field, Company and Media Resources compile in a Cloud app (Field and Company are read by the
// corpus app). Corpus issue 664 item 114 (microsoft/AL#1049, #1020, #1080, #184, #183, #200, #220). Writer BO. (4 diagnostics)
codeunit 51438 "MNC BO 1429"
{
    procedure R()
    var
        FM: Codeunit "File Management";
        EB: Record "Excel Buffer";
        N: Text;
    begin
        N := FM.UploadFile('a', 'b');
        FM.ServerCreateDirectory('c');
        EB.OpenBook('d', 'e');
        EB.CreateBook('f', 'g');
    end;
}
