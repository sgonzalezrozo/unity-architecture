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

        static EditorTestReporter()
        {
            TestRunnerApi api = ScriptableObject.CreateInstance<TestRunnerApi>();
            api.RegisterCallbacks(new Callbacks());
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
                TestReport report = new()
                {
                    startedAtUnixSeconds = _startedAtUnixSeconds > 0 ? _startedAtUnixSeconds : finishedAt,
                    finishedAtUnixSeconds = finishedAt,
                    total = result.PassCount + result.FailCount + result.SkipCount + result.InconclusiveCount,
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
        private class TestReport
        {
            public long startedAtUnixSeconds;
            public long finishedAtUnixSeconds;
            public int total;
            public int passed;
            public int failed;
            public string[] failures;
        }
    }
}
