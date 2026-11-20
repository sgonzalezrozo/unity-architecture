using System;
using System.Collections.Generic;
using NUnit.Framework;

namespace UnityArchitecture.Prefabs.Tests
{
    /// <summary>
    /// TEST-12: every prefab under Assets/Client follows the prefab rules a tool can check. There's one test case per
    /// feature folder, named after it (UnityArchitecture.Prefabs.Tests.ClientPrefabsTests.Inventory), so the Stop hook
    /// can check only the features whose prefabs changed. Prefabs directly in Assets/Client are the Root case.
    /// </summary>
    public class ClientPrefabsTests
    {
        // NUnit needs at least one case to show the test, so a project with no prefabs gets one that passes.
        private const string NO_PREFABS = "NoPrefabs";

        private static IEnumerable<TestCaseData> Features()
        {
            SortedSet<string> features = new(StringComparer.Ordinal);
            foreach (string path in PrefabValidator.FindClientPrefabs())
                features.Add(PrefabValidator.FeatureOf(path));

            if (features.Count == 0)
                features.Add(NO_PREFABS);

            foreach (string feature in features)
                yield return new TestCaseData(feature).SetName(feature);
        }

        [TestCaseSource(nameof(Features))]
        public void ClientPrefabsFollowThePrefabRules(string feature)
        {
            List<string> errors = new();
            foreach (string path in PrefabValidator.FindClientPrefabs())
            {
                if (PrefabValidator.FeatureOf(path) != feature)
                    continue;

                foreach (PrefabViolation violation in PrefabValidator.ValidateAsset(path))
                {
                    if (violation.IsWarning)
                        TestContext.WriteLine(violation.ToString());
                    else
                        errors.Add(violation.ToString());
                }
            }

            Assert.IsEmpty(errors, string.Join("\n", errors));
        }
    }
}
