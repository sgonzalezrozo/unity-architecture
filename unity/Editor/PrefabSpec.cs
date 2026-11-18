using System;
using System.Collections.Generic;
using UnityEngine;

namespace UnityArchitecture.Prefabs
{
    /// <summary>One object of a prefab spec: the handoff table (HAND-01) as data. See architecture/PREFABS.md.</summary>
    public sealed class PrefabSpecNode
    {
        public const string CONTAINER = "container";
        public const string BACKGROUND = "background";
        public const string VISUALS = "visuals";
        public const string IMAGE = "image";
        public const string TEXT = "text";
        public const string ACTION = "action";
        public const string PREFAB = "prefab";

        private static readonly string[] TYPES = { CONTAINER, BACKGROUND, VISUALS, IMAGE, TEXT, ACTION, PREFAB };

        public string Name;
        public string Type;
        public readonly List<string> Components = new();
        public string Text;
        public Color? Color;
        public string Controller;
        public string PrefabPath;
        public PrefabSpecLayout Layout;
        public readonly Dictionary<string, string> Fields = new();
        public bool IgnoreLayout;
        public readonly List<PrefabSpecNode> Children = new();

        public static PrefabSpecNode Parse(string json)
        {
            if (SpecJson.Parse(json) is not Dictionary<string, object> root)
                throw new FormatException("A spec is a JSON object: the prefab's root.");

            return ReadNode(root, null, true);
        }

        private static PrefabSpecNode ReadNode(Dictionary<string, object> data, string parentPath, bool isRoot)
        {
            PrefabSpecNode node = new() { Type = isRoot ? CONTAINER : ReadString(data, "type", parentPath) };
            if (Array.IndexOf(TYPES, node.Type) < 0)
                throw new FormatException($"{parentPath}: unknown type '{node.Type}'. Use one of: {string.Join(", ", TYPES)}.");

            node.Name = ReadName(data, node.Type, parentPath);
            string path = parentPath == null ? node.Name : parentPath + "/" + node.Name;
            node.Text = Optional(data, "text") as string;
            node.Controller = Optional(data, "controller") as string;
            node.PrefabPath = Optional(data, "prefab") as string;
            node.Color = ReadColor(data, path);
            node.Layout = PrefabSpecLayout.Read(Optional(data, "layout"), path);
            ReadStrings(data, "components", node.Components, path);
            ReadFields(data, node.Fields, path);
            node.IgnoreLayout = Optional(data, "ignoreLayout") is true;
            CheckRequiredFields(node, path);

            if (Optional(data, "children") is List<object> children)
            {
                foreach (object child in children)
                {
                    if (child is not Dictionary<string, object> childData)
                        throw new FormatException($"{path}: each child is a JSON object.");

                    node.Children.Add(ReadNode(childData, path, false));
                }
            }

            return node;
        }

        private static string ReadName(Dictionary<string, object> data, string type, string parentPath)
        {
            string name = Optional(data, "name") as string;
            string fixedName = type switch
            {
                BACKGROUND => PrefabRecipes.BACKGROUND,
                VISUALS => PrefabRecipes.VISUALS,
                ACTION => PrefabRecipes.ACTION,
                _ => null
            };
            if (fixedName != null && name != null && name != fixedName)
                throw new FormatException($"{parentPath}: a {type} is always called {fixedName}, not '{name}'.");

            if (name == null && fixedName == null && type != PREFAB)
                throw new FormatException($"{parentPath ?? "root"}: a {type} needs a name.");

            return name ?? fixedName ?? string.Empty;
        }

        private static void CheckRequiredFields(PrefabSpecNode node, string path)
        {
            if (node.Type == ACTION && string.IsNullOrEmpty(node.Controller))
                throw new FormatException($"{path}: an action needs a controller.");

            if (node.Type == PREFAB && string.IsNullOrEmpty(node.PrefabPath))
                throw new FormatException($"{path}: a prefab needs the path of the prefab to nest.");

            if (node.Type == TEXT && node.Text == null)
                node.Text = string.Empty;
        }

        private static Color? ReadColor(Dictionary<string, object> data, string path)
        {
            if (Optional(data, "color") is not List<object> values)
                return null;

            if (values.Count != 4)
                throw new FormatException($"{path}: color is [r, g, b, a], each from 0 to 1.");

            return new Color(ToFloat(values[0], path), ToFloat(values[1], path), ToFloat(values[2], path), ToFloat(values[3], path));
        }

        private static void ReadStrings(Dictionary<string, object> data, string key, List<string> into, string path)
        {
            if (Optional(data, key) is not List<object> values)
                return;

            foreach (object value in values)
            {
                if (value is not string text)
                    throw new FormatException($"{path}: {key} lists type names as strings.");

                into.Add(text);
            }
        }

        private static void ReadFields(Dictionary<string, object> data, Dictionary<string, string> into, string path)
        {
            object value = Optional(data, "fields");
            if (value == null)
                return;

            if (value is not Dictionary<string, object> fields)
                throw new FormatException($"{path}: fields maps a serialized field to the path of an object under this one: {{\"amountText\": \"Amount\"}}.");

            foreach (KeyValuePair<string, object> field in fields)
            {
                if (field.Value is not string target)
                    throw new FormatException($"{path}: the field {field.Key} points to an object path, as a string.");

                into[field.Key] = target;
            }
        }

        private static string ReadString(Dictionary<string, object> data, string key, string path)
        {
            if (Optional(data, key) is string value)
                return value;

            throw new FormatException($"{path ?? "root"}: a child needs a \"{key}\".");
        }

        private static object Optional(Dictionary<string, object> data, string key)
        {
            return data.TryGetValue(key, out object value) ? value : null;
        }

        internal static float ToFloat(object value, string path)
        {
            if (value is double number)
                return (float)number;

            throw new FormatException($"{path}: expected a number, found '{value}'.");
        }
    }

    /// <summary>How an object sits in its parent: stretch, or a point anchor with a size.</summary>
    public sealed class PrefabSpecLayout
    {
        public bool Stretch;
        public Vector2 Anchor;
        public Vector2 Size;
        public Vector2 Position;
        public Vector2 Pivot;

        internal static PrefabSpecLayout Read(object value, string path)
        {
            switch (value)
            {
                case null:
                    return null;
                case "stretch":
                    return new PrefabSpecLayout { Stretch = true };
                case Dictionary<string, object> data:
                    Vector2 anchor = ReadVector(data, "anchor", path, null);
                    return new PrefabSpecLayout
                    {
                        Anchor = anchor,
                        Size = ReadVector(data, "size", path, null),
                        Position = ReadVector(data, "position", path, Vector2.zero),
                        Pivot = ReadVector(data, "pivot", path, anchor)
                    };
                default:
                    throw new FormatException($"{path}: layout is \"stretch\" or {{\"anchor\": [x, y], \"size\": [w, h]}}.");
            }
        }

        private static Vector2 ReadVector(Dictionary<string, object> data, string key, string path, Vector2? fallback)
        {
            if (!data.TryGetValue(key, out object value))
            {
                if (fallback.HasValue)
                    return fallback.Value;

                throw new FormatException($"{path}: layout needs \"{key}\": [x, y].");
            }

            if (value is not List<object> values || values.Count != 2)
                throw new FormatException($"{path}: layout \"{key}\" is [x, y].");

            return new Vector2(PrefabSpecNode.ToFloat(values[0], path), PrefabSpecNode.ToFloat(values[1], path));
        }
    }
}
