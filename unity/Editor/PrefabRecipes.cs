using System;
using System.Collections.Generic;
using TMPro;
using UnityEditor;
using UnityEngine;
using UnityEngine.UI;
using Object = UnityEngine.Object;

namespace UnityArchitecture.Prefabs
{
    /// <summary>
    /// Builds the standard pieces of a UI prefab already following the rules (architecture/PREFABS.md), so an agent
    /// or a person assembles prefabs from calls instead of setting each value by hand. Each recipe is deterministic:
    /// the same calls build the same hierarchy. Build a root, add pieces, save it, then validate it.
    /// With Screen System, create screens and layers with ScreenAuthoring (SCR-13) and build their content here.
    /// </summary>
    public static class PrefabRecipes
    {
        public const string ACTION = "Action";
        public const string BACKGROUND = "Background";
        public const string VISUALS = "Visuals";
        public const string CONTENT = "Content";
        public const string WINDOW = "Window";

        private static readonly Color CLEAR = new(1f, 1f, 1f, 0f);
        private static readonly Color DIM = new(0f, 0f, 0f, 0.6f);

        /// <summary>A prefab root: stretch, scale 1, rotation 0 (PREFAB-01, PREFAB-02), with its Model and root View.</summary>
        public static GameObject CreateRoot(string name, params Type[] components)
        {
            GameObject root = new(name, typeof(RectTransform));
            ApplyStretch(root);
            foreach (Type component in components)
                root.AddComponent(component);

            return root;
        }

        /// <summary>A screen or layer: root, a Background that blocks touches, and a Content to build in (PREFAB-10, PREFAB-14).</summary>
        public static GameObject CreateScreenRoot(string name, params Type[] components)
        {
            GameObject root = CreateRoot(name, components);
            AddBackground(root);
            AddChild(root, CONTENT);
            return root;
        }

        /// <summary>
        /// A modal: a dimming Background, an optional Action that closes on a tap outside, and a centered Window above
        /// it (PREFAB-11). The Window blocks touches with its own Background, so the close Action only gets taps outside it.
        /// </summary>
        public static GameObject CreateModalRoot(string name, Vector2 windowSize, Type closeController, params Type[] components)
        {
            GameObject root = CreateRoot(name, components);
            AddBackground(root).GetComponent<Image>().color = DIM;
            if (closeController != null)
                AddAction(root, closeController);

            GameObject window = AddChild(root, WINDOW);
            ApplyPoint(window, new Vector2(0.5f, 0.5f), windowSize, Vector2.zero);
            AddBackground(window);
            return root;
        }

        /// <summary>A list slot: a root with a fixed size. UI Scroller sets its anchors and pivot.</summary>
        public static GameObject CreateSlotRoot(string name, Vector2 size, params Type[] components)
        {
            GameObject root = CreateRoot(name, components);
            ApplyPoint(root, new Vector2(0f, 1f), size, Vector2.zero);
            root.GetComponent<RectTransform>().pivot = new Vector2(0f, 1f);
            return root;
        }

        /// <summary>A Background with Raycast Target on, first under its parent, so a touch doesn't reach what's under it (PREFAB-14).</summary>
        public static GameObject AddBackground(GameObject parent)
        {
            GameObject background = AddChild(parent, BACKGROUND, typeof(Image));
            background.transform.SetAsFirstSibling();
            IgnoreParentLayout(background);
            return background;
        }

        /// <summary>The Visuals child that a tween scales or rotates, so the root keeps scale 1 (PREFAB-01).</summary>
        public static GameObject AddVisuals(GameObject parent)
        {
            return AddChild(parent, VISUALS);
        }

        /// <summary>An empty stretch child, such as a Container or a state root's parent.</summary>
        public static GameObject AddContainer(GameObject parent, string name)
        {
            return AddChild(parent, name);
        }

        /// <summary>A visual-only Image, with Raycast Target off (INPUT-03).</summary>
        public static Image AddImage(GameObject parent, string name)
        {
            Image image = AddChild(parent, name, typeof(Image)).GetComponent<Image>();
            image.raycastTarget = false;
            return image;
        }

        /// <summary>A TextMeshProUGUI, with Raycast Target off (PREFAB-04, INPUT-03).</summary>
        public static TextMeshProUGUI AddText(GameObject parent, string name, string text)
        {
            TextMeshProUGUI label = AddChild(parent, name, typeof(TextMeshProUGUI)).GetComponent<TextMeshProUGUI>();
            label.text = text;
            label.raycastTarget = false;
            return label;
        }

