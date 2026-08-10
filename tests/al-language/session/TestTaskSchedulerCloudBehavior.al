// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/taskscheduler/taskscheduler-data-type
// Scope: in-scope (Cloud-compatible)
// Fixtures used: none
// BC versions: 27.5+
//
// CLAIM: TaskScheduler.CreateTask, called from inside a running test, is refused --
// a test transaction can't leave a scheduled task behind it that outlives the rollback.

codeunit 60877 "Test TaskScheduler Behavior"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure TaskScheduler_CreateTask_InsideTest_Throws()
    begin
        asserterror TaskScheduler.CreateTask(Codeunit::"Test TaskScheduler Behavior");
        Assert.IsTrue(GetLastErrorText() <> '', 'TaskScheduler.CreateTask must throw when called from inside a running test');
    end;
}
