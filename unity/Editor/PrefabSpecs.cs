using System;
using System.Collections.Generic;
using TMPro;
using UnityEditor;
using UnityEngine;
using UnityEngine.UI;

namespace UnityArchitecture.Prefabs
{
    /// <summary>
    /// Builds a prefab from a spec with the recipes, and compares a built prefab with its spec. The spec lists the
    /// whole hierarchy in order, like the handoff table, so the same spec always builds the same prefab.
    /// Component and controller names are class names in the given assemblies (Client by default).
    /// </summary>
    public static class PrefabSpecs
    {
        private const float TOLERANCE = 0.01f;
        private static readonly string[] CLIENT_ASSEMBLY = { "Client" };

        public static List<PrefabViolation> BuildFromSpec(string json, string prefabPath)
        {
            return BuildFromSpec(json, prefabPath, CLIENT_ASSEMBLY);
        }

        /// <summary>Builds the spec, saves it at prefabPath and returns the validator's result.</summary>
        public static List<PrefabViolation> BuildFromSpec(string json, string prefabPath, string[] layerAssemblies)
        {
            GameObject root = Build(PrefabSpecNode.Parse(json), layerAssemblies);
            return PrefabRecipes.SaveAndValidate(root, prefabPath, layerAssemblies);
        }

        /// <summary>Builds the spec in the open scene, without saving it.</summary>
        public static GameObject Build(PrefabSpecNode spec, string[] layerAssemblies)
        {
            GameObject root = PrefabRecipes.CreateRoot(spec.Name, ResolveAll(spec.Components, layerAssemblies));
            try
            {
                ApplyLayout(root, spec.Layout);
                BuildChildren(root, spec, layerAssemblies);
                return root;
            }
            catch
            {
                UnityEngine.Object.DestroyImmediate(root);
                throw;
            }
        }

        public static List<string> Compare(string json, string prefabPath)
        {
            return Compare(json, prefabPath, CLIENT_ASSEMBLY);
        }

        /// <summary>The differences between a spec and the prefab built from it. Empty when they match.</summary>
        public static List<string> Compare(string json, string prefabPath, string[] layerAssemblies)
        {
            PrefabSpecNode spec = PrefabSpecNode.Parse(json);
            GameObject root = PrefabUtility.LoadPrefabContents(prefabPath);
            try
            {
                List<string> differences = new();
                CompareNode(spec, root, root.name, layerAssemblies, differences);
                return differences;
            }
            finally
            {
                PrefabUtility.UnloadPrefabContents(root);
            }
        }

        private static void BuildChildren(GameObject parent, PrefabSpecNode spec, string[] layerAssemblies)
        {
            // Recipes reorder some pieces (Background first, Action last); the spec's order wins, so set it at the end.
            List<GameObject> children = new();
            foreach (PrefabSpecNode childSpec in spec.Children)
            {
                GameObject child = BuildNode(parent, childSpec, layerAssemblies);
                foreach (Type component in ResolveAll(childSpec.Components, layerAssemblies))
                    child.AddComponent(component);

                ApplyLayout(child, childSpec.Layout);
                children.Add(child);
            }

            for (int i = 0; i < children.Count; i++)
            {
                children[i].transform.SetSiblingIndex(i);
                if (spec.Children[i].Type != PrefabSpecNode.PREFAB)
                    BuildChildren(children[i], spec.Children[i], layerAssemblies);
            }
        }

        private static GameObject BuildNode(GameObject parent, PrefabSpecNode spec, string[] layerAssemblies)
        {
            switch (spec.Type)
            {
                case PrefabSpecNode.BACKGROUND:
                    return Colored(PrefabRecipes.AddBackground(parent), spec.Color);
                case PrefabSpecNode.VISUALS:
                    return PrefabRecipes.AddVisuals(parent);
                case PrefabSpecNode.IMAGE:
                    return Colored(PrefabRecipes.AddImage(parent, spec.Name).gameObject, spec.Color);
                case PrefabSpecNode.TEXT:
                    return PrefabRecipes.AddText(parent, spec.Name, spec.Text).gameObject;
                case PrefabSpecNode.ACTION:
                    return PrefabRecipes.AddAction(parent, Resolve(spec.Controller, layerAssemblies));
                case PrefabSpecNode.PREFAB:
                    return NestedPrefab(parent, spec);
                default:
                    return PrefabRecipes.AddContainer(parent, spec.Name);
            }
        }