        /// <summary>
        /// The input object: a child called Action, stretch, last under its parent, with an invisible raycast target and
        /// the Controller (INPUT-01, INPUT-02, PREFAB-09). A BaseClickController is its own Graphic, so it gets no Image.
        /// </summary>
        public static GameObject AddAction(GameObject parent, Type controllerType)
        {
            GameObject action = AddChild(parent, ACTION);
            if (!IsGraphic(controllerType))
            {
                Image image = action.AddComponent<Image>();
                image.color = CLEAR;
                action.GetComponent<CanvasRenderer>().cullTransparentMesh = true;
            }

            action.AddComponent(controllerType);
            action.transform.SetAsLastSibling();
            IgnoreParentLayout(action);
            return action;
        }

        /// <summary>One stretch root per state, named {State}Root, for a View to switch between (STATE-02).</summary>
        public static List<GameObject> AddStateRoots(GameObject parent, params string[] states)
        {
            List<GameObject> roots = new();
            foreach (string state in states)
                roots.Add(AddChild(parent, state + "Root"));

            return roots;
        }

        /// <summary>An instance of another prefab, which stays its own scope (VIEW-03, SCOPE-04).</summary>
        public static GameObject AddNestedPrefab(GameObject parent, string prefabPath)
        {
            GameObject asset = AssetDatabase.LoadAssetAtPath<GameObject>(prefabPath);
            if (asset == null)
                throw new ArgumentException($"No prefab at {prefabPath}.", nameof(prefabPath));

            GameObject instance = (GameObject)PrefabUtility.InstantiatePrefab(asset, parent.transform);
            KeepActionLast(parent.transform);
            return instance;
        }

        /// <summary>Anchors that fill the parent, with no offsets (PREFAB-02).</summary>
        public static void ApplyStretch(GameObject target)
        {
            RectTransform rect = target.GetComponent<RectTransform>();
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            rect.localScale = Vector3.one;
            rect.localRotation = Quaternion.identity;
        }

        /// <summary>A point anchor with a fixed size, for a fixed-size element (PREFAB-02).</summary>
        public static void ApplyPoint(GameObject target, Vector2 anchor, Vector2 size, Vector2 position)
        {
            RectTransform rect = target.GetComponent<RectTransform>();
            rect.anchorMin = anchor;
            rect.anchorMax = anchor;
            rect.pivot = anchor;
            rect.sizeDelta = size;
            rect.anchoredPosition = position;
        }

        /// <summary>Saves the hierarchy as a prefab, destroys the scene copy and returns the validation result.</summary>
        public static List<PrefabViolation> SaveAndValidate(GameObject root, string prefabPath)
        {
            return SaveAndValidate(root, prefabPath, new[] { "Client" });
        }

        public static List<PrefabViolation> SaveAndValidate(GameObject root, string prefabPath, string[] layerAssemblies)
        {
            PrefabUtility.SaveAsPrefabAsset(root, prefabPath, out bool saved);
            Object.DestroyImmediate(root);
            if (!saved)
                throw new InvalidOperationException($"Couldn't save the prefab at {prefabPath}.");

            return PrefabValidator.ValidateAsset(prefabPath, layerAssemblies);
        }

        private static GameObject AddChild(GameObject parent, string name, params Type[] components)
        {
            GameObject child = new(name, typeof(RectTransform));
            child.transform.SetParent(parent.transform, false);
            ApplyStretch(child);
            foreach (Type component in components)
                child.AddComponent(component);

            KeepActionLast(parent.transform);
            return child;
        }

        /// <summary>
        /// Keeps an object that fills its parent out of the parent's layout group (PREFAB-16): a measured slot's
        /// layout group sizes the content, and its Background, Action and overlays still fill the slot.
        /// </summary>
        public static void IgnoreParentLayout(GameObject target)
        {
            Transform parent = target.transform.parent;
            if (parent == null || parent.GetComponent<LayoutGroup>() == null)
                return;

            LayoutElement element = target.GetComponent<LayoutElement>();
            if (element == null)
                element = target.AddComponent<LayoutElement>();

            element.ignoreLayout = true;
        }

        private static void KeepActionLast(Transform parent)
        {
            Transform action = parent.Find(ACTION);
            if (action != null && action.parent.Find(WINDOW) == null)
                action.SetAsLastSibling();
        }

        private static bool IsGraphic(Type type)
        {
            return typeof(Graphic).IsAssignableFrom(type);
        }
    }
}
