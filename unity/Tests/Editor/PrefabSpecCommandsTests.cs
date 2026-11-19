using NUnit.Framework;
using UnityEditor;
using UnityEngine;

namespace UnityArchitecture.Prefabs.Tests
{
    /// <summary>Where Build Prefab From Spec puts the prefab: next to the spec, or the existing prefab with the spec's name.</summary>
    public class PrefabSpecCommandsTests
    {
        private const string FOLDER = "Assets/UnityArchitectureSpecCommandTests";
        private const string SPECS = FOLDER + "/Specs";
        private const string FEATURE = FOLDER + "/Banner";

        [SetUp]
        public void SetUp()
        {
            AssetDatabase.CreateFolder("Assets", "UnityArchitectureSpecCommandTests");
            AssetDatabase.CreateFolder(FOLDER, "Specs");
            AssetDatabase.CreateFolder(FOLDER, "Banner");
        }

        [TearDown]
        public void TearDown()
        {
            AssetDatabase.DeleteAsset(FOLDER);
        }

        [Test]
        public void ANewPrefab_GoesNextToTheSpec()
        {
            string path = PrefabSpecCommands.PrefabPathFor(SPECS + "/Banner.json", "Banner", FOLDER);

            Assert.AreEqual(SPECS + "/Banner.prefab", path);
        }

        [Test]
        public void AnExistingPrefabWithTheSpecsName_IsRebuilt()
        {
            SavePrefab(FEATURE + "/Banner.prefab");

            string path = PrefabSpecCommands.PrefabPathFor(SPECS + "/Banner.json", "Banner", FOLDER);

            Assert.AreEqual(FEATURE + "/Banner.prefab", path);
        }

        [Test]
        public void APrefabNextToTheSpec_WinsOverOneElsewhere()
        {
            SavePrefab(FEATURE + "/Banner.prefab");
            SavePrefab(SPECS + "/Banner.prefab");

            string path = PrefabSpecCommands.PrefabPathFor(SPECS + "/Banner.json", "Banner", FOLDER);

            Assert.AreEqual(SPECS + "/Banner.prefab", path);
        }

        [Test]
        public void TwoPrefabsWithTheSpecsName_AreNotGuessed()
        {
            AssetDatabase.CreateFolder(FOLDER, "Other");
            SavePrefab(FEATURE + "/Banner.prefab");
            SavePrefab(FOLDER + "/Other/Banner.prefab");

            string path = PrefabSpecCommands.PrefabPathFor(SPECS + "/Banner.json", "Banner", FOLDER);

            Assert.AreEqual(SPECS + "/Banner.prefab", path);
        }

        private static void SavePrefab(string path)
        {
            GameObject root = new("Banner", typeof(RectTransform));
            PrefabUtility.SaveAsPrefabAsset(root, path);
            Object.DestroyImmediate(root);
        }
    }
}