        private static GameObject NestedPrefab(GameObject parent, PrefabSpecNode spec)
        {
            GameObject instance = PrefabRecipes.AddNestedPrefab(parent, spec.PrefabPath);
            if (!string.IsNullOrEmpty(spec.Name))
                instance.name = spec.Name;

            return instance;
        }

        private static GameObject Colored(GameObject target, Color? color)
        {
            if (color.HasValue)
                target.GetComponent<Image>().color = color.Value;

            return target;
        }

        private static void ApplyLayout(GameObject target, PrefabSpecLayout layout)
        {
            if (layout == null)
                return;

            if (layout.Stretch)
            {
                PrefabRecipes.ApplyStretch(target);
                return;
            }

            PrefabRecipes.ApplyPoint(target, layout.Anchor, layout.Size, layout.Position);
            target.GetComponent<RectTransform>().pivot = layout.Pivot;
        }

        private static void CompareNode(PrefabSpecNode spec, GameObject actual, string path, string[] layerAssemblies, List<string> differences)
        {
            if (!string.IsNullOrEmpty(spec.Name) && actual.name != spec.Name)
                differences.Add($"{path}: expected the name {spec.Name}, found {actual.name}.");

            CompareType(spec, actual, path, differences);
            foreach (string component in spec.Components)
            {
                if (!HasComponentNamed(actual, component))
                    differences.Add($"{path}: expected a {component} component.");
            }

            CompareLayout(spec.Layout, actual.GetComponent<RectTransform>(), path, differences);
            if (spec.Type != PrefabSpecNode.PREFAB)
                CompareChildren(spec, actual, path, layerAssemblies, differences);
        }

        private static void CompareChildren(PrefabSpecNode spec, GameObject actual, string path, string[] layerAssemblies, List<string> differences)
        {
            Transform transform = actual.transform;
            if (transform.childCount != spec.Children.Count)
                differences.Add($"{path}: expected {spec.Children.Count} children ({Names(spec)}), found {transform.childCount} ({Names(transform)}).");

            int count = Math.Min(transform.childCount, spec.Children.Count);
            for (int i = 0; i < count; i++)
            {
                GameObject child = transform.GetChild(i).gameObject;
                CompareNode(spec.Children[i], child, path + "/" + child.name, layerAssemblies, differences);
            }
        }

        private static void CompareType(PrefabSpecNode spec, GameObject actual, string path, List<string> differences)
        {
            switch (spec.Type)
            {
                case PrefabSpecNode.BACKGROUND:
                    CompareImage(actual, true, spec.Color, path, differences);
                    break;
                case PrefabSpecNode.IMAGE:
                    CompareImage(actual, false, spec.Color, path, differences);
                    break;
                case PrefabSpecNode.TEXT:
                    TextMeshProUGUI text = actual.GetComponent<TextMeshProUGUI>();
                    if (text == null || text.text != spec.Text)
                        differences.Add($"{path}: expected the text \"{spec.Text}\", found {(text == null ? "no TextMeshProUGUI" : $"\"{text.text}\"")}.");
                    break;
                case PrefabSpecNode.ACTION:
                    if (!HasComponentNamed(actual, spec.Controller))
                        differences.Add($"{path}: expected the controller {spec.Controller}.");
                    break;
                case PrefabSpecNode.PREFAB:
                    GameObject source = PrefabUtility.GetCorrespondingObjectFromSource(actual);
                    string sourcePath = source == null ? null : AssetDatabase.GetAssetPath(source);
                    if (sourcePath != spec.PrefabPath)
                        differences.Add($"{path}: expected an instance of {spec.PrefabPath}, found {sourcePath ?? "no prefab instance"}.");
                    break;
            }
        }

