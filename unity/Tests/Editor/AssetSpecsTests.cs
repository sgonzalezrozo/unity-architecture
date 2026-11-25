using System.Collections.Generic;
using System.IO;
using NUnit.Framework;
using UnityArchitecture.Prefabs.Fixtures;
using UnityEditor;

namespace UnityArchitecture.Prefabs.Tests
{
    public class AssetSpecsTests
    {
        private const string FOLDER = "Assets/UnityArchitectureAssetSpecsTests";
        private const string SPEC = FOLDER + "/Config.asset.json";
        private const string ASSET = FOLDER + "/Config.asset";
        private const string TYPE = "UnityArchitecture.Prefabs.Fixtures.AssetSpecFixtureConfig";

        [SetUp]
        public void SetUp()
        {
            Directory.CreateDirectory(FOLDER);
        }

        [TearDown]
        public void TearDown()
        {
            AssetDatabase.DeleteAsset(FOLDER);
            if (Directory.Exists(FOLDER))
                Directory.Delete(FOLDER, true);
            File.Delete(FOLDER + ".meta");
        }

        private static void WriteSpec(string values, string type = TYPE)
        {
            File.WriteAllText(SPEC, "{ \"type\": \"" + type + "\", \"values\": " + values + " }");
        }

        [Test]
        public void Build_NewSpec_CreatesTheAssetWithItsValues()
        {
            WriteSpec("{ \"version\": 2, \"title\": \"Starter \\\"kit\\\"\", \"items\": [ { \"id\": 1, \"displayName\": \"Iron Sword\", \"kind\": 0 }, { \"id\": 7, \"displayName\": \"Health Potion\", \"kind\": 2 } ] }");

            List<string> problems = AssetSpecs.Build(SPEC);

            Assert.IsEmpty(problems);
            AssetSpecFixtureConfig config = AssetDatabase.LoadAssetAtPath<AssetSpecFixtureConfig>(ASSET);
            Assert.AreEqual(2, config.Version);
            Assert.AreEqual("Starter \"kit\"", config.Title);
            Assert.AreEqual(2, config.Items.Count);
            Assert.AreEqual(AssetSpecFixtureKind.Potion, config.Items[1].kind);
        }

        [Test]
        public void Build_ExistingAsset_UpdatesItInPlace()
        {
            WriteSpec("{ \"version\": 1 }");
            AssetSpecs.Build(SPEC);
            string guid = AssetDatabase.AssetPathToGUID(ASSET);
            WriteSpec("{ \"version\": 5 }");

            List<string> problems = AssetSpecs.Build(SPEC);

            Assert.IsEmpty(problems);
            Assert.AreEqual(guid, AssetDatabase.AssetPathToGUID(ASSET));
            Assert.AreEqual(5, AssetDatabase.LoadAssetAtPath<AssetSpecFixtureConfig>(ASSET).Version);
        }

        [Test]
        public void Build_UnknownField_IsReported()
        {
            WriteSpec("{ \"version\": 1, \"colour\": \"red\" }");

            List<string> problems = AssetSpecs.Build(SPEC);

            Assert.That(problems, Has.Some.Contains("values.colour: no such serialized field"));
        }

        [Test]
        public void Build_UnknownType_CreatesNothing()
        {
            WriteSpec("{ \"version\": 1 }", "Client.Missing.MissingConfig");

            List<string> problems = AssetSpecs.Build(SPEC);

            Assert.That(problems, Has.Some.Contains("isn't a concrete ScriptableObject type"));
            Assert.IsFalse(File.Exists(ASSET));
        }

        [Test]
        public void Compare_ValueChangedByHand_ListsTheDifference()
        {
            WriteSpec("{ \"version\": 3 }");
            AssetSpecs.Build(SPEC);
            WriteSpec("{ \"version\": 4 }");

            List<string> differences = AssetSpecs.Compare(SPEC);

            Assert.That(differences, Has.Some.Contains("values.version: expected 4, is 3"));
        }

        [Test]
        public void BuildMissing_SkipsSpecsThatAlreadyHaveTheirAsset()
        {
            WriteSpec("{ \"version\": 1 }");
            AssetSpecs.Build(SPEC);

            Dictionary<string, List<string>> results = AssetSpecs.BuildMissing(FOLDER);

            Assert.IsEmpty(results);
        }
    }
}
