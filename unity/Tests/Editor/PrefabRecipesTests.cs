using System.Collections.Generic;
using NUnit.Framework;
using UnityArchitecture.Prefabs.Fixtures;
using UnityEditor;
using UnityEngine;
using UnityEngine.UI;

namespace UnityArchitecture.Prefabs.Tests
{
    /// <summary>Each recipe builds a prefab that passes the validator with no errors and no warnings.</summary>
    public class PrefabRecipesTests
    {
        private const string FOLDER = "Assets/UnityArchitectureRecipeTests";
        private static readonly string[] LAYER_ASSEMBLY = { "UnityArchitecture.Prefabs.Fixtures" };

        [SetUp]
        public void SetUp()
        {
            AssetDatabase.CreateFolder("Assets", "UnityArchitectureRecipeTests");
        }

        [TearDown]
        public void TearDown()
        {
            AssetDatabase.DeleteAsset(FOLDER);
        }

        [Test]
        public void ABanner_FollowsTheRules()
        {
            GameObject banner = PrefabRecipes.CreateRoot("ClaimTrophyBanner", typeof(CardModel), typeof(CardView));
            PrefabRecipes.AddBackground(banner);
            PrefabRecipes.AddText(banner, "Label", "Claim your trophy");
            PrefabRecipes.AddImage(banner, "Icon");
            GameObject reward = PrefabRecipes.AddContainer(banner, "Reward");
            reward.AddComponent<RewardView>();
            PrefabRecipes.AddAction(banner, typeof(ClaimController));

            AssertFollowsTheRules(banner);
        }

        [Test]
        public void AScreen_FollowsTheRules()
        {
            GameObject screen = PrefabRecipes.CreateScreenRoot("ShopScreen", typeof(CardModel), typeof(CardView));
            GameObject buy = PrefabRecipes.AddContainer(screen.transform.Find(PrefabRecipes.CONTENT).gameObject, "Buy");
            PrefabRecipes.AddBackground(buy);
            PrefabRecipes.AddText(buy, "Text", "Buy");
            PrefabRecipes.AddAction(buy, typeof(ClaimController));

            AssertFollowsTheRules(screen);
        }

        [Test]
        public void AModalThatClosesOnATapOutside_FollowsTheRules()
        {
            GameObject alert = PrefabRecipes.CreateModalRoot("QuitGameAlert", new Vector2(600f, 400f), typeof(ClaimController), typeof(CardModel), typeof(CardView));
            GameObject window = alert.transform.Find(PrefabRecipes.WINDOW).gameObject;
            PrefabRecipes.AddText(window, "Title", "Quit?");
            GameObject cancel = PrefabRecipes.AddContainer(window, "Cancel");
            PrefabRecipes.AddBackground(cancel);
            PrefabRecipes.AddText(cancel, "Text", "Cancel");
            PrefabRecipes.AddAction(cancel, typeof(ClaimController));

            AssertFollowsTheRules(alert);
        }

        [Test]
        public void ASlot_FollowsTheRules()
        {
            GameObject slot = PrefabRecipes.CreateSlotRoot("ItemSlot", new Vector2(400f, 120f), typeof(CardModel), typeof(CardView));
            PrefabRecipes.AddBackground(slot);
            PrefabRecipes.AddImage(slot, "Icon");
            PrefabRecipes.AddText(slot, "Name", "Sword");
            PrefabRecipes.AddAction(slot, typeof(TapController));

            Assert.IsNull(slot.transform.Find(PrefabRecipes.ACTION).GetComponent<Image>(), "a Controller that is a Graphic needs no Image");
            AssertFollowsTheRules(slot);
        }

        [Test]
        public void AMeasuredSlot_KeepsItsBackgroundAndActionOutOfTheLayout()
        {
            GameObject slot = PrefabRecipes.CreateSlotRoot("MeasuredSlot", new Vector2(400f, 120f), typeof(CardModel), typeof(CardView), typeof(VerticalLayoutGroup));
            PrefabRecipes.AddBackground(slot);
            PrefabRecipes.AddText(slot, "Name", "Sword");
            PrefabRecipes.AddAction(slot, typeof(ClaimController));

            Assert.IsTrue(slot.transform.Find("Background").GetComponent<LayoutElement>().ignoreLayout);
            AssertFollowsTheRules(slot);
        }

        [Test]
        public void StateRoots_FollowTheRules()
        {
            GameObject purchase = PrefabRecipes.CreateRoot("PurchaseArea", typeof(CardModel), typeof(CardView));
            List<GameObject> states = PrefabRecipes.AddStateRoots(purchase, "Available", "Locked", "Owned");
            PrefabRecipes.AddBackground(states[0]);
            PrefabRecipes.AddText(states[0], "Price", "100");
            PrefabRecipes.AddAction(states[0], typeof(ClaimController));
            PrefabRecipes.AddImage(states[1], "LockIcon");

            Assert.AreEqual("AvailableRoot", states[0].name);
            AssertFollowsTheRules(purchase);
        }

        [Test]
        public void ANestedPrefab_StaysItsOwnScope()
        {
            GameObject promo = PrefabRecipes.CreateRoot("PromoSection", typeof(CardModel), typeof(CardView));
            PrefabRecipes.AddText(promo, "Title", "Promo");
            AssertFollowsTheRules(promo);

            GameObject shop = PrefabRecipes.CreateRoot("Shop", typeof(CardModel), typeof(CardView));
            PrefabRecipes.AddNestedPrefab(shop, FOLDER + "/PromoSection.prefab");
            AssertFollowsTheRules(shop);
        }

        [Test]
        public void TheVisualsChild_KeepsTheRootAtScaleOne()
        {
            GameObject card = PrefabRecipes.CreateRoot("Card", typeof(CardModel), typeof(CardView));
            GameObject visuals = PrefabRecipes.AddVisuals(card);
            visuals.transform.localScale = new Vector3(1.2f, 1.2f, 1f);
            PrefabRecipes.AddImage(visuals, "Frame");

            AssertFollowsTheRules(card);
        }

        private static void AssertFollowsTheRules(GameObject root)
        {
            string path = $"{FOLDER}/{root.name}.prefab";
            List<PrefabViolation> violations = PrefabRecipes.SaveAndValidate(root, path, LAYER_ASSEMBLY);

            CollectionAssert.IsEmpty(violations, string.Join("\n", violations));
        }
    }
}
