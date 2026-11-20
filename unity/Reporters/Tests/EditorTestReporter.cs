using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEditor.TestTools.TestRunner.Api;
using UnityEngine;

namespace UnityArchitecture.Reporters
{
    /// <summary>
    /// Writes the result of every test run started in the open Editor (Test Runner window, or an MCP tool such as
    /// run_tests) to Logs/verify/ for the Claude Code Stop hook: editor-tests.json for the whole run,
    /// editor-tests-{Feature}.json for the tests of each feature in it (namespace Client.{Feature}), and
    /// editor-prefabs-{Feature}.json for each feature the prefab validator checked.
    /// Only compiled when the Test Framework package is installed.
    /// </summary>
    [InitializeOnLoad]
    internal static class EditorTestReporter
    {
        private const string REPORT_FILE = "editor-tests.json";
        private const string FEATURE_REPORT_FILE = "editor-tests-{0}.json";
        private const string PREFAB_REPORT_FILE = "editor-prefabs-{0}.json";

        // The prefab validator over Assets/Client (TEST-12), in the .ai/unity package: one case per feature, named after it.
        private const string PREFAB_CASE_PREFIX = "UnityArchitecture.Prefabs.Tests.ClientPrefabsTests.";

        // A project test's full name starts with its feature's namespace: Client.{Feature}.Tests...
        private const string CLIENT_NAMESPACE_PREFIX = "Client.";

        // How many EditMode tests the project has, in all and per feature, to tell a full run (or a whole feature's
        // run) from a filtered one, such as the related tests (TEST-11).
        private static int editModeTestCount = -1;
        private static readonly Dictionary<string, int> featureTestCounts = new();

        static EditorTestReporter()
        {
            TestRunnerApi api = ScriptableObject.CreateInstance<TestRunnerApi>();
            api.RegisterCallbacks(new Callbacks());
            api.RetrieveTestList(TestMode.EditMode, RememberEditModeTestCount);
        }

        private static void RememberEditModeTestCount(ITestAdaptor root)
        {
            editModeTestCount = root.TestCaseCount;
            featureTestCounts.Clear();
            CountFeatureTests(root);
        }

        private static void CountFeatureTests(ITestAdaptor test)
        {
            if (!test.HasChildren)
            {
                string feature = FeatureOf(test.FullName);
                if (feature != null)
                    featureTestCounts[feature] = featureTestCounts.TryGetValue(feature, out int count) ? count + 1 : 1;
                return;
            }

            foreach (ITestAdaptor child in test.Children)
                CountFeatureTests(child);
        }

        /// <summary>The feature of a project test (Client.Inventory.Tests.X → Inventory), or null for any other test.</summary>
        private static string FeatureOf(string fullName)
        {
            if (!fullName.StartsWith(CLIENT_NAMESPACE_PREFIX, StringComparison.Ordinal))
                return null;

            int start = CLIENT_NAMESPACE_PREFIX.Length;
            int end = fullName.IndexOf('.', start);
            return end < 0 ? null : fullName.Substring(start, end - start);
        }

        private class Callbacks : ICallbacks
        {
            private long _startedAtUnixSeconds;

            public void RunStarted(ITestAdaptor testsToRun)
            {
                _startedAtUnixSeconds = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
            }

            public void RunFinished(ITestResultAdaptor result)
            {
                List<string> failures = new();
                CollectFailures(result, failures);

                long finishedAt = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
                long startedAt = _startedAtUnixSeconds > 0 ? _startedAtUnixSeconds : finishedAt;
                int total = result.PassCount + result.FailCount + result.SkipCount + result.InconclusiveCount;
                TestReport report = new()
                {
                    startedAtUnixSeconds = startedAt,
                    // RunStarted gets the whole tree even for a filtered run, so count what actually ran.
                    fullRun = editModeTestCount > 0 && total >= editModeTestCount,
                    finishedAtUnixSeconds = finishedAt,
                    total = total,
                    passed = result.PassCount,
                    failed = result.FailCount,
                    failures = failures.ToArray()
                };
                VerifyReports.Write(REPORT_FILE, JsonUtility.ToJson(report, true));
                WriteFeatureReports(result, startedAt, finishedAt);
            }

