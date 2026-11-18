using System;
using System.Collections.Generic;
using NUnit.Framework;
using TMPro;
using UnityEditor;
using UnityEngine;

namespace UnityArchitecture.Prefabs.Tests
{
    /// <summary>A spec builds a prefab that passes the validator and matches the spec; changes to the prefab show up.</summary>
    public class PrefabSpecsTests
    {
        private const string FOLDER = "Assets/UnityArchitectureSpecTests";
        private static readonly string[] LAYER_ASSEMBLY = { "UnityArchitecture.Prefabs.Fixtures" };

        private const string QUIT_GAME_ALERT = @"{
  ""name"": ""QuitGameAlert"",
  ""components"": [""CardModel"", ""CardView""],
  ""children"": [
    { ""type"": ""background"", ""color"": [0, 0, 0, 0.6] },
    { ""type"": ""action"", ""controller"": ""ClaimController"" },
    {
      ""type"": ""container"", ""name"": ""Window"",
      ""layout"": { ""anchor"": [0.5, 0.5], ""size"": [600, 400] },
      ""children"": [
        { ""type"": ""background"" },
        { ""type"": ""text"", ""name"": ""Title"", ""text"": ""Quit the game?"" },
        { ""type"": ""text"", ""name"": ""Message"", ""text"": ""Your progress is saved."" },
        {
          ""type"": ""container"", ""name"": ""Cancel"",
          ""children"": [
            { ""type"": ""background"" },
            { ""type"": ""text"", ""name"": ""Text"", ""text"": ""Cancel"" },
            { ""type"": ""action"", ""controller"": ""ClaimController"" }
          ]
        },
        {
          ""type"": ""container"", ""name"": ""Quit"",
          ""children"": [
            {
              ""type"": ""container"", ""name"": ""Container"",
              ""children"": [
                { ""type"": ""background"" },
                { ""type"": ""text"", ""name"": ""Text"", ""text"": ""Quit"" },
                { ""type"": ""action"", ""controller"": ""ClaimController"" }
              ]
            }
          ]
        }
      ]
    }
  ]
}";