        private static void CompareImage(GameObject actual, bool raycastTarget, Color? color, string path, List<string> differences)
        {
            Image image = actual.GetComponent<Image>();
            if (image == null)
            {
                differences.Add($"{path}: expected an Image.");
                return;
            }

            if (image.raycastTarget != raycastTarget)
                differences.Add($"{path}: expected Raycast Target {(raycastTarget ? "on" : "off")}.");

            if (color.HasValue && !Approximately(image.color, color.Value))
                differences.Add($"{path}: expected the color {color.Value}, found {image.color}.");
        }

        private static void CompareLayout(PrefabSpecLayout layout, RectTransform rect, string path, List<string> differences)
        {
            if (layout == null || rect == null)
                return;

            if (layout.Stretch)
            {
                if (!Approximately(rect.anchorMin, Vector2.zero) || !Approximately(rect.anchorMax, Vector2.one) || !Approximately(rect.offsetMin, Vector2.zero) || !Approximately(rect.offsetMax, Vector2.zero))
                    differences.Add($"{path}: expected stretch anchors with no offsets.");
                return;
            }

            CompareVector("anchor", layout.Anchor, rect.anchorMin, path, differences);
            CompareVector("anchor", layout.Anchor, rect.anchorMax, path, differences);
            CompareVector("size", layout.Size, rect.sizeDelta, path, differences);
            CompareVector("position", layout.Position, rect.anchoredPosition, path, differences);
            CompareVector("pivot", layout.Pivot, rect.pivot, path, differences);
        }

        private static void CompareVector(string field, Vector2 expected, Vector2 actual, string path, List<string> differences)
        {
            if (!Approximately(expected, actual))
                differences.Add($"{path}: expected {field} {expected}, found {actual}.");
        }

        private static bool Approximately(Vector2 a, Vector2 b)
        {
            return Mathf.Abs(a.x - b.x) <= TOLERANCE && Mathf.Abs(a.y - b.y) <= TOLERANCE;
        }

        private static bool Approximately(Color a, Color b)
        {
            return Mathf.Abs(a.r - b.r) <= TOLERANCE && Mathf.Abs(a.g - b.g) <= TOLERANCE && Mathf.Abs(a.b - b.b) <= TOLERANCE && Mathf.Abs(a.a - b.a) <= TOLERANCE;
        }

        private static bool HasComponentNamed(GameObject target, string typeName)
        {
            foreach (Component component in target.GetComponents<Component>())
            {
                if (component != null && (component.GetType().Name == typeName || component.GetType().FullName == typeName))
                    return true;
            }

            return false;
        }

        private static Type[] ResolveAll(List<string> names, string[] layerAssemblies)
        {
            Type[] types = new Type[names.Count];
            for (int i = 0; i < names.Count; i++)
                types[i] = Resolve(names[i], layerAssemblies);

            return types;
        }

        private static Type Resolve(string typeName, string[] layerAssemblies)
        {
            foreach (System.Reflection.Assembly assembly in AppDomain.CurrentDomain.GetAssemblies())
            {
                if (Array.IndexOf(layerAssemblies, assembly.GetName().Name) < 0)
                    continue;

                foreach (Type type in assembly.GetTypes())
                {
                    if ((type.Name == typeName || type.FullName == typeName) && typeof(Component).IsAssignableFrom(type))
                        return type;
                }
            }

            throw new ArgumentException($"No component called {typeName} in {string.Join(", ", layerAssemblies)}.");
        }

        private static string Names(PrefabSpecNode spec)
        {
            List<string> names = new();
            foreach (PrefabSpecNode child in spec.Children)
                names.Add(child.Name);

            return string.Join(", ", names);
        }

        private static string Names(Transform transform)
        {
            List<string> names = new();
            foreach (Transform child in transform)
                names.Add(child.name);

            return string.Join(", ", names);
        }
    }
}
