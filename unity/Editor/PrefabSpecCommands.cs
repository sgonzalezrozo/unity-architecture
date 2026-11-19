using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

namespace UnityArchitecture.Prefabs
{
    /// <summary>
    /// Builds a prefab from the JSON spec selected in the Project window, so a spec works without a Unity MCP: the agent
    /// writes the spec, and a person builds it with one click. It validates the result and compares it with the spec,
    /// like an agent does through the bridge (EDIT-12).
    /// </summary>
    public static class PrefabSpecCommands
    {
        private const string MENU = "Assets/Unity Architecture/Build Prefab From Spec";
        private const string TITLE = "Build Prefab From Spec";

        [MenuItem(MENU, true)]
        private static bool CanBuildFromMenu()
        {
            return SelectedSpecPath() != null;
        }

        [MenuItem(MENU, false, 30)]
        private static void BuildFromMenu()
        {
            string jsonPath = SelectedSpecPath();
            string json = File.ReadAllText(jsonPath);
            string prefabPath;
            try
            {
                prefabPath = PrefabPathFor(jsonPath, PrefabSpecNode.Parse(json).Name, PrefabValidator.CLIENT_FOLDER);
            }
            catch (System.FormatException exception)
            {
                EditorUtility.DisplayDialog(TITLE, $"{jsonPath} isn't a valid spec:\n{exception.Message}", "OK");
                return;
            }

            bool replaces = AssetDatabase.LoadAssetAtPath<GameObject>(prefabPath) != null;
            string question = replaces ? $"Rebuild {prefabPath} from the spec? This replaces the prefab." : $"Build {prefabPath} from the spec?";
            if (!EditorUtility.DisplayDialog(TITLE, question, replaces ? "Rebuild" : "Build", "Cancel"))
                return;

            List<PrefabViolation> violations = PrefabSpecs.BuildFromSpec(json, prefabPath);
            List<string> differences = PrefabSpecs.Compare(json, prefabPath);
            Report(prefabPath, violations, differences);
        }

        /// <summary>
        /// Where the spec's prefab goes: a prefab with the spec's name next to the JSON, else the only prefab with that name
        /// under <paramref name="searchFolder"/>, else a new one next to the JSON.
        /// </summary>
        public static string PrefabPathFor(string jsonPath, string specName, string searchFolder)
        {
            string fileName = specName + ".prefab";
            string besideSpec = Path.GetDirectoryName(jsonPath)?.Replace('\\', '/') + "/" + fileName;
            if (AssetDatabase.LoadAssetAtPath<GameObject>(besideSpec) != null || !AssetDatabase.IsValidFolder(searchFolder))
                return besideSpec;

            List<string> matches = new();
            foreach (string guid in AssetDatabase.FindAssets(specName + " t:Prefab", new[] { searchFolder }))
            {
                string path = AssetDatabase.GUIDToAssetPath(guid);
                if (Path.GetFileName(path) == fileName)
                    matches.Add(path);
            }

            return matches.Count == 1 ? matches[0] : besideSpec;
        }

        private static string SelectedSpecPath()
        {
            if (Selection.assetGUIDs.Length != 1)
                return null;

            string path = AssetDatabase.GUIDToAssetPath(Selection.assetGUIDs[0]);
            return path.EndsWith(".json", System.StringComparison.OrdinalIgnoreCase) ? path : null;
        }

        private static void Report(string prefabPath, List<PrefabViolation> violations, List<string> differences)
        {
            int errors = 0;
            foreach (PrefabViolation violation in violations)
            {
                if (violation.IsWarning)
                {
                    Debug.LogWarning(violation.ToString());
                    continue;
                }

                errors++;
                Debug.LogError(violation.ToString());
            }

            foreach (string difference in differences)
                Debug.LogError($"[Unity Architecture] {difference}");

            Object prefab = AssetDatabase.LoadAssetAtPath<GameObject>(prefabPath);
            EditorGUIUtility.PingObject(prefab);
            string summary = errors == 0 && differences.Count == 0
                ? $"{prefabPath} follows the prefab rules and matches its spec."
                : $"{prefabPath} was built with {errors} rule errors and {differences.Count} differences from its spec. They're in the Console.";
            Debug.Log($"[Unity Architecture] {summary}");
            EditorUtility.DisplayDialog(TITLE, summary, "OK");
        }
    }
}
