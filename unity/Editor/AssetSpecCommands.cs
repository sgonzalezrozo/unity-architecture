using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace UnityArchitecture.Prefabs
{
    /// <summary>
    /// Builds the data asset described by the spec selected in the Project window (a file ending in .asset.json), so a
    /// spec works without a Unity MCP: the agent writes it, and a person builds it with one click (EDIT-14).
    /// </summary>
    public static class AssetSpecCommands
    {
        private const string MENU = "Assets/Unity Architecture/Build Asset From Spec";

        [MenuItem(MENU, true)]
        private static bool CanBuildFromMenu()
        {
            return SelectedSpecPath() != null;
        }

        [MenuItem(MENU, false, 31)]
        private static void BuildFromMenu()
        {
            string specPath = SelectedSpecPath();
            List<string> problems = AssetSpecs.Build(specPath);
            if (problems.Count == 0)
            {
                Debug.Log($"[AssetSpecs] Built {AssetSpecs.AssetPathFor(specPath)} from {specPath}.");
                return;
            }

            Debug.LogError($"[AssetSpecs] {specPath}:\n- " + string.Join("\n- ", problems));
        }

        private static string SelectedSpecPath()
        {
            if (Selection.activeObject == null)
                return null;

            string path = AssetDatabase.GetAssetPath(Selection.activeObject);
            return path.EndsWith(AssetSpecs.SPEC_SUFFIX, System.StringComparison.Ordinal) ? path : null;
        }
    }
}
