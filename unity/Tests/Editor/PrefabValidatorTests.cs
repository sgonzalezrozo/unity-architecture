using System.Collections.Generic;
using NUnit.Framework;
using UnityArchitecture.Prefabs.Fixtures;
using UnityEditor;
using UnityEngine;
using UnityEngine.UI;

namespace UnityArchitecture.Prefabs.Tests
{
    /// <summary>Each rule on a hierarchy built in code, starting from a card that follows them all.</summary>
    public class PrefabValidatorTests
    {
        private const string TEMP_FOLDER = "Assets/UnityArchitecturePrefabTests";
        private static readonly string[] LAYER_ASSEMBLY = { "UnityArchitecture.Prefabs.Fixtures" };

        private readonly List<GameObject> created = new();

        [TearDown]
        public void TearDown()
        {
            foreach (GameObject gameObject in created)
                Object.DestroyImmediate(gameObject);

            created.Clear();
            AssetDatabase.DeleteAsset(TEMP_FOLDER);
        }

        [Test]
        public void AValidCard_HasNoViolations()
        {
            GameObject card = BuildCard();

            CollectionAssert.IsEmpty(Validate(card));
        }

        [Test]
        public void ARootWithScale_BreaksPrefab01()
        {
            GameObject card = BuildCard();
            card.transform.localScale = new Vector3(2f, 2f, 1f);

            AssertRule(card, "PREFAB-01");
        }

        [Test]
        public void LegacyText_BreaksPrefab04()
        {
            GameObject card = BuildCard();
            AddChild(card, "Label", typeof(Text)).GetComponent<Text>().raycastTarget = false;

            AssertRule(card, "PREFAB-04");
        }

        [Test]
        public void AnAnimator_BreaksPrefab05()
        {
            GameObject card = BuildCard();
            card.AddComponent<Animator>();

            AssertRule(card, "PREFAB-05");
        }

        [Test]
        public void AButton_BreaksArch05()
        {
            GameObject card = BuildCard();
            GameObject button = AddChild(card, "Buy", typeof(Image), typeof(Button));
            button.GetComponent<Image>().raycastTarget = false;

            AssertRule(card, "ARCH-05");
        }

        [Test]
        public void AMask_IsAWarningForPrefab07()
        {
            GameObject card = BuildCard();
            GameObject clip = AddChild(card, "Clip", typeof(Image), typeof(Mask));
            clip.GetComponent<Image>().raycastTarget = false;

            PrefabViolation violation = Find(Validate(card), "PREFAB-07");
            Assert.IsTrue(violation.IsWarning);
        }

        [Test]
        public void AVisibleActionImage_BreaksPrefab09()
        {
            GameObject card = BuildCard();
            card.transform.Find("Action").GetComponent<Image>().color = Color.white;

            AssertRule(card, "PREFAB-09");
        }

        [Test]
        public void ADeepHierarchy_IsAWarningForPrefab13()
        {
            GameObject card = BuildCard();
            GameObject parent = card;
            for (int level = 0; level < PrefabValidator.MAX_DEPTH + 1; level++)
                parent = AddChild(parent, "Level" + level);

            PrefabViolation violation = Find(Validate(card), "PREFAB-13");
            Assert.IsTrue(violation.IsWarning);
        }

        [Test]
        public void ABackgroundWithoutRaycast_BreaksPrefab14()
        {
            GameObject card = BuildCard();
            card.transform.Find("Background").GetComponent<Image>().raycastTarget = false;

            AssertRule(card, "PREFAB-14");
        }

        [Test]
        public void AnActionThatIsntLast_BreaksInput02()
        {
            GameObject card = BuildCard();
            card.transform.Find("Action").SetAsFirstSibling();

            AssertRule(card, "INPUT-02");
        }

        [Test]
        public void AControllerOutsideAction_BreaksInput01()
        {
            GameObject card = BuildCard();
            AddChild(card, "Claim", typeof(ClaimController));

            AssertRule(card, "INPUT-01");
        }

        [Test]
        public void AVisualWithRaycast_BreaksInput03()
        {
            GameObject card = BuildCard();
            AddChild(card, "Icon", typeof(Image));

            AssertRule(card, "INPUT-03");
        }

        [Test]
        public void AModelBelowTheRoot_BreaksScope02()
        {
            GameObject card = BuildCard();
            AddChild(card, "Data", typeof(CardModel));

            AssertRule(card, "SCOPE-02");
        }

