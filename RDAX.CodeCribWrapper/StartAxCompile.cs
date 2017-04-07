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
    [Cmdlet(VerbsLifecycle.Start, "AxCompile")]
    public class StartAxCompile : Cmdlet
    {
        [Parameter(Mandatory = true)]
        public string ConfigurationFile { get; set; }

        [Parameter(Mandatory = true)]
        public int TimeOutMinutes { get; set; }

        [Parameter]
        public string ClientExecutablePath { get; set; }

        [Parameter]
        public bool UpdateXRef { get; set; }

        [Parameter]
        public string[] Layercodes { get; set; }

        [Parameter]
        public string ModelManifest { get; set; }

        private string logFile = "";

        protected override void ProcessRecord()
        {
            try
            {
                StartTasks();

                CompileOutput output = null;

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

                if (File.Exists(logFile))
                    File.Delete(logFile);

                if (hasErrors)
                {
                    throw new Exception("Compile error(s) found");
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
                CancelAxCompile();
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
                    this.CancelAxCompile();
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
            Compile compile = new Compile()
            {
                Minimize = true,
                LazyClassLoading = false,
                LazyTableLoading = false,
                UpdateCrossReference = UpdateXRef,
                Development = true,
                NoModalBoxes = true 
            };

            if (!string.IsNullOrEmpty(ConfigurationFile))
            {
                compile.ConfigurationFile = ConfigurationFile;
            }

            if (Layercodes != null)
            {
                if (!string.IsNullOrEmpty(ModelManifest))
                {
                    string model;
                    string publisher;
                    string layer;
                    string layerCode;

                    Helper.ExtractClientLayerModelInfo(ConfigurationFile, Layercodes, ModelManifest, out model, out publisher, out layer, out layerCode);

                    compile.Model = model;
                    compile.ModelPublisher = publisher;
                    compile.Layer = layer;
                    compile.LayerCode = layerCode;
                }
            }

            var clientConfig = Helper.GetClientConfig(ConfigurationFile);
            logFile = string.Format(@"{0}\{1}", Environment.ExpandEnvironmentVariables(clientConfig.LogDirectory), "AxCompileAll.html");

            Process task = null;
            if (string.IsNullOrEmpty(ClientExecutablePath))
                task = Client.StartCommand(compile);
            else
                task = Client.StartCommand(ClientExecutablePath, compile);

            task.WaitForExit();

            return true;
        }

        private bool StartTimeOut()
        {
            Thread.Sleep(TimeOutMinutes * 60 * 1000);

            return true;
        }

        private void CancelAxCompile()
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
