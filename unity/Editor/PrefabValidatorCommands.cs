using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace UnityArchitecture.Prefabs
{
    /// <summary>
    /// Runs the prefab validator on every prefab under Assets/Client: from a menu, or from the command line with
    /// Unity -batchmode -projectPath . -executeMethod UnityArchitecture.Prefabs.PrefabValidatorCommands.ValidateFromCommandLine
    /// which exits with 0 when no prefab has an error, and 1 otherwise.
    /// </summary>
    public static class PrefabValidatorCommands
    {
        [MenuItem("Tools/Unity Architecture/Validate Client Prefabs")]
        public static void ValidateFromMenu()
        {
            List<string> errors = ValidateClientPrefabs(out int prefabCount);
            if (errors.Count == 0)
            {
                Debug.Log($"[Unity Architecture] {prefabCount} prefabs under {PrefabValidator.CLIENT_FOLDER} follow the prefab rules.");
                return;
            }

            Debug.LogError($"[Unity Architecture] {errors.Count} prefab rule errors:\n{string.Join("\n", errors)}");
        }

        public static void ValidateFromCommandLine()
        {
            List<string> errors = ValidateClientPrefabs(out int prefabCount);
            foreach (string error in errors)
                Debug.LogError(error);

            Debug.Log($"[Unity Architecture] Validated {prefabCount} prefabs: {errors.Count} errors.");
            EditorApplication.Exit(errors.Count == 0 ? 0 : 1);
        }

        private static List<string> ValidateClientPrefabs(out int prefabCount)
        {
            List<string> errors = new();
            List<string> prefabs = PrefabValidator.FindClientPrefabs();
            foreach (string path in prefabs)
            {
                foreach (PrefabViolation violation in PrefabValidator.ValidateAsset(path))
                {
                    if (!violation.IsWarning)
                        errors.Add(violation.ToString());
                }
            }

            prefabCount = prefabs.Count;
            return errors;
        }
    }
}
