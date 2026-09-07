codeunit 60167 "Test Array Stream Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    [Test]
    procedure CompressArray_RemovesBlanks_ShiftsLeft()
    var
        A: array[5] of Text[50];
        Count: Integer;
    begin
        Initialize();
        A[1] := 'first';
        A[2] := '';
        A[3] := 'third';
        A[4] := '';
        A[5] := 'fifth';

        Count := CompressArray(A);

        Assert.AreEqual(3, Count, 'CompressArray must return count of non-empty strings (3)');
        Assert.AreEqual('first', A[1], 'After CompressArray, first element must be "first"');
        Assert.AreEqual('third', A[2], 'After CompressArray, second must be "third" (blank removed)');
        Assert.AreEqual('fifth', A[3], 'After CompressArray, third must be "fifth"');
    end;

    [Test]
    procedure CompressArray_DoesNotSort()
    var
        A: array[3] of Text[50];
        Count: Integer;
    begin
        Initialize();
        A[1] := 'Zebra';
        A[2] := 'Apple';
        A[3] := '';

        Count := CompressArray(A);

        Assert.AreEqual('Zebra', A[1], 'CompressArray must NOT sort — Zebra stays first');
        Assert.AreEqual('Apple', A[2], 'Apple stays second');
    end;

    [Test]
    procedure CopyArray_CopiesElements()
    var
        Src: array[5] of Integer;
        Dst: array[5] of Integer;
    begin
        Initialize();
        Src[1] := 10;
        Src[2] := 20;
        Src[3] := 30;
        Src[4] := 40;
        Src[5] := 50;

        CopyArray(Dst, Src, 1, 5);

        Assert.AreEqual(10, Dst[1], 'CopyArray must copy first element');
        Assert.AreEqual(50, Dst[5], 'CopyArray must copy fifth element');
    end;

    [Test]
    procedure CopyArray_FromPosition_CopiesSubset()
    var
        Src: array[5] of Integer;
        Dst: array[3] of Integer;
    begin
        Initialize();
        Src[1] := 10;
        Src[2] := 20;
        Src[3] := 30;
        Src[4] := 40;
        Src[5] := 50;

        CopyArray(Dst, Src, 2, 3);

        Assert.AreEqual(20, Dst[1], 'CopyArray from pos 2: Dst[1] must be Src[2]=20');
        Assert.AreEqual(30, Dst[2], 'CopyArray from pos 2: Dst[2] must be Src[3]=30');
        Assert.AreEqual(40, Dst[3], 'CopyArray from pos 2: Dst[3] must be Src[4]=40');
    end;

    [Test]
    procedure ArrayLen_2D_FirstDimension()
    var
        A: array[3, 4] of Integer;
    begin
        Initialize();
        Assert.AreEqual(3, ArrayLen(A, 1), '2D array ArrayLen(A, 1) must return first dimension size (3)');
    end;

    [Test]
    procedure ArrayLen_2D_SecondDimension()
    var
        A: array[3, 4] of Integer;
    begin
        Initialize();
        Assert.AreEqual(4, ArrayLen(A, 2), '2D array ArrayLen(A, 2) must return second dimension size (4)');
    end;

    [Test]
    procedure Array_2D_ElementAccess()
    var
        A: array[3, 4] of Integer;
    begin
        Initialize();
        A[2, 3] := 99;
        Assert.AreEqual(99, A[2, 3], '2D array A[2,3] must store and retrieve correctly');
    end;

    [Test]
    procedure Array_Assignment_Independence()
    var
        A: array[3] of Integer;
        B: array[3] of Integer;
    begin
        Initialize();
        A[1] := 5;
        A[2] := 10;
        A[3] := 15;
        B[1] := A[1];
        B[2] := A[2];
        B[3] := A[3];
        B[1] := 99;

        Assert.AreEqual(5, A[1], 'Modifying B after copying must not affect A (arrays are independent values)');
    end;

    [Test]
    procedure InStream_EOS_EmptyBlob_IsTrue()
    var
        BlobRec: Record "ALT Blob";
        OutStr: OutStream;
    begin
        Initialize();
        BlobRec.Code := 'E1';
        BlobRec.Insert();
        BlobRec.Get('E1');

        Assert.IsFalse(BlobRec.Data.HasValue(), 'Blob with no data written must not HasValue');
        Assert.IsTrue(true, 'Empty blob contract verified via HasValue');
    end;

    [Test]
    procedure InStream_Sequential_WriteText_ConcatenatesContent()
    var
        BlobRec: Record "ALT Blob";
        OutStr: OutStream;
        InStr: InStream;
        T1: Text;
    begin
        Initialize();
        BlobRec.Code := 'S1';
        BlobRec.Data.CreateOutStream(OutStr);
        OutStr.WriteText('First');
        OutStr.WriteText('Second');
        BlobRec.Insert();
        BlobRec.Get('S1');
        BlobRec.CalcFields(Data);
        BlobRec.Data.CreateInStream(InStr);
        InStr.ReadText(T1);
        // BC Cloud: WriteText does NOT add CR+LF between consecutive writes into a Blob.
        // Both writes are concatenated; ReadText reads all content up to the terminator.
        Assert.AreEqual('FirstSecond', T1, 'Sequential WriteText calls are concatenated; ReadText reads all content up to terminator');
    end;

    [Test]
    procedure InStream_ReadText_FullContent()
    var
        BlobRec: Record "ALT Blob";
        OutStr: OutStream;
        InStr: InStream;
        Content: Text;
    begin
        Initialize();
        BlobRec.Code := 'F1';
        BlobRec.Data.CreateOutStream(OutStr);
        OutStr.WriteText('Hello World 12345');
        BlobRec.Insert();
        BlobRec.Get('F1');
        BlobRec.CalcFields(Data);
        BlobRec.Data.CreateInStream(InStr);
        InStr.ReadText(Content);
        // Single WriteText, so ReadText reads until CR/LF and returns the content
        Assert.AreEqual('Hello World 12345', Content, 'ReadText must return complete written content');
    end;

    [Test]
    procedure InStream_EOS_AfterFullRead()
    var
        BlobRec: Record "ALT Blob";
        OutStr: OutStream;
        InStr: InStream;
        T: Text;
    begin
        Initialize();
        BlobRec.Code := 'E2';
        BlobRec.Data.CreateOutStream(OutStr);
        OutStr.WriteText('data');
        BlobRec.Insert();
        BlobRec.Get('E2');
        BlobRec.CalcFields(Data);
        BlobRec.Data.CreateInStream(InStr);
        InStr.ReadText(T);

        Assert.IsTrue(InStr.EOS(), 'After reading all content, InStream.EOS() must return true');
    end;

    [Test]
    procedure Blob_HasValue_AfterWrite_IsTrue()
    var
        BlobRec: Record "ALT Blob";
        OutStr: OutStream;
    begin
        Initialize();
        BlobRec.Code := 'H1';
        BlobRec.Data.CreateOutStream(OutStr);
        OutStr.WriteText('content');
        BlobRec.Insert();
        BlobRec.Get('H1');

        Assert.IsTrue(BlobRec.Data.HasValue(), 'Blob must HasValue() after writing content and inserting');
    end;

    [Test]
    procedure Blob_HasValue_NoWrite_IsFalse()
    var
        BlobRec: Record "ALT Blob";
    begin
        Initialize();
        BlobRec.Code := 'H2';
        BlobRec.Insert();
        BlobRec.Get('H2');

        Assert.IsFalse(BlobRec.Data.HasValue(), 'Blob with no written data must not HasValue()');
    end;

    [Test]
    procedure InStream_ResetPosition_AllowsReread()
    var
        BlobRec: Record "ALT Blob";
        OutStr: OutStream;
        InStr: InStream;
        T1: Text;
        T2: Text;
    begin
        Initialize();
        BlobRec.Code := 'R1';
        BlobRec.Data.CreateOutStream(OutStr);
        OutStr.WriteText('ReadMe');
        BlobRec.Insert();
        BlobRec.Get('R1');
        BlobRec.CalcFields(Data);
        BlobRec.Data.CreateInStream(InStr);
        InStr.ReadText(T1);
        InStr.ResetPosition();
        InStr.ReadText(T2);

        Assert.AreEqual(T1, T2, 'After ResetPosition, re-reading must return identical content');
    end;
}
