using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Text;
using UnityEditor;
using UnityEngine;

namespace UnityArchitecture.Prefabs
{
    /// <summary>
    /// Builds a data asset (a ScriptableObject, such as a feature's configuration) from a JSON spec next to it, so an
    /// agent never writes .asset YAML (EDIT-06, EDIT-14). The spec Services/Resources/ShopConfig.asset.json describes
    /// Services/Resources/ShopConfig.asset: { "type": "Client.Shop.ShopConfig", "values": { ... } }. Values use the
    /// serialized field names, enums as their number, as JsonUtility reads them. The same spec always builds the same
    /// asset, and Compare lists every value that differs.
    /// </summary>
    public static class AssetSpecs
    {
        public const string SPEC_SUFFIX = ".asset.json";
        private const string RESULTS_FILE = "Logs/verify/asset-specs.txt";

        /// <summary>The asset a spec describes: the spec's path without ".json".</summary>
        public static string AssetPathFor(string specPath)
        {
            return specPath.Substring(0, specPath.Length - ".json".Length);
        }

        /// <summary>Creates or updates the spec's asset. Returns the problems found, empty when it built and matches.</summary>
        public static List<string> Build(string specPath)
        {
            List<string> problems = new();
            if (!TryRead(specPath, problems, out Type type, out string valuesJson))
                return problems;

            string assetPath = AssetPathFor(specPath);
            ScriptableObject existing = AssetDatabase.LoadAssetAtPath<ScriptableObject>(assetPath);
            if (existing != null && existing.GetType() != type)
            {
                problems.Add($"{assetPath} is a {existing.GetType().FullName}, not the spec's {type.FullName}");
                return problems;
            }

            ScriptableObject asset = existing != null ? existing : ScriptableObject.CreateInstance(type);
            JsonUtility.FromJsonOverwrite(valuesJson, asset);
            if (existing == null)
                AssetDatabase.CreateAsset(asset, assetPath);
            else
                EditorUtility.SetDirty(asset);
            AssetDatabase.SaveAssets();

            problems.AddRange(Compare(specPath));
            return problems;
        }

        /// <summary>
        /// Every value in the spec that the asset doesn't have: a field that doesn't exist (JsonUtility ignores it
        /// silently), a different value, or a missing asset. Empty when they match.
        /// </summary>
        public static List<string> Compare(string specPath)
        {
            List<string> differences = new();
            if (!TryRead(specPath, differences, out Type type, out string _))
                return differences;

            string assetPath = AssetPathFor(specPath);
            ScriptableObject asset = AssetDatabase.LoadAssetAtPath<ScriptableObject>(assetPath);
            if (asset == null || asset.GetType() != type)
            {
                differences.Add($"{assetPath}: no {type.FullName} asset");
                return differences;
            }

            Dictionary<string, object> expected = (Dictionary<string, object>)((Dictionary<string, object>)SpecJson.Parse(File.ReadAllText(specPath)))["values"];
            object actual = SpecJson.Parse(JsonUtility.ToJson(asset));
            CompareValue("values", expected, actual, differences);
            return differences;
        }

        /// <summary>Builds every spec under the folder that has no asset yet. Returns the problems by spec path.</summary>
        public static Dictionary<string, List<string>> BuildMissing(string folder)
        {
            Dictionary<string, List<string>> results = new();
            if (!Directory.Exists(folder))
                return results;

            string[] specs = Directory.GetFiles(folder, "*" + SPEC_SUFFIX, SearchOption.AllDirectories);
            Array.Sort(specs, StringComparer.Ordinal);
            foreach (string spec in specs)
            {
                string specPath = spec.Replace('\\', '/');
                if (File.Exists(AssetPathFor(specPath)))
                    continue;

                results[specPath] = Build(specPath);
            }

            return results;
        }

        /// <summary>
        /// For scripts/verify.sh: builds the missing assets under Assets/Client, writes the result to
        /// Logs/verify/asset-specs.txt and exits with 1 when one failed.
        /// </summary>
        public static void BuildMissingFromCommandLine()
        {
            Dictionary<string, List<string>> results = BuildMissing(PrefabValidator.CLIENT_FOLDER);
            StringBuilder report = new();
            bool failed = false;
            foreach (KeyValuePair<string, List<string>> result in results)
            {
                failed |= result.Value.Count > 0;
                report.AppendLine(result.Value.Count == 0 ? $"built {AssetPathFor(result.Key)}" : $"failed {result.Key}");
                foreach (string problem in result.Value)
                    report.AppendLine("  " + problem);
            }

            Directory.CreateDirectory(Path.GetDirectoryName(RESULTS_FILE) ?? "Logs");
            File.WriteAllText(RESULTS_FILE, report.ToString());
            Debug.Log("[AssetSpecs]\n" + report);
            EditorApplication.Exit(failed ? 1 : 0);
        }

