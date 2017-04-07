using CodeCrib.AX.Manage;
using System;
using System.Linq;

namespace RDAX.CodeCribWrapper
{
    public class Helper
    {
        public static CodeCrib.AX.Config.Client GetClientConfig(string clientConfigFile)
        {
            CodeCrib.AX.Config.Client clientConfig = null;

            if (!string.IsNullOrEmpty(clientConfigFile))
                clientConfig = CodeCrib.AX.Config.Client.GetConfigFromFile(clientConfigFile);
            else
                clientConfig = CodeCrib.AX.Config.Client.GetConfigFromRegistry();

            return clientConfig;
        }

        public static CodeCrib.AX.Config.Server GetServerConfig(string clientConfigFile)
        {
            CodeCrib.AX.Config.Client clientConfig = GetClientConfig(clientConfigFile);

            var servers = CodeCrib.AX.Config.Server.GetAOSInstances();
            var serverConfig = (from c in
                                    (from s in servers select CodeCrib.AX.Config.Server.GetConfigFromRegistry(s))
                                where c.TCPIPPort == clientConfig.Connections[0].TCPIPPort
                                && c.WSDLPort == clientConfig.Connections[0].WSDLPort
                                select c).FirstOrDefault();

            return serverConfig;
        }

        public static uint GetServerNumber(string clientConfigFile)
        {
            CodeCrib.AX.Config.Client clientConfig = GetClientConfig(clientConfigFile);
            uint aosNumber = CodeCrib.AX.Config.Server.GetAOSNumber((uint)clientConfig.Connections[0].TCPIPPort);

            return aosNumber;
        }

        public static void ExtractClientLayerModelInfo(string configurationFile, string[] layerCodes, string modelManifest, out string modelName, out string publisher, out string layer, out string layerCode)
        {
            CodeCrib.AX.Manage.ModelStore.ExtractModelInfo(modelManifest, out publisher, out modelName, out layer);

            string layerInternal = layer;

            CodeCrib.AX.Config.Server serverConfig = Helper.GetServerConfig(configurationFile);
            CodeCrib.AX.Manage.ModelStore modelStore = null;
            if (serverConfig.AOSVersionOrigin.Substring(0, 3) == "6.0")
            {
                modelStore = new ModelStore(serverConfig.DatabaseServer, string.Format("{0}", serverConfig.Database));
            }
            else
            {
                modelStore = new ModelStore(serverConfig.DatabaseServer, string.Format("{0}_model", serverConfig.Database));
            }
            if (!modelStore.ModelExist(modelName, publisher, layer))
            {
                throw new Exception(string.Format("Model {0} ({1}) does not exist in layer {2}", modelName, publisher, layer));
            }

            // Supports:
            // var:CODE
            // var : CODE
            // varCODE
            // var CODE
            layerCode = (from c in layerCodes where c.Substring(0, 3).ToLower() == layerInternal.ToLower() select c.Substring(3).Trim()).FirstOrDefault();
            if (!string.IsNullOrEmpty(layerCode) && layerCode[0] == ':')
            {
                layerCode = layerCode.Substring(1).Trim();
            }

            // An empty layer code is only allowed when either not specifying a layer, or when explicitly specifying the USR or USP layer.
            if (string.IsNullOrEmpty(layerCode) && !string.IsNullOrEmpty(layer) && String.Compare(layer, "USR", true) != 0 && String.Compare(layer, "USP", true) != 0)
            {
                throw new Exception(string.Format("Layer '{0}' requires an access code which couldn't be found in the Layer Codes argument", layer));
            }
        }
    }
}
