// @expect AL0159 | 'Blob' is not a valid return type. Use basic types (Text, Integer, Decimal, etc.) or reference custom types (Record, Enum, etc.).
// @expect AL0159 | 'TestPage' is not a valid return type. Use basic types (Text, Integer, Decimal, etc.) or reference custom types (Record, Enum, etc.).
// Corpus #664 items 35 and 36. Of the complex types only Blob and TestPage are refused as a return type (AL0159). Record, Codeunit,
// Interface, TextBuilder, JsonObject, List, Dictionary, RecordRef, FieldRef, InStream, Page, Report, Query, XmlDocument, Variant
// and the Http types (HttpContent, HttpClient, HttpRequestMessage, HttpResponseMessage, HttpHeaders) compile.
interface "MNC BM I1389" { procedure Foo(); }
query 51389 "MNC BM Q1389" { elements { dataitem(D; Customer) { column(No; "No.") { } } } }
codeunit 51389 "MNC BM C1389"
{
    procedure A(): Record Customer
    begin
    end;
    procedure B(): Codeunit "MNC BM C1389"
    begin
    end;
    procedure C(): Interface "MNC BM I1389"
    begin
    end;
    procedure D(): TextBuilder
    begin
    end;
    procedure E(): JsonObject
    begin
    end;
    procedure F(): List of [Integer]
    begin
    end;
    procedure G(): Dictionary of [Integer, Text]
    begin
    end;
    procedure H(): RecordRef
    begin
    end;
    procedure I(): InStream
    begin
    end;
    procedure J(): Page "Customer Card"
    begin
    end;
    procedure K(): Report "Customer - List"
    begin
    end;
    procedure L(): XmlDocument
    begin
    end;
    procedure M(): FieldRef
    begin
    end;
    procedure N(): Query "MNC BM Q1389"
    begin
    end;
    procedure O(): Variant
    begin
    end;
    procedure P1(): HttpContent
    begin
    end;
    procedure P2(): HttpClient
    begin
    end;
    procedure P3(): HttpRequestMessage
    begin
    end;
    procedure P4(): HttpResponseMessage
    begin
    end;
    procedure P5(): HttpHeaders
    begin
    end;
    procedure Q(): Blob
    begin
    end;
    procedure R(): TestPage "Customer Card"
    begin
    end;
}
