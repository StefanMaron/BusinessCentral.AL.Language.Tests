// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/instream/instream-data-type
// Scope: in-scope
// Companion of StefanMaron/BusinessCentral.AL.Runner#2576, which reports that AL Runner
// implements the conversion from a .NET Stream to an AL OutStream (used e.g. by CU 1279
// "Cryptography Management Impl." GenerateHash(InStream, ...)), but has no counterpart for
// the InStream direction: assigning a .NET Stream (wrapped in a DotNet variable) to an AL
// InStream variable. These tests pin the real BC behavior of that conversion so the runner
// gap has a real-BC-adjudicated spec to close against.
codeunit 60118 "Test DotNet InStream"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure DotNetMemoryStream_AssignedToInStream_ReadsExactContent()
    // CLAIM: a .NET MemoryStream constructed from a byte array, assigned directly to an AL
    // InStream variable, reads back exactly the bytes the .NET stream was constructed with.
    var
        Encoding: DotNet Encoding;
        MemoryStream: DotNet MemoryStream;
        Bytes: DotNet Array;
        InStr: InStream;
        ReadText: Text;
    begin
        Bytes := Encoding.UTF8().GetBytes('hello from dotnet stream');
        MemoryStream := MemoryStream.MemoryStream(Bytes);

        InStr := MemoryStream;

        InStr.ReadText(ReadText);
        Assert.AreEqual('hello from dotnet stream', ReadText,
            'An InStream assigned from a .NET MemoryStream must read the stream''s exact content');
    end;

    [Test]
    procedure DotNetMemoryStream_RoundTripsAgainstOutStreamDirection()
    // CLAIM: content written into a .NET MemoryStream through the (already-working)
    // DotNet-to-OutStream conversion is readable back out of the SAME .NET stream through
    // the DotNet-to-InStream conversion under test — pinning the two directions against
    // each other rather than each in isolation.
    var
        MemoryStream: DotNet MemoryStream;
        OutStr: OutStream;
        InStr: InStream;
        ReadText: Text;
    begin
        MemoryStream := MemoryStream.MemoryStream();

        OutStr := MemoryStream;
        OutStr.WriteText('round trip payload');
        MemoryStream.Position := 0;

        InStr := MemoryStream;
        InStr.ReadText(ReadText);
        Assert.AreEqual('round trip payload', ReadText,
            'Content written through the OutStream direction must read back correctly through the InStream direction on the same .NET stream');
    end;

    [Test]
    procedure DotNetMemoryStream_ReadPastEnd_SetsEOS_ReturnsEmptyText()
    // CLAIM (negative direction): once a .NET-stream-backed InStream has been fully
    // consumed, EOS() reports true and a further ReadText() call returns empty text rather
    // than erroring or repeating the previous content.
    var
        Encoding: DotNet Encoding;
        MemoryStream: DotNet MemoryStream;
        Bytes: DotNet Array;
        InStr: InStream;
        ReadText: Text;
    begin
        Bytes := Encoding.UTF8().GetBytes('short');
        MemoryStream := MemoryStream.MemoryStream(Bytes);
        InStr := MemoryStream;

        InStr.ReadText(ReadText);
        Assert.AreEqual('short', ReadText, 'Sanity: the full content must be read before EOS is exercised');
        Assert.IsTrue(InStr.EOS(), 'EOS() must be true once the .NET stream''s content has been fully consumed');

        InStr.ReadText(ReadText);
        Assert.AreEqual('', ReadText,
            'ReadText() on a .NET-stream-backed InStream that is already at EOS must return empty text');
    end;
}
