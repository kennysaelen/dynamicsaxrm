using CodeCrib.AX.Client;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Management;
using System.Management.Automation;
using System.Threading;
using System.Threading.Tasks;

namespace RDAX.CodeCribWrapper
{
    [Cmdlet(VerbsLifecycle.Start, "AxDBSync")]
    public class StartAxDBSync : Cmdlet
    {
        [Parameter(Mandatory = true)]
        public string ConfigurationFile { get; set; }

        [Parameter(Mandatory = true)]
        public int TimeOut { get; set; }

        private CodeCrib.AX.Client.AutoRun.AxaptaAutoRun autoRun = new CodeCrib.AX.Client.AutoRun.AxaptaAutoRun();
        private string autoRunFile = string.Format(@"{0}\AutoRun-Synchronize-{1}.xml", Environment.GetEnvironmentVariable("temp"), Guid.NewGuid());
        private string logFile = "";
        private bool errorOccured = false;

        protected override void ProcessRecord()
        {
            try
            {
                StartTasks();

                autoRun.ParseLog();

                foreach (var step in autoRun.Steps)
                {
                    if (step.Log != null)
                    {
                        foreach (var message in step.Log)
                        {
                            switch (message.Key)
                            {
                                case "Info":
                                case "Warning":
                                    WriteObject(message.Value);
                                    break;

                                case "Error":
                                    WriteObject(message.Value);
                                    errorOccured = true;
                                    break;
                            }
                        }
                    }
                }

                if (errorOccured.Equals(false))
                {
                    if (File.Exists(logFile))
                        File.Delete(logFile);
                    if (File.Exists(autoRunFile))
                        File.Delete(autoRunFile);
                }
                else
                {
                    throw new Exception("Sync errors detected");
                }
            }
            catch (Exception ex)
            {
                WriteError(new ErrorRecord(ex, "An exception occured", ErrorCategory.InvalidOperation, ConfigurationFile));
            }
        }

        protected override void StopProcessing()
        {
            try
            {
                CancelDBSync();
            }
            catch (Exception ex)
            {
                WriteError(new ErrorRecord(ex, "An exception occured", ErrorCategory.InvalidOperation, ConfigurationFile));
            }
        }

        private void StartTasks()
        {
            var dbSync = Task<bool>.Factory.StartNew(() => StartDBSync());
            var timeOutTask = Task<bool>.Factory.StartNew(() => StartTimeOut());

            var response = Task.WaitAny(new Task[] { timeOutTask, dbSync });
            switch (response)
            {
                case 0:
                    this.CancelDBSync();
                    break;

                default:
                    break;
            }

            if (dbSync.IsFaulted)
            {
                throw dbSync.Exception.InnerException;
            }
        }

        private bool StartDBSync()
        {
            var clientConfig = Helper.GetClientConfig(ConfigurationFile);

            logFile = string.Format(@"{0}\SynchronizeLog-{1}.xml", Environment.ExpandEnvironmentVariables(clientConfig.LogDirectory), Guid.NewGuid());
            autoRun.ExitWhenDone = true;
            autoRun.LogFile = logFile;
            autoRun.Steps.Add(new CodeCrib.AX.Client.AutoRun.Synchronize() { SyncDB = true, SyncRoles = true });


            CodeCrib.AX.Client.AutoRun.AxaptaAutoRun.SerializeAutoRun(autoRun, autoRunFile);

            var process = Client.StartCommand(new CodeCrib.AX.Client.Commands.AutoRun() { ConfigurationFile = ConfigurationFile, Filename = autoRunFile });
            process.WaitForExit();

            return true;
        }

        private bool StartTimeOut()
        {
            Thread.Sleep(TimeOut * 60 * 1000);

            return true;
        }

        private void CancelDBSync()
        {
            var parentId = Process.GetCurrentProcess().Id;
            UInt32 axBuildId = 0;

            using (var mos = new ManagementObjectSearcher(string.Format("SELECT ProcessId, Name FROM Win32_Process WHERE ParentProcessId = {0}", parentId)))
            {
                foreach (var obj in mos.Get())
                {
                    var currentProcessName = (string)obj.Properties["Name"].Value;
                    if (currentProcessName.Equals("Ax32.exe"))
                    {
                        axBuildId = (UInt32)obj.Properties["ProcessId"].Value;
                        if (axBuildId != 0)
                        {
                            Process subProcess = Process.GetProcessById(Convert.ToInt32(axBuildId));
                            if (!subProcess.HasExited)
                                subProcess.Kill();
                        }
                    }
                }
            }

            if (File.Exists(logFile))
                File.Delete(logFile);
            if (File.Exists(autoRunFile))
                File.Delete(autoRunFile);

            ThrowTerminatingError(new ErrorRecord(new TimeoutException("AxBuild timeout"), "Timeout", ErrorCategory.OperationTimeout, ConfigurationFile));
        }
    }
}
