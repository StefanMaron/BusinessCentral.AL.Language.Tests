// Creates the TENANT encryption key that AL's Encrypt/Decrypt and IsolatedStorage.SetEncrypted read (corpus #282).
//
// Why from AL: Import-NAVEncryptionKey -ServerInstance only loads the key of the server instance (used for the
// protected database password). AL reads the key of the tenant (TenantRsaEncryptionProvider), so a key imported
// with the cmdlets left cu 60378 failing with "An encryption key is required to complete the request." on every
// Windows nightly. CreateEncryptionKey() is the AL call that creates the tenant key (the same call the
// "Data Encryption Management" page makes; MsDyn365Bc.On.Linux does the same in its TestRunnerExtension).
//
// The key is created outside any test transaction: in the install trigger, and again (only if still missing)
// from Invoke-NAVCodeunit. A test method must not create it: Codeunit.Run opens a nested transaction, and
// creating a key inside one fails ("An error occurred and the transaction is stopped", MsDyn365Bc.On.Linux, BC 28.4).

table 81846 "LT BK Encryption Key Log"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; "Step"; Text[30]) { }
        field(3; "Result"; Text[250]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

codeunit 81846 "LT BK Encryption Key Install"
{
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    var
        Setup: Codeunit "LT BK Encryption Key Setup";
    begin
        // An install trigger that raises stops the publish, and the workflow step reports the state itself.
        Setup.Ensure('install');
    end;
}

codeunit 81849 "LT BK Encryption Key Setup"
{
    // Invoke-NAVCodeunit without -MethodName: create the key if it is still missing.
    trigger OnRun()
    begin
        Ensure('invoke');
    end;

    procedure Ensure(StepName: Text)
    begin
        ClearLastError();
        if TryEnsure() then
            Log(StepName, StrSubstNo('ok; enabled=%1 exists=%2', EncryptionEnabled(), EncryptionKeyExists()))
        else
            Log(StepName, 'failed: ' + GetLastErrorText());
        ClearLastError();
    end;

    [TryFunction]
    local procedure TryEnsure()
    begin
        if EncryptionEnabled() then begin
            if EncryptionKeyExists() then
                exit;
            // A key file name is recorded but the key is gone: nothing encrypted with it is readable, so start over.
            DeleteEncryptionKey();
        end;
        if not CreateEncryptionKey() then
            Error('CreateEncryptionKey() returned false');
    end;

    local procedure Log(StepName: Text; ResultText: Text)
    var
        Entry: Record "LT BK Encryption Key Log";
    begin
        Entry.Init();
        Entry."Step" := CopyStr(StepName, 1, MaxStrLen(Entry."Step"));
        Entry."Result" := CopyStr(ResultText, 1, MaxStrLen(Entry."Result"));
        if Entry.Insert(true) then;
    end;

    // Invoke-NAVCodeunit -MethodName Verify: raises unless the tenant key works for a real round trip.
    procedure Verify()
    var
        Plain: Text;
        Cipher: Text;
    begin
        Plain := 'lt-bk-encryption-check';
        if not EncryptionEnabled() then
            Error('VERIFY FAILED: EncryptionEnabled() is false. %1', History());
        if not EncryptionKeyExists() then
            Error('VERIFY FAILED: EncryptionKeyExists() is false. %1', History());
        Cipher := Encrypt(Plain);
        if Cipher = Plain then
            Error('VERIFY FAILED: Encrypt() returned its input. %1', History());
        if Decrypt(Cipher) <> Plain then
            Error('VERIFY FAILED: Decrypt(Encrypt(x)) <> x. %1', History());
    end;

    // Invoke-NAVCodeunit -MethodName Report: always raises, with the log, so the workflow can print it.
    procedure Report()
    begin
        Error('STATE: enabled=%1 exists=%2. %3', EncryptionEnabled(), EncryptionKeyExists(), History());
    end;

    local procedure History(): Text
    var
        Entry: Record "LT BK Encryption Key Log";
        Txt: Text;
    begin
        if Entry.FindSet() then
            repeat
                Txt += StrSubstNo('[%1: %2] ', Entry."Step", Entry."Result");
            until Entry.Next() = 0;
        if Txt = '' then
            exit('log: empty');
        exit('log: ' + Txt);
    end;
}