        private const string ITEM_SLOT = @"{
  ""name"": ""ItemSlot"",
  ""components"": [""CardModel"", ""CardView""],
  ""layout"": { ""anchor"": [0, 1], ""size"": [400, 120] },
  ""children"": [
    { ""type"": ""background"" },
    { ""type"": ""image"", ""name"": ""Icon"", ""layout"": { ""anchor"": [0, 0.5], ""size"": [96, 96], ""position"": [12, 0], ""pivot"": [0, 0.5] } },
    { ""type"": ""text"", ""name"": ""Name"", ""text"": ""Sword"" },
    { ""type"": ""container"", ""name"": ""Reward"", ""components"": [""RewardView""] },
    { ""type"": ""action"", ""controller"": ""TapController"" }
  ]
}";

        [SetUp]
        public void SetUp()
        {
            AssetDatabase.CreateFolder("Assets", "UnityArchitectureSpecTests");
        }

        [TearDown]
        public void TearDown()
        {
            AssetDatabase.DeleteAsset(FOLDER);
        }

        [Test]
        public void TheQuitGameAlertSpec_BuildsAPrefabThatFollowsTheRulesAndMatches()
        {
            string path = Build(QUIT_GAME_ALERT, "QuitGameAlert");

            AssertMatches(QUIT_GAME_ALERT, path);
        }

        [Test]
        public void ASlotSpec_SetsTheLayout()
        {
            string path = Build(ITEM_SLOT, "ItemSlot");

            AssertMatches(ITEM_SLOT, path);
            GameObject slot = AssetDatabase.LoadAssetAtPath<GameObject>(path);
            RectTransform icon = (RectTransform)slot.transform.Find("Icon");
            Assert.AreEqual(new Vector2(96f, 96f), icon.sizeDelta);
            Assert.AreEqual(new Vector2(12f, 0f), icon.anchoredPosition);
        }

        [Test]
        public void ASpecWithANestedPrefab_KeepsItAsAnInstance()
        {
            const string promo = @"{ ""name"": ""PromoSection"", ""components"": [""CardModel"", ""CardView""], ""children"": [ { ""type"": ""text"", ""name"": ""Title"", ""text"": ""Promo"" } ] }";
            Build(promo, "PromoSection");
            string shop = @"{ ""name"": ""Shop"", ""components"": [""CardModel"", ""CardView""], ""children"": [ { ""type"": ""prefab"", ""prefab"": """ + FOLDER + @"/PromoSection.prefab"" } ] }";

            AssertMatches(shop, Build(shop, "Shop"));
        }

        [Test]
        public void ChangesToTheBuiltPrefab_AreDifferences()
        {
            string path = Build(QUIT_GAME_ALERT, "QuitGameAlert");
            GameObject contents = PrefabUtility.LoadPrefabContents(path);
            Transform window = contents.transform.Find("Window");
            window.Find("Title").GetComponent<TextMeshProUGUI>().text = "Leave?";
            window.Find("Cancel").name = "Back";
            PrefabUtility.SaveAsPrefabAsset(contents, path);
            PrefabUtility.UnloadPrefabContents(contents);

            List<string> differences = PrefabSpecs.Compare(QUIT_GAME_ALERT, path, LAYER_ASSEMBLY);

            AssertContains(differences, "expected the text \"Quit the game?\", found \"Leave?\"");
            AssertContains(differences, "expected the name Cancel, found Back");
        }

        [Test]
        public void AMissingChild_IsADifference()
        {
            string path = Build(ITEM_SLOT, "ItemSlot");
            string withBadge = ITEM_SLOT.Replace(@"{ ""type"": ""background"" },", @"{ ""type"": ""background"" }, { ""type"": ""image"", ""name"": ""Badge"" },");

            List<string> differences = PrefabSpecs.Compare(withBadge, path, LAYER_ASSEMBLY);

            AssertContains(differences, "expected 6 children");
        }

        [TestCase("{ \"name\": \"Card\", \"children\": [ { \"type\": \"button\", \"name\": \"Buy\" } ] }", "unknown type 'button'")]
        [TestCase("{ \"name\": \"Card\", \"children\": [ { \"type\": \"action\" } ] }", "an action needs a controller")]
        [TestCase("{ \"name\": \"Card\", \"children\": [ { \"type\": \"background\", \"name\": \"Back\" } ] }", "always called Background")]
        [TestCase("{ \"name\": \"Card\", \"children\": [ { \"type\": \"text\" } ] }", "a text needs a name")]
        [TestCase("{ \"name\": \"Card\",\n  \"children\": [ } ", "line 2")]
        public void ABadSpec_SaysWhatToFix(string json, string expected)
        {
            FormatException exception = Assert.Throws<FormatException>(() => PrefabSpecNode.Parse(json));

            StringAssert.Contains(expected, exception.Message);
        }

        [Test]
        public void AnUnknownComponent_SaysWhereItLooked()
        {
            const string json = "{ \"name\": \"Card\", \"components\": [\"MissingView\"] }";

            ArgumentException exception = Assert.Throws<ArgumentException>(() => PrefabSpecs.BuildFromSpec(json, FOLDER + "/Card.prefab", LAYER_ASSEMBLY));

            StringAssert.Contains("No component called MissingView", exception.Message);
        }

        private static string Build(string json, string name)
        {
            string path = $"{FOLDER}/{name}.prefab";
            List<PrefabViolation> violations = PrefabSpecs.BuildFromSpec(json, path, LAYER_ASSEMBLY);
            CollectionAssert.IsEmpty(violations, string.Join("\n", violations));
            return path;
        }

        private static void AssertMatches(string json, string path)
        {
            List<string> differences = PrefabSpecs.Compare(json, path, LAYER_ASSEMBLY);
            CollectionAssert.IsEmpty(differences, string.Join("\n", differences));
        }

        private static void AssertContains(List<string> differences, string expected)
        {
            foreach (string difference in differences)
            {
                if (difference.Contains(expected))
                    return;
            }

            Assert.Fail($"Expected a difference with \"{expected}\". Found:\n{string.Join("\n", differences)}");
        }
    }
}
