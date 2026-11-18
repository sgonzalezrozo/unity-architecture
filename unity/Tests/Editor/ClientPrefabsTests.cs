using System.Collections.Generic;
using NUnit.Framework;

namespace UnityArchitecture.Prefabs.Tests
{
    /// <summary>TEST-12: every prefab under Assets/Client follows the prefab rules a tool can check.</summary>
    public class ClientPrefabsTests
    {
        [Test]
        public void ClientPrefabsFollowThePrefabRules()
        {
            List<string> errors = new();
            foreach (string path in PrefabValidator.FindClientPrefabs())
            {
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
