using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using Object = UnityEngine.Object;

namespace UnityArchitecture.Prefabs
{
    /// <summary>
    /// Checks a UI prefab against the rules a tool can check (architecture/PREFABS.md, UI_PATTERNS.md, MVC.md).
    /// A nested prefab is another scope: its insides aren't checked here, since it's validated as its own asset,
    /// and references into it are violations. Models, Views and Controllers are recognized by their class name,
    /// like the analyzers, and only in the given assemblies (Client by default).
    /// </summary>
    public static class PrefabValidator
    {
        public const string CLIENT_FOLDER = "Assets/Client";
        public const int MAX_DEPTH = 5;

        private const string ACTION = "Action";
        private const string BACKGROUND = "Background";
        private const string TMP_INPUT_FIELD = "TMPro.TMP_InputField";
        private const string BASE_CLICK_CONTROLLER = "UIFoundations.BaseClickController";

        private static readonly string[] CLIENT_ASSEMBLY = { "Client" };

        /// <summary>The prefabs under Assets/Client, the project's own UI.</summary>
        public static List<string> FindClientPrefabs()
        {
            List<string> paths = new();
            foreach (string guid in AssetDatabase.FindAssets("t:Prefab", new[] { CLIENT_FOLDER }))
                paths.Add(AssetDatabase.GUIDToAssetPath(guid));

            paths.Sort(StringComparer.Ordinal);
            return paths;
        }

        public static List<PrefabViolation> ValidateAsset(string assetPath)
        {
            return ValidateAsset(assetPath, CLIENT_ASSEMBLY);
        }

        public static List<PrefabViolation> ValidateAsset(string assetPath, string[] layerAssemblies)
        {
            GameObject root = PrefabUtility.LoadPrefabContents(assetPath);
            try
            {
                List<PrefabViolation> violations = Validate(root, layerAssemblies);
                for (int i = 0; i < violations.Count; i++)
                {
                    PrefabViolation violation = violations[i];
                    violations[i] = new PrefabViolation(violation.RuleId, assetPath + ": " + violation.ObjectPath, violation.Message, violation.IsWarning);
                }

                return violations;
            }
            finally
            {
                PrefabUtility.UnloadPrefabContents(root);
            }
        }

        public static List<PrefabViolation> Validate(GameObject root)
        {
            return Validate(root, CLIENT_ASSEMBLY);
        }

        public static List<PrefabViolation> Validate(GameObject root, string[] layerAssemblies)
        {
            Check check = new(root, layerAssemblies);
            check.Run();
            return check.Violations;
        }

        private sealed class Check
        {
            public readonly List<PrefabViolation> Violations = new();

            private readonly GameObject root;
            private readonly string[] layerAssemblies;
            private bool hasView;
            private bool rootHasView;

            public Check(GameObject root, string[] layerAssemblies)
            {
                this.root = root;
                this.layerAssemblies = layerAssemblies;
            }

            public void Run()
            {
                CheckRootTransform();
                Visit(root.transform, 0);

                if (hasView && !rootHasView)
                    Error("VIEW-03", root, "Views are below the root but the root has no View. The root View subscribes and tells the inner Views what to show.");
            }

            private void Visit(Transform current, int depth)
            {
                if (current != root.transform && IsNestedPrefab(current.gameObject))
                    return;

                if (depth == MAX_DEPTH + 1)
                    Warning("PREFAB-13", current.gameObject, $"More than {MAX_DEPTH} levels under the root. Flatten it, or justify it in the handoff.");

                CheckObject(current.gameObject);
                foreach (Transform child in current)
                    Visit(child, depth + 1);
            }

            private void CheckObject(GameObject target)
            {
                if (target.name == ACTION)
                    CheckAction(target);

                if (target.name == ACTION || target.name == BACKGROUND)
                    CheckIgnoresParentLayout(target);

                foreach (Component component in target.GetComponents<Component>())
                {
                    if (component == null)
                        continue;

                    CheckComponent(target, component);
                    CheckPersistentListeners(target, component);
                    if (component is MonoBehaviour)
                        CheckReferencesIntoNestedPrefabs(target, component);

                    if (component is MonoBehaviour && IsLayerType(component))
                        CheckReferencesAssigned(target, component);
                }
            }

            private void CheckRootTransform()
            {
                Transform transform = root.transform;
                if (transform.localScale != Vector3.one || transform.localRotation != Quaternion.identity)
                    Error("PREFAB-01", root, "The root has scale (1,1,1) and rotation 0. Scale or rotate a Visuals child instead.");
            }