        [Test]
        public void AnInnerViewWithoutARootView_BreaksView03()
        {
            GameObject card = BuildCard();
            Object.DestroyImmediate(card.GetComponent<CardView>());

            AssertRule(card, "VIEW-03");
        }

        [Test]
        public void AReferenceIntoANestedPrefab_BreaksScope04()
        {
            GameObject card = BuildCard();
            GameObject nested = InstantiateNestedPrefab(card);
            SerializedObject view = new(card.AddComponent<ShelfView>());
            view.FindProperty("rewardView").objectReferenceValue = nested.GetComponent<RewardView>();
            view.ApplyModifiedPropertiesWithoutUndo();

            AssertRule(card, "SCOPE-04");
        }

        [Test]
        public void AnUnassignedViewField_BreaksPrefab15()
        {
            GameObject card = BuildCard();
            card.AddComponent<ShelfView>();

            AssertRule(card, "PREFAB-15");
        }

        [Test]
        public void AnAssignedViewField_IsFine()
        {
            GameObject card = BuildCard();
            SerializedObject view = new(card.AddComponent<ShelfView>());
            view.FindProperty("rewardView").objectReferenceValue = card.transform.Find("Reward").GetComponent<RewardView>();
            view.ApplyModifiedPropertiesWithoutUndo();

            CollectionAssert.IsEmpty(Validate(card));
        }

        [Test]
        public void ABackgroundInsideALayoutGroup_BreaksPrefab16()
        {
            GameObject card = BuildCard();
            card.AddComponent<VerticalLayoutGroup>();

            AssertRule(card, "PREFAB-16");
        }

        [Test]
        public void ANestedPrefab_IsNotCheckedFromOutside()
        {
            GameObject card = BuildCard();
            InstantiateNestedPrefab(card);

            CollectionAssert.IsEmpty(Validate(card));
        }

        // ClaimTrophyBanner-like card: root with Model and View, a blocking Background, an inner View, and Action last.
        private GameObject BuildCard()
        {
            GameObject card = new("Card", typeof(RectTransform), typeof(CardModel), typeof(CardView));
            created.Add(card);
            AddChild(card, "Background", typeof(Image));
            GameObject reward = AddChild(card, "Reward", typeof(RewardView));
            AddChild(reward, "RewardIcon", typeof(Image)).GetComponent<Image>().raycastTarget = false;
            AddAction(card);
            return card;
        }

        private static void AddAction(GameObject parent)
        {
            GameObject action = AddChild(parent, "Action", typeof(Image), typeof(ClaimController));
            action.GetComponent<Image>().color = new Color(1f, 1f, 1f, 0f);
            action.GetComponent<CanvasRenderer>().cullTransparentMesh = true;
        }

        // A prefab with a deliberately broken insides (a visual with raycast on), nested in the card.
        private GameObject InstantiateNestedPrefab(GameObject parent)
        {
            AssetDatabase.CreateFolder("Assets", "UnityArchitecturePrefabTests");
            GameObject source = new("Promo", typeof(RectTransform), typeof(RewardView));
            AddChild(source, "Glow", typeof(Image));
            GameObject asset = PrefabUtility.SaveAsPrefabAsset(source, TEMP_FOLDER + "/Promo.prefab");
            Object.DestroyImmediate(source);

            GameObject instance = (GameObject)PrefabUtility.InstantiatePrefab(asset, parent.transform);
            instance.transform.SetSiblingIndex(0);
            return instance;
        }

        private static GameObject AddChild(GameObject parent, string name, params System.Type[] components)
        {
            GameObject child = new(name, typeof(RectTransform));
            foreach (System.Type component in components)
                child.AddComponent(component);

            child.transform.SetParent(parent.transform, false);
            Transform action = parent.transform.Find("Action");
            if (action != null && action.gameObject != child)
                action.SetAsLastSibling();

            return child;
        }

        private static List<PrefabViolation> Validate(GameObject root)
        {
            return PrefabValidator.Validate(root, LAYER_ASSEMBLY);
        }

        private static void AssertRule(GameObject root, string ruleId)
        {
            PrefabViolation violation = Find(Validate(root), ruleId);
            Assert.IsFalse(violation.IsWarning, violation.ToString());
        }

        private static PrefabViolation Find(List<PrefabViolation> violations, string ruleId)
        {
            foreach (PrefabViolation violation in violations)
            {
                if (violation.RuleId == ruleId)
                    return violation;
            }

            Assert.Fail($"Expected {ruleId}. Found: {string.Join("; ", violations)}");
            return default;
        }
    }
}
