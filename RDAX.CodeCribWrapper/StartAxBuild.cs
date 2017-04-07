using CodeCrib.AX.AXBuild;
using CodeCrib.AX.Client;
using System;
using System.Diagnostics;
using System.IO;
using System.Management;
using System.Management.Automation;
using System.Threading;
using System.Threading.Tasks;

namespace RDAX.CodeCribWrapper
{
    [Cmdlet(VerbsLifecycle.Start, "AxBuild")]
    public class StartAxBuild : Cmdlet
    {
        [Parameter(Mandatory = true)]
        public int TimeOutMinutes { get; set; }

        [Parameter]
        public int Workers { get; set; }

        [Parameter(Mandatory = true)]
        public string ConfigurationFile { get; set; }

        private string logPath = Directory.CreateDirectory(Path.Combine(Path.GetTempPath(), Path.GetRandomFileName())).FullName;
        private string logFile = "";

        protected override void ProcessRecord()
        {
            try
            {
                logFile = Path.Combine(logPath, "AxCompileAll.html");

                StartTasks();

                CompileOutput output = null;

                if (File.Exists(logFile))
                {
                    try
                    {
                        output = CompileOutput.CreateFromFile(logFile);
                    }
                    catch (FileNotFoundException)
                    {
                        throw new Exception("Compile log could not be found");
                    }
                    catch (Exception ex)
                    {
                        throw new Exception(string.Format("Error parsing compile log: {0}", ex.Message));
                    }

                    bool hasErrors = false;
                    foreach (var item in output.Output)
                    {
                        string compileMessage = String.Format("{0}, line {1}, column {2} : {3}", item.TreeNodePath, item.LineNumber, item.ColumnNumber, item.Message);
                        switch (item.Severity)
                        {
                            // Compile Errors
                            case 0:
                                WriteObject(compileMessage);
                                hasErrors = true;
                                break;
                            // Compile Warnings
                            case 1:
                            case 2:
                            case 3:
                                WriteObject(compileMessage);
                                break;
                            // Best practices
                            case 4:
                                WriteObject(string.Format("BP: {0}", compileMessage));
                                break;
                            // TODOs
                            case 254:
                            case 255:
                                WriteObject(string.Format("TODO: {0}", compileMessage));
                                break;
                            // "Other"
                            default:
                                WriteObject(compileMessage);
                                break;
                        }
                    }

                    if (hasErrors)
                    {
                        throw new Exception("Compile error(s) found");
                    }
                    else
                    {
                        if (File.Exists(logFile))
                            File.Delete(logFile);
                    }
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
                CancelAxBuild();
            }
            catch (Exception ex)
            {
                WriteError(new ErrorRecord(ex, "An exception occured", ErrorCategory.InvalidOperation, ConfigurationFile));
            }
        }

        private void StartTasks()
        {
            var compileTask = Task<bool>.Factory.StartNew(() => StartCompile());
            var timeOutTask = Task<bool>.Factory.StartNew(() => StartTimeOut());

            var response = Task.WaitAny(new Task[] { timeOutTask, compileTask });
            switch (response)
            {
                case 0:
                    this.CancelAxBuild();
                    break;

                default:
                    break;
            }

            if (compileTask.IsFaulted)
            {
                throw compileTask.Exception.InnerException;
            }
        }

        private bool StartCompile()
        {
            var serverConfig = Helper.GetServerConfig(ConfigurationFile);
            string serverBinPath = serverConfig.AlternateBinDirectory;

            var compile = new CodeCrib.AX.AXBuild.Commands.Compile()
            {
                Workers = this.Workers,
                Compiler = Path.Combine(serverBinPath, "Ax32Serv.exe"),
                AOSInstance = Helper.GetServerNumber(ConfigurationFile).ToString("D2")
            };

            if (string.IsNullOrEmpty(logPath).Equals(false))
            {
                compile.LogPath = logPath;
            }

            var task = AXBuild.StartCommand(serverBinPath, compile);
            task.WaitForExit();

            return true;
        }

        private bool StartTimeOut()
        {
            Thread.Sleep(TimeOutMinutes * 60 * 1000);

            return true;
        }

        private void CancelAxBuild()
        {
            var parentId = Process.GetCurrentProcess().Id;
            UInt32 axBuildId = 0;

            using (var mos = new ManagementObjectSearcher(string.Format("SELECT ProcessId, Name FROM Win32_Process WHERE ParentProcessId = {0}", parentId)))
            {
                foreach (var obj in mos.Get())
                {
                    var currentProcessName = (string)obj.Properties["Name"].Value;
                    if (currentProcessName.Equals("AXBuild.exe"))
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

            if (axBuildId != 0)
            {
                using (var mos = new ManagementObjectSearcher(string.Format("SELECT ProcessId, Name FROM Win32_Process WHERE ParentProcessId = {0}", axBuildId)))
                {
                    foreach (var obj in mos.Get())
                    {
                        string processName = (string)obj.Properties["Name"].Value;
                        if (processName == "Ax32Serv.exe")
                        {
                            UInt32 pid = (UInt32)obj.Properties["ProcessId"].Value;
                            if (pid != 0)
                            {
                                Process subProcess = Process.GetProcessById(Convert.ToInt32(pid));
                                if (!subProcess.HasExited)
                                    subProcess.Kill();
                            }
                        }
                    }
                }
            }

            ThrowTerminatingError(new ErrorRecord(new TimeoutException("AxBuild timeout"), "Timeout", ErrorCategory.OperationTimeout, ConfigurationFile));
        }
    }
}