            private void CheckComponent(GameObject target, Component component)
            {
                switch (component)
                {
                    case Text:
                        Error("PREFAB-04", target, "Use TextMeshProUGUI, not UnityEngine.UI.Text.");
                        break;
                    case Animator:
                    case Animation:
                        Error("PREFAB-05", target, "No Animator or Animation in UI. A View or a layer starts a tween.");
                        break;
                    case EventTrigger:
                        Error("PREFAB-06", target, "No EventTrigger. A Controller on an Action object handles input.");
                        break;
                    case Selectable when !IsType(component, TMP_INPUT_FIELD):
                        Error("ARCH-05", target, $"{component.GetType().Name} is a View and a Controller in one component. Use visuals plus an Action with a Controller.");
                        break;
                    case Mask:
                        Warning("PREFAB-07", target, "Use RectMask2D for rectangular clipping. Mask is only for shapes that aren't rectangles.");
                        break;
                    case Graphic graphic:
                        CheckRaycastTarget(target, graphic);
                        break;
                }

                CheckLayerComponent(target, component);
            }

            private void CheckLayerComponent(GameObject target, Component component)
            {
                if (!IsLayerType(component))
                    return;

                string name = component.GetType().Name;
                bool isRoot = target == root;
                if (IsModel(name) && !isRoot)
                    Error("SCOPE-02", target, $"{name} is a Model: it sits on the scope root.");

                if (name.EndsWith("View", StringComparison.Ordinal))
                {
                    hasView = true;
                    rootHasView |= isRoot;
                }

                if (IsController(component) && !isRoot && target.name != ACTION)
                    Error("INPUT-01", target, $"{name} sits on a child called Action, separate from the visuals.");
            }

            private void CheckAction(GameObject action)
            {
                Transform transform = action.transform;
                if (transform.parent != null && !OnlyBlockersAbove(transform))
                    Error("INPUT-02", action, "Action is the last sibling, so it receives the touch first. Only a panel with its own blocking Background, like a modal's Window, may sit above it.");

                if (!HasController(action))
                    Error("INPUT-01", action, "Action has no Controller.");

                CheckActionGraphic(action);
                CheckBlockingBackground(transform);
            }

            // A modal's close Action sits under its Window (PREFAB-11): what's above it must block touches itself.
            private static bool OnlyBlockersAbove(Transform action)
            {
                Transform parent = action.parent;
                for (int i = action.GetSiblingIndex() + 1; i < parent.childCount; i++)
                {
                    Transform above = parent.GetChild(i);
                    Transform background = above.name == BACKGROUND ? above : above.Find(BACKGROUND);
                    Graphic graphic = background != null ? background.GetComponent<Graphic>() : null;
                    if (graphic == null || !graphic.raycastTarget)
                        return false;
                }

                return true;
            }

            private void CheckIgnoresParentLayout(GameObject target)
            {
                Transform parent = target.transform.parent;
                if (parent == null || parent.GetComponent<LayoutGroup>() == null)
                    return;

                LayoutElement element = target.GetComponent<LayoutElement>();
                if (element == null || !element.ignoreLayout)
                    Error("PREFAB-16", target, $"{target.name} fills its parent, so it ignores the parent's layout group: add a LayoutElement with Ignore Layout on.");
            }

            private void CheckActionGraphic(GameObject action)
            {
                // A Controller that is its own Graphic, like BaseClickController, is the raycast target.
                if (HasInputGraphic(action))
                    return;

                Image image = action.GetComponent<Image>();
                if (image == null || !image.raycastTarget)
                {
                    Error("INPUT-02", action, "Action has its own raycast target: an Image with Raycast Target on.");
                    return;
                }

                CanvasRenderer canvasRenderer = action.GetComponent<CanvasRenderer>();
                if (image.color.a > 0f || canvasRenderer == null || !canvasRenderer.cullTransparentMesh)
                    Error("PREFAB-09", action, "The Action Image has alpha 0 and Cull Transparent Mesh on, so it draws nothing.");
            }

            private void CheckBlockingBackground(Transform action)
            {
                if (action.parent == null)
                    return;

                Transform background = action.parent.Find(BACKGROUND);
                if (background == null)
                    return;

                Graphic graphic = background.GetComponent<Graphic>();
                if (graphic != null && !graphic.raycastTarget)
                    Error("PREFAB-14", background.gameObject, "The Background of an element with an Action has Raycast Target on, so a touch doesn't reach what's under it.");
            }

            private void CheckRaycastTarget(GameObject target, Graphic graphic)
            {
                if (!graphic.raycastTarget || target.name == ACTION || target.name == BACKGROUND)
                    return;

                if (ReceivesInput(target))
                    return;

                Error("INPUT-03", target, "Visual-only Graphics have Raycast Target off. Only Action and a blocking Background have it on.");
            }

            private void CheckPersistentListeners(GameObject target, Component component)
            {
                SerializedProperty property = new SerializedObject(component).GetIterator();
                while (property.Next(true))
                {
                    if (property.isArray && property.propertyPath.EndsWith("m_PersistentCalls.m_Calls", StringComparison.Ordinal) && property.arraySize > 0)
                    {
                        Error("PREFAB-06", target, $"{component.GetType().Name} has persistent UnityEvent listeners. A Controller handles input.");
                        return;
                    }
                }
            }

