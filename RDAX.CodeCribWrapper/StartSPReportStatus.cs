using Microsoft.SharePoint.Client;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace RDAX.CodeCribWrapper
{
    [Cmdlet(VerbsLifecycle.Start, "SPReportStatus")]
    public class StartSPReportStatus : Cmdlet
    {
        [Parameter(Mandatory = true)]
        public string SiteURL { get; set; }

        [Parameter(Mandatory = true)]
        public string DocumentListName { get; set; }
            
        [Parameter(Mandatory = true)]
        public string DocumentListUrl { get; set; }

        [Parameter(Mandatory = true)]
        public string DocumentTitle { get; set; }

        [Parameter(Mandatory = true)]
        public string Status { get; set; }

        protected override void ProcessRecord()
        {
            try
            {
                StartReportStatus();
            }
            catch (Exception ex)
            {
                WriteError(new ErrorRecord(ex, "An exception occured", ErrorCategory.InvalidOperation, Status));
            }
           
        }

        private bool StartReportStatus()
        {
            
            using (ClientContext clientContext = new ClientContext(SiteURL))
            {
                var fileTitle = string.Format("{0}_{1}_{2}.txt", DocumentTitle, DateTime.Now.ToString("yyyyMMdd_HHmmss"), Status.ToString());

                List documentsList = clientContext.Web.Lists.GetByTitle(DocumentListName);
                var fileCreationInformation = new FileCreationInformation();
                fileCreationInformation.Content = this.generateFile();
                fileCreationInformation.Overwrite = true;
                fileCreationInformation.Url = string.Format("{0}/{1}/{2}", SiteURL, DocumentListUrl, fileTitle); 
                Microsoft.SharePoint.Client.File uploadFile = documentsList.RootFolder.Files.Add(fileCreationInformation);

                uploadFile.ListItemAllFields.Update();
                clientContext.ExecuteQuery();

            }
            return true;
        }

        private byte[] generateFile()
        {
            byte[] buffer = new byte[16 * 1024];

            using (var stream = new MemoryStream())
            {
                var sw = new StreamWriter(stream);
                sw.WriteLine(Status.ToString());
                sw.Flush();
                stream.Position = 0;

                buffer = stream.ToArray();
            }

            return buffer;
        }

    }
}
