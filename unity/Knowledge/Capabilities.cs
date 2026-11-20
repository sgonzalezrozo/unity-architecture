using System;
using System.IO;
using UnityEngine;

namespace UnityArchitecture.Knowledge
{
    /// <summary>
    /// Reads .ai/capabilities.json, the capability table scripts/ai-profile.sh and the rules also use, so a doc can say
    /// <c>requires: ["fastIoC"]</c> or <c>&lt;!-- if: uiScroller --&gt;</c> instead of repeating package names.
    /// A capability is true when the project has one of its packages, or one of its paths exists.
    /// </summary>
    internal static class Capabilities
    {
        private const string TABLE_FILE = "capabilities.json";

        [Serializable]
        private class CapabilityTable
        {
            public CapabilityEntry[] capabilities = new CapabilityEntry[0];
        }

        [Serializable]
        private class CapabilityEntry
        {
            public string id;
            public string[] packages = new string[0];
            public string[] paths = new string[0];
        }

        /// <summary>The table next to the package's folder (.ai/unity → .ai), or none when it isn't there.</summary>
        public static string FindTable(string packageFolder)
        {
            DirectoryInfo aiFolder = string.IsNullOrEmpty(packageFolder) ? null : Directory.GetParent(packageFolder);
            string path = aiFolder == null ? null : Path.Combine(aiFolder.FullName, TABLE_FILE);
            return path != null && File.Exists(path) ? path : null;
        }

        /// <summary>Adds each true capability's id to installedPackages, so conditions and requires take it.</summary>
        public static void AddTrueCapabilities(string tablePath, string projectFolder,
            System.Collections.Generic.Dictionary<string, string> installedPackages)
        {
            if (string.IsNullOrEmpty(tablePath))
                return;

            CapabilityTable table;
            try
            {
                table = JsonUtility.FromJson<CapabilityTable>(File.ReadAllText(tablePath));
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[RulesGuide] Couldn't read {tablePath}: {exception.Message}");
                return;
            }

            for (int i = 0; table != null && i < table.capabilities.Length; i++)
            {
                CapabilityEntry entry = table.capabilities[i];
                if (!string.IsNullOrEmpty(entry.id) && !installedPackages.ContainsKey(entry.id)
                    && IsTrue(entry, projectFolder, installedPackages))
                    installedPackages[entry.id] = string.Empty;
            }
        }

        private static bool IsTrue(CapabilityEntry entry, string projectFolder,
            System.Collections.Generic.Dictionary<string, string> installedPackages)
        {
            for (int i = 0; entry.packages != null && i < entry.packages.Length; i++)
            {
                if (installedPackages.ContainsKey(entry.packages[i]))
                    return true;
            }

            for (int i = 0; entry.paths != null && i < entry.paths.Length; i++)
            {
                if (File.Exists(Path.Combine(projectFolder, entry.paths[i]))
                    || Directory.Exists(Path.Combine(projectFolder, entry.paths[i])))
                    return true;
            }

            return false;
        }
    }
}