        private static bool TryRead(string specPath, List<string> problems, out Type type, out string valuesJson)
        {
            type = null;
            valuesJson = null;
            if (!specPath.EndsWith(SPEC_SUFFIX, StringComparison.Ordinal))
            {
                problems.Add($"{specPath}: a data asset spec ends with {SPEC_SUFFIX}");
                return false;
            }

            if (!File.Exists(specPath))
            {
                problems.Add($"{specPath}: not found");
                return false;
            }

            Dictionary<string, object> spec;
            try
            {
                spec = SpecJson.Parse(File.ReadAllText(specPath)) as Dictionary<string, object>;
            }
            catch (FormatException exception)
            {
                problems.Add($"{specPath}: {exception.Message}");
                return false;
            }

            if (spec == null || !(spec.TryGetValue("type", out object typeName) && typeName is string) || !(spec.TryGetValue("values", out object values) && values is Dictionary<string, object>))
            {
                problems.Add($"{specPath}: needs \"type\" (a string) and \"values\" (an object)");
                return false;
            }

            type = FindType((string)typeName);
            if (type == null || !typeof(ScriptableObject).IsAssignableFrom(type) || type.IsAbstract)
            {
                problems.Add($"{specPath}: {typeName} isn't a concrete ScriptableObject type in the project");
                return false;
            }

            valuesJson = Write(values);
            return true;
        }

        private static Type FindType(string fullName)
        {
            foreach (System.Reflection.Assembly assembly in AppDomain.CurrentDomain.GetAssemblies())
            {
                Type type = assembly.GetType(fullName, false);
                if (type != null)
                    return type;
            }

            return null;
        }

        private static void CompareValue(string path, object expected, object actual, List<string> differences)
        {
            if (expected is Dictionary<string, object> expectedObject)
            {
                if (actual is not Dictionary<string, object> actualObject)
                {
                    differences.Add($"{path}: expected an object");
                    return;
                }

                foreach (KeyValuePair<string, object> field in expectedObject)
                {
                    if (!actualObject.TryGetValue(field.Key, out object actualField))
                        differences.Add($"{path}.{field.Key}: no such serialized field");
                    else
                        CompareValue(path + "." + field.Key, field.Value, actualField, differences);
                }

                return;
            }

            if (expected is List<object> expectedList)
            {
                if (actual is not List<object> actualList || actualList.Count != expectedList.Count)
                {
                    differences.Add($"{path}: expected {expectedList.Count} elements");
                    return;
                }

                for (int i = 0; i < expectedList.Count; i++)
                    CompareValue($"{path}[{i}]", expectedList[i], actualList[i], differences);
                return;
            }

            if (!Equals(expected, actual) && !(expected is double expectedNumber && actual is double actualNumber && Math.Abs(expectedNumber - actualNumber) < 1e-6))
                differences.Add($"{path}: expected {Write(expected)}, is {Write(actual)}");
        }

        // JSON text for the values SpecJson reads: objects, arrays, strings, numbers, booleans and null.
        private static string Write(object value)
        {
            StringBuilder builder = new();
            Write(value, builder);
            return builder.ToString();
        }

        private static void Write(object value, StringBuilder builder)
        {
            switch (value)
            {
                case null:
                    builder.Append("null");
                    break;
                case string text:
                    builder.Append('"');
                    foreach (char character in text)
                    {
                        switch (character)
                        {
                            case '"': builder.Append("\\\""); break;
                            case '\\': builder.Append("\\\\"); break;
                            case '\n': builder.Append("\\n"); break;
                            case '\r': builder.Append("\\r"); break;
                            case '\t': builder.Append("\\t"); break;
                            default:
                                if (character < ' ')
                                    builder.Append("\\u").Append(((int)character).ToString("x4", CultureInfo.InvariantCulture));
                                else
                                    builder.Append(character);
                                break;
                        }
                    }

                    builder.Append('"');
                    break;
                case bool flag:
                    builder.Append(flag ? "true" : "false");
                    break;
                case double number:
                    builder.Append(number.ToString("R", CultureInfo.InvariantCulture));
                    break;
                case Dictionary<string, object> map:
                    builder.Append('{');
                    bool first = true;
                    foreach (KeyValuePair<string, object> field in map)
                    {
                        if (!first)
                            builder.Append(',');
                        first = false;
                        Write(field.Key, builder);
                        builder.Append(':');
                        Write(field.Value, builder);
                    }

                    builder.Append('}');
                    break;
                case IList list:
                    builder.Append('[');
                    for (int i = 0; i < list.Count; i++)
                    {
                        if (i > 0)
                            builder.Append(',');
                        Write(list[i], builder);
                    }

                    builder.Append(']');
                    break;
                default:
                    builder.Append(Convert.ToString(value, CultureInfo.InvariantCulture));
                    break;
            }
        }
    }
}