            private static void WriteFeatureReports(ITestResultAdaptor result, long startedAt, long finishedAt)
            {
                Dictionary<string, FeatureTestReport> reports = new();
                CollectFeatureResults(result, reports);
                foreach (KeyValuePair<string, FeatureTestReport> entry in reports)
                {
                    FeatureTestReport report = entry.Value;
                    report.startedAtUnixSeconds = startedAt;
                    report.finishedAtUnixSeconds = finishedAt;
                    report.complete = featureTestCounts.TryGetValue(entry.Key, out int count) && report.total >= count;
                    report.failures = report.failureList.ToArray();
                    VerifyReports.Write(string.Format(FEATURE_REPORT_FILE, entry.Key), JsonUtility.ToJson(report, true));
                }
            }

            private static void CollectFeatureResults(ITestResultAdaptor result, Dictionary<string, FeatureTestReport> reports)
            {
                if (result.HasChildren)
                {
                    foreach (ITestResultAdaptor child in result.Children)
                        CollectFeatureResults(child, reports);
                    return;
                }

                string feature = FeatureOf(result.Test.FullName);
                if (feature == null)
                    return;

                if (!reports.TryGetValue(feature, out FeatureTestReport report))
                {
                    report = new FeatureTestReport();
                    reports.Add(feature, report);
                }

                report.total++;
                if (result.TestStatus == TestStatus.Failed)
                {
                    report.failed++;
                    report.failureList.Add(result.Test.FullName);
                }
            }

            public void TestStarted(ITestAdaptor test)
            {
            }

            public void TestFinished(ITestResultAdaptor result)
            {
                string fullName = result.Test.FullName;
                if (result.HasChildren || !fullName.StartsWith(PREFAB_CASE_PREFIX, StringComparison.Ordinal))
                    return;

                string feature = fullName.Substring(PREFAB_CASE_PREFIX.Length);
                PrefabReport report = new()
                {
                    startedAtUnixSeconds = _startedAtUnixSeconds,
                    passed = result.TestStatus == TestStatus.Passed,
                    errors = result.TestStatus == TestStatus.Passed ? new string[0] : ErrorLines(result.Message)
                };
                VerifyReports.Write(string.Format(PREFAB_REPORT_FILE, feature), JsonUtility.ToJson(report, true));
            }

            private static string[] ErrorLines(string message)
            {
                List<string> lines = new();
                foreach (string line in (message ?? string.Empty).Split('\n'))
                {
                    // The validator's lines start with the prefab's path; NUnit repeats them in its "But was:" line.
                    string trimmed = line.Trim();
                    if (trimmed.StartsWith("Assets/", StringComparison.Ordinal) && trimmed.Contains(": error "))
                        lines.Add(trimmed);
                }

                return lines.ToArray();
            }

            private static void CollectFailures(ITestResultAdaptor result, List<string> failures)
            {
                if (!result.HasChildren)
                {
                    if (result.TestStatus == TestStatus.Failed)
                        failures.Add(result.Test.FullName);
                    return;
                }

                foreach (ITestResultAdaptor child in result.Children)
                    CollectFailures(child, failures);
            }
        }

        [Serializable]
        private class PrefabReport
        {
            public long startedAtUnixSeconds;
            public bool passed;
            public string[] errors;
        }

        [Serializable]
        private class TestReport
        {
            public long startedAtUnixSeconds;
            public bool fullRun;
            public long finishedAtUnixSeconds;
            public int total;
            public int passed;
            public int failed;
            public string[] failures;
        }

        [Serializable]
        private class FeatureTestReport
        {
            public long startedAtUnixSeconds;
            public bool complete;
            public long finishedAtUnixSeconds;
            public int total;
            public int failed;
            public string[] failures;

            [NonSerialized] public readonly List<string> failureList = new();
        }
    }
}
