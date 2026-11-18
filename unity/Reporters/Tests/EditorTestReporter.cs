using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEditor.TestTools.TestRunner.Api;
using UnityEngine;

namespace UnityArchitecture.Reporters
{
    /// <summary>
    /// Writes the result of every test run started in the open Editor (Test Runner window, or an MCP tool such as
    /// run_tests) to Logs/verify/editor-tests.json, for the Claude Code Stop hook.
    /// Only compiled when the Test Framework package is installed.
    /// </summary>
    [InitializeOnLoad]
    internal static class EditorTestReporter
    {
        private const string REPORT_FILE = "editor-tests.json";
        private const string PREFAB_REPORT_FILE = "editor-prefabs.json";

        // The prefab validator over Assets/Client (TEST-12), in the .ai/unity package. The hook asks for it when a prefab changed.
        private const string PREFAB_TEST = "UnityArchitecture.Prefabs.Tests.ClientPrefabsTests.ClientPrefabsFollowThePrefabRules";

        // How many EditMode tests the project has, to tell a full run from a filtered one (the related tests, TEST-11).
        private static int editModeTestCount = -1;

        static EditorTestReporter()
        {
            TestRunnerApi api = ScriptableObject.CreateInstance<TestRunnerApi>();
            api.RegisterCallbacks(new Callbacks());
            api.RetrieveTestList(TestMode.EditMode, RememberEditModeTestCount);
        }

        private static void RememberEditModeTestCount(ITestAdaptor root)
        {
            editModeTestCount = root.TestCaseCount;
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
                int total = result.PassCount + result.FailCount + result.SkipCount + result.InconclusiveCount;
                TestReport report = new()
                {
                    startedAtUnixSeconds = _startedAtUnixSeconds > 0 ? _startedAtUnixSeconds : finishedAt,
                    // RunStarted gets the whole tree even for a filtered run, so count what actually ran.
                    fullRun = editModeTestCount > 0 && total >= editModeTestCount,
                    finishedAtUnixSeconds = finishedAt,
                    total = total,
                    passed = result.PassCount,
                    failed = result.FailCount,
                    failures = failures.ToArray()
                };
                VerifyReports.Write(REPORT_FILE, JsonUtility.ToJson(report, true));
            }

            public void TestStarted(ITestAdaptor test)
            {
            }

            public void TestFinished(ITestResultAdaptor result)
            {
                if (result.Test.FullName != PREFAB_TEST)
                    return;

                PrefabReport report = new()
                {
                    startedAtUnixSeconds = _startedAtUnixSeconds,
                    passed = result.TestStatus == TestStatus.Passed,
                    errors = result.TestStatus == TestStatus.Passed ? new string[0] : ErrorLines(result.Message)
                };
                VerifyReports.Write(PREFAB_REPORT_FILE, JsonUtility.ToJson(report, true));
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
    }
}
