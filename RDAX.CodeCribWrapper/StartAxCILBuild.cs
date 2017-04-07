using CodeCrib.AX.Client;
using CodeCrib.AX.Client.Commands;
using System;
using System.Diagnostics;
using System.IO;
using System.Management;
using System.Management.Automation;
using System.Threading;
using System.Threading.Tasks;

namespace RDAX.CodeCribWrapper
{
    [Cmdlet(VerbsLifecycle.Start, "AxCILBuild")]
    public class StartAxCILBuild : Cmdlet
    {
        [Parameter(Mandatory = true)]
        public int TimeOutMinutes { get; set; }

        [Parameter(Mandatory = true)]
        public string ConfigurationFile { get; set; }

        [Parameter(Mandatory = false)]
        public string ClientExecutablePath { get; set; }

        private string logFile = "";

        protected override void ProcessRecord()
        {
            try
            {
                StartTasks();

                CILGenerationOutput output = null;
                try
                {
                    output = CILGenerationOutput.CreateFromFile(logFile);
                }
                catch (FileNotFoundException)
                {
                    throw new Exception("CIL generation log could not be found");
                }
                catch (Exception ex)
                {
                    throw new Exception(string.Format("Error parsing CIL generation log: {0}", ex.Message));
                }

                bool hasErrors = false;
                foreach (var item in output.Output)
                {
                    string compileMessage;

                    if (item.LineNumber > 0)
                        compileMessage = string.Format("Object {0} method {1}, line {2} : {3}", item.ElementName, item.MethodName, item.LineNumber, item.Message);
                    else
                        compileMessage = string.Format("Object {0} method {1} : {2}", item.ElementName, item.MethodName, item.Message);

                    switch (item.Severity)
                    {
                        // Compile Errors
                        case 0:
                            WriteObject(compileMessage);
                            hasErrors = true;
                            break;
                        // Compile Warnings
                        case 1:
                            WriteObject(compileMessage);
                            break;
                        // "Other"
                        case 4:
                        default:
                            WriteObject(item.Message);
                            break;
                    }
                }

                if (File.Exists(logFile))
                    File.Delete(logFile);

                if (hasErrors)
                {
                    throw new Exception("CIL error(s) found");
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
                CancelCILBuild();
            }
            catch (Exception ex)
            {
                WriteError(new ErrorRecord(ex, "An exception occured", ErrorCategory.InvalidOperation, ConfigurationFile));
            }
        }

        private void StartTasks()
        {
            var compileTask = Task<bool>.Factory.StartNew(() => StartCILBuild());
            var timeOutTask = Task<bool>.Factory.StartNew(() => StartTimeOut());

            var response = Task.WaitAny(new Task[] { timeOutTask, compileTask });
            switch (response)
            {
                case 0:
                    this.CancelCILBuild();
                    break;

                default:
                    break;
            }

            if (compileTask.IsFaulted)
            {
                throw compileTask.Exception.InnerException;
            }
        }

        private bool StartCILBuild()
        {
            var compile = new GenerateCIL()
            {
                Minimize = true,
                LazyClassLoading = false,
                LazyTableLoading = false,
                Development = true,
                NoModalBoxes = true
            };

            if (!string.IsNullOrEmpty(ConfigurationFile))
            {
                compile.ConfigurationFile = ConfigurationFile;
            }

            var alternateBinDirectory = Helper.GetServerConfig(ConfigurationFile).AlternateBinDirectory;
            logFile = string.Format(@"{0}\XppIL\Dynamics.Ax.Application.dll.log", Environment.ExpandEnvironmentVariables(alternateBinDirectory));

            Process process = null;
            if (string.IsNullOrEmpty(ClientExecutablePath))
            {
                process = Client.StartCommand(compile);
            }
            else
            {
                process = Client.StartCommand(ClientExecutablePath, compile);
            }

            process.WaitForExit();

            return true;
        }

        private bool StartTimeOut()
        {
            Thread.Sleep(TimeOutMinutes * 60 * 1000);

            return true;
        }

        private void CancelCILBuild()
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

            ThrowTerminatingError(new ErrorRecord(new TimeoutException("AxBuild timeout"), "Timeout", ErrorCategory.OperationTimeout, ConfigurationFile));
        }
    }
}
