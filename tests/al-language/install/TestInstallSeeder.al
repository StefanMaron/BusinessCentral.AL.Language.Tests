// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-installation-codeunit
// Scope: in-scope
// Fixtures used: Install Seed (60617), Install Seed Database (60621)
//
// The Subtype=Install codeunit under test. Real BC fires its lifecycle
// triggers on app install; each trigger inserts distinctly-marked rows so the
// tests can prove BOTH triggers fired (not just one). OnInstallAppPerDatabase
// fires once, globally, before any company exists, so it writes to the
// per-database table. OnInstallAppPerCompany fires once per EXISTING company,
// so it writes to the per-company table — otherwise a sandbox with more than
// one company would collide inserting the same Code twice.

codeunit 60618 "Install Seeder"
{
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    var
        Seed: Record "Install Seed Database";
    begin
        Seed.Init();
        Seed."Code" := 'DATABASE';
        Seed."Value" := 99;
        Seed.Insert();
    end;

    trigger OnInstallAppPerCompany()
    var
        Seed: Record "Install Seed";
        EventPublisher: Codeunit "Install Event Publisher";
    begin
        Seed.Init();
        Seed."Code" := 'COMPANY1';
        Seed."Value" := 11;
        Seed.Insert();

        Seed.Init();
        Seed."Code" := 'COMPANY2';
        Seed."Value" := 22;
        Seed.Insert();

        // Raise an integration event from inside the install trigger — the
        // ordinary way an app lets other code contribute setup rows while it
        // installs. Its subscriber writes to "Install Event Seed" (60832), a
        // DIFFERENT table, so the exact-count assertions over "Install Seed"
        // stay meaningful.
        EventPublisher.Discover();
    end;
}