            private void CheckReferencesIntoNestedPrefabs(GameObject target, Component component)
            {
                SerializedProperty property = new SerializedObject(component).GetIterator();
                while (property.NextVisible(true))
                {
                    if (property.propertyType != SerializedPropertyType.ObjectReference || !IsInsideNestedPrefab(property.objectReferenceValue))
                        continue;

                    Error("SCOPE-04", target, $"{component.GetType().Name}.{property.name} points inside a nested prefab, which is another scope. Its own root View renders it.");
                }
            }

            private void CheckReferencesAssigned(GameObject target, Component component)
            {
                // Only the fields the project's own classes declare: Unity's optional ones, like a Graphic's m_Material, aren't.
                SerializedProperty property = new SerializedObject(component).GetIterator();
                while (property.NextVisible(true))
                {
                    if (property.depth != 0 || property.propertyType != SerializedPropertyType.ObjectReference || property.objectReferenceValue != null)
                        continue;

                    if (IsDeclaredInLayerType(component.GetType(), property.name))
                        Error("PREFAB-15", target, $"{component.GetType().Name}.{property.name} isn't assigned. Assign it in the prefab, or in the spec's fields.");
                }
            }

            private bool IsDeclaredInLayerType(Type type, string fieldName)
            {
                const System.Reflection.BindingFlags FLAGS = System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.DeclaredOnly;
                for (Type current = type; current != null; current = current.BaseType)
                {
                    if (current.GetField(fieldName, FLAGS) != null)
                        return Array.IndexOf(layerAssemblies, current.Assembly.GetName().Name) >= 0;
                }

                return false;
            }

            private bool IsInsideNestedPrefab(Object referenced)
            {
                GameObject target = referenced switch
                {
                    GameObject gameObject => gameObject,
                    Component component => component.gameObject,
                    _ => null
                };
                if (target == null || !target.transform.IsChildOf(root.transform))
                    return false;

                // The nested prefab's root GameObject or Transform may be shown or hidden; its components and insides are its own.
                bool isNestedRootObject = IsNestedPrefab(target) && (referenced is GameObject || referenced is Transform);
                for (Transform current = target.transform; current != root.transform; current = current.parent)
                {
                    if (IsNestedPrefab(current.gameObject))
                        return !isNestedRootObject || current != target.transform;
                }

                return false;
            }

            private bool IsNestedPrefab(GameObject target)
            {
                return target != root && PrefabUtility.IsAnyPrefabInstanceRoot(target);
            }

            private bool HasController(GameObject target)
            {
                foreach (Component component in target.GetComponents<Component>())
                {
                    if (component != null && IsLayerType(component) && IsController(component))
                        return true;
                }

                return HasComponentOfType(target, BASE_CLICK_CONTROLLER);
            }

            private bool IsLayerType(Component component)
            {
                string assembly = component.GetType().Assembly.GetName().Name;
                return Array.IndexOf(layerAssemblies, assembly) >= 0;
            }

            private void Error(string ruleId, GameObject target, string message)
            {
                Violations.Add(new PrefabViolation(ruleId, PathOf(target), message, false));
            }

            private void Warning(string ruleId, GameObject target, string message)
            {
                Violations.Add(new PrefabViolation(ruleId, PathOf(target), message, true));
            }

            private string PathOf(GameObject target)
            {
                string path = target.name;
                for (Transform current = target.transform.parent; current != null; current = current.parent)
                    path = current.name + "/" + path;

                return path;
            }
        }

        private static bool IsModel(string typeName)
        {
            return typeName.EndsWith("Model", StringComparison.Ordinal) || typeName.EndsWith("Module", StringComparison.Ordinal);
        }

        private static bool IsController(Component component)
        {
            return component.GetType().Name.EndsWith("Controller", StringComparison.Ordinal) || IsType(component, BASE_CLICK_CONTROLLER);
        }

        private static bool ReceivesInput(GameObject target)
        {
            foreach (Component component in target.GetComponents<Component>())
            {
                if (component is IEventSystemHandler)
                    return true;
            }

            return false;
        }

        private static bool HasInputGraphic(GameObject target)
        {
            foreach (Component component in target.GetComponents<Component>())
            {
                if (component is Graphic && component is IEventSystemHandler)
                    return true;
            }

            return false;
        }

        private static bool HasComponentOfType(GameObject target, string fullTypeName)
        {
            foreach (Component component in target.GetComponents<Component>())
            {
                if (component != null && IsType(component, fullTypeName))
                    return true;
            }

            return false;
        }

        private static bool IsType(Component component, string fullTypeName)
        {
            for (Type type = component.GetType(); type != null; type = type.BaseType)
            {
                if (type.FullName == fullTypeName)
                    return true;
            }

            return false;
        }
    }
}
