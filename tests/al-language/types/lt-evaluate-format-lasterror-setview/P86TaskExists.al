// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/taskscheduler/taskscheduler-taskexists-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained objects
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: TaskScheduler.TaskExists for a random guid, an empty guid, a created task, a cancelled task, cancelled twice (tasks are created not ready and far in the future, and always cancelled in the same test)
// BC versions: 29 (27 and 28 by CI)

codeunit 73532 "LT P86 Task Target"
{
    trigger OnRun()
    begin
    end;
}

codeunit 73533 "LT P86 Task Exists"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Far(): DateTime
    begin
        exit(CreateDateTime(DMY2Date(1, 1, 2099), 120000T));
    end;

    [Test]
    procedure TaskExists_Unknown()
    var
        Observer: Codeunit "Probe Observer";
        Empty: Guid;
        G: Guid;
    begin
        G := CreateGuid();
        Observer.Observe('random', Format(TaskScheduler.TaskExists(G)));
        Observer.Observe('random_twice', Format(TaskScheduler.TaskExists(G)));
        Observer.Observe('random2', Format(TaskScheduler.TaskExists(CreateGuid())));
        Observer.Observe('empty', Format(TaskScheduler.TaskExists(Empty)));
        Observer.Finish();
    end;

    [Test]
    procedure TaskExists_CreatedThenCancelled()
    var
        Observer: Codeunit "Probe Observer";
        Id: Guid;
    begin
        Id := TaskScheduler.CreateTask(Codeunit::"LT P86 Task Target", 0, false, CompanyName(), Far());
        Observer.Observe('id_not_null', Format(not IsNullGuid(Id)));
        Observer.Observe('exists_created', Format(TaskScheduler.TaskExists(Id)));
        Observer.Observe('exists_again', Format(TaskScheduler.TaskExists(Id)));
        Observer.Observe('cancel_first', Format(TaskScheduler.CancelTask(Id)));
        Observer.Observe('exists_cancelled', Format(TaskScheduler.TaskExists(Id)));
        Observer.Observe('cancel_second', Format(TaskScheduler.CancelTask(Id)));
        Observer.Observe('exists_after_second', Format(TaskScheduler.TaskExists(Id)));
        Observer.Finish();
    end;

    [Test]
    procedure TaskExists_TwoTasks()
    var
        Observer: Codeunit "Probe Observer";
        A: Guid;
        B: Guid;
    begin
        A := TaskScheduler.CreateTask(Codeunit::"LT P86 Task Target", 0, false, CompanyName(), Far());
        B := TaskScheduler.CreateTask(Codeunit::"LT P86 Task Target", 0, false, CompanyName(), Far());
        Observer.Observe('distinct', Format(A <> B));
        Observer.Observe('a_exists', Format(TaskScheduler.TaskExists(A)));
        Observer.Observe('b_exists', Format(TaskScheduler.TaskExists(B)));
        Observer.Observe('cancel_a', Format(TaskScheduler.CancelTask(A)));
        Observer.Observe('a_after', Format(TaskScheduler.TaskExists(A)));
        Observer.Observe('b_after', Format(TaskScheduler.TaskExists(B)));
        Observer.Observe('cancel_b', Format(TaskScheduler.CancelTask(B)));
        Observer.Observe('b_after2', Format(TaskScheduler.TaskExists(B)));
        Observer.Finish();
    end;

    [Test]
    procedure TaskExists_ReadyFlagAndFailureCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        A: Guid;
        B: Guid;
    begin
        A := TaskScheduler.CreateTask(Codeunit::"LT P86 Task Target", Codeunit::"LT P86 Task Target", false, CompanyName(), Far());
        Observer.Observe('with_failure_cu', Format(TaskScheduler.TaskExists(A)));
        B := TaskScheduler.CreateTask(Codeunit::"LT P86 Task Target", 0, true, CompanyName(), Far());
        Observer.Observe('ready_far_future', Format(TaskScheduler.TaskExists(B)));
        Observer.Observe('cancel_a', Format(TaskScheduler.CancelTask(A)));
        Observer.Observe('cancel_b', Format(TaskScheduler.CancelTask(B)));
        Observer.Observe('a_after', Format(TaskScheduler.TaskExists(A)));
        Observer.Observe('b_after', Format(TaskScheduler.TaskExists(B)));
        Observer.Finish();
    end;

    [Test]
    procedure TaskExists_CancelUnknownThenCreated()
    var
        Observer: Codeunit "Probe Observer";
        Id: Guid;
        Other: Guid;
    begin
        Other := CreateGuid();
        Id := TaskScheduler.CreateTask(Codeunit::"LT P86 Task Target", 0, false, CompanyName(), Far());
        Observer.Observe('cancel_unknown', Format(TaskScheduler.CancelTask(Other)));
        Observer.Observe('created_still_exists', Format(TaskScheduler.TaskExists(Id)));
        Observer.Observe('unknown_exists', Format(TaskScheduler.TaskExists(Other)));
        Observer.Observe('cancel_created', Format(TaskScheduler.CancelTask(Id)));
        Observer.Finish();
    end;
}

